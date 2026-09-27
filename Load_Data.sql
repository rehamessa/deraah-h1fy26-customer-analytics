/* ============================================================
   Deraah SDA Technical Assessment — Step 1: Load data into SQL Server
   Loads the 6 CSVs into a raw "stg" (staging) schema
   ============================================================ */

/* ------------------------------------------------------------
CREATE DATABASE
------------------------------------------------------------ */

 Database
IF DB_ID('Deraah_SDA') IS NULL
    CREATE DATABASE Deraah_SDA;
GO
USE Deraah_SDA;
GO

/* ------------------------------------------------------------
CREATE  SCHEMA
------------------------------------------------------------ */

IF SCHEMA_ID('stg') IS NULL
    EXEC('CREATE SCHEMA stg');
GO


/* ------------------------------------------------------------
 create tables in Staging Layer
   ------------------------------------------------------------ */

IF OBJECT_ID('stg.branches') IS NOT NULL DROP TABLE stg.branches;
CREATE TABLE stg.branches (
    branch_id     VARCHAR(10),
    branch_name   VARCHAR(100),
    city          VARCHAR(50),
    region        VARCHAR(50),
    store_format  VARCHAR(50),
    area_sqm      INT,
    open_date     DATE,
    close_date    DATE NULL
);

IF OBJECT_ID('stg.products') IS NOT NULL DROP TABLE stg.products;
CREATE TABLE stg.products (
    sku           VARCHAR(20),
    product_name  VARCHAR(150),
    brand         VARCHAR(50),
    category      VARCHAR(50),
    sub_category  VARCHAR(50),
    list_price    DECIMAL(12,2),
    unit_cost     DECIMAL(12,2),
    launch_date   DATE NULL
);

IF OBJECT_ID('stg.customers') IS NOT NULL DROP TABLE stg.customers;
CREATE TABLE stg.customers (
    customer_id        VARCHAR(10),
    full_name          VARCHAR(100),
    phone              VARCHAR(20),
    email              VARCHAR(100),
    city               VARCHAR(50),
    home_branch_id     VARCHAR(10) NULL,
    join_date          DATE,
    loyalty_tier       VARCHAR(20),
    marketing_consent  TINYINT NULL   -- 1/0, may contain NULLs — see F1
);

IF OBJECT_ID('stg.promotions') IS NOT NULL DROP TABLE stg.promotions;
CREATE TABLE stg.promotions (
    promo_id        VARCHAR(10),
    promo_name      VARCHAR(100),
    start_date      DATE,
    end_date        DATE,
    category_scope  VARCHAR(50),   -- a category name, or 'ALL'
    discount_pct    DECIMAL(5,4)
);

IF OBJECT_ID('stg.transactions') IS NOT NULL DROP TABLE stg.transactions;
CREATE TABLE stg.transactions (
    txn_id          VARCHAR(15),
    txn_datetime    DATETIME2(0),
    branch_id       VARCHAR(10),
    customer_id     VARCHAR(10) NULL,   -- blank = walk-in
    channel         VARCHAR(20),
    payment_method  VARCHAR(20),
    txn_type        VARCHAR(10)         -- Sale / Return
);

IF OBJECT_ID('stg.transaction_lines') IS NOT NULL DROP TABLE stg.transaction_lines;
CREATE TABLE stg.transaction_lines (
    line_id          INT,
    txn_id           VARCHAR(15),
    sku              VARCHAR(20),
    qty              INT,
    unit_price       DECIMAL(12,2),
    discount_amount  DECIMAL(12,2),
    net_amount       DECIMAL(12,2),
    promo_id         VARCHAR(10) NULL,
    is_return        TINYINT
);
GO


/* ------------------------------------------------------------
BULK INSERT
   ------------------------------------------------------------ */

DECLARE @path VARCHAR(260) = 'E:\deraah-h1fy26-customer-analytics\data\';

DECLARE @sql NVARCHAR(MAX);

SET @sql = N'BULK INSERT stg.branches FROM ''' + @path + N'branches.csv''
  WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK);';
EXEC (@sql);

SET @sql = N'BULK INSERT stg.products FROM ''' + @path + N'products.csv''
  WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK);';
EXEC (@sql);

SET @sql = N'BULK INSERT stg.customers FROM ''' + @path + N'customers.csv''
  WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK);';
EXEC (@sql);

SET @sql = N'BULK INSERT stg.promotions FROM ''' + @path + N'promotions.csv''
  WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK);';
EXEC (@sql);

SET @sql = N'BULK INSERT stg.transactions FROM ''' + @path + N'transactions.csv''
  WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK);';
EXEC (@sql);

SET @sql = N'BULK INSERT stg.transaction_lines FROM ''' + @path + N'transaction_lines.csv''
  WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK);';
EXEC (@sql);
GO


