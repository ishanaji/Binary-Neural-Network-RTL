# /// script
# requires-python = ">=3.12"
# dependencies = []
# ///
"""Golden reference model for the 64 -> 32 -> 10 binary neural network.

Checks every test image against data/expected.hex (hidden bits and class)
and reports accuracy against data/test_y.txt.

Run from the kit folder:  uv run python/bnn_ref.py
"""
from pathlib import Path

DATA = Path(__file__).resolve().parent.parent / "data"


def load_hex(name: str) -> list[int]:
    """Read a file with one hex number per line into a list of ints."""
    with open(DATA / name) as f:
        return [int(s, 16) for s in f.read().split()]


def load_expected() -> list[tuple[int, int]]:
    """Read expected.hex: each line is '<hidden hex> <class>'."""
    expected = []
    with open(DATA / "expected.hex") as f:
        for line in f:
            if line.strip():
                h_hex, y_str = line.split()
                expected.append((int(h_hex, 16), int(y_str)))
    return expected


def bnn_neuron(a: int, b: int, bitwidth: int) -> int:
    """popcount(XNOR(a, b)) over the low `bitwidth` bits."""
    mask = (1 << bitwidth) - 1
    xnor_bitwise = (a ^ b) ^ mask
    return xnor_bitwise.bit_count()


def bnn_top(x: int, w1: list[int], t1: list[int], w2: list[int]):
    """Run one image through the network. Returns (h, s, y)."""
    # Hidden layer: h[j] = 1 if popcount(XNOR(x, W1[j])) >= T1[j]
    h = 0
    for j in range(len(w1)):
        if bnn_neuron(x, w1[j], 64) >= t1[j]:
            h |= 1 << j

    # Output layer: s[k] = popcount(XNOR(h, W2[k]))
    s = [bnn_neuron(h, w2[k], 32) for k in range(len(w2))]

    # Class: index of the largest score; index() returns the lowest on a tie
    y = s.index(max(s))
    return h, s, y


def main():
    w1 = load_hex("w1.hex")
    t1 = load_hex("t1.hex")
    w2 = load_hex("w2.hex")
    xs = load_hex("test_x.hex")
    expected = load_expected()
    with open(DATA / "test_y.txt") as f:
        labels = [int(s) for s in f.read().split()]

    assert len(w1) == 32 and len(t1) == 32 and len(w2) == 10
    assert len(xs) == len(expected) == len(labels)

    n_match = 0
    n_correct = 0
    for i, (x, (h_exp, y_exp), label) in enumerate(zip(xs, expected, labels)):
        h, s, y = bnn_top(x, w1, t1, w2)

        # Sanity check: each score counts agreements over 32 bits
        assert all(0 <= sk <= 32 for sk in s), f"image {i}: score out of range {s}"

        if h == h_exp and y == y_exp:
            n_match += 1
        else:
            print(f"MISMATCH image {i}: got h={h:08x} y={y}, "
                  f"expected h={h_exp:08x} y={y_exp}")

        if y == label:
            n_correct += 1

    n = len(xs)
    print(f"expected.hex: {n_match}/{n} match")
    print(f"accuracy:     {n_correct}/{n}")
    if n_match != n:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
