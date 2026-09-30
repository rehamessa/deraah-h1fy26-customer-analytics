/* ============================================================
Data Profiling
   ============================================================ */

   
USE Deraah_SDA;
GO

/* ============================================================
	branches
============================================================ */

-- Row count + duplicate branch_id check

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT branch_id) AS distinct_branch_id
FROM stg.branches;

-- Nulls in key columns

SELECT
    SUM(CASE WHEN branch_id     IS NULL THEN 1 ELSE 0 END) AS null_branch_id,
    SUM(CASE WHEN branch_name   IS NULL THEN 1 ELSE 0 END) AS null_branch_name,
    SUM(CASE WHEN city          IS NULL THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN region        IS NULL THEN 1 ELSE 0 END) AS null_region,
    SUM(CASE WHEN store_format  IS NULL THEN 1 ELSE 0 END) AS null_store_format,
    SUM(CASE WHEN area_sqm      IS NULL THEN 1 ELSE 0 END) AS null_area_sqm,
    SUM(CASE WHEN open_date     IS NULL THEN 1 ELSE 0 END) AS null_open_date
FROM stg.branches;

-- Distinct values in categorical columns (look for unexpected values)

SELECT region,
       COUNT(*) AS n 
FROM stg.branches 
GROUP BY region 
ORDER BY region;

SELECT store_format,
       COUNT(*) AS n
FROM stg.branches 
GROUP BY store_format 
ORDER BY store_format;

-- Ranges / sanity on dates and area

SELECT MIN(open_date) AS min_open,
       MAX(open_date) AS max_open,
       MIN(close_date) AS min_close,
       MAX(close_date) AS max_close,
       MIN(area_sqm) AS min_area,
       MAX(area_sqm) AS max_area
FROM stg.branches;


-- Branches that close before they open, or open in the future

SELECT * 
FROM stg.branches 
WHERE close_date IS NOT NULL 
      AND close_date < open_date;

SELECT * 
FROM stg.branches 
WHERE open_date > '2026-06-30';

/* ============================================================
products
   ============================================================ */

-- Row count + duplicate sku

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT sku) AS distinct_sku
FROM stg.products;

-- Nulls in key columns

SELECT
    SUM(CASE WHEN sku          IS NULL THEN 1 ELSE 0 END) AS null_sku,
    SUM(CASE WHEN product_name IS NULL THEN 1 ELSE 0 END) AS null_name,
    SUM(CASE WHEN brand        IS NULL THEN 1 ELSE 0 END) AS null_brand,
    SUM(CASE WHEN category     IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN sub_category IS NULL THEN 1 ELSE 0 END) AS null_sub_category,
    SUM(CASE WHEN list_price   IS NULL THEN 1 ELSE 0 END) AS null_list_price,
    SUM(CASE WHEN unit_cost    IS NULL THEN 1 ELSE 0 END) AS null_unit_cost
FROM stg.products;

-- Distinct values in categorical columns (look for unexpected values)

SELECT category,
       COUNT(*) AS n 
FROM stg.products 
GROUP BY category 
ORDER BY category;

-- Price sanity: negative, zero, or cost higher than price

SELECT MIN(list_price) AS min_price,
       MAX(list_price) AS max_price,
       MIN(unit_cost) AS min_cost,
       MAX(unit_cost) AS max_cost
FROM stg.products;

SELECT * 
FROM stg.products
WHERE list_price <= 0 OR unit_cost <= 0;

SELECT * 
FROM stg.products 
WHERE unit_cost > list_price;

/* ============================================================
   customers
   ============================================================ */

-- Row count + duplicate customer_id

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT customer_id) AS distinct_customer_id
FROM stg.customers;

-- Nulls in key columns

SELECT
    SUM(CASE WHEN customer_id       IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN full_name         IS NULL THEN 1 ELSE 0 END) AS null_full_name,
    SUM(CASE WHEN phone             IS NULL THEN 1 ELSE 0 END) AS null_phone,
    SUM(CASE WHEN email             IS NULL THEN 1 ELSE 0 END) AS null_email,
    SUM(CASE WHEN city              IS NULL THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN home_branch_id    IS NULL THEN 1 ELSE 0 END) AS null_home_branch,
    SUM(CASE WHEN join_date         IS NULL THEN 1 ELSE 0 END) AS null_join_date,
    SUM(CASE WHEN loyalty_tier      IS NULL THEN 1 ELSE 0 END) AS null_loyalty_tier,
    SUM(CASE WHEN marketing_consent IS NULL THEN 1 ELSE 0 END) AS null_marketing_consent
FROM stg.customers;

-- Distinct values in categorical columns (look for unexpected values)

SELECT loyalty_tier,
       COUNT(*) AS n 
FROM stg.customers 
GROUP BY loyalty_tier 
ORDER BY loyalty_tier;

SELECT marketing_consent, 
       COUNT(*) AS n
