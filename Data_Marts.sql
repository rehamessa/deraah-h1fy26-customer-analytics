/* ============================================================
   Deraah SDA --> Star Schema (marts layer)
   ============================================================ */

   USE Deraah_SDA;
GO

IF SCHEMA_ID('marts') IS NULL
    EXEC('CREATE SCHEMA marts');
GO

/* ------------------------------------------------------------
 dim_date 
------------------------------------------------------------*/

CREATE TABLE marts.dim_date (
    date_key      INT          PRIMARY KEY,   -- yyyymmdd surrogate key
    [date]        DATE         NOT NULL,
    day_name      VARCHAR(10),
    month_num     INT,
    month_name    VARCHAR(10),
    quarter       INT,
    [year]        INT,
    is_weekend    BIT
);
