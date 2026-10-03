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