FROM stg.customers 
GROUP BY marketing_consent;

-- Duplicate email / phone 

SELECT email, 
COUNT(*) AS n 
FROM stg.customers 
WHERE email IS NOT NULL 
GROUP BY email 
HAVING COUNT(*) > 1;

SELECT phone, 
       COUNT(*) AS n 
FROM stg.customers 
WHERE phone IS NOT NULL 
GROUP BY phone 
HAVING COUNT(*) > 1;


-- home_branch_id (FK) values that don't exist in stg.branches
SELECT c.home_branch_id,
       COUNT(*) AS n
FROM stg.customers c
LEFT JOIN stg.branches b 
ON c.home_branch_id = b.branch_id
WHERE c.home_branch_id IS NOT NULL AND b.branch_id IS NULL
GROUP BY c.home_branch_id;

-- join_date in the future or before the business existed
SELECT MIN(join_date) AS min_join,
       MAX(join_date) AS max_join 
FROM stg.customers;

SELECT * 
FROM stg.customers 
WHERE join_date > '2026-06-30';

--total_affected rows by duplicated customer

SELECT SUM(n) AS total_affected_rows
FROM (
    SELECT email, COUNT(*) AS n
    FROM stg.customers
    WHERE email IS NOT NULL
    GROUP BY email
    HAVING COUNT(*) > 1
) x;

-- total rows has issue phone
SELECT COUNT(*) AS n
FROM stg.customers
WHERE phone IN ('N/A','966','0000000000','123456','0512345','5512345678','05123456789','05X1234567');

-- total customer in the future date

SELECT COUNT(*) AS n
FROM stg.customers
WHERE join_date > '2026-06-30';

/* ============================================================
   promotions
   ============================================================ */

-- Row count + duplicate promo_id

SELECT COUNT(*) AS total_rows, 
       COUNT(DISTINCT promo_id) AS distinct_promo_id
FROM stg.promotions;

SELECT * FROM stg.promotions ORDER BY start_date;

-- Sanity: end before start, discount out of [0,1] range

SELECT *
FROM stg.promotions 
WHERE end_date < start_date;

SELECT * 
FROM stg.promotions 
WHERE discount_pct < 0 OR discount_pct > 1;

SELECT category_scope, 
       COUNT(*) AS n 
FROM stg.promotions 
GROUP BY category_scope;

/* ============================================================
  transactions
   ============================================================ */

   -- Row count + duplicate  txn_id

SELECT COUNT(*) AS total_rows, 
       COUNT(DISTINCT txn_id) AS distinct_txn_id
FROM stg.transactions;


-- Nulls in key columns

SELECT
    SUM(CASE WHEN txn_id         IS NULL THEN 1 ELSE 0 END) AS null_txn_id,
    SUM(CASE WHEN txn_datetime   IS NULL THEN 1 ELSE 0 END) AS null_txn_datetime,
    SUM(CASE WHEN branch_id      IS NULL THEN 1 ELSE 0 END) AS null_branch_id,
    SUM(CASE WHEN customer_id    IS NULL THEN 1 ELSE 0 END) AS null_customer_id, 
    SUM(CASE WHEN channel        IS NULL THEN 1 ELSE 0 END) AS null_channel,
    SUM(CASE WHEN payment_method IS NULL THEN 1 ELSE 0 END) AS null_payment_method,
    SUM(CASE WHEN txn_type       IS NULL THEN 1 ELSE 0 END) AS null_txn_type
FROM stg.transactions;


-- Duplicate txn_id 
SELECT txn_id, 
       COUNT(*) AS n 
FROM stg.transactions 
GROUP BY txn_id 
HAVING COUNT(*) > 1;

-- Distinct values in categorical columns (look for unexpected values)

SELECT channel, 
       COUNT(*) AS n 
FROM stg.transactions 
GROUP BY channel 
ORDER BY channel;

SELECT payment_method, 
       COUNT(*) AS n 
FROM stg.transactions 
GROUP BY payment_method 
ORDER BY payment_method;

SELECT txn_type, 
       COUNT(*) AS n 
FROM stg.transactions 
GROUP BY txn_type 
ORDER BY txn_type;


-- Date range

SELECT MIN(txn_datetime) AS min_dt, 
       MAX(txn_datetime) AS max_dt 
FROM stg.transactions;

SELECT * 
FROM stg.transactions 
WHERE txn_datetime < '2025-01-01' OR txn_datetime > '2026-06-30 23:59:59';

-- transactions whose branch_id / customer_id (FK) don't exist in dimension tables

SELECT t.branch_id, 
       COUNT(*) AS n
FROM stg.transactions t
LEFT JOIN stg.branches b 
ON t.branch_id = b.branch_id
WHERE b.branch_id IS NULL
GROUP BY t.branch_id;

SELECT t.customer_id, 
       COUNT(*) AS n
