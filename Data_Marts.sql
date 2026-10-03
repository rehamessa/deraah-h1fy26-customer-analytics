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


