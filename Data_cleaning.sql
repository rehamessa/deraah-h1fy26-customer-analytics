/* ============================================================
   Deraah SDA — Clean intermediate/Silver layer 
   ============================================================ */

USE Deraah_SDA;
GO

IF SCHEMA_ID('slv') IS NULL
    EXEC('CREATE SCHEMA slv');
GO

/* ------------------------------------------------------------
branches_clean --> drop the QA/test branch (Issue #1)
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
customers_clean --> one row per customer
future join_dates excluded from the clean  (Issue #5 - 4 rows)
 ------------------------------------------------------------*/
CREATE OR ALTER VIEW slv.customers AS
SELECT c.*
FROM stg.customers c
JOIN slv.customer_map m ON c.customer_id = m.customer_id
WHERE c.customer_id = m.canonical_customer_id
  AND c.join_date <= '2026-06-30';
GO



