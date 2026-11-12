// Testbench for bnn_neuron.
//
// Part 1, directed edge cases. The real data below only produces scores
// from 16 to 48, so these cover what it never reaches: score 0 and 64
// (all 7 output bits) and the threshold extremes 0 and 64.
//
// Part 2, real vectors. Every (image, hidden neuron) pair from test_x.hex
// and w1.hex/t1.hex: 450 x 32 = 14400 checks. Expected answers come from
// the Python golden model (python/gen_expected_tb_neuron.py).
// Each line of data/tb_neuron.hex is: x w thresh score fire (all hex).
// 1141 of these vectors have score == thresh, which checks >= vs >.
`timescale 1ns/1ps
module tb_neuron;
    reg  [63:0] x, w;
    reg  [6:0]  thresh;
    wire [6:0]  score;
    wire        fire;
    reg  [6:0]  exp_score;
    reg         exp_fire;
    integer fd, errors, checks;

    bnn_neuron #(.N(64)) dut (.x(x), .w(w), .thresh(thresh), .score(score), .fire(fire));

    task check;
        begin
            #1;
            checks = checks + 1;
            if (score !== exp_score || fire !== exp_fire) begin
                errors = errors + 1;
                if (errors <= 10)
                    $display("FAIL x=%h w=%h thresh=%0d got score=%0d fire=%b expected score=%0d fire=%b",
                             x, w, thresh, score, fire, exp_score, exp_fire);
            end
        end
    endtask

    initial begin
        errors = 0;
        checks = 0;

        // Part 1: directed edge cases
        x = 64'h0;      w = 64'h0;      thresh = 64; exp_score = 64; exp_fire = 1; check; // all agree, thresh 64 fires
        x = 64'h0;      w = ~64'h0;     thresh = 0;  exp_score = 0;  exp_fire = 1; check; // none agree, thresh 0 always fires
        x = 64'h0;      w = ~64'h0;     thresh = 1;  exp_score = 0;  exp_fire = 0; check; // score 0 below thresh 1
        x = 64'h0;      w = 64'h1;      thresh = 64; exp_score = 63; exp_fire = 0; check; // one bit off, just misses 64
        x = ~64'h0;     w = ~64'h0;     thresh = 64; exp_score = 64; exp_fire = 1; check; // all ones agree too
        x = 64'h8000_0000_0000_0000;
                        w = 64'h0;      thresh = 63; exp_score = 63; exp_fire = 1; check; // top bit (bit 63) differs

        // Part 2: real vectors from the Python model
        fd = $fopen("data/tb_neuron.hex", "r");
        if (fd == 0) begin
            $display("FAIL tb_neuron: cannot open data/tb_neuron.hex (run python/gen_expected_tb_neuron.py)");
            $finish;
        end
        while ($fscanf(fd, "%h %h %h %h %h\n", x, w, thresh, exp_score, exp_fire) == 5)
            check;
        $fclose(fd);

        if (errors == 0) $display("PASS tb_neuron (%0d checks)", checks);
        else             $display("FAIL tb_neuron: %0d errors in %0d checks", errors, checks);
        $finish;
    end
endmodule
