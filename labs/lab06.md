# 🧠 Lab 06: NumPy - ndarrays & Vectorization

**Duration:** ~60 minutes  

## Objectives

- Create and inspect NumPy `ndarray`s (shape, dtype, size, memory, strides).
- Understand views vs copies and array layout.
- Replace Python loops with vectorized NumPy operations.
- Build a simple vectorized predictor and evaluate accuracy.

---

## Outline

### 0) Setup

```python
import numpy as np
import time
rng = np.random.default_rng(123)
```

### 1) Generate a Simple Dataset

Two features per student: `study_hours`, `attendance_rate`.

```python
n_samples = 500
study_hours = rng.normal(loc=5, scale=2, size=n_samples)
attendance_rate = rng.uniform(low=0.5, high=1.0, size=n_samples)
X = np.column_stack([study_hours, attendance_rate])

linear_combo = 0.6 * X[:, 0] + 0.4 * X[:, 1] * 10
noise = rng.normal(0, 0.5, size=n_samples)
scores_true = linear_combo + noise
y = (scores_true > 4.5).astype(np.int64)
```

### 2) Inspect Arrays

```python
X.shape, X.dtype, X.itemsize, X.nbytes
X.flags['C_CONTIGUOUS'], X.flags['F_CONTIGUOUS'], X.strides
```

#### Views vs Copies

```python
X_view = X.view(); X_copy = X.copy()
X_view.base is X, X_copy.base is X
```

### 3) Vectorization vs Loops

```python
# Loop
total = 0.0
for h in study_hours:
    total += h
avg_loop = total / len(study_hours)

# Vectorized
avg_vec = np.mean(study_hours)
```

#### Timing (illustrative)

```python
t0=time.perf_counter(); _ = sum(study_hours)/len(study_hours); t1=time.perf_counter(); loop_ms=(t1-t0)*1e3
t0=time.perf_counter(); _ = np.mean(study_hours);               t1=time.perf_counter(); vec_ms=(t1-t0)*1e3
loop_ms, vec_ms, loop_ms/vec_ms
```

### 4) Vectorized Predictor

```python
weights = np.array([0.8, 1.5]); bias = -4.0
scores = X @ weights + bias
sigmoid = lambda t: 1/(1+np.exp(-t))
probs = sigmoid(scores)
y_pred = (probs >= 0.5).astype(int)
accuracy = (y_pred == y).mean()
```

### 5) Memory & Layout Demos

```python
subset = X[:, ::2]
subset.flags['C_CONTIGUOUS'], subset.flags['F_CONTIGUOUS'], subset.strides

raw = np.ascontiguousarray(X).view(np.uint8)  # safe reinterpret
raw.shape
```

### 6) Discussion

- Why does NumPy vectorization offer speedups?
- When to use `.view()` vs `.copy()`?
- Where did broadcasting and `@` help in the predictor?

### Stretch

1. Add a third feature and re-run.
2. Standardize: `X = (X - X.mean(axis=0)) / X.std(axis=0)`
3. Write `def accuracy(X, y, w, b): ...`.
4. Increase `n_samples`; compare timings.
