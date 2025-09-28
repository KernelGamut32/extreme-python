
# Lab 08: Matplotlib Basics — Essential Plots & Patterns

**Duration:** ~45 minutes  
**Data:** `SampleData.csv`

## Objectives

- Load CSV → prep data
- Create line, multi-line, grouped bar, histogram, scatter, and box plots
- Apply titles, labels, legends, tick formatting, grids
- Save figures

---

## Part 0 — Setup

1. Imports:
   - `pandas`, `numpy`, `matplotlib.pyplot`
   - `DateFormatter`, `MonthLocator` for dates
2. Load data and prep:
   - Parse `Invoice_date` with `%m/%d/%Y`
   - Sort by date; add `YearMonth`, `Quarter` columns
3. Sanity check: `head()`, `dtypes`, `describe()`

---

## Part A — Single Line Plot

- Aggregate monthly kWh: group by `YearMonth` → `Total_kwh`
- Plot with markers, grid, and rotated monthly ticks

**Pattern:** `plot` → labels → `MonthLocator` + `DateFormatter` → `tight_layout()`

---

## Part B — Multiple Lines

- Pivot monthly usage by `ProductID` into wide format
- Loop each column to `plot` with a legend

**Pattern:** loop series → `legend(ncols=2)` → consistent tick formatting

---

## Part C — Grouped Bar Chart

- Aggregate quarterly kWh by `ProductID`
- Compute bar positions with `np.arange` and `width = 0.8 / n_series`
- Align `xticks` to centers

**Pattern:** manual x-positions → axis grid on y → legend

---

## Part D — Distribution & Spread

- Histogram of `Bill` with ~20 bins
- Box plot of `Billed_usage_kwh` by `ProductID` (use `showmeans=True`)

**Pattern:** one variable (hist) vs multiple groups (box)

---

## Part E — Scatter + Trendline

- Scatter `Billed_usage_kwh` vs `Bill` with slight transparency
- Add linear fit via `np.polyfit`

**Pattern:** overlay line on scatter → grid → tight layout

---

## Part F — Subplots & Export

- 1×2 figure: histogram (Bill) and scatter (Usage vs Bill)
- Save a figure: `fig.savefig("matplotlib_summary.png", dpi=150, bbox_inches="tight")`

---

## Troubleshooting

- **Dates:** use `errors="coerce"` if format varies
- **Bars misaligned:** check bar centers and `xticks`
- **Crowded labels:** `tight_layout()` and `xticks(rotation=45)`
- **Odd trendline:** consider outliers or log scale
