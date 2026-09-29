/* ============================================================
   Deraah SDA — Load Staging Layer (stg) 
   ============================================================ */

USE Deraah_SDA;
GO

CREATE OR ALTER PROCEDURE stg.load_staging AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @START_BATCH DATETIME, @END_BATCH DATETIME;
	BEGIN TRY
	SET @START_BATCH = GETDATE();
		PRINT '------------------------------------------------';
		PRINT 'Loading Staging Layer (stg)';
		PRINT '=================================================================';

		--------------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>> Truncate Table: stg.branches';
		TRUNCATE TABLE stg.branches;
		PRINT '>> Insert data into Table: stg.branches';
		BULK INSERT stg.branches
		FROM 'E:\deraah-h1fy26-customer-analytics\data\branches.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			Tablock
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' SEC';
		PRINT '*********************************************************************';

		--------------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>> Truncate Table: stg.products';
		TRUNCATE TABLE stg.products;
		PRINT '>> Insert data into Table: stg.products';
		BULK INSERT stg.products
		FROM 'E:\deraah-h1fy26-customer-analytics\data\products.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			Tablock
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' SEC';
		PRINT '*********************************************************************';

		--------------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>> Truncate Table: stg.customers';
		TRUNCATE TABLE stg.customers;
		PRINT '>> Insert data into Table: stg.customers';
		BULK INSERT stg.customers
		FROM 'E:\deraah-h1fy26-customer-analytics\data\customers.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			Tablock
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' SEC';
		PRINT '*********************************************************************';

		--------------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>> Truncate Table: stg.promotions';
		TRUNCATE TABLE stg.promotions;
		PRINT '>> Insert data into Table: stg.promotions';
		BULK INSERT stg.promotions
		FROM 'E:\deraah-h1fy26-customer-analytics\data\promotions.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			Tablock
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' SEC';
		PRINT '*********************************************************************';

		--------------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>> Truncate Table: stg.transactions';
		TRUNCATE TABLE stg.transactions;
		PRINT '>> Insert data into Table: stg.transactions';
		BULK INSERT stg.transactions
		FROM 'E:\deraah-h1fy26-customer-analytics\data\transactions.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			Tablock
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' SEC';
		PRINT '*********************************************************************';

		--------------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>> Truncate Table: stg.transaction_lines';
		TRUNCATE TABLE stg.transaction_lines;
		PRINT '>> Insert data into Table: stg.transaction_lines';
		BULK INSERT stg.transaction_lines
		FROM 'E:\deraah-h1fy26-customer-analytics\data\transaction_lines.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			Tablock
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' SEC';
		PRINT '*********************************************************************';

		PRINT '=================================';
		SET @END_BATCH = GETDATE();
		PRINT '>> Load batch Duration: ' + CAST(DATEDIFF(SECOND, @START_BATCH, @END_BATCH) AS VARCHAR) + ' SEC';
		PRINT '*********************************************************************';

	END TRY
	BEGIN CATCH
		PRINT '=================================';
		PRINT 'Error occurred during loading Staging layer';
		PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
		PRINT 'ERROR NUMBER: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR STATE: ' + CAST(ERROR_STATE() AS NVARCHAR);
	END CATCH;
END;
GO

EXEC stg.load_staging;

/* ------------------------------------------------------------
   Sanity check
   ------------------------------------------------------------ */
SELECT 'branches' AS tbl, COUNT(*) AS rows_loaded FROM stg.branches
UNION ALL SELECT 'products', COUNT(*) FROM stg.products
UNION ALL SELECT 'customers', COUNT(*) FROM stg.customers
UNION ALL SELECT 'promotions', COUNT(*) FROM stg.promotions
UNION ALL SELECT 'transactions', COUNT(*) FROM stg.transactions
UNION ALL SELECT 'transaction_lines', COUNT(*) FROM stg.transaction_lines;