FROM stg.transactions t
LEFT JOIN stg.customers c 
ON t.customer_id = c.customer_id
WHERE t.customer_id IS NOT NULL AND c.customer_id IS NULL
GROUP BY t.customer_id;

-- Share of walk-ins

SELECT
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS walkin_share
FROM stg.transactions;

-- total dupliactes raws

SELECT SUM(n) AS total_affected_rows
FROM (
    SELECT txn_id, COUNT(*) AS n
    FROM stg.transactions
    GROUP BY txn_id
    HAVING COUNT(*) > 1
) x;

-- total transaction >June-2026

SELECT COUNT(*) AS n
FROM stg.transactions
WHERE txn_datetime > '2026-06-30 23:59:59';


/* ============================================================
    transaction_lines
   ============================================================ */

   -- Row count + duplicate promo_id

SELECT COUNT(*) AS total_rows, 
       COUNT(DISTINCT line_id) AS distinct_line_id
FROM stg.transaction_lines;

-- Nulls in key columns

SELECT
    SUM(CASE WHEN line_id          IS NULL THEN 1 ELSE 0 END) AS null_line_id,
    SUM(CASE WHEN txn_id           IS NULL THEN 1 ELSE 0 END) AS null_txn_id,
    SUM(CASE WHEN sku              IS NULL THEN 1 ELSE 0 END) AS null_sku,
    SUM(CASE WHEN qty              IS NULL THEN 1 ELSE 0 END) AS null_qty,
    SUM(CASE WHEN unit_price       IS NULL THEN 1 ELSE 0 END) AS null_unit_price,
    SUM(CASE WHEN discount_amount  IS NULL THEN 1 ELSE 0 END) AS null_discount_amount,
    SUM(CASE WHEN net_amount       IS NULL THEN 1 ELSE 0 END) AS null_net_amount,
    SUM(CASE WHEN promo_id         IS NULL THEN 1 ELSE 0 END) AS null_promo_id,     -- expected
    SUM(CASE WHEN is_return        IS NULL THEN 1 ELSE 0 END) AS null_is_return
FROM stg.transaction_lines;

-- txn_id / sku / promo_id (FK)

SELECT tl.txn_id, 
       COUNT(*) AS n
FROM stg.transaction_lines tl
LEFT JOIN stg.transactions t 
ON tl.txn_id = t.txn_id
WHERE t.txn_id IS NULL
GROUP BY tl.txn_id;

SELECT tl.sku, 
       COUNT(*) AS n
FROM stg.transaction_lines tl
LEFT JOIN stg.products p 
ON tl.sku = p.sku
WHERE p.sku IS NULL
GROUP BY tl.sku;

SELECT tl.promo_id, 
       COUNT(*) AS n
FROM stg.transaction_lines tl
LEFT JOIN stg.promotions pr 
ON tl.promo_id = pr.promo_id
WHERE tl.promo_id IS NOT NULL AND pr.promo_id IS NULL
GROUP BY tl.promo_id;

-- check consistency

SELECT is_return,
       SUM(CASE WHEN qty > 0 THEN 1 ELSE 0 END)        AS positive_qty,
       SUM(CASE WHEN qty < 0 THEN 1 ELSE 0 END)        AS negative_qty,
       SUM(CASE WHEN net_amount > 0 THEN 1 ELSE 0 END) AS positive_net,
       SUM(CASE WHEN net_amount < 0 THEN 1 ELSE 0 END) AS negative_net
FROM stg.transaction_lines
GROUP BY is_return;

-- net_amount formula check

SELECT COUNT(*) AS mismatched_rows
FROM stg.transaction_lines
WHERE ABS(net_amount - (qty * unit_price - discount_amount)) > 0.01;

-- Ranges: look for absurd qty or negative prices

SELECT MIN(qty) AS min_qty, 
       MAX(qty) AS max_qty,
       MIN(unit_price) AS min_price, 
       MAX(unit_price) AS max_price,
       MIN(discount_amount) AS min_discount, 
       MAX(discount_amount) AS max_discount,
       MIN(net_amount) AS min_net, 
       MAX(net_amount) AS max_net
FROM stg.transaction_lines;

-- discount_amount bigger than gross

SELECT COUNT(*) AS n
FROM stg.transaction_lines
WHERE discount_amount > (qty * unit_price) AND is_return = 0;

-- raws have negative amount or price
SELECT line_id, 
       txn_id, sku, qty, unit_price, discount_amount, net_amount, is_return
FROM stg.transaction_lines
WHERE is_return = 0 AND (qty < 0 OR net_amount < 0);

-- total raws unit_price equal 0

SELECT COUNT(*) AS n 
FROM stg.transaction_lines 
WHERE unit_price = 0;

-- total raws discount_amount < 0

SELECT COUNT(*) AS n 
FROM stg.transaction_lines 
WHERE discount_amount < 0;