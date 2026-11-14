// bnn_top: the whole 64 -> 32 -> 10 binary network. See README.md for the spec.
//
// Interface (do not change the ports or parameter names):
//   start     : one-cycle pulse. Capture x on this cycle.
//   busy      : high while computing.
//   done      : one-cycle pulse when hidden and class_out are valid.
//               They must stay valid until the next start.
//   P         : number of layer-1 neurons computed per clock (1, 2, 4, 8, 16, 32).
//
// Weights come from hex files with $readmemh. Paths are relative to the
// directory you run the simulation from (the kit directory).
module bnn_top #(
    /* verilator lint_off UNUSEDPARAM */  // P is not used yet: this version is P = 1 only
    parameter P = 1,
    /* verilator lint_on UNUSEDPARAM */
    parameter W1_FILE = "data/w1.hex",
    parameter T1_FILE = "data/t1.hex",
    parameter W2_FILE = "data/w2.hex"
) (
    input  wire        clk,
    input  wire        rst,        // synchronous, active high
    input  wire        start,
    input  wire [63:0] x,
    output reg         busy,
    output reg         done,
    output reg  [31:0] hidden,
    output reg  [3:0]  class_out
);
    reg [63:0] w1 [0:31];
    reg [6:0]  t1 [0:31];
    reg [31:0] w2 [0:9];
    initial begin
        $readmemh(W1_FILE, w1);
        $readmemh(T1_FILE, t1);
        $readmemh(W2_FILE, w2);
    end

    // ------------------------------------------------------------ control signals
    localparam L1_IDLE = 1'b0, L1_WORKING = 1'b1;
    localparam L2_IDLE = 2'd0, L2_WORKING = 2'd1, L2_DONE = 2'd2;

    reg       l1_state, l1_next;
    reg [1:0] l2_state, l2_next;
    reg [4:0] cnt_j;
    reg [3:0] cnt_k;

    wire l1_idle = (l1_state == L1_IDLE);
    wire l2_idle = (l2_state == L2_IDLE);
    wire in_L1   = (l1_state == L1_WORKING);
    wire in_L2   = (l2_state == L2_WORKING);

    wire load_x  = start && l1_idle && l2_idle;
    wire L1_done = (cnt_j == 5'd31) && in_L1;
    wire L2_done = (cnt_k == 4'd9)  && in_L2;

    always @(*) begin
        busy = !l1_idle || !l2_idle;
        done = (l2_state == L2_DONE);
    end

    // ------------------------------------------------------------ L1 FSM
    always @(posedge clk)
        if (rst) l1_state <= L1_IDLE;
        else     l1_state <= l1_next;

    always @(*) begin
        case (l1_state)
            L1_IDLE:    if (load_x)  l1_next = L1_WORKING;
                        else         l1_next = L1_IDLE;
            L1_WORKING: if (L1_done) l1_next = L1_IDLE;
                        else         l1_next = L1_WORKING;
        endcase
    end

    // ------------------------------------------------------------ L2 FSM
    always @(posedge clk)
        if (rst) l2_state <= L2_IDLE;
        else     l2_state <= l2_next;

    always @(*) begin
        case (l2_state)
            L2_IDLE:    if (L1_done) l2_next = L2_WORKING;
                        else         l2_next = L2_IDLE;
            L2_WORKING: if (L2_done) l2_next = L2_DONE;
                        else         l2_next = L2_WORKING;
            L2_DONE:                 l2_next = L2_IDLE;
            default:                 l2_next = L2_IDLE;
        endcase
    end

    // ------------------------------------------------------------ layer 1
    reg [63:0] x_reg;
    always @(posedge clk)
        if (load_x) x_reg <= x;

    always @(posedge clk)
        if (load_x)     cnt_j <= 5'd0;
        else if (in_L1) cnt_j <= cnt_j + 5'd1;

    wire fire1;
    // score of L1 and fire of L2 are not needed, so those pins are left empty
    /* verilator lint_off PINCONNECTEMPTY */
    bnn_neuron #(.N(64)) L1_neuron (
        .x(x_reg), .w(w1[cnt_j]), .thresh(t1[cnt_j]),
        .score(), .fire(fire1)
    );

    always @(posedge clk)
        if (in_L1) hidden[cnt_j] <= fire1;

    // ------------------------------------------------------------ layer 2
    always @(posedge clk)
        if (L1_done)    cnt_k <= 4'd0;
        else if (in_L2) cnt_k <= cnt_k + 4'd1;

    wire [5:0] score2;
    bnn_neuron #(.N(32)) L2_neuron (
        .x(hidden), .w(w2[cnt_k]), .thresh(6'd0),
        .score(score2), .fire()
    );
    /* verilator lint_on PINCONNECTEMPTY */

    reg  [5:0] max_score;
    wire       upd = (score2 > max_score);   // strict: a tie keeps the lower class

    always @(posedge clk)
        if (L1_done) begin
            max_score <= 6'd0;
            class_out <= 4'd0;
        end else if (upd && in_L2) begin
            max_score <= score2;
            class_out <= cnt_k;
        end

endmodule
