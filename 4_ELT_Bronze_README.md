# ELT Pipeline – Bronze Layer (Delta Tables)
## Medallion Architecture na Databricks Community Edition

**Author:** Jarosław Błaziński  
**Tech Stack:** PySpark 3.x, Delta Lake, Databricks  
**Dataset:** 500 000 transakcji e-commerce (2024)

---

## 📋 Problem biznesowy

Firma e-commerce operująca na rynkach PL, DE, DK i SE otrzymuje codziennie pliki CSV z transakcjami ze źródłowych systemów sprzedażowych. Dane są niespójne – zawierają NULLe, ujemne kwoty (zwroty) i brak historii zmian. Analitycy nie mają pewności czy pracują na aktualnych danych ani możliwości powrotu do poprzedniej wersji w razie błędu.

**Rozwiązanie:** warstwa Bronze w architekturze Medallion – surowe dane trafiają do Delta Table bez żadnych modyfikacji. Każda ingestia jest wersjonowana, a metadane (`_ingested_at`, `_source_file`) zapewniają pełny audit trail.

---

## 💡 Czym jest warstwa Bronze?

Bronze to pierwsza warstwa architektury Medallion:

```
CSV (źródło)
     ↓
[BRONZE]  ← ten notebook
     ↓
[SILVER]  – czyszczenie i transformacje
     ↓
[GOLD]    – agregaty gotowe do raportowania
```

Zasada Bronze: **load as-is** – zapisujemy wszystko co przychodzi ze źródła, łącznie z błędami i NULLami. Dzięki temu zawsze możemy wrócić do oryginału i zweryfikować co trafiło do systemu.

---

## 🏗️ Co robi ten notebook?

| Krok | Opis |
|---|---|
| Schemat ręczny | Zamiast `inferSchema=True` – szybszy i deterministyczny |
| Metadane ingestii | Kolumny `_ingested_at` i `_source_file` na każdym wierszu |
| Zapis Delta Table | Format delta, partycjonowanie po `country` |
| Time Travel | `DeltaTable.history()` – pełna historia operacji |
| Quality Report | Raport NULLi, ujemnych kwot i rozkładu danych |

---

## 📊 Raport jakości danych wejściowych

```
Total rows      : 500 000
NULL amounts    :  ~10%   (brakujące dane ze źródła)
Negative amounts:   ~5%   (zwroty i obciążenia zwrotne)
```

Rozkład po krajach:
```
PL: ~25%  |  DE: ~25%  |  DK: ~25%  |  SE: ~25%
```

---

## ⚡ Delta Table – dlaczego nie zwykły Parquet?

Delta Lake = Parquet + transaction log. Daje to:

- **Time Travel** – `SELECT * FROM table VERSION AS OF 0` – poprzednia wersja jedną linijką
- **ACID transactions** – brak częściowych zapisów przy błędzie
- **Audit trail** – `DESCRIBE HISTORY` pokazuje kto i kiedy coś zmienił
- **Schema enforcement** – Delta odrzuci dane niezgodne ze schematem

---

## 🛠️ Jak uruchomić na Databricks Community Edition

### Krok 1 – Wgraj dane
*Data → Add Data → Upload File* → wybierz `input_data_v2.csv`

### Krok 2 – Podmień ścieżkę w notebooku
```python
INPUT_PATH = "/FileStore/tables/input_data_v2.csv"
```

### Krok 3 – Uruchom wszystkie komórki
*Run All* lub cell by cell (zalecane przy pierwszym uruchomieniu)

### Wymagania
- Databricks Community Edition (darmowe konto)
- Cluster z DBR 11.3+ (Delta Lake wbudowany)
- Plik `input_data_v2.csv` wgrany do DBFS

---

## 📂 Pliki projektu

```
├── 4_ELT_Bronze.ipynb          # ten notebook
├── 4_ELT_Bronze_README.md      # ten plik
├── 5_ELT_Silver.ipynb          # czyszczenie i transformacje
├── 6_ELT_Gold.ipynb            # agregaty i ranking (źródło dla Power BI)
└── input_data_v2.csv           # dataset 500k transakcji
```

---

## 🔄 Następny krok

Po uruchomieniu Bronze przejdź do **`5_ELT_Silver.ipynb`** – warstwa Silver czyści dane (usuwa NULLe, filtruje zwroty), wzbogaca je o dane wymiarowe i oblicza VAT.
