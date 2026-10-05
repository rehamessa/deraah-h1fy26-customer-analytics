/* ============================================================
   Deraah SDA — Section C: Customer Analytics
   ============================================================ */

   
USE Deraah_SDA;
GO


/* C1 ------------------------------------------------------------
-- Cohort retention: customers joining Jan/Feb/Mar 2025.
 % with >=1 Sale in the calendar month M+1, M+3, M+6 after join month*/

WITH cohorts AS (
    SELECT
        customer_id,
        DATEFROMPARTS(YEAR(join_date),MONTH(join_date), 1) AS cohort_month
    FROM marts.dim_customer
    WHERE join_date >= '2025-01-01' AND join_date < '2025-04-01'
),

sales_months AS (
    SELECT DISTINCT
        dc.customer_id,
        DATEFROMPARTS(YEAR(dd.[date]), MONTH(dd.[date]), 1) AS sale_month
    FROM marts.fct_sales_lines f
    JOIN marts.dim_date dd     
    ON f.date_key = dd.date_key
    JOIN marts.dim_customer dc 
    ON f.customer_key = dc.customer_key
    WHERE f.txn_type = 'Sale'
)

SELECT
    c.cohort_month,
    COUNT(DISTINCT c.customer_id) AS cohort_size,
    ROUND(COUNT(DISTINCT sm1.customer_id) * 100.0 / COUNT(DISTINCT c.customer_id), 1) AS m_plus1_pct,
    ROUND(COUNT(DISTINCT sm3.customer_id) * 100.0 / COUNT(DISTINCT c.customer_id), 1) AS m_plus3_pct,
    ROUND(COUNT(DISTINCT sm6.customer_id) * 100.0 / COUNT(DISTINCT c.customer_id), 1) AS m_plus6_pct
FROM cohorts c
LEFT JOIN sales_months sm1 ON sm1.customer_id = c.customer_id AND sm1.sale_month = DATEADD(MONTH, 1, c.cohort_month)
LEFT JOIN sales_months sm3 ON sm3.customer_id = c.customer_id AND sm3.sale_month = DATEADD(MONTH, 3, c.cohort_month)
LEFT JOIN sales_months sm6 ON sm6.customer_id = c.customer_id AND sm6.sale_month = DATEADD(MONTH, 6, c.cohort_month)
GROUP BY c.cohort_month
ORDER BY c.cohort_month;




/*C2 ------------------------------------------------------------
-- RFM segmentation as of 30 Jun 2026, window 1 Jul 2025-30 Jun 2026,
-- identified customers with >=1 Sale in that window*/

WITH cust_rfm_base AS (
    SELECT
        dc.customer_id,
        DATEDIFF(DAY, MAX(CASE WHEN f.txn_type = 'Sale' THEN dd.[date] END), '2026-06-30') AS recency_days,
        COUNT(DISTINCT CASE WHEN f.txn_type = 'Sale' THEN f.txn_id END)AS frequency,
        SUM(f.net_amount)AS monetary
    FROM marts.fct_sales_lines f
    JOIN marts.dim_date dd     
    ON f.date_key = dd.date_key
    JOIN marts.dim_customer dc 
    ON f.customer_key = dc.customer_key
    WHERE dd.[date] BETWEEN '2025-07-01' AND '2026-06-30'
    GROUP BY dc.customer_id
    HAVING COUNT(DISTINCT CASE WHEN f.txn_type = 'Sale' THEN f.txn_id END) >= 1
),

scored AS (
    SELECT
        customer_id, recency_days, frequency, monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC, customer_id ASC) AS R,  -- most recent 
        NTILE(5) OVER (ORDER BY frequency    ASC, customer_id ASC) AS F,  -- highest freq 
        NTILE(5) OVER (ORDER BY monetary     ASC, customer_id ASC) AS M   -- highest value 
    FROM cust_rfm_base
),

segmented AS (
    SELECT *,
        CASE
            WHEN R = 5 AND F >= 4 AND M >= 4 THEN 'Champions'
            WHEN R >= 4 AND F >= 3 THEN 'Loyal'
            WHEN R <= 2 AND F >= 4 THEN 'At Risk'
            WHEN R <= 2 AND F <= 2 THEN 'Hibernating'
            ELSE 'Others'
        END AS segment
    FROM scored
)

