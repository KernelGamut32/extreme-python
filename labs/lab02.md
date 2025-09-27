# Lab 02: Dates & File I/O (CSV & Excel) — ~30 minutes

**Dataset:** `SampleData.csv`

## Learning goals

- Load CSV files and parse date columns.
- Work with `datetime` features (year, month, quarter).
- Filter and aggregate by date.
- Write data to **CSV** and **Excel** (multiple sheets), and read it back.

## Prerequisites

- Python 3.9+ and `pandas` installed (`pip install pandas`)
- For Excel writing/reading: `openpyxl` (`pip install openpyxl`)
- Place the provided `SampleData.csv` in the same folder as your notebook or script.

---

## Part 0 — Setup (2 minutes)

Create an `outputs/` folder to hold files you’ll write.

```python
from pathlib import Path
Path("outputs").mkdir(exist_ok=True)
```

---

## Part 1 — Read CSV & parse dates (5 minutes)

1) **Load** the CSV and parse `Invoice_date` as `datetime`:

```python
import pandas as pd

df = pd.read_csv(
    "SampleData.csv",
    parse_dates=["Invoice_date"]
)

print(df.dtypes)
df.head()
df.info()
df["Invoice_date"].min(), df["Invoice_date"].max()
```

---

## Part 2 — Work with dates (8 minutes)

3) **Add calendar features** from the date column and build a month-normalized column:

```python
df["Year"] = df["Invoice_date"].dt.year
df["Month"] = df["Invoice_date"].dt.month
df["MonthName"] = df["Invoice_date"].dt.month_name()
df["Quarter"] = df["Invoice_date"].dt.quarter
df["InvoiceMonth"] = df["Invoice_date"].dt.to_period("M").dt.to_timestamp("M")
```

4) **Set a DatetimeIndex** (optional but useful for time filtering):

```python
df_dt = df.set_index("Invoice_date").sort_index()
df_dt.head(3)
```

5) **Filter by date range** (e.g., July–December 2020):

```python
mask = (df_dt.index >= "2020-07-01") & (df_dt.index <= "2020-12-31")
df_jul_dec_2020 = df_dt.loc[mask]
df_jul_dec_2020[["Account_no","CustomerID","Billed_usage_kwh","Price","Bill"]].head()
```

> **Alternate approach** using the `InvoiceMonth` column:

```python
df[df["InvoiceMonth"].between("2020-07-31", "2020-12-31")]
```

---

## Part 3 — Aggregate by month & compute totals (8 minutes)

6) **Create** a `TotalDue` (Base + Usage*Price) and preview:

```python
df["UsageCharge"] = df["Billed_usage_kwh"] * df["Price"]
df["TotalDue"] = df["Base_charge"] + df["UsageCharge"]
df[["Billed_usage_kwh","Price","Base_charge","Bill","TotalDue"]].head(5)
```

7) **Monthly usage & revenue summary** (across all accounts):

```python
monthly_summary = (
    df.groupby("InvoiceMonth")
      .agg(
          Total_kWh=("Billed_usage_kwh","sum"),
          Total_Bill=("Bill","sum"),
          Total_Due=("TotalDue","sum")
      )
      .reset_index()
      .sort_values("InvoiceMonth")
)
monthly_summary.head()
```

8) **Monthly pivot by CustomerID**:

```python
customer_month_pivot = (
    df.pivot_table(
        index="InvoiceMonth",
        columns="CustomerID",
        values="TotalDue",
        aggfunc="sum"
    )
    .sort_index()
)
customer_month_pivot.head()
```

9) **Account history example** (pick one account):

```python
example_acct = df["Account_no"].iloc[0]
acct_history = (
    df.loc[df["Account_no"] == example_acct, ["Invoice_date","Billed_usage_kwh","TotalDue"]]
      .sort_values("Invoice_date")
      .reset_index(drop=True)
)
acct_history.head()
```

---

## Part 4 — Write & read files (CSV + Excel) (5 minutes)

10) **Write CSV outputs**:

```python
monthly_summary.to_csv("outputs/monthly_summary.csv", index=False)
customer_month_pivot.to_csv("outputs/customer_month_pivot.csv")
acct_history.to_csv("outputs/account_history.csv", index=False)
```

