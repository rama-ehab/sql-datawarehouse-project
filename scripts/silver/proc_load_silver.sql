/*
===============================================================================
Stored Procedure: Load Silver Layer
===============================================================================
Script Purpose:
    This stored procedure transforms and loads data from the Bronze layer
    into the Silver layer of the Data Warehouse.

    It cleans, standardizes, and validates CRM and ERP data before loading
    it into the corresponding Silver tables.

Main Operations:
    - Truncates existing Silver tables before reloading.
    - Removes duplicate customer records and excludes NULL customer IDs.
    - Standardizes names, gender, marital status, and product categories.
    - Handles missing values and invalid dates.
    - Corrects sales amounts and prices where necessary.
    - Standardizes customer IDs and country names.
    - Logs individual table load durations and total batch duration.
    - Uses TRY/CATCH to report errors during execution.

WARNING:
    This procedure truncates existing Silver tables before loading new data.
    If an error occurs, the tables may be left empty or partially loaded.
    The procedure reports errors but does not rethrow them.
===============================================================================
*/

-- Execute the procedure to load the Silver layer.
-- EXEC silver.load_silver

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    BEGIN TRY
        -- Variables for tracking individual table and total batch durations.
        DECLARE @start_time DATETIME, @end_time DATETIME,
                @batch_start_time DATETIME, @batch_end_time DATETIME;

        SET @batch_start_time = GETDATE();

        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

        PRINT '------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '------------------------------------------------';

        -----------------------------------------------------------------------
        -- 1. Load CRM Customer Information
        -----------------------------------------------------------------------
        -- Keep the latest record for each customer ID.
        -- Exclude records with NULL customer IDs and standardize text values.

        SET @start_time = GETDATE();

        PRINT '>> Truncating silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;

        PRINT 'Inserting data into silver.crm_cust_info';

        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,
            -- Convert marital status codes into descriptive values.
            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'N/A'
            END cst_marital_status,
            -- Standardize gender codes and handle unknown values.
            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'N/A'
            END cst_gndr,
            cst_create_date
        FROM (
            SELECT
                *,
                -- Rank records by creation date, newest first, per customer.
                ROW_NUMBER() OVER (
                    PARTITION BY cst_id
                    ORDER BY cst_create_date DESC
                ) flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t
        WHERE flag_last = 1;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -----------------------------------------------------------------------
        -- 2. Load CRM Product Information
        -----------------------------------------------------------------------
        -- Derive category and product keys, standardize product lines,
        -- replace missing costs, and calculate product validity end dates.

        SET @start_time = GETDATE();

        PRINT '>> Truncating silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;

        PRINT 'Inserting data into silver.crm_prd_info';

        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,
            -- Extract the category identifier and standardize its separator.
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') cat_id,
            -- Extract the product key, excluding its category prefix.
            SUBSTRING(prd_key, 7, LEN(prd_key)) prd_key,
            prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,
            -- Convert product line codes into descriptive labels.
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'N/A'
            END prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            -- Set each product version's end date to one day before
            -- the next version starts, within the same product key.
            CAST(
                LEAD(prd_start_dt) OVER (
                    PARTITION BY prd_key
                    ORDER BY prd_start_dt
                ) - 1 AS DATE
            ) AS prd_end_dt
        FROM bronze.crm_prd_info;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -----------------------------------------------------------------------
        -- 3. Load CRM Sales Details
        -----------------------------------------------------------------------
        -- Validate date formats and correct sales or price values where needed.

        SET @start_time = GETDATE();

        PRINT '>> Truncating silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;

        PRINT 'Inserting data into silver.crm_sales_details';

        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            -- Convert valid YYYYMMDD integer dates into DATE values.
            -- Invalid-length dates and zero values become NULL.
            CASE
                WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END AS sls_order_dt,

            CASE
                WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END AS sls_ship_dt,

            CASE
                WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END AS sls_due_dt,

            -- Recalculate sales when the source value is missing,
            -- nonpositive, or inconsistent with quantity multiplied by price.
            CASE
                WHEN sls_sales IS NULL
                    OR sls_sales <= 0
                    OR sls_sales != ABS(sls_quantity * sls_price)
                THEN ABS(sls_quantity * sls_price)
                ELSE sls_sales
            END AS sls_sales,

            sls_quantity,

            -- Derive the price from sales and quantity when the source
            -- price is missing or nonpositive; NULLIF prevents division by zero.
            CASE
                WHEN sls_price IS NULL OR sls_price <= 0
                THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price

        FROM bronze.crm_sales_details;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -----------------------------------------------------------------------
        -- 4. Load ERP Customer Information
        -----------------------------------------------------------------------
        -- Standardize customer IDs, remove the NAS prefix where present,
        -- exclude future birth dates, and normalize gender values.

        SET @start_time = GETDATE();

        PRINT '>> Truncating silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;

        PRINT 'Inserting data into silver.erp_cust_az12';

        INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
        SELECT
            CASE
                WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid,

            CASE
                WHEN bdate > GETDATE() THEN NULL
                ELSE bdate
            END AS bdate,

            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                ELSE 'N/A'
            END AS gen
        FROM bronze.erp_cust_az12;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -----------------------------------------------------------------------
        -- 5. Load ERP Customer Location Information
        -----------------------------------------------------------------------
        -- Standardize customer IDs and map common country codes to full names.

        SET @start_time = GETDATE();

        PRINT '>> Truncating silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;

        PRINT 'Inserting data into silver.erp_loc_a101';

        INSERT INTO silver.erp_loc_a101 (cid, cntry)
        SELECT
            REPLACE(cid, '-', '') AS cid,
            CASE
                WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
                ELSE TRIM(cntry)
            END AS cntry
        FROM bronze.erp_loc_a101;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -----------------------------------------------------------------------
        -- 6. Load ERP Product Category Information
        -----------------------------------------------------------------------
        -- Load category, subcategory, and maintenance attributes into Silver.

        SET @start_time = GETDATE();

        PRINT '>> Truncating silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        PRINT 'Inserting data into silver.erp_px_cat_g1v2';

        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT
            id,
            cat,
            subcat,
            maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -----------------------------------------------------------------------
        -- Log the total duration for loading the Silver layer.
        -----------------------------------------------------------------------
        SET @batch_end_time = GETDATE();
        PRINT 'Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';

    END TRY
    BEGIN CATCH
        -- Report error details if any operation in the procedure fails.
        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
    END CATCH
END
