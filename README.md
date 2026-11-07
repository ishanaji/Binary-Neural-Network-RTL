# Hardware screener: a tiny binary neural network in Verilog

This is a one-week exercise you do on your own before starting a project with
us. It tells both of us whether the project work is a good fit for you right
now. It is not an exam. A clean, honest partial result is worth more than a
complete result you cannot explain.

Expected effort: about 20 hours over 7 days. If you are well past 30 hours,
stop, write up where you are, and send it.

## What you will build

A hardware block that classifies 8x8 handwritten digits using a binary
neural network (BNN). In a BNN every weight and every activation is a single
bit. Multiplication becomes XNOR, and adding up the products becomes counting
ones (popcount). That makes BNNs cheap in hardware, and a good first design.

The network is already trained. Its weights are in `data/`.

```
x  : 64 bits   one bit per pixel (pixel on if its value > 7), pixel 0 = bit 0
h  : 32 bits   h[j] = 1 if popcount(XNOR(x, W1[j])) >= T1[j], else 0
s  : 10 ints   s[k] = popcount(XNOR(h, W2[k]))       (each 0..32)
y  : 4 bits    the index k with the largest s[k]; on a tie, the lowest k
```

`XNOR(a, b)` is 1 in each bit position where `a` and `b` are equal.

## Files

| file | what it is |
|---|---|
| `data/w1.hex` | 32 lines, one 64-bit weight row per hidden neuron, bit 0 = pixel 0 |
| `data/t1.hex` | 32 lines, one threshold per hidden neuron (0..64) |
| `data/w2.hex` | 10 lines, one 32-bit weight row per output class, bit 0 = h[0] |
| `data/test_x.hex` | 450 test images, one 64-bit word per line |
| `data/test_y.txt` | the true digit for each test image |
| `data/expected.hex` | what the hardware must output: `hidden class` per line |
| `rtl/*.v` | the three modules you write (port lists given) |
| `tb/*.v` | provided testbenches; do not edit them |
| `python/train_bnn.py` | how the network was trained (read it, you do not need to run it) |
| `Makefile` | `make test`, `make lint`, `make synth`; see the top of the file |

## Tools

All free and open source. The kit has been tested on Ubuntu, where you
can install everything with:

```bash
sudo apt install iverilog verilator yosys gtkwave make python3
```

For Python, install `uv` (https://docs.astral.sh/uv/) and run scripts with
`uv run --with numpy python yourscript.py`. Windows users: use WSL2.

If you use another OS or distribution, you are responsible for fixing any
setup problems you run into. Say in your report what you changed.

Different Yosys versions give somewhat different cell counts. Run
`yosys -V` and put the version in your report.

## Tasks

The kit is not a git repository. Start one before you begin:

```bash
cd hw-screener
git init
git add -A
git commit -m "Initial kit"
```

The included `.gitignore` keeps build outputs and waveforms out of your
history. Do not commit them.

Do them in order. Commit to git after each step that works, with a message
that says what changed. We will look at your history, so commit as you go
rather than once at the end.

### A. Reference model in Python (about 3 hours)

Write `python/bnn_ref.py`. It reads the files in `data/`, runs every test
image through the network as specified above, and checks:

1. Your hidden bits and class match `data/expected.hex` for all 450 images.
2. The accuracy against `data/test_y.txt`. It should be 390/450.

This is your golden model. When the hardware disagrees with it later, it
is how you find out which side is wrong. Getting the bit ordering right is
part of the task.

### B. popcount and neuron (about 5 hours)

1. Write `rtl/popcount.v`. Pass `make test_popcount`.
2. Write `rtl/bnn_neuron.v`.
3. Write your own testbench `tb/tb_neuron.v` for the neuron. Decide what
   to test and why. Hint: take a few rows from `w1.hex` and images from
   `test_x.hex` and compute the expected answers with your Python model.
   Add a `test_neuron` target to the Makefile.

### C. The full network (about 7 hours)

Write `rtl/bnn_top.v` and pass `make test_top` for `P=1`, then for as many
of `P = 2, 4, 8, 16, 32` as you can. `P` is the number of layer-1 neurons
computed in one clock cycle. Layer 2 can stay at one output per cycle.

Draw a block diagram and a state diagram before you write the code. Put
both in your report. A photo of a hand drawing is fine.

Use `make lint` and deal with every warning. Fix it, or explain in a
comment why it is harmless.

### D. Area versus speed (about 3 hours)

For each `P` that works, run `make synth P=...`. It synthesises your design
for a Gowin FPGA (the chip on the Tang Nano boards), which has 4-input
look-up tables (LUT4). Record:

- LUT4 count, flip-flop count (DFF*), total cells
- cycles per image (printed by `make test_top`)

Make a table and one plot. Then answer, in your own words:

1. How do area and cycles change with `P`? Is the trade-off linear? Why or why not?
2. Look at where the LUTs go. What part of the design is most expensive,
   and why? `make synth P=... FLATTEN=0` keeps the module hierarchy, so
   the report shows statistics for each module.
3. Is there a value of `P` that you would choose, and for what kind of use?

### E. Report (about 2 hours)

At most 3 pages, as `report.md` or a PDF. Include:

- what works and what does not, stated plainly
- block and state diagrams
- the table and plot from part D, with your answers
- one bug that took you a long time, and how you found it
- a time log: date, hours, what you did

## Stretch tasks (optional, pick at most one)

Only if A to E are done. Each tells us something different, so pick the one
you find interesting.

- **S1. Smaller.** Reduce the LUT count at `P=1` by at least 30% without
  changing the outputs. Explain what you changed.
- **S2. Faster.** Make the design accept a new image every N cycles, with
  N smaller than its latency (pipelining). Write your own testbench for it.
- **S3. Better.** Retrain with `train_bnn.py --hidden 64`, adapt the
  hardware, and report the accuracy and the area cost.
- **S4. Real.** Run it on an FPGA board you have access to, or as an HLS
  design on a Pynq board. Report how you checked it was correct.

## Rules

- Work alone. You may read anything, and you may use AI assistants. If you
  do, say in the report which tool you used and for what. After you submit
  there is a 30-minute conversation where you walk us through your code and
  make a small change to it live. That conversation is the main part of the
  assessment. Make sure you understand every line you submit.
- Do not edit the provided testbenches. If you think one is wrong, say so in
  the report.
- Submit a link to your git repository, or a zip of it with the `.git`
  folder included, within 7 days of receiving the kit.
