// bnn_neuron: one binary neuron.
//   score = number of positions where x and w agree  (popcount of XNOR)
//   fire  = (score >= thresh)
// Combinational. Use your popcount module. Keep the port list.
module bnn_neuron #(parameter N = 64, parameter W = $clog2(N+1)) (
    input  wire [N-1:0] x,
    input  wire [N-1:0] w,
    input  wire [W-1:0] thresh,
    output wire [W-1:0] score,
    output wire         fire
);
    // TODO
    wire[N-1:0] xnor_xw;
    assign xnor_xw = x ~^ w;
    popcount #(.N(N), .W(W)) pop1(xnor_xw, score);
    assign fire = (score >= thresh);
endmodule
