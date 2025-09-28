# Lab 05: NumPy `ndarray` dtypes, shapes, and memory layout (≈30 min)

## What you’ll practice

- Loading real data and creating `ndarray`s
- Inspecting and changing **dtypes**
- Understanding **shape**, **strides**, **contiguity flags**
- Seeing how **views vs. copies** and **C vs. Fortran order** affect memory

> Data: `SampleData.csv` (place it in the same folder as your notebook).

## 0) Setup (1–2 min)

```python
import numpy as np
import pandas as pd

csv_path = "SampleData.csv"  # adjust if needed
```

**Task 0.1** – Confirm the file is readable and peek at columns:

```python
df = pd.read_csv(csv_path)
df.head(), df.dtypes
```

## 1) Build a clean numeric `ndarray` (3–4 min)

**Task 1.1** – Select numeric columns and convert to NumPy:

```python
num_df = df.select_dtypes(include="number")
A = num_df.to_numpy()            # same as num_df.values, but preferred
A[:3], A.shape, A.dtype
```

- **Question:** What are the array’s `shape` and `dtype`?
- **Note:** If there are no numeric columns, pick a few columns that can be safely converted:

```python
# Example fallback if CSV lacks all-numeric columns:
# cols = ["col1","col2","col3"]  # put your numeric columns here
# A = df[cols].to_numpy()
```

## 2) Inspect dtype & memory footprint (3–4 min)

**Task 2.1** – Explore dtype metadata:

```python
A.dtype, A.dtype.kind, A.itemsize, A.size, A.nbytes
```

**Task 2.2** – Cross-check `nbytes` math:

```python
A.size * A.itemsize
```

## 3) Shape, reshape, and basic layout (4–5 min)

**Task 3.1** – Get shape and try reshaping:

```python
A.shape
rows, cols = A.shape
# If it has at least 2 dims, flatten and reshape to (rows, cols) again:
B = A.reshape(rows, cols)        # should be identical shape
(B.shape, B.flags['C_CONTIGUOUS'], B.flags['F_CONTIGUOUS'])
```

**Task 3.2** – Create a 1D view and reshape it in different orders:

```python
flat = A.ravel(order='C')        # C order flatten (row-major)
flat_F = A.ravel(order='F')      # F order flatten (col-major)
flat.shape, flat_F.shape
```

## 4) Strides & contiguity (5–6 min)

**Task 4.1** – Check strides and flags:

```python
A.strides, A.flags
```

**Task 4.2** – Transpose and observe memory changes:

```python
AT = A.T
AT.shape, AT.strides, AT.flags['C_CONTIGUOUS'], AT.flags['F_CONTIGUOUS']
```

```python
AT.base is A, AT.flags['OWNDATA']
```

**Task 4.3** – Force a specific memory order:

```python
A_C = np.ascontiguousarray(A)            # ensure C-order
A_F = np.asfortranarray(A)               # ensure F-order
A_C.flags['C_CONTIGUOUS'], A_F.flags['F_CONTIGUOUS']
```

## 5) Dtype changes: `astype`, precision, and bytes (5–6 min)

**Task 5.1** – Change dtype and compare memory:

```python
A32 = A.astype(np.float32, copy=True)
A64 = A.astype(np.float64, copy=True)
A.dtype, A32.dtype, A64.dtype, A.nbytes, A32.nbytes, A64.nbytes
```

**Task 5.2** – Reinterpret the same memory as raw bytes (view):

```python
bytes_view = A.view(np.uint8)
bytes_view.shape, bytes_view.strides, bytes_view.flags['C_CONTIGUOUS']
```

```python
# Peek at the first element's bytes (illustrative)
r, c = 0, 0
start = (r * A.strides[0]) + (c * A.strides[1])
bytes_view_flat = bytes_view.ravel(order='C')
bytes_view_flat[start:start + A.itemsize]
```

## 6) Views vs. copies in practice (4–5 min)

**Task 6.1** – Create a slice (likely a **view**) and modify it:

```python
V = A[:3, :3]          # slicing usually returns a view
V.base is A, V.flags['OWNDATA']
V[0,0] = V[0,0] + 1    # mutate the view
A[0,0]                 # did A change?
```

**Task 6.2** – Create an explicit **copy** and modify it:

```python
C = A[:3, :3].copy()
C.base is A, C.flags['OWNDATA']
C[0,0] = C[0,0] + 100
A[0,0], C[0,0]
```

## 7) C vs. Fortran order effects (3–4 min)

**Task 7.1** – Time `ravel`/`reshape` in different orders (tiny demo):

```python
# If your array is small, timings will be noisy; this is illustrative.
# In a Notebook, you can also use %timeit directly.
from time import perf_counter

def time_op(op, repeats=5):
    best = float("inf")
    for _ in range(repeats):
        t0 = perf_counter()
        _ = op()
        best = min(best, perf_counter() - t0)
    return best

t_c_flat = time_op(lambda: A.ravel(order="C"))
t_f_flat = time_op(lambda: A.ravel(order="F"))
print(f"ravel(order='C') best: {t_c_flat:.6f}s | ravel(order='F') best: {t_f_flat:.6f}s")
```

## 8) Quick wrap-up checks (2–3 min)

Answer in comments or Markdown:

1. What are the meanings of `shape`, `strides`, and `itemsize`?
2. When does NumPy give you a **view** vs. a **copy**?
3. How can you guarantee C-contiguity or F-contiguity?
4. How does changing `dtype` affect memory size and potential precision?

### Key notes

- If `SampleData.csv` is mostly strings, demo selecting numeric columns with `select_dtypes`. If there are mixed types with thousands separators or currency symbols, show:

```python
df['Amount'] = pd.to_numeric(df['Amount'].str.replace(r'[$,]', '', regex=True), errors='coerce')
```

