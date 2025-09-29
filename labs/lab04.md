# Lab 04: Pandas Lambdas, `apply`/`map`, and Reshaping (Wide ↔ Tall)

**Target duration:** ~60 minutes  
**Data:** `SampleData.csv` (columns include: `Account_no`, `LocationID`, `CustomerID`, `ProductID`, `Billed_usage_kwh`, `Invoice_date`, `Base_charge`, `Price`, `Bill`)

## Learning objectives

- Use `lambda` with `Series.map`, `Series.apply`, and `DataFrame.apply(axis=1)`.
- Chain transformations with `.assign(...)` for readable pipelines.
- Reshape datasets using `pivot`, `pivot_table`, `melt`, `stack`, and `unstack`.
- Validate reshapes by comparing tall vs. wide summaries.

---

## 0) Setup (5 min)

1. Import libs and load the CSV.
2. Parse dates and add helper columns.

```python
import pandas as pd
import numpy as np

# Load data (file is in the working directory)
df = pd.read_csv("SampleData.csv")

# Parse and enrich date features
df["Invoice_date"] = pd.to_datetime(df["Invoice_date"], errors="coerce")
df["Year"] = df["Invoice_date"].dt.year
df["Month"] = df["Invoice_date"].dt.month
df["YearMonth"] = df["Invoice_date"].dt.to_period("M").astype(str)

# Convert Account_no to string type
df["Account_no"] = df["Account_no"].astype('string')

df.head()
```

**Check:** You should see the new columns and plausible dates.

---

## Part A — Lambda + `apply`/`map` in practice (25 min)

### A1) Price tiers via `map`

```python
price_to_tier = {0.025: "Low", 0.030: "Medium", 0.045: "High"}  # adjust if your file has different values
df["PriceTier"] = df["Price"].map(price_to_tier).fillna("Other")
df["PriceTier"].value_counts()
```

### A2) Usage bucket via `apply` + `lambda`

```python
def usage_bucket(kwh: float) -> str:
    if kwh < 200: 
        return "Low"
    elif kwh < 500:
        return "Medium"
    else:
        return "High"

df["UsageBucket"] = df["Billed_usage_kwh"].apply(lambda x: usage_bucket(x))
df["UsageBucket"].value_counts()
```

### A3) Row-wise calculations with `DataFrame.apply(axis=1)` + `.assign`

```python
df = df.assign(
    Variable_charge=lambda _df: _df["Billed_usage_kwh"] * _df["Price"],
    Recalc_Bill=lambda _df: _df["Base_charge"] + _df["Variable_charge"],
    Bill_Diff=lambda _df: (_df["Recalc_Bill"] - _df["Bill"]).round(2)
)

df["Recalc_Bill_rowwise"] = df.apply(
    lambda r: r["Base_charge"] + r["Billed_usage_kwh"] * r["Price"], axis=1
)

df[["Bill", "Recalc_Bill", "Bill_Diff"]].head()
```

### A4) Chaining transformations with `.assign()`

```python
summer_months = {6, 7, 8, 9}
q90 = df["Bill"].quantile(0.90)

df = (
    df
    .assign(
        IsSummer=lambda _df: _df["Month"].isin(summer_months),
        IsHighBill=lambda _df: _df["Bill"] >= q90,
        SummerDiscount=lambda _df: np.where(_df["IsSummer"] & (_df["PriceTier"]=="High"), 0.05, 0.0),
        Discounted_Bill=lambda _df: (1 - _df["SummerDiscount"]) * _df["Recalc_Bill"]
    )
)

df[["Month", "PriceTier", "IsSummer", "IsHighBill", "SummerDiscount", "Discounted_Bill"]].head()
```

### A5) Translating codes to labels with `map`

```python
prod_map = {"P01": "Standard", "P02": "Peak", "P03": "OffPeak"}
df["ProductLabel"] = df["ProductID"].map(prod_map).fillna(df["ProductID"])
df["ProductLabel"].value_counts()
```

---

## Part B — Reshaping: Wide ↔ Tall (25 min)

### B1) Tall monthly summary

