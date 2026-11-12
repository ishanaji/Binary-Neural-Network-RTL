// popcount: count the number of 1 bits in `in`.
// Combinational. Keep the port list exactly as it is; the testbench uses it.
module popcount #(parameter N = 64, parameter W = $clog2(N+1)) (
    input  wire [N-1:0] in,
    output reg  [W-1:0] count
);
    integer i;
    always@(*) begin
        count = 0;
        for(i=0; i<N; i=i+1) begin
            //in[i] is 1-bit, so lint threw some warning, so I zero-extended it, 
            //harmless warning though as test_popcount passed.
            count = count + {{(W-1){1'b0}}, in[i]};
        end
    end
endmodule
