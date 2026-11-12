# /// script
# requires-python = ">=3.14"
# dependencies = []
# ///

from pathlib import Path

# data/ folder, found from this file's location so the script runs from any folder
DATA = Path(__file__).resolve().parent.parent / "data"

def read_file(name:str) -> list[str]:
    with open(DATA / name, "r") as f:
        return f.readlines()

# Load all data files once, converting hex text to ints
w1 = [int(line, 16) for line in read_file("w1.hex")]
t1 = [int(line, 16) for line in read_file("t1.hex")]
x_list = [int(line, 16) for line in read_file("test_x.hex")]

n = len(x_list)


def bnn_neuron(a:int, b:int, bitwidth:int) -> int:
    xor_bitwise = a ^ b
    mask = (1 << bitwidth) - 1
    xnor_bitwise = xor_bitwise ^ mask

    return xnor_bitwise.bit_count()


def bnn_top(in_image: int):

    # Hidden Layer outputs
    scores_h = [bnn_neuron(in_image, w1[i], 64) for i in range(32)]
    h = 0
    for j in range(32):
        if scores_h[j] >= t1[j]:
            h += 1<<j   #h basically becomes a bit array of fire (that the neuron rtl outputs)

    return h, scores_h


if __name__ == '__main__':
    with open(DATA/"tb_neuron.hex", "w") as f:
        for i in range(n):
            fire, scores = bnn_top(x_list[i])
            for j in range(32):
                # x  w  thresh  expected_score  expected_fire   (all hex)
                f.write(f"{x_list[i]:016x} {w1[j]:016x} {t1[j]:02x} {scores[j]:02x} {(fire >> j) & 1}\n")