11) **Write a multi-sheet Excel workbook**:

```python
with pd.ExcelWriter("outputs/pandas_lab_outputs.xlsx", engine="openpyxl") as xlw:
    df.to_excel(xlw, sheet_name="RawData", index=False)
    monthly_summary.to_excel(xlw, sheet_name="MonthlySummary", index=False)
    customer_month_pivot.to_excel(xlw, sheet_name="CustomerPivot")
    acct_history.to_excel(xlw, sheet_name="AccountHistory", index=False)
```

12) **Read back from Excel** to verify:

```python
ms_back = pd.read_excel("outputs/pandas_lab_outputs.xlsx", sheet_name="MonthlySummary")
ms_back.head()

sheets = pd.read_excel("outputs/pandas_lab_outputs.xlsx", sheet_name=["MonthlySummary","CustomerPivot"])
list(sheets.keys()), sheets["CustomerPivot"].head()
```

---

## Stretch goals

- Add `MonthLabel` with `strftime("%b %Y")` and view a small subset.
- Export 2020-only rows to new CSV/Excel.
- Append an additional sheet to the same Excel file.
- Add basic input validation around reading the CSV.

---

## Notes (what "good" looks like)

- `Invoice_date` parsed as `datetime64[ns]` and new date columns created (`Year`, `Month`, `Quarter`, `InvoiceMonth`).
- Filters work either via `DatetimeIndex` or `between` on `InvoiceMonth`.
- Four output files produced:
  - `outputs/monthly_summary.csv`
  - `outputs/customer_month_pivot.csv`
  - `outputs/account_history.csv`
  - `outputs/pandas_lab_outputs.xlsx` with `RawData`, `MonthlySummary`, `CustomerPivot`, `AccountHistory`

---

## Main exercises: One-cell demo (optional)

```python
import pandas as pd
from pathlib import Path

Path("outputs").mkdir(exist_ok=True)

df = pd.read_csv("SampleData.csv", parse_dates=["Invoice_date"])
df["Year"] = df["Invoice_date"].dt.year
df["Month"] = df["Invoice_date"].dt.month
df["MonthName"] = df["Invoice_date"].dt.month_name()
df["Quarter"] = df["Invoice_date"].dt.quarter
df["InvoiceMonth"] = df["Invoice_date"].dt.to_period("M").dt.to_timestamp("M")

df["UsageCharge"] = df["Billed_usage_kwh"] * df["Price"]
df["TotalDue"] = df["Base_charge"] + df["UsageCharge"]

monthly_summary = (
    df.groupby("InvoiceMonth")
      .agg(Total_kWh=("Billed_usage_kwh","sum"),
           Total_Bill=("Bill","sum"),
           Total_Due=("TotalDue","sum"))
      .reset_index()
      .sort_values("InvoiceMonth")
)

customer_month_pivot = (
    df.pivot_table(index="InvoiceMonth", columns="CustomerID", values="TotalDue", aggfunc="sum")
    .sort_index()
)

example_acct = df["Account_no"].iloc[0]
acct_history = (
    df.loc[df["Account_no"] == example_acct, ["Invoice_date","Billed_usage_kwh","TotalDue"]]
      .sort_values("Invoice_date")
      .reset_index(drop=True)
)

monthly_summary.to_csv("outputs/monthly_summary.csv", index=False)
customer_month_pivot.to_csv("outputs/customer_month_pivot.csv")
acct_history.to_csv("outputs/account_history.csv", index=False)

with pd.ExcelWriter("outputs/pandas_lab_outputs.xlsx", engine="openpyxl") as xlw:
    df.to_excel(xlw, sheet_name="RawData", index=False)
    monthly_summary.to_excel(xlw, sheet_name="MonthlySummary", index=False)
    customer_month_pivot.to_excel(xlw, sheet_name="CustomerPivot")
    acct_history.to_excel(xlw, sheet_name="AccountHistory", index=False)
```

---

## Stretch Goal Solutions

These solutions assume you've already read `SampleData.csv` with `parse_dates=["Invoice_date"]` and created `InvoiceMonth` as in the main lab.

