# Data Catalog – E-Commerce Medallion Pipeline

**Owner:** Jarosław Błaziński  
**Pipeline:** E-Commerce ELT Medallion Architecture  
**Last Updated:** 2026-02-25  
**Stack:** PySpark, Delta Lake, Databricks Community Edition

---

## Architektura

```
input_data_v2.csv
        │
        ▼
┌─────────────────┐
│  bronze.         │  Raw ingestion – load as-is
│  transactions    │  Partitioned by: country
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  silver.         │  Cleaned + enriched
│  transactions    │  Partitioned by: country, year
└────────┬────────┘
         │
         ├──────────────────────────────────┐
         │                                  │
         ▼                                  ▼
┌─────────────────────────┐   ┌──────────────────────┐
│ gold.revenue_by_         │   │ gold.monthly_trend   │
│ country_category         │   │ gold.payment_methods │
└──────────────────────────┘   └──────────────────────┘
         │
         ▼
    Power BI Desktop
```

---

## Tabele

### bronze.transactions

| Właściwość | Wartość |
|---|---|
| **Ścieżka** | `/tmp/medallion/bronze/transactions` |
| **Format** | Delta |
| **Partycjonowanie** | `country` |
| **Wiersze** | ~500 000 |
| **Właściciel** | Jarosław Błaziński |
| **Źródło** | `input_data_v2.csv` |
| **PII** | ⚠️ Tak – `customer_id`, `amount` |
| **Tagi** | bronze, raw, ecommerce, pii |

**Schemat:**

| Kolumna | Typ | Nullable | Opis | PII |
|---|---|---|---|---|
| transaction_id | IntegerType | NOT NULL | Unikalny ID transakcji | ⚠️ IDENTIFIER |
| customer_id | IntegerType | nullable | ID klienta | ⚠️ HIGH |
| amount | DoubleType | nullable | Kwota transakcji (z NULLami i ujemnymi) | ⚠️ FINANCIAL |
| category | StringType | nullable | Kategoria produktu | - |
| country | StringType | nullable | Kod kraju (PL/DE/DK/SE) | - |
| status | StringType | nullable | Status: completed / refunded / cancelled | - |
| payment_method | StringType | nullable | Metoda płatności | - |
| quantity | IntegerType | nullable | Liczba sztuk | - |
| transaction_date | TimestampType | nullable | Data i czas transakcji | - |
| _ingested_at | TimestampType | nullable | Znacznik czasu ingestii (metadata) | - |
| _source_file | StringType | nullable | Nazwa pliku źródłowego (metadata) | - |

---

### silver.transactions

| Właściwość | Wartość |
|---|---|
| **Ścieżka** | `/tmp/medallion/silver/transactions` |
| **Format** | Delta |
| **Partycjonowanie** | `country`, `year` |
| **Wiersze** | ~375 000 (po czyszczeniu) |
| **Właściciel** | Jarosław Błaziński |
| **Źródło** | `bronze.transactions` |
| **PII** | ⚠️ Tak – `customer_id` (do pseudonymizacji) |
| **Tagi** | silver, clean, ecommerce, vat, pii |

**Transformacje względem Bronze:**
- `FILTER: amount IS NOT NULL`
- `FILTER: amount > 0`
- `FILTER: status != 'cancelled'`
- `LEFT JOIN country_dim ON country` (broadcast join)
- `DROP: _ingested_at, _source_file`

**Schemat (kolumny dodane względem Bronze):**

| Kolumna | Typ | Źródło | Opis |
|---|---|---|---|
| country_name | StringType | country_dim JOIN | Pełna nazwa kraju |
| vat_rate | DoubleType | country_dim JOIN | Stawka VAT: PL=0.23, DE=0.19, DK/SE=0.25 |
| amount_vat | DoubleType | `amount * (1 + vat_rate)` | Kwota z VAT |
| revenue | DoubleType | `amount * quantity` | Przychód netto |
| revenue_vat | DoubleType | `amount_vat * quantity` | Przychód z VAT |
| transaction_date_only | DateType | `to_date(transaction_date)` | Sama data (bez czasu) |
| month | IntegerType | `month(transaction_date)` | Miesiąc (1-12) |
| year | IntegerType | `year(transaction_date)` | Rok |
| day_of_week | IntegerType | `dayofweek(transaction_date)` | Dzień tygodnia (1=Sun) |
| is_weekend | BooleanType | `day_of_week IN (1, 7)` | Flaga weekendu |
| _processed_at | TimestampType | `current_timestamp()` | Znacznik przetworzenia |

