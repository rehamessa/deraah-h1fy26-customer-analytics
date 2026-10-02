/* ============================================================
   Deraah SDA — Clean intermediate/Silver layer 
   ============================================================ */

USE Deraah_SDA;
GO

IF SCHEMA_ID('slv') IS NULL
    EXEC('CREATE SCHEMA slv');
GO

/* ------------------------------------------------------------
branches clean --> drop the QA/test branch (Issue #1)
 ------------------------------------------------------------*/

CREATE OR ALTER VIEW slv.branches AS
SELECT *
FROM stg.branches
WHERE branch_id <> 'B999';
GO

/* ------------------------------------------------------------
 customer_map -->(Issue #3 - 38 duplicate emails) Keeps the earliest
 join_date as the canonical record ties broken by customer_id.
 ------------------------------------------------------------*/

CREATE OR ALTER VIEW slv.customer_map AS
SELECT
    customer_id,
    FIRST_VALUE(customer_id) OVER (
        PARTITION BY LOWER(email)
        ORDER BY join_date ASC, customer_id ASC
    ) AS canonical_customer_id
FROM stg.customers;
GO

/* ------------------------------------------------------------
customers clean --> one row per customer
future join_dates excluded from the clean  (Issue #5 - 4 rows)
 ------------------------------------------------------------*/
CREATE OR ALTER VIEW slv.customers AS
SELECT c.*
FROM stg.customers c
JOIN slv.customer_map m ON c.customer_id = m.customer_id
WHERE c.customer_id = m.canonical_customer_id
  AND c.join_date <= '2026-06-30';
GO

/* ------------------------------------------------------------
 transactions clean --> dedupe txn_id (Issue #6 - 74 rows)
drop future-dated rows (Issue #7 - 5 rows) remap customer_id to its canonical id
------------------------------------------------------------*/

CREATE OR ALTER VIEW slv.transactions AS
SELECT
    t.txn_id,
    t.txn_datetime,
    t.branch_id,
    COALESCE(m.canonical_customer_id, t.customer_id) AS customer_id,
    t.channel,
    t.payment_method,
    t.txn_type
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY txn_id ORDER BY txn_datetime) AS rn
    FROM stg.transactions
) t
LEFT JOIN slv.customer_map m ON t.customer_id = m.customer_id
WHERE t.rn = 1
  AND t.txn_datetime <= '2026-06-30 23:59:59';
GO

/* transaction_lines clean -->
- drop lines on FK SKUs not in products (Issue #8 - 9 rows)
- drop lines whose header didn't survive dedup/future-date cut
- fix mislabeled is_return flag (Issue #9 - 25 rows)
- fix negative discount_amount (Issue #11 - 142 rows) and recompute net_amount to stay consistent with the fix
------------------------------------------------------------*/
CREATE OR ALTER VIEW slv.transaction_lines AS
SELECT
    tl.line_id,
    tl.txn_id,
    tl.sku,
    tl.qty,
    tl.unit_price,
    ABS(tl.discount_amount) AS discount_amount,
    tl.qty * tl.unit_price - ABS(tl.discount_amount) AS net_amount,
    tl.promo_id,
    CASE WHEN tl.is_return = 0 AND tl.qty < 0 THEN 1 ELSE tl.is_return END AS is_return
FROM stg.transaction_lines tl
WHERE EXISTS (SELECT 1 FROM stg.products p WHERE p.sku = tl.sku)
  AND EXISTS (SELECT 1 FROM slv.transactions t WHERE t.txn_id = tl.txn_id);
GO

/* ------------------------------------------------------------
   Quick check --> row counts before/after cleaning
   ------------------------------------------------------------ */
SELECT 'branches'          AS tbl,
(SELECT COUNT(*) FROM stg.branches)          AS raw_rows,
(SELECT COUNT(*) FROM slv.branches)          AS clean_rows

UNION ALL

SELECT 'customers',
(SELECT COUNT(*) FROM stg.customers),                
(SELECT COUNT(*) FROM slv.customers)

UNION ALL

SELECT 'transactions',            
(SELECT COUNT(*) FROM stg.transactions),             
(SELECT COUNT(*) FROM slv.transactions)

UNION ALL

SELECT 'transaction_lines',       
(SELECT COUNT(*) FROM stg.transaction_lines),        
(SELECT COUNT(*) FROM slv.transaction_lines);
