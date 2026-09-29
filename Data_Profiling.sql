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
