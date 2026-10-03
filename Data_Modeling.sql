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

/* B4 ------------------------------------------------------------
-- Like-for-like (LFL) growth, H1 2026 vs H1 2025. A branch is LFL
-- only if it traded for the whole of both periods (open on or
-- before 1 Jan 2025 and not closed before 30 Jun 2026)*/

-- Step 1: how many branches qualify as LFL

SELECT COUNT(*) AS lfl_branch_count
FROM slv.branches
WHERE open_date <= '2025-01-01'
  AND (close_date IS NULL OR close_date >= '2026-06-30');

-- Step 2: LFL growth % - same branches only, both periods
SELECT
    net_sales_h1_2025,
    net_sales_h1_2026,
    ROUND((net_sales_h1_2026 - net_sales_h1_2025) * 100.0
          / NULLIF(net_sales_h1_2025, 0), 1) AS lfl_growth_pct
FROM (
    SELECT
        SUM(CASE WHEN t.txn_datetime < '2025-07-01' THEN tl.net_amount ELSE 0 END) AS net_sales_h1_2025,
        SUM(CASE WHEN t.txn_datetime >= '2026-01-01' THEN tl.net_amount ELSE 0 END) AS net_sales_h1_2026
    FROM slv.transaction_lines tl
    JOIN slv.transactions t ON tl.txn_id = t.txn_id
    JOIN slv.branches b     ON t.branch_id = b.branch_id
    WHERE b.open_date <= '2025-01-01'
      AND (b.close_date IS NULL OR b.close_date >= '2026-06-30')
      AND ((t.txn_datetime >= '2025-01-01' AND t.txn_datetime < '2025-07-01')
        OR (t.txn_datetime >= '2026-01-01' AND t.txn_datetime < '2026-07-01'))
) lfl;

-- Step 3: TOTAL growth %  all branches, for comparison
SELECT
    net_sales_h1_2025,
    net_sales_h1_2026,
    ROUND((net_sales_h1_2026 - net_sales_h1_2025) * 100.0
          / NULLIF(net_sales_h1_2025, 0), 1) AS total_growth_pct
FROM (
    SELECT
        SUM(CASE WHEN t.txn_datetime < '2025-07-01' THEN tl.net_amount ELSE 0 END) AS net_sales_h1_2025,
        SUM(CASE WHEN t.txn_datetime >= '2026-01-01' THEN tl.net_amount ELSE 0 END) AS net_sales_h1_2026
    FROM slv.transaction_lines tl
    JOIN slv.transactions t ON tl.txn_id = t.txn_id
    WHERE (t.txn_datetime >= '2025-01-01' AND t.txn_datetime < '2025-07-01')
       OR (t.txn_datetime >= '2026-01-01' AND t.txn_datetime < '2026-07-01')
) total;

