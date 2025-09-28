
# ✅ Lab 06: Stretch Solutions — NumPy ndarrays & Vectorization Lab

This handout provides reference solutions for the Stretch items.

## SG1 — Third Feature (`sleep_hours`)

```python
sleep_hours = rng.normal(loc=7, scale=1.5, size=n_samples)
X3 = np.column_stack([study_hours, attendance_rate, sleep_hours])

w3 = np.array([0.8, 1.5, 0.2])
b3 = -4.0

probs3 = 1/(1+np.exp(-(X3 @ w3 + b3)))
y_pred3 = (probs3 >= 0.5).astype(int)
acc3 = (y_pred3 == y).mean()
```

## SG2 — Standardize Features

```python
# 2-feature
mu2 = X.mean(axis=0); std2 = X.std(axis=0) + 1e-8
X_std2 = (X - mu2) / std2
acc_std2 = accuracy(X_std2, y, w_base, b_base)

# 3-feature
mu3 = X3.mean(axis=0); std3 = X3.std(axis=0) + 1e-8
X_std3 = (X3 - mu3) / std3
acc_std3 = accuracy(X_std3, y, w3, b3)
```

## SG3 — Reusable Accuracy Helper

```python
def accuracy(X, y, w, b):
    probs = 1/(1+np.exp(-(X @ w + b)))
    y_pred = (probs >= 0.5).astype(int)
    return (y_pred == y).mean()
```

## SG4 — Larger Dataset Timing

```python
n_big = 500_000
study_hours_big = rng.normal(loc=5, scale=2, size=n_big)

# Loop
t0=time.perf_counter()
total=0.0
for h in study_hours_big:
    total += h
avg_loop = total / len(study_hours_big)
t1=time.perf_counter()
loop_ms = (t1 - t0)*1e3

# Vectorized
t0=time.perf_counter()
avg_vec = np.mean(study_hours_big)
t1=time.perf_counter()
vec_ms = (t1 - t0)*1e3

speedup = loop_ms / vec_ms
```
