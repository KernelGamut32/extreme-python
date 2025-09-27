# Lab 01: Pandas Index, Series & DataFrame Fundamentals (≈30 minutes)

**Goal:** Build confident, mental models for **Index**, **Series**, and **DataFrame**—and how to select, slice, filter, and reshape using labels vs positions.

---

## What you’ll accomplish

- Create and inspect `Series` and `DataFrame` objects
- Understand **Index**: why it exists, how to set/reset/rename/sort it
- Use **label-based** vs **position-based** selection: `.loc`, `.iloc`, `.at`, `.iat`
- Practice reindexing, boolean filtering, computed columns
- Try a **MultiIndex** (hierarchical index) mini‑exercise

> ⏱️ **Timebox**: ~30 minutes total. Each task has an estimate—keep moving if you’re behind.

---

## Prereqs

- Python 3.9+
- `pandas` (any recent release is fine):  

  ```bash
  pip install pandas
  ```

- IDE or notebook (VS Code, Jupyter, Databricks, etc.)

---

## Setup (2 min)

Open a Python REPL or notebook and run:

```python
import pandas as pd
import numpy as np

pd.__version__
```

Create a small "orders" dataset we’ll use throughout:

```python
orders_data = {
    "order_id":   [1001, 1002, 1003, 1004, 1005, 1006],
    "customer":   ["Ava", "Ben", "Ava", "Cara", "Ben", "Ava"],
    "city":       ["NYC", "Boston", "NYC", "Austin", "Boston", "NYC"],
    "quantity":   [2, 1, 4, 3, 2, 1],
    "unit_price": [12.5, 9.0, 12.5, 15.0, 9.0, 12.5],
    "order_date": ["2024-01-10", "2024-01-12", "2024-01-12", "2024-02-01", "2024-02-03", "2024-03-15"],
}

df = pd.DataFrame(orders_data)
df["order_date"] = pd.to_datetime(df["order_date"])
df.head()
```

---

## Task 1 — Series basics (5 min)

A **Series** is a 1‑D labeled array (values + index).

1) Create a Series with a custom index and a name.

```python
s = pd.Series([3, 5, 7], index=["x", "y", "z"], name="scores")
s
```

2) Access items by **label** and **position**:

```python
s.loc["y"]      # label-based -> 5
s.iloc[1]       # position-based -> 5
s.loc[["z","x"]]   # re-ordered selection by labels
s.iloc[[2,0]]      # the same but by positions
```

3) Inspect metadata and stats:

```python
s.index, s.dtype, s.name
s.describe()
s.mean()
```

4) Build a Series from a dict and reindex:

```python
prices = pd.Series({"AAPL": 189.3, "MSFT": 418.2, "GOOG": 172.1}, name="price")
prices = prices.rename_axis("ticker")
prices

# Add a new label via reindex (introduces missing values unless you fill them)
prices2 = prices.reindex(["MSFT", "AAPL", "AMZN", "GOOG"])
prices2

prices2.isna()        # which are missing?
prices2.fillna(0.0)   # simple fill example
```

✔ **Topics convered**: Know what a Series is, how labels work, and how reindex creates/handles missing values.

---

## Task 2 — Index fundamentals (5 min)

The **Index** is the label axis. It’s used for alignment, selection, and joining.

1) Look at the default Index of `df`:

```python
df.index, df.columns
```

2) Set a meaningful index (primary key) and add a computed column:

```python
df = df.set_index("order_id")   # label rows by order id
df["total"] = df["quantity"] * df["unit_price"]
df.head()
```

3) Common index ops:

```python
df.index.name                 # 'order_id'
df = df.sort_index()          # sort by index labels
df = df.rename_axis("OrderID")# give the index a nicer name
df.head(3)
```

4) Reset the index when you need a simple RangeIndex again:

```python
tmp = df.reset_index()
tmp.head(2)
```

✔ **Topics convered**: Understand why Index matters, how to set/reset it, and why sorting/naming helps with clarity.

---

## Task 3 — DataFrame essentials (8 min)

A **DataFrame** is a 2‑D table: columns (named), rows (indexed).

1) Column selection and basic inspection:

