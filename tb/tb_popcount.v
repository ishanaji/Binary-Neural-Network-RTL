// Testbench for popcount. Provided. Do not edit; write your own tests too.
`timescale 1ns/1ps
module tb_popcount;
    reg  [63:0] in;
    wire [6:0]  count;
    integer i, b, ref_count, errors;

    popcount #(.N(64)) dut (.in(in), .count(count));

    task check;
        begin
            ref_count = 0;
            for (b = 0; b < 64; b = b + 1) ref_count = ref_count + in[b];
            #1;
            if (count !== ref_count) begin
                errors = errors + 1;
                if (errors <= 10)
                    $display("FAIL in=%h got=%0d expected=%0d", in, count, ref_count);
            end
        end
    endtask

    initial begin
        errors = 0;
        in = 64'h0;                  check;
        in = {64{1'b1}};             check;
        for (i = 0; i < 64; i = i + 1) begin
            in = 64'h1 << i;         check;
            in = ~(64'h1 << i);      check;
        end
        for (i = 0; i < 5000; i = i + 1) begin
            in = {$random, $random}; check;
        end
        if (errors == 0) $display("PASS tb_popcount");
        else             $display("FAIL tb_popcount: %0d errors", errors);
        $finish;
    end
endmodule