---

### gold.revenue_by_country_category

| Właściwość | Wartość |
|---|---|
| **Ścieżka** | `/tmp/medallion/gold/revenue_by_country_category` |
| **Format** | Delta |
| **Wiersze** | ≤ 32 (4 kraje × 8 kategorii) |
| **Właściciel** | Jarosław Błaziński |
| **Źródło** | `silver.transactions` |
| **PII** | ✅ Brak – dane zagregowane |
| **Tagi** | gold, aggregated, reporting, powerbi, no-pii |
| **Odświeżanie** | MERGE INTO (upsert przy każdym uruchomieniu) |

**Schemat:**

| Kolumna | Typ | Opis |
|---|---|---|
| country | StringType | Kod kraju |
| country_name | StringType | Pełna nazwa kraju |
| category | StringType | Kategoria produktu |
| total_revenue | DoubleType | Suma przychodu netto |
| total_revenue_vat | DoubleType | Suma przychodu z VAT |
| avg_order_value | DoubleType | Średnia wartość zamówienia |
| transaction_count | LongType | Liczba transakcji |
| unique_customers | LongType | Liczba unikalnych klientów |
| rank_in_country | IntegerType | Ranking kategorii w kraju (dense_rank) |
| _created_at | TimestampType | Znacznik ostatniej aktualizacji |

---

### gold.monthly_trend

| Właściwość | Wartość |
|---|---|
| **Ścieżka** | `/tmp/medallion/gold/monthly_trend` |
| **Format** | Delta |
| **Wiersze** | ≤ 48 (4 kraje × 12 miesięcy) |
| **PII** | ✅ Brak |
| **Tagi** | gold, aggregated, trend, powerbi, no-pii |

| Kolumna | Typ | Opis |
|---|---|---|
| year | IntegerType | Rok |
| month | IntegerType | Miesiąc (1-12) |
| country | StringType | Kod kraju |
| country_name | StringType | Pełna nazwa kraju |
| monthly_revenue | DoubleType | Przychód miesięczny |
| transaction_count | LongType | Liczba transakcji |
| unique_customers | LongType | Unikalnych klientów |
| avg_order_value | DoubleType | Średnia wartość zamówienia |

---

### gold.payment_methods

| Właściwość | Wartość |
|---|---|
| **Ścieżka** | `/tmp/medallion/gold/payment_methods` |
| **Format** | Delta |
| **Wiersze** | ≤ 20 (4 kraje × 5 metod płatności) |
| **PII** | ✅ Brak |
| **Tagi** | gold, aggregated, payments, powerbi, no-pii |

| Kolumna | Typ | Opis |
|---|---|---|
| country | StringType | Kod kraju |
| country_name | StringType | Pełna nazwa kraju |
| payment_method | StringType | Metoda płatności |
| transaction_count | LongType | Liczba transakcji |
| total_revenue | DoubleType | Suma przychodu |
| avg_order_value | DoubleType | Średnia wartość zamówienia |

---

## PII Registry

| Kolumna | Tabela | Typ PII | Ryzyko | Akcja |
|---|---|---|---|---|
| customer_id | bronze, silver | IDENTIFIER | 🔴 HIGH | Pseudonymizacja SHA-256 przed Gold |
| transaction_id | bronze, silver | IDENTIFIER | 🟡 MEDIUM | Zachować – potrzebny do audytu |
| amount | bronze, silver | FINANCIAL | 🟡 MEDIUM | Zachować – agregacje w Gold nie ujawniają danych jednostkowych |

---

## Quality SLA

| Warstwa | Metryka | Oczekiwana wartość |
|---|---|---|
| Bronze | NULL rate w `amount` | < 15% |
| Bronze | Unikalność `transaction_id` | 100% |
| Silver | NULL w `amount` | 0% |
| Silver | Wartości ujemne w `amount` | 0% |
| Silver | Retencja względem Bronze | 65–90% |
| Gold | Wiersze `revenue_by_country_category` | ≤ 32 |
