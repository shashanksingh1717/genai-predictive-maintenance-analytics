# Balanced Predictive Maintenance Dataset — Generative AI for Data Analysts

An end-to-end Data Analyst portfolio project combining **Python, SQL, Machine Learning,
and Generative AI** to analyze and predict industrial machine failure.

## Project Overview

Unplanned machine failure is one of the costliest problems on a production floor. This
project analyzes 10,000 sensor readings from industrial machines to understand *when*,
*why*, and *which type* of machine tends to fail — then builds and compares classification
models to predict failure before it happens, using both classic oversampling (SMOTE) and
a **Generative AI (CTGAN)** synthetic-data approach to address severe class imbalance.

## Business Problem

Only 3.51% of machines in the dataset actually fail — a realistic, highly imbalanced
scenario. A model that ignores minority failure cases would look "accurate" on paper
while missing almost every real failure. The business problem is therefore not "predict
failure" in the abstract, but **catch enough real failures to prevent downtime, without
flooding the maintenance team with false alarms.**

## Objectives

1. Understand the structure, quality, and class balance of the dataset.
2. Perform SQL and Python-based exploratory analysis to find real, actionable patterns.
3. Build and honestly compare multiple classification models across three training
   regimes (imbalanced baseline, SMOTE, CTGAN-synthetic).
4. Demonstrate practical Generative AI use cases for a data analyst's day-to-day workflow.
5. Design a Power BI dashboard translating the analysis into a decision-support tool.
6. Produce 13 business insights, each tied to a specific number in the analysis.

## Dataset Description

| File | Rows | Purpose |
|---|---|---|
| `cleaned_data.csv` | 10,000 | Full cleaned dataset used for EDA and SQL analytics |
| `X_train.csv` / `y_train.csv` | 7,000 | Original (imbalanced) training split |
| `X_test.csv` / `y_test.csv` | 3,000 | Held-out test set — used for every model comparison |
| `X_smote.csv` / `y_smote.csv` | 47,229 | Training data balanced with SMOTE oversampling |
| `X_ctgan.csv` / `y_ctgan.csv` | 87,458 | Training data augmented with CTGAN-generated synthetic samples |

**Columns:** `Type` (machine duty class, 1=Low/2=Medium/3=High), `Air temperature [K]`,
`Process temperature [K]`, `Rotational speed [rpm]`, `Torque [Nm]`, `Tool wear [min]`
(all pre-standardized/z-scored), and `Reason of Failure` (0 = healthy, 1–6 = failure
category).

## Tech Stack

- **Python** — Pandas, NumPy, scikit-learn, Matplotlib, Seaborn
- **SQL** — SQLite (portable to PostgreSQL/Snowflake/SQL Server), CTEs, window functions
- **Machine Learning** — Logistic Regression, Decision Tree, Random Forest
- **Generative AI** — CTGAN synthetic tabular data generation; LLM-assisted analyst
  workflow (prompt engineering, AI-assisted SQL/Python, insight generation)
- **Power BI** — dashboard design (spec provided; see `POWERBI_DASHBOARD.md`)

## Data Workflow

```
Raw sensor data → cleaning validation (no missing/dup values found)
                → EDA (Python: distributions, correlation, boxplots, scatter)
                → SQL analytics (aggregations, CTEs, window functions)
                → Train/test split (provided) → 3 training regimes:
                      Baseline | SMOTE-balanced | CTGAN-augmented (Generative AI)
                → Model training: Logistic Regression, Decision Tree, Random Forest
                → Evaluation on one fixed held-out test set (fair comparison)
                → Business insight generation (AI-assisted, analyst-validated)
                → Power BI dashboard design
```

## Python Analysis

See `predictive_maintenance_analysis.ipynb` for the full, executed notebook: data
understanding, cleaning validation, five EDA visualizations (each with a business
interpretation), and the full ML comparison.

## SQL Analysis

See `sql_queries.sql` for 11 annotated queries covering totals, failure rates by
segment, temperature/torque aggregations, top failure categories, a tool-wear quartile
risk analysis (`NTILE` window function), an operating-condition risk segmentation, and a
per-type risk ranking (`RANK` window function).

## Machine Learning — Headline Results

Random Forest trained on the original (baseline) split is the best *balanced* model:

| Training Data | Model | Accuracy | Precision | Recall | F1 | ROC-AUC |
|---|---|---|---|---|---|---|
| Baseline | Random Forest | 0.985 | 0.896 | 0.612 | 0.727 | **0.946** |
| SMOTE | Random Forest | 0.928 | 0.277 | 0.745 | 0.403 | 0.923 |
| CTGAN | Random Forest | 0.774 | 0.118 | **0.908** | 0.208 | 0.933 |

