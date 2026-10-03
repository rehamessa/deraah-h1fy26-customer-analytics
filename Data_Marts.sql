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

/*------------------------------------------------------------
-- dim_branch 
 ------------------------------------------------------------*/
CREATE TABLE marts.dim_branch (
    branch_key    INT IDENTITY PRIMARY KEY,   -- surrogate key
    branch_id     VARCHAR(10) NOT NULL UNIQUE, -- natural key from source
    branch_name   VARCHAR(100),
    city          VARCHAR(50),
    region        VARCHAR(50),
    store_format  VARCHAR(50),
    area_sqm      INT,
    open_date     DATE,
    close_date    DATE NULL
);

/* ------------------------------------------------------------
-- dim_product 
------------------------------------------------------------*/
CREATE TABLE marts.dim_product (
    product_key   INT IDENTITY PRIMARY KEY,
    sku           VARCHAR(50) NOT NULL UNIQUE,
    product_name  VARCHAR(50),
    brand         VARCHAR(50),
    category      VARCHAR(50),
    sub_category  VARCHAR(50),
    list_price    DECIMAL,
    unit_cost     DECIMAL
);

/*------------------------------------------------------------
-- dim_customer —->
------------------------------------------------------------*/

CREATE TABLE marts.dim_customer (
    customer_key       INT IDENTITY PRIMARY KEY,
    customer_id         VARCHAR(50) NOT NULL UNIQUE, 
    full_name            VARCHAR(50),
    city                  VARCHAR(50),
    home_branch_id        VARCHAR(50),
    join_date             DATE,
    loyalty_tier           VARCHAR(50),
    marketing_consent      INT         
);

/* ------------------------------------------------------------
 dim_promotion 
------------------------------------------------------------*/
CREATE TABLE marts.dim_promotion (
    promo_key     INT IDENTITY PRIMARY KEY,
    promo_id      VARCHAR(50) NOT NULL UNIQUE,
    promo_name    VARCHAR(50),
    start_date    DATE,
    end_date      DATE,
    category_scope VARCHAR(50),
    discount_pct  DECIMAL
);

/*------------------------------------------------------------
-- fct_sales_lines — grain --> one row per transaction line
------------------------------------------------------------*/
CREATE TABLE marts.fct_sales_lines (
    line_id          INT PRIMARY KEY,         -- 
    txn_id           VARCHAR(50) NOT NULL,     -- degenerate dimension (transaction header id)
    date_key         INT         NOT NULL REFERENCES marts.dim_date(date_key),
    branch_key       INT         NOT NULL REFERENCES marts.dim_branch(branch_key),
    customer_key     INT         NULL REFERENCES marts.dim_customer(customer_key),
    product_key      INT         NOT NULL REFERENCES marts.dim_product(product_key),
    promo_key        INT         NULL REFERENCES marts.dim_promotion(promo_key),
    channel          VARCHAR(50),              -- degenerate dim: low cardinality, kept on the fact
    payment_method    VARCHAR(50),              -- degenerate dim
    txn_type          VARCHAR(50),              -- degenerate dim: Sale / Return
    qty                INT,
    unit_price          DECIMAL,
    discount_amount      DECIMAL,
    net_amount            DECIMAL,
    is_return              BIT
);


