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

