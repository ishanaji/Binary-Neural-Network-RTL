"""Train the tiny binary neural network used by the screener.

You do not need to run this to do the screener. The trained weights are
already in ../data. It is here so you can see where they came from, and for
the stretch task (retrain a bigger network and regenerate the files).

Network (all weights and activations are single bits):
    x  : 64 bits  (8x8 digit image, pixel on if value > 7)
    h  : 32 bits  h[j] = popcount(XNOR(x, W1[j])) >= T1[j]
    s  : 10 ints  s[k] = popcount(XNOR(h, W2[k]))       (0..32)
    y  : argmax(s), ties go to the lowest index

Training uses the usual trick for binary networks: keep real-valued
"latent" weights, use sign() of them in the forward pass, and pass the
gradient straight through sign() as if it were the identity (clipped to
[-1, 1]). This is called the straight-through estimator (STE).

Usage:  uv run python train_bnn.py [--hidden 32] [--seed 1] [--out ../data]
"""

import argparse
from pathlib import Path

import numpy as np
from sklearn.datasets import load_digits
from sklearn.model_selection import train_test_split

N_IN = 64
N_OUT = 10


def binarize_images(images):
    return (images > 7).astype(np.uint8)


def sign(a):
    return np.where(a >= 0, 1.0, -1.0)


def train(x01, y, n_hidden, epochs, seed):
    rng = np.random.default_rng(seed)
    w1 = rng.uniform(-1, 1, (n_hidden, N_IN))
    b1 = np.zeros(n_hidden)
    w2 = rng.uniform(-1, 1, (N_OUT, n_hidden))
    scale = 0.2  # softmax temperature for the output scores

    xs = 2.0 * x01 - 1.0
    params = [w1, b1, w2]
    m = [np.zeros_like(p) for p in params]
    v = [np.zeros_like(p) for p in params]
    lr, beta1, beta2, eps = 0.01, 0.9, 0.999, 1e-8
    step = 0
    batch = 64
    onehot = np.eye(N_OUT)[y]

    for epoch in range(epochs):
        order = rng.permutation(len(xs))
        for i in range(0, len(xs), batch):
            idx = order[i:i + batch]
            xb, tb = xs[idx], onehot[idx]

            wb1 = sign(w1)
            a1 = xb @ wb1.T - b1
            hb = sign(a1)
            wb2 = sign(w2)
            a2 = scale * (hb @ wb2.T)

            p = np.exp(a2 - a2.max(axis=1, keepdims=True))
            p /= p.sum(axis=1, keepdims=True)

            g_a2 = (p - tb) / len(idx)
            g_wb2 = scale * g_a2.T @ hb
            g_hb = scale * g_a2 @ wb2
            g_a1 = g_hb * (np.abs(a1) <= N_IN / 4)  # STE through sign, with a window
            g_wb1 = g_a1.T @ xb
            g_b1 = -g_a1.sum(axis=0)

            grads = [g_wb1 * (np.abs(w1) <= 1), g_b1, g_wb2 * (np.abs(w2) <= 1)]
            step += 1
            for k, (prm, g) in enumerate(zip(params, grads)):
                m[k] = beta1 * m[k] + (1 - beta1) * g
                v[k] = beta2 * v[k] + (1 - beta2) * g * g
                mh = m[k] / (1 - beta1 ** step)
                vh = v[k] / (1 - beta2 ** step)
                prm -= lr * mh / (np.sqrt(vh) + eps)
            np.clip(w1, -1, 1, out=w1)
            np.clip(w2, -1, 1, out=w2)
    return w1, b1, w2


def to_hardware(w1, b1, w2):
    """Convert trained parameters to the bit-level form the hardware uses.

    With x, w in {-1,+1}: dot(x, w) = 2*popcount(XNOR) - N.
    So  dot - b >= 0  <=>  popcount >= (N + b) / 2.
    """
    W1 = (w1 >= 0).astype(np.uint8)
    W2 = (w2 >= 0).astype(np.uint8)
    T1 = np.clip(np.ceil((N_IN + b1) / 2), 0, N_IN).astype(int)
    return W1, T1, W2


def popcount_xnor(x, w):
    return int(np.sum(x == w))


def reference(x01, W1, T1, W2):
    h = np.array([popcount_xnor(x01, W1[j]) >= T1[j] for j in range(len(T1))],
                 dtype=np.uint8)
    s = np.array([popcount_xnor(h, W2[k]) for k in range(N_OUT)])
    return h, s, int(np.argmax(s))


def bits_to_hex(bits):
    """bits[0] is the least significant bit."""
    val = 0
    for i, b in enumerate(bits):
        val |= int(b) << i
    return f"{val:0{(len(bits) + 3) // 4}x}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--hidden", type=int, default=32)
    ap.add_argument("--epochs", type=int, default=60)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--out", type=Path, default=Path(__file__).parent.parent / "data")
    args = ap.parse_args()

    digits = load_digits()
    x01 = binarize_images(digits.data)
    xtr, xte, ytr, yte = train_test_split(x01, digits.target, test_size=0.25,
                                          random_state=0, stratify=digits.target)
    w1, b1, w2 = train(xtr, ytr, args.hidden, args.epochs, args.seed)
    W1, T1, W2 = to_hardware(w1, b1, w2)

    preds = [reference(x, W1, T1, W2) for x in xte]
    acc = np.mean([p[2] for p in preds] == yte)
    tr_acc = np.mean([reference(x, W1, T1, W2)[2] for x in xtr] == ytr)
    print(f"hidden={args.hidden}  train acc={tr_acc:.3f}  test acc={acc:.3f}")

    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    (out / "w1.hex").write_text("".join(bits_to_hex(r) + "\n" for r in W1))
    (out / "t1.hex").write_text("".join(f"{t:02x}\n" for t in T1))
    (out / "w2.hex").write_text("".join(bits_to_hex(r) + "\n" for r in W2))
    (out / "test_x.hex").write_text("".join(bits_to_hex(x) + "\n" for x in xte))
    (out / "test_y.txt").write_text("".join(f"{int(t)}\n" for t in yte))
    # Expected hardware outputs for the testbench: hidden bits and class.
    (out / "expected.hex").write_text(
        "".join(f"{bits_to_hex(h)} {c:x}\n" for h, _, c in preds))
    print(f"wrote {len(xte)} test vectors to {out}")


if __name__ == "__main__":
    main()
