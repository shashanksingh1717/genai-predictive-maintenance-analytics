# Business Insights — Predictive Maintenance Analysis

Every insight below is traceable to a specific number computed in
`predictive_maintenance_analysis.ipynb` or `sql_queries.sql`. Format:
**Observation → Evidence → Business Impact → Recommended Action.**

---

**1. Overall failure rate is low but consequential.**
Observation: only 3.51% of records represent a failure.
Evidence: 351 of 10,000 records have `Reason of Failure` ≠ 0 (SQL Query 3).
Business Impact: rare events are easy to miss in manual review and easy for a naive
model to ignore while still scoring high "accuracy."
Recommended Action: track Recall and ROC-AUC as primary maintenance-model KPIs, not
Accuracy — a model predicting "healthy" for everything would already score 96.5%.

**2. Type-1 (Low-duty) machines fail far more often than Type-3 (High-duty).**
Observation: failure rate is 4.07% for Type 1 vs 2.39% for Type 3 — a 70% relative gap.
Evidence: SQL Query 4 (244/6,000 vs 24/1,003).
Business Impact: the "low-duty" fleet, likely assumed lower-risk, is actually the
highest-risk segment.
Recommended Action: re-prioritize preventive-maintenance scheduling toward the Type-1
fleet rather than the higher-spec Type-3 units.

**3. Type-1's higher failure rate is not explained by heavier load.**
Observation: average torque is statistically indistinguishable across all three types
(≈0.001, 0.003, −0.015 in z-score terms).
Evidence: SQL Query 6.
Business Impact: rules out "Type 1 works harder" as the cause; points toward machine
age, wear accumulation, or maintenance-schedule gaps instead.
Recommended Action: pull maintenance-log/age data for Type-1 units to find the real
root cause before changing operating limits.

**4. Torque and tool wear are the strongest individual linear indicators of failure.**
Observation: Torque (r = 0.195) and Tool wear (r = 0.106) show the highest correlation
with the binary failure flag; other sensors are near zero.
Evidence: correlation heatmap, Section 3.1 of the notebook.
Business Impact: neither correlation is strong alone — no single-sensor rule will
catch most failures.
Recommended Action: build composite alert logic combining torque and tool-wear jointly
rather than a single-variable threshold.

**5. Tool-wear risk is a cliff, not a ramp.**
Observation: failure rate is flat (2.2–2.4%) across the bottom three tool-wear
quartiles, then jumps to 7.16% in the top quartile — roughly 3× higher.
Evidence: SQL Query 9 (NTILE window function).
Business Impact: a fixed, uniform wear ceiling wastes inspection budget on
low-risk machines while under-reacting right at the danger zone.
Recommended Action: trigger proactive tool replacement/inspection specifically once a
tool crosses the fleet's 75th-percentile wear mark.

**6. Failed machines run measurably hotter on both temperature gauges.**
Observation: average air/process temperature (z-score) is 0.438 / 0.203 for failed
machines vs −0.016 / −0.007 for healthy ones.
Evidence: SQL Query 5.
Business Impact: thermal readings are a legitimate, low-cost early-warning signal.
Recommended Action: add a temperature-deviation alert tier alongside the torque/wear
rule, escalating when both fire together.

**7. Failure has (at least) two distinct operating-condition signatures.**
Observation: failures visually cluster in a low-speed/high-torque corner *and*, separately,
a high-speed/low-torque corner of the operating envelope.
Evidence: torque-vs-speed scatter plot, Section 3.5.
Business Impact: a single "high torque = risk" rule would miss the second failure mode
entirely.
Recommended Action: implement two separate operating-condition alert segments (see SQL
Query 10) rather than one combined rule.

**8. Two failure categories account for the majority of incidents.**
Observation: categories 2 and 3 together represent 59% of all 351 failures (91 + 115).
Evidence: SQL Query 7 / failure-category chart, Section 3.4.
Business Impact: engineering time invested in root-causing categories 2 and 3 addresses
the largest share of preventable downtime.
Recommended Action: sequence root-cause investigations by category volume — categories
2 and 3 first, then 4 and 6, with 1 and 5 deferred (see Insight 9).

**9. Some failure categories are too rare in this dataset to model reliably.**
Observation: category 1 has only 3 total occurrences (1 in the test set); category 5 has
18 total (7 in test). A multi-class model trained on CTGAN-augmented data reaches 0%
recall on category 1 and 0% on category 5.
Evidence: multi-class classification report, Section 5 of the notebook.
Business Impact: an automated root-cause label for these two mechanisms cannot yet be
trusted.
Recommended Action: route any flagged category-1/5 event to manual engineering review
rather than an automated classification, and prioritize collecting more real (not
synthetic) examples of these two failure modes.

**10. Random Forest is the strongest model architecture across every training regime.**
Observation: Random Forest outperforms Logistic Regression and Decision Tree on F1 and
ROC-AUC in all three training regimes tested (baseline, SMOTE, CTGAN).
Evidence: model comparison table, Section 5.
Business Impact: ensemble tree methods handle the non-linear, interaction-heavy failure
patterns in this data far better than a linear model.
Recommended Action: standardize on Random Forest (or a gradient-boosted variant) as the
production model family for this use case.

**11. Class-balancing technique controls the precision/recall trade-off, not overall
model skill.**
Observation: Random Forest ROC-AUC stays in a tight 0.92–0.95 band whether trained on
baseline, SMOTE, or CTGAN data, while recall rises from 61.2% → 74.5% → 90.8% and
precision falls from 89.6% → 27.7% → 11.8% across the same three regimes.
Evidence: model comparison table, Section 5.
Business Impact: there is no free lunch — catching more real failures with synthetic
minority data means generating more false alarms, not a smarter model.
Recommended Action: pick the training regime (and resulting decision threshold) to match
actual maintenance-team inspection capacity, rather than chasing the single "best" model.

**12. Rotational speed matters far more to the model than to a simple correlation check.**
Observation: Rotational speed is the #1 feature by Random Forest importance (26.3%)
despite showing almost no linear correlation with failure (r = −0.049).
Evidence: feature importance chart, Section 5, vs correlation heatmap, Section 3.1.
Business Impact: a dashboard or rule engine built only on correlation analysis would
under-weight the single most predictive sensor.
Recommended Action: surface Rotational speed prominently on the Power BI Machine Health
page even though it doesn't stand out in a simple correlation view.

**13. Machine duty class (`Type`) is the least useful predictive feature.**
Observation: `Type` contributes only 2.5% of Random Forest feature importance — the
lowest of all six features.
Evidence: feature importance chart, Section 5.
Business Impact: live sensor telemetry, not the machine's static duty classification,
should drive real-time risk scoring.
Recommended Action: use `Type` for fleet segmentation/reporting (as in Insight 2), but
do not rely on it as a leading indicator in the real-time alerting model.
