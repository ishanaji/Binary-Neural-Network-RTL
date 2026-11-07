// Testbench for bnn_top. Provided. Do not edit.
// Runs every test image through the design and checks the hidden layer bits
// and the predicted class against the Python reference in data/expected.hex.
`timescale 1ns/1ps
module tb_bnn_top;
    parameter P = 1;
    parameter N_TESTS = 450;
    parameter TIMEOUT = 1000;   // cycles allowed per image

    reg clk = 0, rst = 1, start = 0;
    reg  [63:0] x;
    wire busy, done;
    wire [31:0] hidden;
    wire [3:0]  class_out;

    bnn_top #(.P(P)) dut (.clk(clk), .rst(rst), .start(start), .x(x),
        .busy(busy), .done(done), .hidden(hidden), .class_out(class_out));

    always #5 clk = ~clk;

    reg [63:0] xs [0:N_TESTS-1];
    reg [31:0] exp_h;
    reg [3:0]  exp_c;
    integer fd_e, fd_y, label, n, cycles, total_cycles, max_cycles;
    integer errors, correct, r;

    initial begin
        $readmemh("data/test_x.hex", xs);
        fd_e = $fopen("data/expected.hex", "r");
        fd_y = $fopen("data/test_y.txt", "r");
        if (fd_e == 0 || fd_y == 0) begin
            $display("FAIL cannot open data files (run from the kit directory)");
            $finish;
        end
        errors = 0; correct = 0; total_cycles = 0; max_cycles = 0;
        repeat (3) @(posedge clk);
        rst <= 0;
        @(posedge clk);

        for (n = 0; n < N_TESTS; n = n + 1) begin
            r = $fscanf(fd_e, "%h %h\n", exp_h, exp_c);
            r = $fscanf(fd_y, "%d\n", label);
            x <= xs[n];
            start <= 1;
            @(posedge clk);
            start <= 0;
            x <= 64'hx;          // x must be captured on the start cycle
            cycles = 1;
            while (!done && cycles < TIMEOUT) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            if (!done) begin
                $display("FAIL image %0d: no done after %0d cycles", n, TIMEOUT);
                $finish;
            end
            #1;
            if (hidden !== exp_h || class_out !== exp_c) begin
                errors = errors + 1;
                if (errors <= 10)
                    $display("FAIL image %0d: hidden=%h class=%0d, expected hidden=%h class=%0d",
                             n, hidden, class_out, exp_h, exp_c);
            end
            if (class_out == label) correct = correct + 1;
            total_cycles = total_cycles + cycles;
            if (cycles > max_cycles) max_cycles = cycles;
            @(posedge clk);
            if (done) begin
                $display("FAIL done must be a one-cycle pulse");
                errors = errors + 1;
            end
        end

        $display("images=%0d  mismatches=%0d  accuracy=%0d/%0d  cycles/image avg=%0d max=%0d",
                 N_TESTS, errors, correct, N_TESTS, total_cycles / N_TESTS, max_cycles);
        if (errors == 0) $display("PASS tb_bnn_top (P=%0d)", P);
        else             $display("FAIL tb_bnn_top (P=%0d)", P);
        $finish;
    end
endmodule
