/* ============================================================
   Deraah SDA —->Retail & Promotion Analysis
   ============================================================ */

USE Deraah_SDA;
GO


/* D1 ------------------------------------------------------------
-- Promotion P07 (Ramadan Oud Offer 2026, 20% off Oud, 18 Feb-19 Mar
-- 2026). Average daily Net Sales for Oud vs all other categories, in
-- the promo window vs the 28 days immediately before it. Plus total
-- discount cost of the promotion*/

WITH promo_window AS (
    SELECT
        CASE WHEN p.category = 'Oud' THEN 'Oud' ELSE 'Other' END AS category_group,
        dd.[date],
        f.net_amount
    FROM marts.fct_sales_lines f
    JOIN marts.dim_date dd    
    ON f.date_key = dd.date_key
    JOIN marts.dim_product p  
    ON f.product_key = p.product_key
    WHERE dd.[date] BETWEEN '2026-02-18' AND '2026-03-19'
),

pre_window AS (
    SELECT
        CASE WHEN p.category = 'Oud' THEN 'Oud' ELSE 'Other' END AS category_group,
        dd.[date],
        f.net_amount
    FROM marts.fct_sales_lines f
    JOIN marts.dim_date dd    ON f.date_key = dd.date_key
    JOIN marts.dim_product p  ON f.product_key = p.product_key
    WHERE dd.[date] BETWEEN '2026-01-21' AND '2026-02-17'   -- 28 days 
)

SELECT 'Promo window (18 Feb-19 Mar)' AS period, 
       category_group,
       COUNT(DISTINCT [date])AS days,
       SUM(net_amount)AS total_net_sales,
       ROUND(SUM(net_amount) / COUNT(DISTINCT [date]), 2) AS avg_daily_net_sales
FROM promo_window
GROUP BY category_group
UNION ALL
SELECT 'Pre-period (28 days before)' AS period, category_group,
       COUNT(DISTINCT [date])AS days,
       SUM(net_amount)AS total_net_sales,
       ROUND(SUM(net_amount) / COUNT(DISTINCT [date]), 2) AS avg_daily_net_sales
FROM pre_window
GROUP BY category_group
ORDER BY category_group, period;