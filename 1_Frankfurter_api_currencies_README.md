# Waluty API Frankfurter – Apache Airflow DAG

DAG pobierający kursy walut z API [Frankfurter](https://www.frankfurter.app/) i zapisujący je do pliku CSV gotowego do otwarcia w programie Excel.

---

## Opis działania

Skrypt łączy się z publicznym API Frankfurter, pobiera aktualne kursy wymiany względem PLN, a następnie oblicza 6 par walutowych i zapisuje wynik do pliku `.csv` na pulpicie użytkownika.

**Obliczane pary walut:**

| Para | Opis |
|------|------|
| EUR/PLN | Kurs euro do złotego |
| USD/PLN | Kurs dolara do złotego |
| GBP/PLN | Kurs funta do złotego |
| EUR/USD | Kurs euro do dolara |
| GBP/USD | Kurs funta do dolara |
| EUR/GBP | Kurs euro do funta |

---

## Wymagania

- Python 3.8+
- Apache Airflow 2.x
- Pakiet `requests` (`pip install requests`)
- Dostęp do internetu (API Frankfurter jest publiczne i bezpłatne)

---

## Instalacja i konfiguracja

1. Skopiuj plik `waluty_api_frankfurter.py` do folderu `dags/` w swoim środowisku Airflow.
2. Upewnij się, że pakiet `requests` jest zainstalowany w środowisku, w którym działa Airflow.
3. DAG pojawi się automatycznie w interfejsie Airflow po odświeżeniu listy DAGów.

---

## Harmonogram

DAG uruchamia się **co poniedziałek o godzinie 10:00** (UTC).

```
schedule: '0 10 * * 1'
```

Parametr `catchup=False` oznacza, że Airflow nie będzie nadrabiać pominiętych uruchomień po przerwie lub pierwszym włączeniu.

---

## Wynik działania

Plik CSV jest zapisywany w folderze:

```
~/Desktop/Raporty_Walutowe/kursy_YYYY-MM-DD_HH-MM.csv
```

Folder jest tworzony automatycznie, jeśli nie istnieje. Każde uruchomienie tworzy nowy plik z timestampem w nazwie.

Plik jest przygotowany pod Excel – zawiera nagłówek `sep=;` oraz separatora `;` zamiast przecinka. Liczby używają przecinka jako separatora dziesiętnego (format polski). Kodowanie: `UTF-8 BOM` (dla poprawnego wyświetlania polskich znaków w Excelu).

**Przykładowa zawartość pliku:**

```
sep=;
Para walut;Kurs;Data pobrania
EUR/PLN;4,2150;2026-01-06 10:00:00
USD/PLN;3,9870;2026-01-06 10:00:00
GBP/PLN;5,0320;2026-01-06 10:00:00
...
```

---

## Uruchamianie ręczne

Skrypt można uruchomić bezpośrednio (poza Airflow) w celach testowych:

```bash
python waluty_api_frankfurter.py
```

---

## Obsługa błędów

- Wszystkie błędy (sieciowe, błędy API, problemy z zapisem pliku) są logowane przez standardowy logger Airflow.
- W przypadku błędu task zostaje oznaczony jako `FAILED`, co umożliwia ponowne uruchomienie z poziomu UI Airflow.

---

## Źródło danych

API: [https://www.frankfurter.app/](https://www.frankfurter.app/)  
Dane pochodzą z Europejskiego Banku Centralnego (EBC). API jest bezpłatne i nie wymaga klucza.
