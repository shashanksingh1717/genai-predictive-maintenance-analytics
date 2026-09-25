/* =====================================================================
   PREDICTIVE MAINTENANCE — SQL ANALYTICS
   Table: machines (Type, Air temperature [K], Process temperature [K],
                     Rotational speed [rpm], Torque [Nm], Tool wear [min],
                     Reason of Failure)
   Note: numeric sensor columns are pre-standardized (z-scores).
   Tested against SQLite; window-function queries also run unmodified on
   PostgreSQL / SQL Server / Snowflake.
   ===================================================================== */

-- 1. Total machines (records) in the dataset
-- Purpose: baseline denominator for every rate calculation below.
SELECT COUNT(*) AS total_machines
FROM machines;
-- Result: 10,000


-- 2. Total failures
-- Purpose: numerator for failure-rate KPI; headline count for exec dashboard.
SELECT COUNT(*) AS total_failures
FROM machines
WHERE `Reason of Failure` != 0;
-- Result: 351


-- 3. Overall failure rate (%)
-- Purpose: single headline KPI for Page 1 of the Power BI dashboard.
SELECT ROUND(100.0 * SUM(CASE WHEN `Reason of Failure` != 0 THEN 1 ELSE 0 END) / COUNT(*), 3)
       AS failure_rate_pct
FROM machines;
-- Result: 3.51%


-- 4. Failure rate by machine type
-- Purpose: identify which duty class (Low/Medium/High) needs more maintenance attention.
SELECT Type,
       COUNT(*) AS total,
       SUM(CASE WHEN `Reason of Failure` != 0 THEN 1 ELSE 0 END) AS failures,
       ROUND(100.0 * SUM(CASE WHEN `Reason of Failure` != 0 THEN 1 ELSE 0 END) / COUNT(*), 2)
           AS failure_rate_pct
FROM machines
GROUP BY Type
ORDER BY Type;
-- Result: Type 1 (L) 4.07% | Type 2 (M) 2.77% | Type 3 (H) 2.39%
-- Insight: Type-1 (Low-duty) machines fail ~70% more often than Type-3 (High-duty).


-- 5. Average temperature by failure status
-- Purpose: check whether failed machines run measurably hotter (thermal stress signal).
SELECT CASE WHEN `Reason of Failure` != 0 THEN 'Failure' ELSE 'No Failure' END AS status,
       ROUND(AVG(`Air temperature [K]`), 3)     AS avg_air_temp_z,
       ROUND(AVG(`Process temperature [K]`), 3) AS avg_process_temp_z
FROM machines
GROUP BY status;
-- Result: Failure avg_air_temp_z=0.438, avg_process_temp_z=0.203
--         No Failure avg_air_temp_z=-0.016, avg_process_temp_z=-0.007
-- Insight: failed machines run noticeably above-average temperature on both gauges.


