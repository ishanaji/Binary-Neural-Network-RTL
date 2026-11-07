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
    parameter P = 1,
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

    // TODO
endmodule