then `to_numpy()` again.

- Emphasize:
  - **Views ≠ copies** (show `base`, `OWNDATA`, and mutation effects).
  - **Contiguity flags** and **strides** as the core “memory layout” mental model.
  - **Dtype ↔ memory ↔ precision** trade-offs (`float32` vs `float64`).

---

## (Optional) Stretch goals

- Structured dtypes: Load a few columns with different types using np.genfromtxt(..., names=True, dtype=None, encoding='utf-8'), then access fields like arr['Revenue'].
- Memory order & BLAS: Create A_big = np.asfortranarray(np.random.rand(4000,4000)) and compare A_big.T @ A_big timings with C vs. F order (if your machine is fast enough).

## Stretch Goal Solutions

### 1) Structured dtypes with `np.genfromtxt`

```python
import numpy as np
import pandas as pd

csv_path = "SampleData.csv"  # adjust if needed

# Load as a structured array (field names come from the header row).
rec = np.genfromtxt(
    csv_path,
    delimiter=",",
    names=True,              # use header row for field names
    dtype=None,              # let NumPy try to infer types
    encoding="utf-8"
)

# Inspect fields and dtypes
print("Field names:", rec.dtype.names)
print("Field dtypes:", [rec.dtype.fields[name][0] for name in rec.dtype.names])

# Pick the first numeric field (int/uint/float)
numeric_kinds = {"i", "u", "f"}
num_field = next(
    (name for name in rec.dtype.names
     if rec.dtype.fields[name][0].kind in numeric_kinds),
    None
)

if num_field is None:
    # Fall back: use pandas to coerce a column to numeric, then rebuild a structured array
    df = pd.read_csv(csv_path)
    # choose a column and coerce
    candidate = df.columns[0]
    df[candidate] = pd.to_numeric(df[candidate], errors="coerce")
    # drop NaNs for a clean demo
    coerced = df[[candidate]].dropna()
    rec = np.core.records.fromarrays([coerced[candidate].to_numpy()], names=[candidate])
    num_field = candidate
    print(f"No numeric field detected initially; coerced column: {candidate}")

print("Using numeric field:", num_field)

# Do a quick numeric operation on that field:
vals = rec[num_field]
print("Sample values:", vals[:5])
print("Mean:", np.mean(vals))
print("Std:", np.std(vals))

# Accessing fields is columnar and fast:
# e.g., if you also have a second numeric field, compute correlation:
other_field = next(
    (name for name in rec.dtype.names
     if name != num_field and rec.dtype.fields[name][0].kind in numeric_kinds),
    None
)

if other_field:
    corr = np.corrcoef(rec[num_field], rec[other_field])[0, 1]
    print(f"Correlation between {num_field} and {other_field}: {corr:.4f}")
else:
    print("Only one numeric field found; skipping correlation demo.")
```

### 2) Memory order & BLAS: C- vs F-contiguous timing

```python
import numpy as np
import pandas as pd
from time import perf_counter

# Start from your numeric matrix A (from earlier in the lab).
# If you don't have A yet, build it from the CSV:
df = pd.read_csv("SampleData.csv")
A = df.select_dtypes(include="number").to_numpy()
if A.ndim != 2 or min(A.shape) < 2:
    # fall back to a synthetic numeric matrix with similar scale
    A = np.random.rand(1500, 1500)

print("A shape:", A.shape, "C-contig?", A.flags['C_CONTIGUOUS'], "F-contig?", A.flags['F_CONTIGUOUS'])

# Ensure we have explicit C- and F-contiguous versions
A_C = np.ascontiguousarray(A)
A_F = np.asfortranarray(A)

print("A_C flags:", A_C.flags['C_CONTIGUOUS'], A_C.flags['F_CONTIGUOUS'])
print("A_F flags:", A_F.flags['C_CONTIGUOUS'], A_F.flags['F_CONTIGUOUS'])

def time_op(op, repeats=5):
    best = float("inf")
    for _ in range(repeats):
        t0 = perf_counter()
        _ = op()
        best = min(best, perf_counter() - t0)
    return best

# 2.1 Compare flatten cost
t_c_flat = time_op(lambda: A_C.ravel(order="C"))
t_f_flat = time_op(lambda: A_C.ravel(order="F"))
print(f"ravel(order='C') best: {t_c_flat:.6f}s | ravel(order='F') best: {t_f_flat:.6f}s")

# 2.2 Compare a BLAS-backed op (matrix multiply)
t_mm_C = time_op(lambda: A_C @ A_C.T, repeats=3)
t_mm_F = time_op(lambda: A_F @ A_F.T, repeats=3)
print(f"(C-order) A_C @ A_C.T best: {t_mm_C:.3f}s")
print(f"(F-order) A_F @ A_F.T best: {t_mm_F:.3f}s")

# 2.3 Confirm identical numeric results on a small slice
res_C = (A_C[:200, :200] @ A_C[:200, :200].T)
res_F = (A_F[:200, :200] @ A_F[:200, :200].T)
print("Results identical on slice? ", np.allclose(res_C, res_F))
```

### Optional: explicit structured `dtype` for speed/clarity

```python
import numpy as np

# Example schema (change field names/types to match your CSV)
schema = np.dtype([
    ("Account_no", "<i8"),
    ("LocationID",  "<U10"),
    ("CustomerID",  "<U10"),
    ("ProductID",  "<U10"),
    ("Billed_usage_kwh","<f8"),
])

rec_fast = np.genfromtxt(
    "SampleData.csv",
    delimiter=",",
    names=True,
    dtype=schema,
    encoding="utf-8"
)

print(rec_fast.dtype)
print(rec_fast["Billed_usage_kwh"][:5])
```
