# 🚀 Data Warehouse and Analytics Project

A modern **Data Warehouse built with Microsoft SQL Server**, integrating CRM and ERP data into a centralized analytical model using the Medallion Architecture.

This project demonstrates an end-to-end data engineering workflow, from raw data ingestion and data cleansing to dimensional modeling and analytical reporting.

## 📌 Project Overview

The objective of this project is to consolidate sales-related data from two source systems (CRM and ERP) into a centralized data warehouse, ensuring data quality, consistency, and readiness for analytical queries.

The project follows a three-layer architecture:

- **Bronze:** Raw data ingestion from CSV files.
- **Silver:** Data cleansing, standardization, and transformation.
- **Gold:** Business-ready views organized into a Star Schema for analytics and reporting.

## 🏗️ Data Architecture

The project follows the **Medallion Architecture**, separating data processing into Bronze, Silver, and Gold layers.

### 🥉 Bronze Layer — Raw Data

- Created tables to store raw CRM and ERP data.
- Loaded six CSV source files into SQL Server using `BULK INSERT`.
- Developed a stored procedure (`bronze.load_bronze`) to automate ingestion.
- Implemented table truncation and load-duration logging.

### 🥈 Silver Layer — Cleansed and Standardized Data

- Developed a stored procedure (`silver.load_silver`) to transform data from Bronze to Silver.
- Removed duplicate customer records and handled missing customer IDs.
- Standardized names, gender, marital status, product lines, and country values.
- Handled invalid dates and missing or inconsistent sales values.
- Transformed product keys and derived product validity end dates.
- Integrated data quality rules into the transformation process.

### 🥇 Gold Layer — Business-Ready Data

Created SQL views to implement a Star Schema for analytical queries.

**Dimension Views**
- `gold.dim_customers` — Customer details, demographics, and location.
- `gold.dim_products` — Product details, categories, and product attributes.

**Fact View**
- `gold.fact_sales` — Sales transactions containing order dates, quantities, sales amounts, prices, and dimension keys.

Surrogate keys connect sales transactions to the customer and product dimensions, making the model suitable for reporting and aggregation.

## 📊 Data Model

The Gold layer follows a Star Schema, with the sales fact view connected to customer and product dimensions.

```text
              gold.dim_customers
                      |
                      |
               gold.fact_sales
                      |
                      |
              gold.dim_products
```

**Fact table grain:** Each row represents a sales transaction record at the grain provided by the source sales data.

## 🛠️ Technologies Used

- **Database:** Microsoft SQL Server
- **SQL:** T-SQL, DDL, DML, CTEs, window functions, joins, and aggregations
- **ETL:** `BULK INSERT`, stored procedures, and SQL-based transformations
- **Data Modeling:** Medallion Architecture and Star Schema
- **Data Quality:** Deduplication, standardization, missing-value handling, and validation
- **Tools:** SQL Server Management Studio (SSMS), Git, and GitHub

## 📂 Project Structure

```text
sql-data-warehouse-project/
│
├── 01_datasets/
│   ├── source_crm/
│   └── source_erp/
│
├── 02_scripts/
│   ├── init_database.sql
│   ├── bronze/
│   ├── silver/
│   └── gold/
│
└── README.md
```

*The structure above summarizes the main project folders. Your repository may contain additional setup files and scripts.*

## 🚀 How to Run the Project

1. Install Microsoft SQL Server and SQL Server Management Studio (SSMS).
2. Download or clone the repository.
3. Ensure the six CRM and ERP CSV files are available in the expected directory.
4. Update the file paths in the Bronze loading procedure to match your local environment.
5. Execute `init_database.sql` to create the database and schemas.
6. Execute the Bronze, Silver, and Gold scripts in the correct order.
7. Run the Bronze and Silver loading procedures to populate their respective layers.
8. Query the Gold views to explore the integrated analytical data.

## 🎯 Key Learning Outcomes

- Designed and implemented a layered data warehouse architecture.
- Built repeatable ETL processes using SQL Server stored procedures.
- Applied SQL-based data cleansing and transformation techniques.
- Used window functions to identify duplicate records and derive product validity periods.
- Integrated CRM and ERP data from multiple source systems.
- Implemented dimensional modeling using fact and dimension views.
- Prepared a centralized dataset for customer, product, and sales analysis.

## 👩‍💻 Author

**Rama Ehab Ahmed**

- [LinkedIn](https://www.linkedin.com/in/rama-ehab-95557631b/)
- [GitHub](https://github.com/rama-ehab)
- [Portfolio](https://rama-ehab-portfolio.vercel.app/)
