# /// script
# requires-python = ">=3.14"
# dependencies = [
#     "numpy>=2.5.4",
# ]
# ///

import numpy as np
# print(np.bitwise_xor(5,2))

def bnn_neuron(a:str, b:str, bitwidth:int = 64) -> int:
    a_int = int(a, 16)
    b_int = int(b, 16)

    xor_bitwise = a_int ^ b_int
    mask = (1 << bitwidth) - 1
    xnor_bitwise = xor_bitwise ^ mask

    return xnor_bitwise.bit_count()


def bnn_top(in_image: np.uint64):

    # Hidden Layer outputs
    h = np.uint32()
    f = open("../data/w1.hex", "r")
    w1 = f.readlines()
    f = open("../data/t1.hex", "r")
    t1 = f.readlines()
    for j in range(32):
        if bnn_neuron(f"{in_image:x}", w1[j], 64) >= int(t1[j],16):
            h += 1<<j

    # Output Layer
    s = [0 for i in range(10)]
    f = open("../data/w2.hex", "r")
    w2 = f.readlines()
    for k in range(10):
        s[k] = bnn_neuron(f"{h:x}", w2[k], 32)
    return h, s.index(max(s))


if __name__ == '__main__':

    f = open("../data/test_x.hex")
    x_list = f.readlines()

    f = open("../data/test_y.txt")
    y_list = f.readlines()

    f = open("../data/expected.hex")
    expected = f.readlines()
    h_expected = [0 for i in range(450)]
    y_expected = [0 for i in range(450)]

    for i in range(450):
        temp = expected[i].split()
        h_expected[i] = int(temp[0],16)
        y_expected[i] = int(temp[1])

    accuracy_count = 0
    for i in range(450):
        temp = bnn_top(np.uint64(int(x_list[i], 16)))
        
        if temp[0] != h_expected[i] or temp[1] != y_expected[i]:
            print("ERROR", i)
        if temp[1] == int(y_list[i]):
            accuracy_count += 1
        
    print(accuracy_count)