# ELT Pipeline – Gold Layer (Aggregations & Power BI Export)
## Medallion Architecture na Databricks Community Edition

**Author:** Jarosław Błaziński  
**Tech Stack:** PySpark 3.x, Delta Lake, Databricks  
**Dataset:** 500 000 transakcji e-commerce (2024)

---

## 📋 Problem biznesowy

Management firmy e-commerce potrzebuje odpowiedzi na trzy pytania co tydzień:
- Które kategorie produktów generują największy przychód w każdym kraju?
- Jak zmienia się sprzedaż miesiąc do miesiąca?
- Jakie metody płatności dominują na poszczególnych rynkach?

Wcześniej analityk przygotowywał te raporty ręcznie w Excelu – 3-5 dni pracy. Pipeline Gold dostarcza gotowe odpowiedzi w kilka minut, automatycznie, przy każdym uruchomieniu.

---

## 💡 Co robi warstwa Gold?

```
[SILVER]  – oczyszczone dane transakcyjne
     ↓
[GOLD]    ← ten notebook
  - agregacje per kraj i kategoria
  - ranking kategorii (window function)
  - trend miesięczny
  - analiza metod płatności
  - MERGE INTO (upsert pattern)
  - eksport CSV do Power BI
     ↓
Power BI Desktop (dashboard)
```

---

## 🏗️ Trzy tabele Gold

| Tabela | Pytanie biznesowe | Użycie w Power BI |
|---|---|---|
| `revenue_by_country_category` | Które kategorie generują największy przychód per kraj? | Bar chart, tabela rankingowa |
| `monthly_trend` | Jak zmienia się przychód miesiąc do miesiąca? | Line chart, KPI cards |
| `payment_methods` | Jakie metody płatności dominują per kraj? | Pie chart, stacked bar |

---

## ⚡ MERGE INTO – dlaczego to ważne?

W produkcji nie możemy nadpisywać całej tabeli Gold przy każdym uruchomieniu – to zbyt wolne i ryzykowne. MERGE (upsert) aktualizuje tylko zmienione rekordy:

```python
delta_gold.alias("target")
.merge(new_data.alias("source"), warunek_dopasowania)
.whenMatchedUpdateAll()     # rekord istnieje → zaktualizuj
.whenNotMatchedInsertAll()  # nowy rekord → wstaw
.execute()
```

To wzorzec inkrementalnego ładowania – kluczowy w każdym produkcyjnym pipeline'ie.

---

## 📊 Przykładowe wyniki

### Top 3 kategorie per kraj:
```
+-------+-------------------+-------------+-----------------+
|country|category           |total_revenue|rank_in_country  |
+-------+-------------------+-------------+-----------------+
|DE     |Electronics        |1,245,830.50 |1                |
|DE     |Automotive         |  987,220.30 |2                |
|DE     |Home & Garden      |  876,540.20 |3                |
|PL     |Electronics        |1,198,430.10 |1                |
|PL     |Health & Beauty    |  923,180.60 |2                |
...
```

---

## 🔗 Podłączenie do Power BI

Databricks Community Edition nie obsługuje Direct Query – eksportujemy Gold jako CSV.

### Krok 1 – Pobierz pliki z Databricks
W Databricks: *Data → DBFS → /tmp/medallion/export/* → pobierz każdy folder jako CSV

### Krok 2 – Power BI Desktop
*Get Data → Text/CSV* → wczytaj wszystkie trzy pliki Gold

### Sugerowane wizualizacje:
- **Bar chart** – `total_revenue` per `category` filtrowany po `country`
- **Line chart** – `monthly_revenue` po `month` z podziałem na `country`
- **Slicer** – filtr po `country` i `year`
- **KPI card** – suma `total_revenue`, liczba transakcji, średnia wartość zamówienia

---

## 🛠️ Jak uruchomić

Uruchom jako trzeci i ostatni notebook w pipeline:

```
4_ELT_Bronze.ipynb  →  5_ELT_Silver.ipynb  →  6_ELT_Gold.ipynb
```

Gold czyta dane bezpośrednio z Silver Delta Table.

---

## 📂 Pliki projektu

```
├── 4_ELT_Bronze.ipynb          # warstwa Bronze (ingestion)
├── 5_ELT_Silver.ipynb          # warstwa Silver (cleaning)
├── 6_ELT_Gold.ipynb            # ten notebook
├── 6_ELT_Gold_README.md        # ten plik
└── input_data_v2.csv           # dataset 500k transakcji
```

---

## 🔄 Future Enhancements

- [ ] Scheduled job w Databricks Workflows (automatyczne uruchomienie co noc)
- [ ] Delta Live Tables – deklaratywny pipeline z automatycznym lineage
- [ ] Direct Query z Power BI (wymaga płatnego Databricks SQL Warehouse)
- [ ] Great Expectations – automatyczna walidacja jakości danych Gold
