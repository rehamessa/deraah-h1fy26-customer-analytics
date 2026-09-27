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

