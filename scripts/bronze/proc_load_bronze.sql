/*
===============================================================================
Stored Procedure: Load Bronze Layer
===============================================================================
Script Purpose:
    This stored procedure loads raw data from CRM and ERP CSV source files
    into the corresponding tables in the 'bronze' schema.

    For each table, the procedure:
        1. Truncates the existing data.
        2. Loads fresh data from the source CSV file using BULK INSERT.
        3. Records and prints the individual table load duration.

    The procedure also tracks the total batch duration and handles errors
    using TRY...CATCH.

WARNING:
    TRUNCATE TABLE removes all existing data from the target table before
    loading. If a load fails, the table may remain empty or partially loaded.
    Ensure the source files exist at the specified paths before execution.

Prerequisites:
    - Bronze tables must already exist.
    - SQL Server must be able to access the source CSV files.
===============================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME,
            @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        PRINT '=================================================';
        PRINT 'Loading Bronze Layer';
        PRINT '=================================================';

        PRINT '-------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '-------------------------------------------------';

        -- Record the start time of the entire batch.
        SET @batch_start_time = GETDATE();

        -- Load CRM customer information.
        SET @start_time = GETDATE();

        PRINT '>> Truncating bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;

        PRINT '>> Inserting data into bronze.crm_cust_info';
        BULK INSERT bronze.crm_cust_info
        FROM 'D:\9-Data with Baraa\sql-data-warehouse-project-main\01_datasets\source_crm\cust_info.csv'
        WITH(
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -------------------------------------

        -- Load CRM product information.
        SET @start_time = GETDATE();

        PRINT '>> Truncating bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info

        PRINT '>> Inserting data into bronze.crm_prd_info';
        BULK INSERT bronze.crm_prd_info
        FROM 'D:\9-Data with Baraa\sql-data-warehouse-project-main\01_datasets\source_crm\prd_info.csv'
        WITH(
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -------------------------------------

        -- Load CRM sales transaction details.
        SET @start_time = GETDATE();

        PRINT '>> Truncating bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details

        PRINT '>> Inserting data into bronze.crm_sales_details';
        BULK INSERT bronze.crm_sales_details
        FROM 'D:\9-Data with Baraa\sql-data-warehouse-project-main\01_datasets\source_crm\sales_details.csv'
        WITH(
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        ---------------------------------------------------------------------

        PRINT '-------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '-------------------------------------------------';

        -- Load ERP customer location and country information.
        SET @start_time = GETDATE();

        PRINT '>> Truncating bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101

        PRINT '>> Inserting data into bronze.erp_loc_a101';
        BULK INSERT bronze.erp_loc_a101
        FROM 'D:\9-Data with Baraa\sql-data-warehouse-project-main\01_datasets\source_erp\LOC_A101.csv'
        WITH(
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -------------------------------------

        -- Load ERP customer birth dates and gender.
        SET @start_time = GETDATE();

        PRINT '>> Truncating bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12

        PRINT '>> Inserting data into bronze.erp_cust_az12';
        BULK INSERT bronze.erp_cust_az12
        FROM 'D:\9-Data with Baraa\sql-data-warehouse-project-main\01_datasets\source_erp\CUST_AZ12.csv'
        WITH(
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -------------------------------------

        -- Load ERP product category and maintenance information.
        SET @start_time = GETDATE();

        PRINT '>> Truncating bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2

        PRINT '>> Inserting data into bronze.erp_px_cat_g1v2';
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'D:\9-Data with Baraa\sql-data-warehouse-project-main\01_datasets\source_erp\PX_CAT_G1V2.csv'
        WITH(
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- Calculate the total duration of the Bronze loading process.
        SET @batch_end_time = GETDATE();
        PRINT '>> Batch Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';

    END TRY
    BEGIN CATCH
        -- Display error details if any table fails to load.
        PRINT '===================================='
        PRINT 'ERROR OCCURED DURING LOADING BRONZE'
        PRINT 'Error Message' + ERROR_MESSAGE();
        PRINT 'Error Number' + CAST (ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '===================================='
    END CATCH
END

