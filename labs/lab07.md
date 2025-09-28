# Lab 07: NumPy - Slicing, Advanced Indexing, Reshaping & Broadcasting

**Duration:** ~60 minutes  

## Learning goals

1. Distinguish **views** vs **copies** when slicing ndarrays.
2. Apply **advanced indexing** (boolean masks & fancy indexing).
3. Use **reshape** and **broadcasting** for vectorized operations.

---

## Data & Setup

- CSV: `SampleData.csv`
- Create: `df` (DataFrame), `A` (NumPy array with `["Billed_usage_kwh","Base_charge","Price","Bill"]`), and helpers `acct`, `month`, `product`.
- Parse `Invoice_date` using `pd.to_datetime(..., format="%m/%d/%Y")`.

---

## Part 1 — Slicing, Views & Copies

- **Basic slicing** like `A[:10, :2]`, `A[::2, :]`, `A[-5:, -1]` returns **views**.
- **Mutations to a slice** (view) reflect in the original array.
- Use `.copy()` to avoid side effects.
- `ravel()` returns a **view** when possible; `flatten()` returns a **copy**.

### Checks

- `np.shares_memory(A, slice)` → often `True` (view).  
- `np.shares_memory(A, fancy_idx)` → `False` (copy).

---

## Part 2 — Advanced Indexing & Selection

- **Boolean masks**: `A[A[:,0] > 1000]` for usage > 1000.  
- **Combined conditions**: `&` (AND), `|` (OR).  
- **Assignment with masks** allows in-place updates.  
- **Fancy indexing** with integer arrays creates **copies**.  
- **`np.where`** enables vectorized conditional expressions.

---

## Part 3 — Reshaping & Broadcasting

- Columnwise centering: `(N,4) - (1,4)` with `keepdims=True` on the mean.  
- Z-scores: `(A - mean) / std` (also with `keepdims=True`).  
- Use `reshape(-1,1)` or `None/np.newaxis` to align dimensions for broadcasting.  
- Row-wise normalization: divide by an `(N,1)` denominator slice.

---

## Stretch Goals (Solutions Summary)

- **S1:** Per-account month-to-month **usage deltas** using `np.lexsort`, `np.diff`, and block loops between boundaries.  
- **S2:** “High bill in summer” mask: `Bill > 30` & month in `(6, 7, 8)`; compute count, avg usage, avg unit cost.  
- **S3:** Pairwise absolute bill differences for first `k` rows using broadcasting: `np.abs(b[:,None] - b[None,:])`.  
- **S4:** Demonstrate **slice(view)** vs **fancy(copy)** with `np.shares_memory` and mutations.

---

## Reflection

- When do operations give **views** vs **copies**?  
- What shapes are involved in your broadcasts, and how do you align them?  
- When should you prefer pure NumPy over pandas for vectorized transforms?
