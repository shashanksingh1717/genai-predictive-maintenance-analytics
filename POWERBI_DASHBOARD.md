# Power BI Dashboard Design — Predictive Maintenance

Four-page dashboard built on the cleaned dataset plus model-output tables
(`predictions.csv` — machine ID, predicted failure probability, predicted class —
exported from the notebook's Random Forest model). Suggested data model: a single
`Machines` fact table plus a `Type` dimension table (1 → many) for cleaner DAX and
slicer behavior.

## Page 1 — Executive Overview

| Element | Type | DAX / Notes |
|---|---|---|
| Total Machines | Card KPI | `Total Machines = COUNTROWS(Machines)` |
| Total Failures | Card KPI | `Total Failures = CALCULATE(COUNTROWS(Machines), Machines[Reason of Failure] <> 0)` |
| Failure Rate | Card KPI (with target) | `Failure Rate = DIVIDE([Total Failures], [Total Machines])`, format as %, conditional color if > 5% |
| Average Temperature | Card KPI | `AVERAGE('Machines'[Air temperature [K]])` |
| Average Torque | Card KPI | `AVERAGE('Machines'[Torque [Nm]])` |
| Average Tool Wear | Card KPI | `AVERAGE('Machines'[Tool wear [min]])` |
| Failure Rate Trend | Line/area chart | Placeholder — enabled once a date/time field is added upstream (see SQL file, Query 12 note) |
| Failure Rate by Type | Donut/bar | Quick visual anchor to Insight #2 in `BUSINESS_INSIGHTS.md` |

**Slicers (global, apply to all pages):** `Type`, failure-status toggle
(All / Failures Only / Healthy Only).

## Page 2 — Machine Health Analysis

| Element | Type | Notes |
|---|---|---|
| Temperature Distribution | Histogram | Air vs Process temperature, split by failure status |
| Torque vs Rotational Speed | Scatter | Color by `Reason of Failure`; matches notebook Section 3.5 — this is the single most useful diagnostic visual on the page |
| Tool Wear Distribution | Box plot / ribbon chart | By `Type`, annotated with the Q4 "cliff" from SQL Query 9 |
| Machine-Type Comparison | Clustered column | Avg Torque, Avg Tool Wear, Avg Temperature side-by-side per `Type` |

**Drill-through:** clicking a `Type` bar drills through to a filtered table of that
type's individual machine records (Torque, Tool Wear, Speed, Failure flag).

## Page 3 — Failure Analysis

| Element | Type | Notes |
|---|---|---|
| Failure Categories | Bar chart, sorted descending | Mirrors SQL Query 7; highlight categories 2 & 3 as "priority" (Insight #8) |
| Failure Rate by Machine Type | Bar chart | Same measure as Page 1, larger with data labels |
| Failure Rate by Tool-Wear Quartile | Column chart | `Wear Quartile = RANKX(ALL(Machines), Machines[Tool wear [min]], , ASC)` binned into 4 groups via a calculated column, replicating SQL Query 9's cliff pattern |
| High-Risk Operating Conditions | Scatter with reference lines | Torque × Speed, shaded quadrants marking the two risk corners from Insight #7 |

**Filters:** failure-category multi-select; tool-wear quartile slicer.

## Page 4 — Predictive Maintenance

| Element | Type | Notes |
|---|---|---|
| Predicted Failure Probability | Gauge / conditional table | Sourced from exported model scores (`predictions.csv`); color-scale 0–100% |
| High-Risk Machines | Table, sorted by probability desc | Top-N machines above a probability threshold slicer (default 50%) |
| Model Performance | KPI cards | Precision, Recall, F1, ROC-AUC — pulled directly from the notebook's Section 5 results table so the dashboard always matches the documented model run |
| Maintenance Priority Indicator | Traffic-light table (Green/Amber/Red) | `Priority = SWITCH(TRUE(), [Probability] > 0.7, "Red", [Probability] > 0.4, "Amber", "Green")` |

**Drill-through:** clicking a high-risk machine opens a single-machine detail page
showing its full sensor history (once a time dimension is available) or its current
snapshot values against fleet averages.

## Cross-cutting recommendations

- **Bookmarks:** "Executive View" (Page 1 only, simplified) vs "Analyst View" (all four
  pages, all slicers visible) as two bookmark states for different audiences.
- **Tooltips:** every KPI card should show a tooltip page with the trend and the
  underlying counts (numerator/denominator), not just the headline %.
- **Row-level security:** if extended to a real multi-plant deployment, filter by
  plant/site using RLS roles tied to `Type` or a future `Plant` dimension.
- **Refresh cadence:** daily scheduled refresh is sufficient given the batch nature of
  this sensor data; move to near-real-time (DirectQuery/streaming dataset) only if the
  upstream system starts emitting a live event stream.
