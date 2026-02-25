import requests
import csv
import os
import logging
from datetime import datetime, timedelta
from airflow import DAG

try:
    from airflow.providers.standard.operators.python import PythonOperator
except ImportError:
    from airflow.operators.python import PythonOperator

# Konfiguracja logowania (ważne dla Airflow)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def pobierz_i_zapisz_kursy():
    url = "https://api.frankfurter.app/latest?from=PLN&symbols=EUR,USD,GBP"
    teraz = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    plik_timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M")
    
    try:
        logger.info("Rozpoczynam pobieranie danych z API Frankfurter...")
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        rates = data['rates']
        
        def excel_format(num):
            return str(round(num, 4)).replace('.', ',')

        rows = [
            ["EUR/PLN", excel_format(1 / rates['EUR']), teraz],
            ["USD/PLN", excel_format(1 / rates['USD']), teraz],
            ["GBP/PLN", excel_format(1 / rates['GBP']), teraz],
            ["EUR/USD", excel_format(rates['USD'] / rates['EUR']), teraz],
            ["GBP/USD", excel_format(rates['USD'] / rates['GBP']), teraz],
            ["EUR/GBP", excel_format(rates['GBP'] / rates['EUR']), teraz]
        ]

        # Tworzenie folderu na pulpicie, jeśli nie istnieje
        path_to_save = os.path.join(os.path.expanduser("~"), 'Desktop', 'Raporty_Walutowe')
        if not os.path.exists(path_to_save):
            os.makedirs(path_to_save)
            
        sciezka_pliku = os.path.join(path_to_save, f"kursy_{plik_timestamp}.csv")

        with open(sciezka_pliku, mode='w', newline='', encoding='utf-8-sig') as f:
            # Trik dla Excela: informujemy go o separatorze w pierwszej linii
            f.write("sep=;\n") 
            writer = csv.writer(f, delimiter=';')
            writer.writerow(['Para walut', 'Kurs', 'Data pobrania'])
            writer.writerows(rows)
            
        logger.info(f"Sukces! Plik zapisany w: {sciezka_pliku}")

    except Exception as e:
        logger.error(f"Wystąpił błąd: {e}")
        raise

# --- DAG ---
with DAG(
    dag_id='waluty_v1_production',
    start_date=datetime(2026, 1, 1),
    schedule='0 10 * * 1', 
    catchup=False
) as dag:
    task = PythonOperator(task_id='pobierz_waluty', python_callable=pobierz_i_zapisz_kursy)

if __name__ == "__main__":
    pobierz_i_zapisz_kursy()