/* C3 ------------------------------------------------------------
Churn--> among customers who bought (Sale) in calendar 2025
how many have last Sale > 180 days before 30 Jun 2026? 
Count, churn %, and their share of 2025 Net Sales*/


WITH customers_2025 AS (
    SELECT DISTINCT dc.customer_id
    FROM marts.fct_sales_lines f
    JOIN marts.dim_date dd     
    ON f.date_key = dd.date_key
    JOIN marts.dim_customer dc 
    ON f.customer_key = dc.customer_key
    WHERE f.txn_type = 'Sale' AND dd.[date] BETWEEN '2025-01-01' AND '2025-12-31'
),

last_sale AS (
    SELECT dc.customer_id, 
    MAX(dd.[date]) AS last_sale_date
    FROM marts.fct_sales_lines f
    JOIN marts.dim_date dd     
    ON f.date_key = dd.date_key
    JOIN marts.dim_customer dc 
    ON f.customer_key = dc.customer_key
    WHERE f.txn_type = 'Sale'
    GROUP BY dc.customer_id
),

churn_flag AS (
    SELECT
        c.customer_id,
        CASE WHEN DATEDIFF(DAY, ls.last_sale_date, '2026-06-30') > 180 THEN 1 ELSE 0 END AS is_churned
    FROM customers_2025 c
    JOIN last_sale ls ON c.customer_id = ls.customer_id
),

net_sales_2025 AS (
    SELECT dc.customer_id,
    SUM(f.net_amount) AS net_sales_2025
    FROM marts.fct_sales_lines f
    JOIN marts.dim_date dd     
    ON f.date_key = dd.date_key
    JOIN marts.dim_customer dc
    ON f.customer_key = dc.customer_key
    WHERE dd.[date] BETWEEN '2025-01-01' AND '2025-12-31'
    GROUP BY dc.customer_id
)

SELECT
    COUNT(*)  AS customers_bought_2025,
    SUM(cf.is_churned)AS churned_customers,
    ROUND(SUM(cf.is_churned) * 100.0 / COUNT(*), 1)  AS churn_pct,
    ROUND(SUM(CASE WHEN cf.is_churned = 1 THEN ns.net_sales_2025 ELSE 0 END) * 100.0/ SUM(ns.net_sales_2025), 1) AS pct_of_2025_net_sales_from_churned
FROM churn_flag cf
JOIN net_sales_2025 ns ON cf.customer_id = ns.customer_id;


/* C4 ------------------------------------------------------------
 Median days between consecutive purchase days per customer, by
 loyalty tier (customers with >= 2 distinct purchase days, whole period)*/

WITH purchase_dates AS (
    SELECT DISTINCT dc.customer_id, dd.[date] AS purchase_date
    FROM marts.fct_sales_lines f
    JOIN marts.dim_date dd     
    ON f.date_key = dd.date_key
    JOIN marts.dim_customer dc 
    ON f.customer_key = dc.customer_key
    WHERE f.txn_type = 'Sale'
),
gaps AS (
    SELECT
        customer_id,
        DATEDIFF(DAY, LAG(purchase_date) OVER (PARTITION BY customer_id ORDER BY purchase_date), purchase_date) AS gap_days
    FROM purchase_dates
),
customer_median_gap AS (
    -- PERCENTILE_CONT in SQL Server always requires an OVER() clause,
    -- even when used as a per-group aggregate - so we partition by
    -- customer_id and DISTINCT down to one row per customer instead
    -- of a plain GROUP BY.
    SELECT DISTINCT
        customer_id,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_days) OVER (PARTITION BY customer_id) AS median_gap_days
    FROM gaps
    WHERE gap_days IS NOT NULL      -- drops customers with only 1 purchase day (no gap to measure)
),
tier_data AS (
    SELECT
        dc.loyalty_tier,
        cmg.customer_id,
        COUNT(*)     OVER (PARTITION BY dc.loyalty_tier) AS customers_with_2plus_purchase_days,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cmg.median_gap_days) OVER (PARTITION BY dc.loyalty_tier) AS tier_median_gap_days
    FROM customer_median_gap cmg
    JOIN marts.dim_customer dc ON cmg.customer_id = dc.customer_id
)
SELECT DISTINCT
    loyalty_tier,
    customers_with_2plus_purchase_days,
    ROUND(tier_median_gap_days, 1) AS tier_median_gap_days
FROM tier_data
ORDER BY tier_median_gap_days;