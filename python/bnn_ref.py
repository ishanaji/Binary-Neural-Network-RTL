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
w2 = [int(line, 16) for line in read_file("w2.hex")]

x_list = [int(line, 16) for line in read_file("test_x.hex")]
y_list = [int(line) for line in read_file("test_y.txt")]
expected = read_file("expected.hex")
n = len(x_list)

h_expected = [0 for i in range(n)]
y_expected = [0 for i in range(n)]

for i in range(n):
    temp = expected[i].split()
    h_expected[i] = int(temp[0],16)
    y_expected[i] = int(temp[1])


def bnn_neuron(a:int, b:int, bitwidth:int) -> int:
    xor_bitwise = a ^ b
    mask = (1 << bitwidth) - 1
    xnor_bitwise = xor_bitwise ^ mask

    return xnor_bitwise.bit_count()


def bnn_top(in_image: int):

    # Hidden Layer outputs
    h = 0
    for j in range(32):
        if bnn_neuron(in_image, w1[j], 64) >= t1[j]:
            h += 1<<j

    # Output Layer
    s = [0 for i in range(10)]
    for k in range(10):
        s[k] = bnn_neuron(h, w2[k], 32)
    return h, s, s.index(max(s))


if __name__ == '__main__':

    accuracy_count = 0
    expected_count = 0
    score_ok_count = 0
    for i in range(n):
        h, s, y = bnn_top(x_list[i])

        # No expected scores are given, so only check the range: 0..32
        if all(0 <= s[k] <= 32 for k in range(10)):
            score_ok_count += 1
        else:
            print("SCORE OUT OF RANGE", i, s)

        if h == h_expected[i] and y == y_expected[i]:
            expected_count += 1
        else:
            print("ERROR", i)

        if y == y_list[i]:
            accuracy_count += 1

    print(f"expected.hex:    {expected_count}/{n} match")
    print(f"scores in range: {score_ok_count}/{n}")
    print(f"accuracy:        {accuracy_count}/{n}")
