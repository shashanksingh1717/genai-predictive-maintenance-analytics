# Generative AI Integration — Use Cases for a Data Analyst

Each use case distinguishes the **AI-generated suggestion** from the **analyst-validated
conclusion** that actually made it into the project. Prompts shown are representative of
what was used while building this project; outputs are summarized/paraphrased rather than
pasted verbatim, since raw LLM transcripts are rarely portfolio-ready as-is.

---

### A. Prompt Engineering for Data Exploration
**Task:** decide what to check before touching the model.
**Prompt used:** "I have a predictive-maintenance dataset with a `Reason of Failure`
column (0 = healthy, 1–6 = failure types) and standardized sensor columns. What should I
check before modeling?"
**AI-generated output:** a checklist — class balance, per-class sample counts, outliers
per sensor, correlation of each sensor with the target, and whether categorical columns
need re-encoding.
**Analyst validation:** confirmed the checklist was complete but added one item the AI
missed — checking whether the numeric columns were *already* standardized (they were),
which changes how outliers and business-unit interpretation should be handled.
**Final improved result:** Section 1–2 of the notebook, including the "Note on scale"
callout that a generic checklist wouldn't have surfaced.

### B. AI-assisted SQL Query Generation
**Task:** write a query showing whether failure risk rises smoothly or has a threshold
effect with tool wear.
**Prompt used:** "Write a SQL query using a window function to bucket machines into
tool-wear quartiles and show the failure rate per bucket."
**AI-generated output:** a `NTILE(4)` CTE query, structurally correct but grouping on the
raw partition alias incorrectly (referenced the window function inside the same `SELECT`
without a CTE, which most engines reject).
**Analyst validation:** rewrote using a `WITH ranked AS (...)` CTE so the window-function
result could be grouped in the outer query; verified output against a manual Pandas
`pd.qcut` calculation (both approaches produced the same quartile-4 = 7.16% figure).
**Final improved result:** SQL Query 9 in `sql_queries.sql`.

### C. AI-assisted Python/Pandas Coding
**Task:** build the torque-vs-speed scatter plot colored by failure status.
**Prompt used:** "Give me matplotlib code for a scatter plot of two numeric columns
colored by a binary target, sampling for readability on 10,000 rows."
**AI-generated output:** correct base code, but without the readability sample and using
a non-colorblind-safe color map.
**Analyst validation:** added `df.sample(3000, random_state=42)` for a reproducible,
legible plot and switched to the `coolwarm` diverging map for the binary target.
**Final improved result:** Section 3.5 of the notebook.

### D. AI-assisted Data Cleaning
**Task:** decide how to treat the 77 rotational-speed rows with |z| > 4.
**Prompt used:** "I found 77 outlier rows on one sensor column in a failure dataset with
only 351 failures total. Should I remove them?"
**AI-generated output:** a generic recommendation to "consider removing outliers beyond 3
standard deviations to improve model performance."
**Analyst validation:** rejected the generic advice — cross-checked how many of the 77
outlier rows were failures. A meaningful share were, meaning the "outliers" were partly
real failure signal, not sensor error. Removing them would have thrown away scarce
positive-class data.
**Final improved result:** the explicit "kept, not removed" decision documented in
Section 2 of the notebook — a case where the AI's default answer was wrong for this
specific class-imbalance context and needed analyst override.

### E. AI-assisted EDA Interpretation
**Task:** interpret why Type-1 machines fail more often despite (assumed) lighter duty.
**Prompt used:** "Type-1 (low-duty) machines have a 4.07% failure rate vs 2.39% for
Type-3 (high-duty). What are plausible explanations?"
**AI-generated output:** three hypotheses — lighter maintenance scheduling for
"low-risk" units, older average fleet age, and possible under-reporting bias for
high-duty units.
**Analyst validation:** tested the first hypothesis against available data by comparing
average torque across types (Query 6) — confirmed torque was *not* different, ruling out
"they're just worked harder," and narrowing the explanation toward maintenance/age causes
that would need data outside this dataset to confirm.
**Final improved result:** Insight #2 and #3 in `BUSINESS_INSIGHTS.md`, explicitly
flagged as needing external maintenance-log data to fully confirm.

