# ELT Pipeline – Silver Layer (Cleaning & Enrichment)
## Medallion Architecture na Databricks Community Edition

**Author:** Jarosław Błaziński  
**Tech Stack:** PySpark 3.x, Delta Lake, Databricks  
**Dataset:** 500 000 transakcji e-commerce (2024)

---

## 📋 Problem biznesowy

Surowe dane z warstwy Bronze zawierają ~10% NULLi w kolumnie `amount`, ~5% ujemnych kwot (zwroty) oraz anulowane zamówienia. Analitycy pracujący bezpośrednio na takich danych ryzykują błędne wyniki – np. przychód zaniżony przez zwroty wliczone do sumy, lub zawyżony przez anulowane zamówienia.

**Rozwiązanie:** warstwa Silver automatycznie oczyszcza dane, wzbogaca je o kontekst biznesowy (nazwy krajów, stawki VAT) i oblicza gotowe metryki (`revenue`, `amount_vat`). Analityk dostaje pewne, spójne dane.

---

## 💡 Co robi warstwa Silver?

```
[BRONZE]  – surowe dane (load as-is)
     ↓
[SILVER]  ← ten notebook
  - usunięcie NULLi i błędnych rekordów
  - broadcast join z country dimension
  - obliczenie VAT per kraj (PL 23%, DE 19%, DK/SE 25%)
  - metryki czasowe (month, year, is_weekend)
  - zapis Delta Table z partycjonowaniem
     ↓
[GOLD]    – agregaty do raportowania
```

---

## 🏗️ Co robi ten notebook?

| Krok | Opis |
|---|---|
| Quality check PRZED | Dokumentacja stanu wejściowego |
| Czyszczenie | Usunięcie NULLi, zwrotów (`amount < 0`), anulowanych |
| Broadcast join | Dołączenie `country_name` i `vat_rate` bez shuffle |
| Transformacje | `amount_vat`, `revenue`, `revenue_vat`, `month`, `year`, `is_weekend` |
| Zapis Delta | Partycjonowanie po `country` i `year` |
| Time Travel | Weryfikacja wersji i odczyt historyczny |
| Quality check PO | Porównanie z danymi wejściowymi |

---

## 📊 Wyniki czyszczenia

```
Przed czyszczeniem : 500 000
Po czyszczeniu     : ~375 000  (~75% retencja)

Usunięto:
  - NULL amounts    : ~50 000  (10%)
  - Negative amounts: ~25 000  (5%)
  - Cancelled       : ~50 000  (10%)
```

---

## ⚡ Broadcast join – dlaczego?

`country_dim` ma tylko 4 wiersze. Broadcast join wysyła tę małą tabelę do każdego executora zamiast wykonywać kosztowny shuffle 375k wierszy. Przy dużych danych (miliony rekordów) różnica w czasie może być ogromna.

```python
df_clean.join(broadcast(country_dim), on="country", how="left")
```

---

## 🛠️ Jak uruchomić

Uruchom po `4_ELT_Bronze.ipynb`. Silver czyta dane bezpośrednio z Bronze Delta Table – nie potrzebujesz ponownie wgrywać pliku CSV.

```
Run: 4_ELT_Bronze.ipynb  →  5_ELT_Silver.ipynb  →  6_ELT_Gold.ipynb
```

---

## 📂 Pliki projektu

```
├── 4_ELT_Bronze.ipynb          # warstwa Bronze
├── 5_ELT_Silver.ipynb          # ten notebook
├── 5_ELT_Silver_README.md      # ten plik
├── 6_ELT_Gold.ipynb            # agregaty i Power BI export
└── input_data_v2.csv           # dataset 500k transakcji
```

---

## 🔄 Następny krok

Po uruchomieniu Silver przejdź do **`6_ELT_Gold.ipynb`** – warstwa Gold tworzy zagregowane tabele odpowiadające na konkretne pytania biznesowe i eksportuje dane do Power BI.
