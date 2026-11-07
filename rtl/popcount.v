// popcount: count the number of 1 bits in `in`.
// Combinational. Keep the port list exactly as it is; the testbench uses it.
module popcount #(parameter N = 64, parameter W = $clog2(N+1)) (
    input  wire [N-1:0] in,
    output reg  [W-1:0] count
);
    // TODO
endmodule
