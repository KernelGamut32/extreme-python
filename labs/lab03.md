# Lab 03: Practical Pandas — Sorting, De-duping, GroupBy, Merging, and Column Ops (≈45 min)

**Data file:** `SampleData.csv`

## Learning goals

By the end, you will be able to:

- Sort DataFrames by one or more columns
- Detect and remove duplicates safely
- Aggregate with `groupby` (sum, mean, max, multiple metrics)
- Merge a fact table with a small lookup table
- Create and transform columns, apply basic functions, and export results

## Prerequisites

- Python 3.x, `pandas` installed
- Jupyter Notebook or any Python editor
- `SampleData.csv` placed next to the notebook/script

---

## 0) Setup & Quick Peek (≈5 min)

1. Import Pandas and read the CSV.
2. Convert `Invoice_date` to datetime and add Year/Month helpers.
3. Review basic stats and unique counts.

```python
import pandas as pd
from pathlib import Path

# Adjust path if needed
csv_path = Path("SampleData.csv")
df = pd.read_csv(csv_path)

df.head()
df.shape, df.dtypes

# Convert Invoice_date to datetime and add helpers
df['Invoice_date'] = pd.to_datetime(df['Invoice_date'])
df['Year']  = df['Invoice_date'].dt.year
df['Month'] = df['Invoice_date'].dt.month

df.describe()

df.shape, df.dtypes

# Convert Account_no to string type
df['Account_no'] = df['Account_no'].astype('string')
df.describe(include=['int64', 'float64'])

df[['Account_no','LocationID','ProductID']].nunique()
```

---

## Part A — Sorting & De-duping (≈10–12 min)

### A1) Sort by a single column — See highest usage first

```python
sorted_usage = df.sort_values(by='Billed_usage_kwh', ascending=False)
sorted_usage[['Account_no','LocationID','ProductID','Invoice_date','Billed_usage_kwh']].head(10)
```

### A2) Multi-column sort — Chronological within each account

```python
sorted_multi = df.sort_values(by=['Account_no','Invoice_date'], ascending=[True, True])
sorted_multi.head(10)
```

### A3) Detect potential duplicates — Exact vs. key-based duplicates

```python
# Exact duplicate rows (all columns identical)
first_row = df.iloc[[0]]
new_row = pd.DataFrame({'Account_no': first_row['Account_no'],
                         'CustomerID': 'P99',
                         'ProductID': first_row['ProductID'],
                         'Invoice_date': first_row['Invoice_date']})
df = pd.concat([df, new_row], ignore_index=True)
exact_dups_mask = df.duplicated(keep=False)
df[exact_dups_mask].sort_values(df.columns.tolist()).head()

# Business-key duplicates: same account + date + product
key_cols = ['Account_no','Invoice_date','ProductID']
key_dups_mask = df.duplicated(subset=key_cols, keep=False)
df[key_dups_mask].sort_values(key_cols).head()
```

### A4) Remove duplicates safely — Keep the “last” occurrence on key columns

```python
df_nodup = df.drop_duplicates(subset=key_cols, keep='last').copy()
print("Before:", len(df), "After:", len(df_nodup))
```

> ✅ **Checkpoint:** When would you use `drop_duplicates()` with `subset=` vs. on all columns?

**Answer**:

- Using drop_duplicates() on All Columns (Default Behavior):
  - When to Use:
    You want to remove rows that are completely identical across all columns.
  - Example Use Case:
    Cleaning a dataset where duplicate rows represent redundant data (e.g., duplicate entries in a database export).

```python
df.drop_duplicates(inplace=True)
```

- Using drop_duplicates(subset=...):
  - When to Use:
    You want to remove duplicates based on specific columns while ignoring others. This is useful when only certain columns determine whether a row is considered a duplicate.
  - Example Use Case:
    - Removing duplicates based on a unique identifier (e.g., user_id) while keeping other columns like timestamps.
    - Deduplicating based on a combination of columns (e.g., name and email) while ignoring others.

```python
# Remove duplicates based on 'name' and 'email' columns
df.drop_duplicates(subset=['name', 'email'], inplace=True)
```

---

## Part B — GroupBy & Aggregations (≈10–12 min)

### B1) Product-level usage and revenue summary

```python
prod_summary = (
    df_nodup
    .groupby('ProductID', as_index=False)
    .agg(
        total_usage_kwh = ('Billed_usage_kwh','sum'),
        avg_usage_kwh   = ('Billed_usage_kwh','mean'),
        max_usage_kwh   = ('Billed_usage_kwh','max'),
        total_revenue   = ('Bill','sum')
    )
    .sort_values('total_usage_kwh', ascending=False)
)
prod_summary
```

### B2) Monthly revenue by product (pivot-style)

```python
monthly_prod = (
    df_nodup
    .groupby(['Year','Month','ProductID'], as_index=False)
    .agg(monthly_revenue=('Bill','sum'),
         monthly_usage_kwh=('Billed_usage_kwh','sum'))
    .sort_values(['Year','Month','ProductID'])
)
monthly_prod.head(12)
```

> 🔎 **Try:** Filter `monthly_prod` to a single year and inspect which product leads revenue.

```python
# Filter the monthly summary to a single year (e.g., 2020)
year_filter = 2020
monthly_2020 = monthly_prod[monthly_prod['Year'] == year_filter]

# Find the product with the highest total revenue in that year
top_product_2020 = (
    monthly_2020
    .groupby('ProductID', as_index=False)['monthly_revenue']
    .sum()
    .sort_values('monthly_revenue', ascending=False)
)

print(f"Top product in {year_filter}:")
top_product_2020.head(1)
```

---

