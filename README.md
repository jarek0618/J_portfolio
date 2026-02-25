# 👋 Jarosław Błaziński – Data Engineering Portfolio

Junior / Mid Data Engineer z doświadczeniem w PySpark, SQL Server i Apache Airflow.  
Projekty skupiają się na praktycznych problemach: przetwarzaniu danych, automatyzacji i jakości danych.

📧 [Your Email] &nbsp;|&nbsp; 💼 [LinkedIn] &nbsp;|&nbsp; 🐙 [GitHub](https://github.com/jarek0618)

---

## 🗂️ Projekty

### 1. 💱 Frankfurter API – Airflow DAG pobierający kursy walut
**Plik:** `1_Frankfurter_api_currencies.py`  
**Tech:** Python, Apache Airflow, REST API  

Automatyczny DAG uruchamiany co poniedziałek, który pobiera kursy 6 par walutowych z publicznego API Europejskiego Banku Centralnego i zapisuje je do pliku CSV gotowego do otwarcia w Excelu.

**Co pokazuje:**
- integrację z zewnętrznym REST API
- budowę DAG-a w Apache Airflow
- obsługę błędów i logowanie

📄 README: [`1_Frankfurter_api_currencies_README.md`](1_Frankfurter_api_currencies_README.md)

---

### 2. ⚡ PySpark ETL Pipeline – analityka transakcji e-commerce
**Pliki:** `2_PySpark_ETL.ipynb`, `2_input_data.csv`  
**Tech:** PySpark 3.x, Python 3.8+, Jupyter / Databricks  

Pipeline przetwarzający ~500 000 rekordów transakcji z europejskich rynków (PL, DE, DK, SE). Obejmuje walidację jakości danych, czyszczenie, wzbogacanie o dane wymiarowe i analizę z użyciem window functions.

**Co pokazuje:**
- DataFrame API, window functions (`dense_rank`), joiny, agregacje
- automatyczną walidację jakości danych (NULLe, wartości ujemne)
- logowanie i parametryzację konfiguracji
- gotowość do uruchomienia na Databricks (DBFS/Delta Lake)

📄 README: [`2_PySpark_ETL_README.md`](2_PySpark_ETL_README.md)

---

### 3. 🔄 CDC Demo – Change Data Capture w SQL Server
**Plik:** `3_CDC_Demo_SQLServer.sql`  
**Tech:** SQL Server 2016+, T-SQL  

Kompletne demo włączenia i obsługi CDC na SQL Server. Pokazuje przechwytywanie zmian INSERT / UPDATE / DELETE, budowę audit trail oraz zapytania net changes.

**Co pokazuje:**
- konfigurację CDC (`sp_cdc_enable_db`, `sp_cdc_enable_table`)
- odczyt tabeli `cdc.dbo_Transactions_CT` z interpretacją `__$operation`
- audit trail (wartości przed i po zmianie)
- net changes – ostatni stan każdego rekordu

---

## 🛠️ Stack technologiczny

| Obszar | Technologie |
|---|---|
| Big Data | PySpark 3.x, Databricks |
| Orchestration | Apache Airflow |
| Bazy danych | SQL Server, T-SQL |
| Języki | Python 3.8+, SQL |
| Narzędzia | Jupyter Notebook, Git |

---

## 📝 Uwaga

Wszystkie projekty są demonstracjami portfolio — nie są to fragmenty kodu produkcyjnego z poprzednich pracodawców.  
Celem jest pokazanie umiejętności technicznych, myślenia biznesowego i znajomości dobrych praktyk data engineering.
