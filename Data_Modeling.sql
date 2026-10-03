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


/* B2  Top 10 SKUs by Net Sales during Ramadan 2026 (18 Feb-19 Mar 2026 inclusive) with product name, category and units*/

SELECT TOP 10
    p.sku,
    p.product_name,
    p.category,
    SUM(tl.qty)AS units,
    SUM(tl.net_amount)AS net_sales
FROM slv.transaction_lines tl
JOIN slv.transactions t ON tl.txn_id = t.txn_id
JOIN stg.products p           ON tl.sku = p.sku   -- products had no DQ issues
WHERE t.txn_datetime >= '2026-02-18'
  AND t.txn_datetime <  '2026-03-20'              -- 19 Mar inclusive
GROUP BY p.sku, p.product_name, p.category
ORDER BY net_sales DESC;

/* B3 ------------------------------------------------------------
H1 2026, Sale transactions only: number of transactions, average basket value (Net Sales / transactions) and units per transaction(UPT), by channel*/

SELECT
    t.channel,
    COUNT(DISTINCT t.txn_id)AS num_transactions,
    SUM(tl.net_amount) AS net_sales,
    SUM(tl.qty) AS total_units,
    ROUND(SUM(tl.net_amount) / COUNT(DISTINCT t.txn_id), 2) AS avg_basket_value,
    ROUND(SUM(tl.qty) * 1.0 / COUNT(DISTINCT t.txn_id), 2) AS units_per_transaction
FROM slv.transactions t
JOIN slv.transaction_lines tl ON t.txn_id = tl.txn_id
WHERE t.txn_type = 'Sale'
  AND t.txn_datetime >= '2026-01-01' AND t.txn_datetime < '2026-07-01'
GROUP BY t.channel
ORDER BY net_sales DESC;