## Part C — Merging with a Lookup Table (≈8–10 min)

Create a tiny in-memory lookup that adds friendly names and attributes per `ProductID`.

```python
product_lookup = pd.DataFrame({
    'ProductID': ['P01','P02','P03'],
    'ProductName': ['Standard Saver','Peak Flex','Green Choice'],
    'Tier': ['Standard','Peak','Green'],
    'Is_Green': [False, False, True]
})
product_lookup
```

### C1) Left-merge onto the fact data

```python
df_enriched = df_nodup.merge(product_lookup, on='ProductID', how='left')
df_enriched[['ProductID','ProductName','Tier','Is_Green']].drop_duplicates()
```

### C2) Re-run a summary with the enriched attributes

```python
tier_summary = (
    df_enriched
    .groupby('Tier', as_index=False)
    .agg(
        customers=('Account_no','nunique'),
        locations=('LocationID','nunique'),
        total_usage_kwh=('Billed_usage_kwh','sum'),
        total_revenue=('Bill','sum')
    )
    .sort_values('total_revenue', ascending=False)
)
tier_summary
```

> ✅ **Checkpoint:** Explain `how='left'` and when you’d choose `inner`, `right`, or `outer`.

**Answer**:

- `how='left'`
  - Explanation: A left join keeps all rows from the left DataFrame and only the matching rows from the right DataFrame. If there’s no match, the result will have NaN for the columns from the right DataFrame.
  - When to Use:
    - When you want to preserve all data from the left DataFrame, even if there’s no corresponding match in the right DataFrame.
    - Example: Merging a list of customers (left) with their orders (right), ensuring all customers are included, even those without orders.
- `how='inner'`
  - Explanation: An inner join keeps only the rows that have matching keys in both DataFrames.
  - When to Use:
    - When you want to include only the data that exists in both DataFrames.
    - Example: Combining sales data (left) with product details (right) but only for products that have sales.
- `how='right'`
  - Explanation: A right join keeps all rows from the right DataFrame and only the matching rows from the left DataFrame. If there’s no match, the result will have NaN for the columns from the left DataFrame.
  - When to Use:
    - When you want to preserve all data from the right DataFrame, even if there’s no corresponding match in the left DataFrame.
    - Example: Merging product details (right) with sales data (left), ensuring all products are included, even those without sales.
- `how='outer'`
  - Explanation: An outer join keeps all rows from both DataFrames, filling in NaN where there’s no match.
  - When to Use:
    - When you want a complete dataset, including all rows from both DataFrames, regardless of whether they match.
    - Example: Combining two datasets of employees from different departments, ensuring no one is left out.

---

## Part D — Column Manipulation & Basic Functions (≈8–10 min)

### D1) Create calculated columns** — Recompute bill and compare

```python
df_enriched['calc_bill'] = df_enriched['Base_charge'] + df_enriched['Price'] * df_enriched['Billed_usage_kwh']
df_enriched['bill_diff'] = (df_enriched['calc_bill'] - df_enriched['Bill']).round(2)

df_enriched['bill_diff'].describe()
df_enriched.loc[df_enriched['bill_diff'].abs() > 0.01, 
                ['Account_no','Invoice_date','ProductID','Bill','calc_bill','bill_diff']].head()
```

### D2) Categorize usage with `pd.cut`

```python
import numpy as np

bins = [0, 500, 1000, 2000, float('inf')]
labels = ['Low','Moderate','High','Very High']
df_enriched['usage_band'] = pd.cut(df_enriched['Billed_usage_kwh'], bins=bins, labels=labels, right=True)
df_enriched['usage_band'].value_counts()
```

### D3) Add a boolean flag with `np.where`

```python
df_enriched['is_high_usage'] = np.where(df_enriched['Billed_usage_kwh'] >= 1000, True, False)
df_enriched['is_high_usage'].mean()  # proportion
```

### D4) Simple row-wise function via `apply` *(vectorized ops are usually faster)*

```python
def usage_per_dollar(row):
    return row['Billed_usage_kwh'] / row['Bill'] if row['Bill'] else None

df_enriched['kwh_per_dollar'] = df_enriched.apply(usage_per_dollar, axis=1)
df_enriched[['Billed_usage_kwh','Bill','kwh_per_dollar']].head()
```

---

## Part E — Export a Clean Result (≈2–3 min)

Export a tidy monthly summary for downstream reporting:

```python
monthly_clean = (
    df_enriched
    .groupby(['Year','Month','ProductName'], as_index=False)
    .agg(revenue=('Bill','sum'), usage_kwh=('Billed_usage_kwh','sum'))
    .sort_values(['Year','Month','revenue'], ascending=[True, True, False])
)

monthly_clean.to_csv("monthly_summary.csv", index=False)
print("Wrote monthly_summary.csv")
```

---

## Optional Stretch

### 1) De-dupe simulation — Append a duplicate row and verify removal

```python
dupe_row = df_enriched.iloc[[0]]
df_dupe_test = pd.concat([df_enriched, dupe_row], ignore_index=True)
len_before = len(df_dupe_test)
df_dupe_test = df_dupe_test.drop_duplicates(subset=['Account_no','Invoice_date','ProductID'], keep='last')
len_after = len(df_dupe_test)
len_before, len_after
```

### 2) Multi-metric aggregation

```python
complex_agg = (
    df_enriched
    .groupby('ProductName', as_index=False)
    .agg(
        revenue_sum=('Bill','sum'),
        bill_min=('Bill','min'),
        bill_max=('Bill','max'),
        accounts=('Account_no','nunique')
    )
    .sort_values('revenue_sum', ascending=False)
)
complex_agg
```
