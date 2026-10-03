/* ============================================================
   Deraah SDA --> SQL & Data Modelling
   ============================================================ */

USE Deraah_SDA;
GO

/* B1 ------------------------------------------------------------
 Net Sales by region for H1 2026 vs H1 2025 and YoY growth % Ordered by growth*/

WITH sales AS (
    SELECT
        b.region,
        CASE
            WHEN t.txn_datetime >= '2025-01-01' AND t.txn_datetime < '2025-07-01' THEN 'H1_2025'
            WHEN t.txn_datetime >= '2026-01-01' AND t.txn_datetime < '2026-07-01' THEN 'H1_2026'
        END AS period,
        tl.net_amount
    FROM slv.transaction_lines tl
    JOIN slv.transactions t ON tl.txn_id = t.txn_id
    JOIN slv.branches b     ON t.branch_id = b.branch_id
    WHERE (t.txn_datetime >= '2025-01-01' AND t.txn_datetime < '2025-07-01')
       OR (t.txn_datetime >= '2026-01-01' AND t.txn_datetime < '2026-07-01')
),

agg AS (
    SELECT region, period, SUM(net_amount) AS net_sales
    FROM sales
    GROUP BY region, period
)

--select * from agg

SELECT
    region,
    MAX(CASE WHEN period = 'H1_2025' THEN net_sales END) AS net_sales_h1_2025,
    MAX(CASE WHEN period = 'H1_2026' THEN net_sales END) AS net_sales_h1_2026,
    ROUND(
        (MAX(CASE WHEN period = 'H1_2026' THEN net_sales END)
       - MAX(CASE WHEN period = 'H1_2025' THEN net_sales END))
       / NULLIF(MAX(CASE WHEN period = 'H1_2025' THEN net_sales END), 0) * 100
    , 1) AS yoy_growth_pct
FROM agg
GROUP BY region
ORDER BY yoy_growth_pct DESC;