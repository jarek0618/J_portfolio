# Data Governance – Medallion Pipeline
## E-Commerce ELT Architecture na Databricks Community Edition

**Author:** Jarosław Błaziński  
**Tech Stack:** PySpark 3.x, Delta Lake, Databricks  
**Dataset:** 500 000 transakcji e-commerce (2024)

---

## 📋 Problem biznesowy

Pipeline przetwarza dane transakcyjne z rynków PL, DE, DK i SE. Dane zawierają `customer_id` i `amount` – informacje objęte wymogami RODO. Bez formalnego governance nie wiadomo: gdzie dokładnie przechowywane są dane wrażliwe, czy dane w każdej warstwie spełniają minimalne wymagania jakości, ani skąd pochodzi każda kolumna w Gold.

**Rozwiązanie:** notebook implementuje cztery filary governance: Data Lineage, PII Detection, Data Quality Checks i Data Catalog – jako działający kod, nie tylko dokumentacja.

---

## 💡 Cztery filary governance

```
[BRONZE] → [SILVER] → [GOLD]
              │
              ▼
    ┌─────────────────────┐
    │  Data Governance    │
    │                     │
    │  1. Data Lineage    │  skąd pochodzi każda kolumna?
    │  2. PII Detection   │  gdzie są dane wrażliwe?
    │  3. Quality Checks  │  czy dane spełniają SLA?
    │  4. Data Catalog    │  co jest w każdej tabeli?
    └─────────────────────┘
```

---

## 🏗️ Co robi ten notebook?

| Sekcja | Opis |
|---|---|
| 1. Data Lineage | Dokumentacja przepływu Bronze→Silver→Gold z row count per layer |
| 2. PII Detection | Rejestr kolumn PII, automatyczny skaner, pseudonymizacja `customer_id` SHA-256 |
| 3. Data Quality Checks | Framework testów: completeness, validity, uniqueness, cross-layer consistency |
| 4. Data Catalog | Automatyczny katalog generowany z Delta metadata: schemat, właściciel, historia |

---

## 🔍 Sekcja 1 – Data Lineage

Lineage odpowiada na pytanie: **skąd pochodzi każda kolumna i jakie transformacje przeszła?**

```
input_data_v2.csv
      │
      ▼
BRONZE  – load as-is, +_ingested_at, +_source_file
      │
      ▼
SILVER  – FILTER NULLs/negatives/cancelled
          JOIN country_dim (broadcast)
          +country_name, +vat_rate, +amount_vat
          +revenue, +revenue_vat, +month, +year, +is_weekend
      │
      ▼
GOLD    – GROUP BY + SUM/AVG/COUNT
          WINDOW: dense_rank() per country
          MERGE INTO (upsert)
```

Notebook weryfikuje też ile wierszy przetrwało każdą warstwę i wyświetla retention rate Silver vs Bronze (oczekiwane 65–90%).

---

## 🔒 Sekcja 2 – PII Detection

| Kolumna | Tabela | Typ PII | Ryzyko | Akcja |
|---|---|---|---|---|
| `customer_id` | bronze, silver | IDENTIFIER | 🔴 HIGH | Pseudonymizacja SHA-256 przed Gold |
| `transaction_id` | bronze, silver | IDENTIFIER | 🟡 MEDIUM | Zachować – potrzebny do audytu |
| `amount` | bronze, silver | FINANCIAL | 🟡 MEDIUM | Zachowany – agregacje w Gold nie ujawniają danych jednostkowych |

**Pseudonymizacja customer_id:**
```python
sha2(col("customer_id").cast("string"), 256).alias("customer_id_hashed")
```

Gold nie zawiera żadnych danych PII – wszystkie tabele są zagregowane.

---

## ✅ Sekcja 3 – Data Quality Checks

Framework testów inspirowany Great Expectations, zaimplementowany natywnie w PySpark:

**Bronze SLA:**
```
✅ row_count BETWEEN 400 000 AND 600 000
✅ transaction_id NOT NULL
✅ transaction_id UNIQUE
✅ NULL rate w amount < 15%
✅ country IN (PL, DE, DK, SE)
✅ status IN (completed, refunded, cancelled)
```

**Silver SLA (wyższe wymagania):**
```
✅ amount NOT NULL (zero tolerancji)
✅ amount > 0 (zero tolerancji)
✅ country_name NOT NULL (join musiał się udać)
✅ vat_rate BETWEEN 0.10 AND 0.30
✅ month BETWEEN 1 AND 12
✅ status NOT IN (cancelled)
```

**Cross-layer consistency:**
```
✅ Silver retention 65–90% względem Bronze
✅ Gold row count ≤ 32 (4 kraje × 8 kategorii)
```

---

## 📚 Sekcja 4 – Data Catalog

Katalog generowany automatycznie z Delta metadata – bez ręcznego utrzymywania dokumentacji:

```
TABLE: bronze.transactions
  Path        : /tmp/medallion/bronze/transactions
  Row Count   : 500 000
  Last Updated: <timestamp z Delta history>
  Version     : <numer wersji>
  Schema      : transaction_id, customer_id ⚠️ PII, amount ⚠️ PII ...
```

Pełna dokumentacja wszystkich tabel dostępna w: [`data_catalog.md`](data_catalog.md)

---

## 🛠️ Jak uruchomić

Uruchom jako ostatni notebook po całym pipeline:

```
4_ELT_Bronze.ipynb
      ↓
5_ELT_Silver.ipynb
      ↓
6_ELT_Gold.ipynb
      ↓
7_Data_Governance.ipynb  ← ten notebook
```

Governance czyta dane z istniejących Delta Tables – nie modyfikuje żadnej warstwy.

---

## 📂 Pliki projektu

```
├── 4_ELT_Bronze.ipynb              # warstwa Bronze (ingestion)
├── 5_ELT_Silver.ipynb              # warstwa Silver (cleaning)
├── 6_ELT_Gold.ipynb                # warstwa Gold (aggregations)
├── 7_Data_Governance.ipynb         # ten notebook
├── 7_Data_Governance_README.md     # ten plik
├── data_catalog.md                 # pełny katalog tabel i schematów
└── input_data_v2.csv               # dataset 500k transakcji
```

---

## 🔄 Future Enhancements

- [ ] Unity Catalog (Databricks) – centralny katalog z kontrolą dostępu na poziomie kolumny
- [ ] Azure Purview / AWS Macie – automatyczne skanowanie PII w całej organizacji
- [ ] Great Expectations – zaawansowane testy z raportowaniem HTML i alertami
- [ ] Alerty Slack/email gdy Quality Check = FAIL
- [ ] Automatyczne uruchomienie Governance jako ostatni krok Databricks Workflow