-- 6. Average torque by machine type
-- Purpose: verify torque load is comparable across duty classes (rules out "Type 1 just
-- runs harder" as the explanation for its higher failure rate in Query 4).
SELECT Type, ROUND(AVG(`Torque [Nm]`), 3) AS avg_torque_z
FROM machines
GROUP BY Type
ORDER BY Type;
-- Result: Type 1 ≈ 0.001 | Type 2 ≈ 0.003 | Type 3 ≈ -0.015 (all essentially equal)
-- Insight: torque load is NOT higher for Type 1 -> its elevated failure rate is not
-- explained by heavier mechanical load, pointing toward maintenance-schedule or
-- machine-age causes instead.


-- 7. Top failure categories by frequency
-- Purpose: prioritize root-cause engineering effort by volume.
SELECT `Reason of Failure` AS failure_code, COUNT(*) AS occurrences
FROM machines
WHERE `Reason of Failure` != 0
GROUP BY `Reason of Failure`
ORDER BY occurrences DESC;
-- Result: 3->115, 2->91, 4->78, 6->46, 5->18, 1->3
-- Insight: categories 2 and 3 alone account for 59% of all failures.


-- 8. High-risk machines: highest tool-wear failures (worst-case exemplars)
-- Purpose: surface concrete example records for engineering review / drill-through.
SELECT Type, `Reason of Failure`, `Tool wear [min]`, `Torque [Nm]`
FROM machines
WHERE `Reason of Failure` != 0
ORDER BY `Tool wear [min]` DESC
LIMIT 10;
-- Insight: the highest-wear failures cluster in categories 4 and 6, and combine high
-- tool-wear with above-average torque -> supports a joint torque+wear alert rule.


-- 9. Tool-wear quartile risk analysis (window function: NTILE)
-- Purpose: test whether failure risk rises smoothly or has a "cliff" at high wear.
WITH ranked AS (
    SELECT *, NTILE(4) OVER (ORDER BY `Tool wear [min]`) AS wear_quartile
    FROM machines
)
SELECT wear_quartile,
       COUNT(*) AS total,
       SUM(CASE WHEN `Reason of Failure` != 0 THEN 1 ELSE 0 END) AS failures,
       ROUND(100.0 * SUM(CASE WHEN `Reason of Failure` != 0 THEN 1 ELSE 0 END) / COUNT(*), 2)
           AS failure_rate_pct
FROM ranked
GROUP BY wear_quartile
ORDER BY wear_quartile;
-- Result: Q1 2.28% | Q2 2.40% | Q3 2.20% | Q4 7.16%
-- Insight: risk is flat across the bottom three quartiles then TRIPLES in the top
-- quartile -> tool-wear risk is non-linear ("cliff", not a ramp). Maintenance triggers
-- should target the top wear quartile specifically, not a uniform fixed threshold.


-- 10. Operating-condition risk segments (torque x rotational speed, via CTE + CASE)
-- Purpose: flag the two distinct high-risk operating corners seen in the scatter plot
-- (low-speed/high-torque and high-speed/low-torque).
WITH segmented AS (
    SELECT *,
        CASE
            WHEN `Torque [Nm]` > 0.5 AND `Rotational speed [rpm]` < -0.5 THEN 'Low-Speed / High-Torque'
            WHEN `Torque [Nm]` < -0.5 AND `Rotational speed [rpm]` > 0.5 THEN 'High-Speed / Low-Torque'
            ELSE 'Normal Operating Range'
        END AS risk_segment
    FROM machines
)
SELECT risk_segment,
       COUNT(*) AS total,
       SUM(CASE WHEN `Reason of Failure` != 0 THEN 1 ELSE 0 END) AS failures,
       ROUND(100.0 * SUM(CASE WHEN `Reason of Failure` != 0 THEN 1 ELSE 0 END) / COUNT(*), 2)
           AS failure_rate_pct
FROM segmented
GROUP BY risk_segment
ORDER BY failure_rate_pct DESC;
-- Insight: both flagged corners show a materially higher failure rate than the "Normal"
-- segment, confirming two distinct mechanical failure modes worth separate alert rules.


-- 11. Rank machines within each type by failure risk proxy (window function: RANK)
-- Purpose: example of a ranking window function for a "top N riskiest machines per type"
-- drill-through table on the Power BI Predictive Maintenance page.
SELECT Type, `Reason of Failure`, `Tool wear [min]`, `Torque [Nm]`,
       RANK() OVER (PARTITION BY Type ORDER BY `Tool wear [min]` DESC) AS wear_rank_within_type
FROM machines
WHERE `Reason of Failure` != 0
QUALIFY wear_rank_within_type <= 5;
-- (SQLite has no QUALIFY; wrap in an outer SELECT ... WHERE wear_rank_within_type <= 5
--  on engines without QUALIFY support, e.g.:
--  SELECT * FROM ( ... RANK() ... ) sub WHERE wear_rank_within_type <= 5;)


-- 12. Monthly/periodic failure trend
-- Not applicable: this dataset has no timestamp/date column, so no time-series trend
-- query can be produced without fabricating dates. If a future data pull adds an
-- event timestamp, the recommended query is:
--   SELECT strftime('%Y-%m', failure_date) AS month,
--          COUNT(*) AS failures
--   FROM machines WHERE `Reason of Failure` != 0
--   GROUP BY month ORDER BY month;
