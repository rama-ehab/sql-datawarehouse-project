
/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script initializes the 'DataWarehouse' database by checking if it
    already exists. If it does, the existing database is dropped and
    recreated. The script then creates three schemas within the database
    to implement the Medallion Architecture: 'bronze', 'silver', and 'gold'.

WARNING:
    Running this script will drop the entire 'DataWarehouse' database if it
    exists. All data in the database will be permanently deleted.
    Ensure you have proper backups before running this script.
    Use this script only in development or test environments.
*/

USE master;
GO

-- Drop the database if it already exists.
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    -- Disconnect active connections and roll back uncommitted transactions.
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE DataWarehouse;
END;
GO

-- Create a new DataWarehouse database.
CREATE DATABASE DataWarehouse;
GO

-- Switch to the new database.
USE DataWarehouse;
GO

-- Create the Bronze schema for raw data.
CREATE SCHEMA bronze;
GO

-- Create the Silver schema for cleaned and transformed data.
CREATE SCHEMA silver;
GO

-- Create the Gold schema for business-ready analytical data.
CREATE SCHEMA gold;
GO