```python
df[["customer","city"]].head(3)
df.dtypes
df.shape
```

2) Label‑based vs position‑based **row** selection:

```python
df.loc[1003]          # row *with* label 1003 (because our index is OrderID)
df.iloc[2]            # the 3rd physical row
```

3) Slicing differences (inclusive vs exclusive end):

```python
df.loc[1002:1005, ["customer","total"]]  # inclusive of 1005
df.iloc[1:4, [0, -1]]                    # exclusive of stop (row 4)
```

4) Fast scalar access:

```python
df.at[1004, "city"]   # single value by label
df.iat[1, 0]          # single value by numeric position
```

5) Boolean filtering + sorting:

```python
nyc_big = df.loc[(df["city"].eq("NYC")) & (df["total"] > 25), ["customer","city","total"]]
nyc_big.sort_values("total", ascending=False)
```

6) Add/update columns the vectorized way:

```python
df["month"] = df["order_date"].dt.to_period("M")  # fast transform
df["discounted"] = np.where(df["total"] >= 40, df["total"]*0.9, df["total"])  # conditional logic
df.head()
```

✔ **Topics convered**: Comfortably select columns/rows, slice, filter, and add vectorized columns.

---

## Task 4 — MultiIndex mini‑exercise (5 min)

A **MultiIndex** lets you index by multiple keys (e.g., `customer` and `city`).

1) Create a MultiIndex:

```python
midx = df.reset_index().set_index(["customer","city","OrderID"]).sort_index()
midx.head()
```

2) Select all orders for a customer in a city (label tuple):

```python
midx.loc[("Ava","NYC")]
```

3) Select by one level using `.xs` (cross-section):

```python
midx.xs("Ava", level="customer")          # all Ava orders
midx.xs("NYC", level="city")              # all NYC orders
```

4) Partial slice across a range of order IDs for one customer/city:

```python
midx.loc[("Ava","NYC")].loc[1002:1006]
```

✔ **You should now**: Read a MultiIndex, select with tuples, and slice at a given level.

---

## Stretch (optional, 3 min) — Time index

Working with dates is easier if dates are the index.

```python
t = df.set_index("order_date").sort_index()
# Total quantity by month (period start):
t["quantity"].resample("MS").sum()
```

---

## Quick self‑check (2 min)

Answer without running code (then verify):

1) Which accessor is *inclusive* at the end for slicing: `.loc` or `.iloc`?  
2) What happens when you `reindex` with labels not present in the original Series?  
3) Which is faster for single‑cell gets: `.loc` or `.at`?  
4) How do you select all rows for `customer="Ben"` in the MultiIndex DataFrame?

**Answers:**

1) `.loc` is inclusive; `.iloc` is exclusive at the stop.  
2) New labels appear with `NaN` (unless you provide `fill_value` or a method).  
3) `.at` (label) and `.iat` (position) are optimized for scalars.  
4) `midx.xs("Ben", level="customer")` (or `midx.loc["Ben"]` if it’s the outermost level).

---

## (Optional) Challenge

- Add a `category` column: map `unit_price >= 12` → `"Premium"` else `"Standard"`.  
- Compute total revenue by `(customer, category)` using `groupby(["customer","category"])["total"].sum()`.  
- Which two orders had the highest `discounted` value? Return `OrderID` and `discounted` only.

```python
df["category"] = np.where(df["unit_price"] >= 12, "Premium", "Standard")
revenue_by_cc = df.groupby(["customer","category"])["total"].sum().sort_values(ascending=False)
top2_discounted = df["discounted"].nlargest(2)
df.loc[df["discounted"].nlargest(2).index, ["discounted"]]
```

---

## Key takeaways

- **Index** gives rows their identity. Set it meaningfully (`set_index`) and reset it when convenient (`reset_index`).
- Use **labels** (`.loc`, `.at`) when you care about *what* you’re selecting; use **positions** (`.iloc`, `.iat`) when you care about *where*.
- Vectorized operations on whole columns are the pandas "way"—avoid Python loops for rowwise math.
- MultiIndex is powerful—but only use it when it simplifies your selection/aggregation story.