### 1) Date formatting for presentation (`MonthLabel`)

```python
monthly_summary["MonthLabel"] = monthly_summary["InvoiceMonth"].dt.strftime("%b %Y")
monthly_summary[["MonthLabel", "Total_kWh", "Total_Due"]].head(10)

# Or, directly from raw dates (if needed)
df["MonthLabel"] = df["Invoice_date"].dt.strftime("%b %Y")
df[["Invoice_date", "MonthLabel"]].head(10)
```

### 2) Export 2020-only rows to new CSV/Excel

```python
# A) Filter by dt.year
df_2020 = df[df["Invoice_date"].dt.year == 2020].copy()
df_2020.to_csv("outputs/only_2020.csv", index=False)
df_2020.to_excel("outputs/only_2020.xlsx", index=False, sheet_name="Only2020")

# B) Filter by between on Invoice_date (alternative)
start, end = "2020-01-01", "2020-12-31"
df_2020_alt = df[(df["Invoice_date"] >= start) & (df["Invoice_date"] <= end)].copy()
df_2020_alt.to_csv("outputs/only_2020_between.csv", index=False)

# C) Using normalized InvoiceMonth boundaries
df_2020_months = df[df["InvoiceMonth"].between("2020-01-31", "2020-12-31")].copy()
df_2020_months.to_excel("outputs/only_2020_months.xlsx", index=False, sheet_name="Only2020")
```

### 3) Append an additional sheet to the same Excel file

```python
monthly_usage_only = (
    df.groupby("InvoiceMonth")
      .agg(Total_kWh=("Billed_usage_kwh", "sum"))
      .reset_index()
      .sort_values("InvoiceMonth")
)
with pd.ExcelWriter(
    "outputs/pandas_lab_outputs.xlsx",
    engine="openpyxl",
    mode="a",
    if_sheet_exists="replace"
) as xlw:
    monthly_usage_only.to_excel(xlw, sheet_name="Monthly_Usage_Only", index=False)
```

### 4) Input validation: friendly errors for missing CSV & bad dates

```python
import pandas as pd
from pathlib import Path
csv_path = Path("SampleData.csv")
try:
    if not csv_path.exists():
        raise FileNotFoundError(f"Could not find {csv_path.resolve()}.")
    df_valid = pd.read_csv(csv_path, parse_dates=["Invoice_date"])  # new var to avoid overwriting
    df_valid["Invoice_date"] = pd.to_datetime(df_valid["Invoice_date"], errors="coerce")
    bad_dates = df_valid["Invoice_date"].isna().sum()
    if bad_dates > 0:
        raise ValueError(f"{bad_dates} row(s) have invalid or missing Invoice_date. Please check the source file.")
    print("CSV loaded successfully for validation.")
    print("Rows:", len(df_valid), "| Columns:", len(df_valid.columns))
except FileNotFoundError as e:
    print("ERROR:", e)
    print("Hint: Place 'SampleData.csv' in the same folder as this notebook/script.")
except ValueError as e:
    print("ERROR:", e)
except Exception as e:
    print("Unexpected error while reading SampleData.csv:", repr(e))
```

### Optional: Bundle the stretch goals end-to-end

```python
monthly_summary["MonthLabel"] = monthly_summary["InvoiceMonth"].dt.strftime("%b %Y")
df_2020 = df[df["Invoice_date"].dt.year == 2020].copy()
df_2020.to_csv("outputs/only_2020.csv", index=False)
df_2020.to_excel("outputs/only_2020.xlsx", index=False, sheet_name="Only2020")
monthly_usage_only = (
    df.groupby("InvoiceMonth")
      .agg(Total_kWh=("Billed_usage_kwh", "sum"))
      .reset_index()
      .sort_values("InvoiceMonth")
)
with pd.ExcelWriter(
    "outputs/pandas_lab_outputs.xlsx",
    engine="openpyxl",
    mode="a",
    if_sheet_exists="replace"
) as xlw:
    monthly_usage_only.to_excel(xlw, sheet_name="Monthly_Usage_Only", index=False)
print("Stretch goals completed: MonthLabel + 2020 exports + appended sheet.")
```
