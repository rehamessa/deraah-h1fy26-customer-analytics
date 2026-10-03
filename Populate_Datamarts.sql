/* ============================================================
   Deraah SDA 
   ============================================================ */

USE Deraah_SDA;
GO

/* ------------------------------------------------------------
--dim_date full data period (1 Jan 2025 - 30 Jun 2026)
------------------------------------------------------------*/

WITH DateSeries AS (
    SELECT CAST('2025-01-01' AS DATE) AS d
    UNION ALL
    SELECT DATEADD(DAY, 1, d) FROM DateSeries WHERE d < '2026-06-30'
)
INSERT INTO marts.dim_date (date_key, [date], day_name, month_num, month_name, quarter, [year], is_weekend)
SELECT
    CONVERT(INT, FORMAT(d, 'yyyyMMdd')),
    d,
    DATENAME(WEEKDAY, d),
    MONTH(d),
    DATENAME(MONTH, d),
    DATEPART(QUARTER, d),
    YEAR(d),
    CASE WHEN DATENAME(WEEKDAY, d) IN ('Friday', 'Saturday') THEN 1 ELSE 0 END  -- KSA weekend
FROM DateSeries
OPTION (MAXRECURSION 600);
GO

/*------------------------------------------------------------
 dim_branch
------------------------------------------------------------*/

INSERT INTO marts.dim_branch (branch_id, branch_name, city, region, store_format, area_sqm, open_date, close_date)
SELECT branch_id, branch_name, city, region, store_format, area_sqm, open_date, close_date
FROM slv.branches;
GO

/*------------------------------------------------------------
dim_product
------------------------------------------------------------*/

INSERT INTO marts.dim_product (sku, product_name, brand, category, sub_category, list_price, unit_cost)
SELECT sku, product_name, brand, category, sub_category, list_price, unit_cost
FROM stg.products;
GO


/*------------------------------------------------------------
 dim_customer
-- ------------------------------------------------------------*/
INSERT INTO marts.dim_customer (customer_id, full_name, city, home_branch_id, join_date, loyalty_tier, marketing_consent)
SELECT customer_id, full_name, city, home_branch_id, join_date, loyalty_tier, ISNULL(marketing_consent, 0)
FROM slv.customers;
GO

/*------------------------------------------------------------
dim_promotion
------------------------------------------------------------*/
INSERT INTO marts.dim_promotion (promo_id, promo_name, start_date, end_date, category_scope, discount_pct)
SELECT promo_id, promo_name, start_date, end_date, category_scope, discount_pct
FROM stg.promotions;
GO

/*------------------------------------------------------------
 fct_sales_lines 
------------------------------------------------------------*/
INSERT INTO marts.fct_sales_lines
    (line_id, txn_id, date_key, branch_key, customer_key, product_key, promo_key,
     channel, payment_method, txn_type, qty, unit_price, discount_amount, net_amount, is_return)
SELECT
    tl.line_id,
    tl.txn_id,
    CONVERT(INT, FORMAT(t.txn_datetime, 'yyyyMMdd'))  AS date_key,
    db.branch_key,
    dc.customer_key,     
    dp.product_key,
    dpr.promo_key,       
    t.channel,
    t.payment_method,
    t.txn_type,
    tl.qty,
    tl.unit_price,
    tl.discount_amount,
    tl.net_amount,
    tl.is_return
FROM slv.transaction_lines tl
JOIN slv.transactions t      
ON tl.txn_id = t.txn_id
JOIN marts.dim_branch db           
ON t.branch_id = db.branch_id
JOIN marts.dim_product dp          
ON tl.sku = dp.sku
LEFT JOIN marts.dim_customer dc    
ON t.customer_id = dc.customer_id
LEFT JOIN marts.dim_promotion dpr  
ON tl.promo_id = dpr.promo_id;
GO