```python
tall = (
    df
    .groupby(["Account_no", "YearMonth", "ProductID"], as_index=False)
    .agg(
        Monthly_kwh=("Billed_usage_kwh", "sum"),
        Monthly_bill=("Bill", "sum")
    )
    .sort_values(["Account_no", "YearMonth", "ProductID"])
)

tall.head()
```

### B2) Wide usage with `pivot_table`

```python
wide_kwh = (
    tall
    .pivot_table(
        index=["Account_no", "YearMonth"],
        columns="ProductID",
        values="Monthly_kwh",
        aggfunc="sum",
        fill_value=0
    )
    .reset_index()
)
wide_kwh.columns.name = None
wide_kwh.head()
```

### B3) Back to tall with `melt` and validate round-trip

```python
# 1) Melt back to tall
tall_back = (
    wide_kwh
    .melt(id_vars=["Account_no", "YearMonth"], var_name="ProductID", value_name="Monthly_kwh")
    .sort_values(["Account_no", "YearMonth", "ProductID"])
    .reset_index(drop=True)
)

# 2) Align by keys and compare to original tall (treat missing combos as 0 in original)
keys = ["Account_no", "YearMonth", "ProductID"]

cmp = (
    tall_back
    .merge(
        tall[keys + ["Monthly_kwh"]],
        on=keys,
        how="left",
        suffixes=("_back", "")
    )
    .fillna({"Monthly_kwh": 0})
    .sort_values(keys, kind="stable")
    .reset_index(drop=True)
)

# display(cmp)

# 3) Validation result: True means round-trip preserved monthly usage
import numpy as np
np.allclose(cmp["Monthly_kwh_back"].to_numpy(), cmp["Monthly_kwh"].to_numpy())
```

### B4) Wide with multiple values (MultiIndex columns)

```python
wide_multi = (
    tall
    .pivot_table(
        index=["Account_no", "YearMonth"],
        columns="ProductID",
        values=["Monthly_kwh", "Monthly_bill"],
        aggfunc="sum",
        fill_value=0
    )
)
# Flatten columns
wide_multi.columns = [f"{val}_{pid}" for (val, pid) in wide_multi.columns]
wide_multi = wide_multi.reset_index()
wide_multi.head()
```

### B5) `stack` / `unstack` alternative

```python
tall_usage = tall.set_index(["Account_no", "YearMonth", "ProductID"])["Monthly_kwh"]
wide_via_unstack = tall_usage.unstack("ProductID", fill_value=0).reset_index()
tall_via_stack = (
    wide_via_unstack
    .set_index(["Account_no", "YearMonth"])
    .stack(dropna=False)
    .rename_axis(["Account_no", "YearMonth", "ProductID"])
    .rename("Monthly_kwh")
    .reset_index()
)
tall_via_stack.head()
```

---

## Part C — Mini-challenges / Stretch (10 min)

1) **Percent contribution per product per month (tall).**

```python
tall_pct = (
    tall
    .assign(Total_kwh=lambda _df: _df.groupby(["Account_no", "YearMonth"])["Monthly_kwh"].transform("sum"))
    .assign(Pct_of_month=lambda _df: (_df["Monthly_kwh"] / _df["Total_kwh"]).round(4))
)
tall_pct.head()
```

2) **Detect missing product months.**

```python
counts = tall.groupby(["Account_no", "YearMonth"])["ProductID"].nunique()
missing = counts[counts < 3].reset_index(name="n_products")
missing.head()
```

3) **Friendly row label via row-wise `apply`.**

```python
tall["Label"] = tall.apply(
    lambda r: f"A{r['Account_no']}-{r['YearMonth']}[{r['ProductID']}]", axis=1
)
tall[["Label", "Monthly_kwh"]].head()
```

4) **Map codes to categories (practice).**

```python
cust_map = {"P01": "Residential", "P02": "Commercial", "P03": "Industrial"}
df["CustomerType"] = df["CustomerID"].map(cust_map).fillna("Other")
df["CustomerType"].value_counts()
```

---

## Wrap-up

- Prefer `map` for 1:1 value lookups; `apply` when logic or multiple columns are needed.
- Validate reshapes via round-trips (tall→wide→tall).
- `.assign()` with lambdas keeps pipelines readable and avoids temporary variables.
