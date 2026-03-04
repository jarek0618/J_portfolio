# 👋 Jarosław Błaziński – Analytics Engineer / Data Engineering Portfolio

**Analytics Engineer   or    Junior / Mid Data Engineer** with hands-on experience in PySpark, SQL Server, Apache Airflow, and Databricks.  
Projects focus on practical data challenges: pipeline automation, ETL/ELT processing, Medallion Architecture, data quality, and governance.

📧 [j.blazinski@gmail.com](mailto:j.blazinski@gmail.com) · 💼 [LinkedIn](https://www.linkedin.com/in/jaroslaw-blazinski-8204b2186/) · 🐙 [GitHub](https://github.com/jarek0618/J_portfolio)

---

## 🗂️ Projects

### 1. 💱 Frankfurter API – Airflow DAG for Currency Rates
**File:** `1_Frankfurter_api_currencies.py`  
**Tech:** Python · Apache Airflow · REST API

A scheduled Airflow DAG (runs every Monday) that fetches exchange rates for 6 currency pairs from the European Central Bank's public API and saves them to a CSV file ready for analysis.

**Key concepts:** REST API integration · DAG scheduling · error handling & logging

📄 Details: [`1_Frankfurter_api_currencies_README.md`](./1_Frankfurter_api_currencies_README.md)

---

### 2. ⚡ PySpark ETL Pipeline – E-commerce Transaction Analytics
**Files:** `2_PySpark_ETL.ipynb` · `2_input_data.csv`  
**Tech:** PySpark 3.x · Python 3.8+ · Jupyter / Databricks

An end-to-end ETL pipeline processing ~500,000 transaction records from European markets (PL, DE, DK, SE). Covers data quality validation, cleansing, dimensional enrichment, and advanced analytics using window functions.

**Key concepts:** DataFrame API · window functions (`dense_rank`) · joins & aggregations · null/negative value validation · Databricks / Delta Lake readiness

📄 Details: [`2_PySpark_ETL_README.md`](./2_PySpark_ETL_README.md)

---

### 3. 🔄 CDC Demo – Change Data Capture in SQL Server
**File:** `3_CDC_Demo_SQLServer.sql`  
**Tech:** SQL Server 2016+ · T-SQL

A complete demo of enabling and querying CDC on SQL Server. Captures INSERT / UPDATE / DELETE changes, builds an audit trail, and queries net changes per record.

**Key concepts:** CDC configuration (`sp_cdc_enable_db`, `sp_cdc_enable_table`) · `__$operation` interpretation · before/after audit trail · net changes queries

---

### 4. 🥉 ELT Bronze Layer – Raw Data Ingestion
**File:** `4_ELT_Bronze.ipynb`  
**Tech:** PySpark · Databricks · Delta Lake

First layer of the Medallion Architecture. Ingests raw data from source systems into the Bronze zone with minimal transformation — preserving data as-is with added metadata (ingestion timestamp, source).

**Key concepts:** Medallion Architecture · raw zone design · Delta Lake write · schema-on-read

📄 Details: [`4_ELT_Bronze_README.md`](./4_ELT_Bronze_README.md)

---

### 5. 🥈 ELT Silver Layer – Cleansed & Conformed Data
**File:** `5_ELT_Silver.ipynb`  
**Tech:** PySpark · Databricks · Delta Lake

Second layer of the Medallion Architecture. Applies data cleansing, deduplication, type casting, and business rules to produce a reliable, conformed dataset.

**Key concepts:** data cleansing · deduplication · SCD handling · Delta Lake merge (UPSERT)

📄 Details: [`5_ELT_Silver_README.md`](./5_ELT_Silver_README.md)

---

### 6. 🥇 ELT Gold Layer – Business-Ready Aggregations
**File:** `6_ELT_Gold.ipynb`  
**Tech:** PySpark · Databricks · Delta Lake

Third and final layer of the Medallion Architecture. Produces aggregated, denormalized tables optimized for reporting and analytics consumption.

**Key concepts:** aggregation logic · star schema design · Delta Lake optimization · BI-ready output

📄 Details: [`6_ELT_Gold_README.md`](./6_ELT_Gold_README.md)

---

### 7. 🏛️ Data Governance
**Files:** `7_Data_Governance.ipynb` · `data_catalog.md`  
**Tech:** PySpark · Databricks · Delta Lake

Demonstrates core data governance practices applied across the Medallion pipeline: data cataloging, lineage tracking, quality rule enforcement, and access control patterns.

**Key concepts:** data catalog · column-level lineage · data quality checks · PII handling · Unity Catalog concepts

📄 Details: [`7_Data_Governance_README.md`](./7_Data_Governance_README.md)

---

## 🛠️ Tech Stack

| Area | Technologies |
|---|---|
| Big Data | PySpark 3.x, Databricks, Delta Lake |
| Architecture | Medallion (Bronze / Silver / Gold) |
| Orchestration | Apache Airflow |
| Databases | SQL Server, T-SQL |
| Data Governance | Data Catalog, Lineage, Quality Rules |
| Languages | Python 3.8+, SQL |
| Tools | Jupyter Notebook, Git |

---

## 📝 Note

All projects are portfolio demonstrations — not production code from previous employers.  
The goal is to showcase technical skills, business thinking, and knowledge of data engineering best practices.