**Why recall matters more than accuracy here:** a model predicting "no failure" for
every machine would already score 96.5% accuracy while catching zero real failures.
Recall (did we catch the real failures?) and ROC-AUC (can the model rank risk at all?)
are the metrics that actually matter for a predictive-maintenance use case, where a
missed failure is far costlier than an unnecessary inspection. Full discussion of the
precision/recall trade-off across training regimes is in the notebook, Section 5, and
Insight #11 in `BUSINESS_INSIGHTS.md`.

## Generative AI Applications

Two distinct GenAI applications are demonstrated:

1. **CTGAN synthetic tabular data** — a Conditional Tabular GAN generated realistic
   synthetic examples of rare failure categories, directly improving failure-detection
   recall from 61% to 91% (at a measured precision cost — see above).
2. **LLM-assisted analyst workflow** — 10 documented use cases (prompt engineering,
   AI-assisted SQL/Python, AI-assisted cleaning decisions, insight generation, and
   plain-language explanation of model results), each showing the AI's draft output next
   to the analyst's validation and correction. See `GENAI_USE_CASES.md`.

## Power BI Dashboard

Four-page dashboard specification — Executive Overview, Machine Health Analysis, Failure
Analysis, Predictive Maintenance — with recommended visuals, DAX measures, slicers, and
drill-through behavior. See `POWERBI_DASHBOARD.md`.
👉 **[Open the live dashboard](https://shashanksingh1717.github.io/genai-predictive-maintenance-analytics/)**

## Key Insights

13 insights, each as Observation → Evidence → Business Impact → Recommended Action, are
documented in full in `BUSINESS_INSIGHTS.md`. Highlights:

- Type-1 (low-duty) machines fail 70% more often than Type-3 machines, and it is **not**
  explained by heavier torque load — a maintenance-schedule or machine-age cause is more
  likely.
- Tool-wear risk is a **cliff, not a ramp**: flat ~2.3% failure rate across the bottom
  three wear quartiles, then 7.16% in the top quartile.
- Failures cluster in two distinct operating-condition corners (low-speed/high-torque and
  high-speed/low-torque), not one — a single-threshold alert rule would miss half the
  failure modes.
- Random Forest is the strongest model architecture across every tested training regime.
- Balancing technique (SMOTE/CTGAN) controls the precision/recall trade-off; it does not
  make the model fundamentally "smarter" (ROC-AUC stays in a tight 0.92–0.95 band).

## Business Recommendations

- Re-prioritize preventive maintenance toward the Type-1 fleet, not the higher-duty units.
- Replace fixed tool-wear thresholds with a quartile-based (or percentile-based) trigger.
- Deploy dual operating-condition alert rules rather than a single torque threshold.
- Choose the training regime (baseline / SMOTE / CTGAN) to match actual inspection
  capacity — maximize recall only if the maintenance team can absorb the extra false
  alarms.
- Route rare failure categories (1 and 5) to manual engineering review rather than
  automated classification until more real examples are collected.

## Project Architecture

```
project/
├── data/                                # provided train/test/augmented splits
├── predictive_maintenance_analysis.ipynb # full executed Python analysis
├── sql_queries.sql                      # standalone annotated SQL analytics
├── BUSINESS_INSIGHTS.md                 # 13 insights (Observation→Evidence→Impact→Action)
├── GENAI_USE_CASES.md                   # 10 documented GenAI-assisted analyst workflows
├── POWERBI_DASHBOARD.md                 # 4-page dashboard design spec
├── outputs/                             # exported charts (PNG) referenced in the notebook
└── README.md                            # this file
```

## Skills Demonstrated

**SQL:** querying, aggregations, `CASE` logic, CTEs, window functions (`NTILE`, `RANK`).

**Python:** Pandas, NumPy, EDA, Matplotlib/Seaborn visualization, scikit-learn
(Logistic Regression, Decision Tree, Random Forest, classification metrics).

**Power BI:** dashboard/data-model design, DAX measures, KPI cards, slicers, drill-through.

**Generative AI:** prompt engineering, AI-assisted SQL/Python drafting, AI-assisted
insight generation and natural-language model explanation, CTGAN-based synthetic data
generation for class-imbalance mitigation, and — critically — analyst validation of every
AI output against the real data.

## Future Improvements

- Add a real timestamp field to enable the monthly/periodic failure-trend analysis noted
  as "not applicable" in `sql_queries.sql` (Query 12).
- Collect additional real (non-synthetic) examples of failure categories 1 and 5, which
  remain unlearnable at current sample sizes.
- Extend the Power BI model with a `Plant`/`Site` dimension and row-level security if
  deployed across multiple facilities.
- Explore gradient-boosted models (XGBoost/LightGBM) and threshold-tuning (rather than
  only data-balancing) as an additional lever on the precision/recall trade-off.
- Build the actual `.pbix` file from the specification in `POWERBI_DASHBOARD.md` once
  connected to a live or refreshable data source.