### F. AI-assisted Anomaly Investigation
**Task:** understand the two-cluster pattern in the torque/speed scatter plot.
**Prompt used:** "Failures in this torque-vs-speed scatter plot cluster in two separate
corners rather than one region. What mechanical failure modes would produce that pattern?"
**AI-generated output:** suggested this is consistent with two distinct failure
mechanisms — an overload/stall mode (low speed, high torque) and a tool-breakage/loss-of-load
mode (high speed, low torque).
**Analyst validation:** accepted as a plausible engineering hypothesis (consistent with
common CNC/rotating-equipment failure literature) but labeled it as a hypothesis, not a
confirmed root cause, since the dataset has no direct failure-mechanism sensor to verify it.
**Final improved result:** Insight #7, worded carefully to separate the *data pattern*
(confirmed) from the *mechanical explanation* (plausible, unconfirmed).

### G. KPI Recommendation
**Task:** decide which metrics belong on the executive dashboard page.
**Prompt used:** "For a predictive-maintenance exec dashboard, what 5–6 KPIs would a
plant manager actually look at daily?"
**AI-generated output:** Total Machines, Failure Rate, Average Downtime, Cost of
Failures, MTBF (Mean Time Between Failures), Maintenance Backlog.
**Analyst validation:** removed Average Downtime, Cost of Failures, and MTBF — this
dataset has no timestamp or cost field, so those KPIs cannot actually be computed here.
Kept the ones the data supports and added Average Torque/Tool Wear as leading indicators
this specific dataset does support.
**Final improved result:** Page 1 KPI list in `POWERBI_DASHBOARD.md` — a case of trimming
an AI suggestion down to what's honestly deliverable from the available fields.

### H. Dashboard Storytelling
**Task:** decide the narrative order of the four Power BI pages.
**Prompt used:** "What's a logical page order for a predictive-maintenance dashboard
audience: plant executives, maintenance engineers, and a data-science-facing predictive
page?"
**AI-generated output:** Executive Summary → Predictive Scores → Root Cause → Health
Detail.
**Analyst validation:** reordered to Executive Overview → Machine Health → Failure
Analysis → Predictive Maintenance, so each page builds on the last (what's happening →
why → predict what's next) rather than leading with predictions before the audience has
seen the underlying health data.
**Final improved result:** page order in `POWERBI_DASHBOARD.md`.

### I. Automated Business Insight Generation
**Task:** draft first-pass business insights from the completed EDA/SQL/ML outputs.
**Prompt used:** "Given these summary statistics [pasted the JSON report], draft business
insights in an Observation → Evidence → Impact → Action format."
**AI-generated output:** an initial set of ~15 draft insights, two of which overstated
causality (e.g., claiming torque "causes" failure rather than "is associated with").
**Analyst validation:** rewrote overstated claims to correlational language, removed one
duplicate insight, and discarded one insight the underlying numbers didn't actually
support after re-checking.
**Final improved result:** the final 13 insights in `BUSINESS_INSIGHTS.md`.

### J. Natural-Language Explanation of ML Results
**Task:** explain, for a non-technical stakeholder, why the CTGAN-trained model has lower
precision than the baseline model.
**Prompt used:** "Explain in plain business language why training on synthetic
CTGAN-balanced data increased our failure-detection recall from 61% to 91% but dropped
precision from 90% to 12%."
**AI-generated output:** a plain-language explanation of the precision/recall trade-off
and an analogy to a smoke detector's sensitivity setting.
**Analyst validation:** kept the analogy (useful for stakeholders) but corrected a subtle
error in the AI's draft, which implied the model got "smarter" — verified via ROC-AUC
(stable ~0.92–0.95 across regimes) that the model's ranking ability didn't materially
change, only its decision threshold behavior did.
**Final improved result:** the "Why it matters" writeup under Section 5 of the notebook
and Insight #11 in `BUSINESS_INSIGHTS.md`.

---

## Summary: AI-generated vs analyst-validated

In every use case above, the AI output was a **draft or starting hypothesis**, not a
final answer. The analyst's role — verifying against the actual data, rejecting generic
advice that didn't fit this dataset's constraints (no timestamps, extreme class rarity,
already-standardized features), and correcting overstated causal language — is what turned
each AI draft into something safe to put in front of a business stakeholder.
