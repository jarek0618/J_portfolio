-- ============================================================
-- CDC (Change Data Capture) Demo – SQL Server
-- Portfolio project: Junior / Mid Data Engineer
-- Author: Jarosław Błaziński
-- ============================================================
-- Wymagania: SQL Server 2016+ (lub SQL Server Express)
--            Uruchom jako administrator / sa
-- ============================================================


-- ============================================================
-- KROK 1: Tworzenie bazy danych
-- ============================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'CDC_Demo')
    DROP DATABASE CDC_Demo;
GO

CREATE DATABASE CDC_Demo;
GO

USE CDC_Demo;
GO


-- ============================================================
-- KROK 2: Tworzenie tabeli transakcji (tabela źródłowa)
-- ============================================================

CREATE TABLE dbo.Transactions (
    transaction_id   INT           NOT NULL PRIMARY KEY,
    customer_id      INT           NOT NULL,
    amount           DECIMAL(10,2) NOT NULL,
    status           VARCHAR(20)   NOT NULL,   -- 'pending', 'completed', 'cancelled'
    created_at       DATETIME      NOT NULL DEFAULT GETDATE()
);
GO


-- ============================================================
-- KROK 3: Włączenie CDC na bazie danych
-- ============================================================

EXEC sys.sp_cdc_enable_db;
GO

-- Sprawdź czy CDC jest włączone na bazie
SELECT name, is_cdc_enabled
FROM sys.databases
WHERE name = 'CDC_Demo';
GO


-- ============================================================
-- KROK 4: Włączenie CDC na tabeli Transactions
-- ============================================================

EXEC sys.sp_cdc_enable_table
    @source_schema   = N'dbo',
    @source_name     = N'Transactions',
    @role_name       = NULL,          -- brak ograniczeń dostępu
    @supports_net_changes = 1;        -- umożliwia zapytania net changes
GO

-- Sprawdź czy CDC jest włączone na tabeli
SELECT
    s.name        AS schema_name,
    t.name        AS table_name,
    t.is_tracked_by_cdc
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.name = 'Transactions';
GO


-- ============================================================
-- KROK 5: Wstawianie przykładowych danych (INSERT)
-- ============================================================

INSERT INTO dbo.Transactions (transaction_id, customer_id, amount, status)
VALUES
    (1, 101, 250.00, 'pending'),
    (2, 102, 89.99,  'pending'),
    (3, 103, 420.50, 'pending');
GO

-- Poczekaj chwilę aby SQL Agent zdążył przechwycić zmiany
WAITFOR DELAY '00:00:05';
GO


-- ============================================================
-- KROK 6: Zaktualizuj dane (UPDATE)
-- ============================================================

UPDATE dbo.Transactions
SET status = 'completed', amount = 260.00
WHERE transaction_id = 1;

UPDATE dbo.Transactions
SET status = 'cancelled'
WHERE transaction_id = 2;
GO

WAITFOR DELAY '00:00:05';
GO


-- ============================================================
-- KROK 7: Usuń rekord (DELETE)
-- ============================================================

DELETE FROM dbo.Transactions
WHERE transaction_id = 3;
GO

WAITFOR DELAY '00:00:05';
GO


-- ============================================================
-- KROK 8: Podgląd surowych danych CDC
-- Tabela CDC: cdc.dbo_Transactions_CT
-- Kolumna __$operation:
--   1 = DELETE (przed usunięciem)
--   2 = INSERT
--   3 = UPDATE (wartości PRZED zmianą)
--   4 = UPDATE (wartości PO zmianie)
-- ============================================================

SELECT
    __$operation,
    CASE __$operation
        WHEN 1 THEN 'DELETE'
        WHEN 2 THEN 'INSERT'
        WHEN 3 THEN 'UPDATE (before)'
        WHEN 4 THEN 'UPDATE (after)'
    END                          AS operation_name,
    __$start_lsn                 AS lsn,
    transaction_id,
    customer_id,
    amount,
    status
FROM cdc.dbo_Transactions_CT
ORDER BY __$start_lsn, __$seqval;
GO


-- ============================================================
-- KROK 9: Audit trail – czytelny log zmian
-- Pokazuje: co się zmieniło, z jakiej wartości na jaką
-- ============================================================

SELECT
    curr.transaction_id,
    curr.customer_id,
    prev.amount        AS amount_before,
    curr.amount        AS amount_after,
    prev.status        AS status_before,
    curr.status        AS status_after,
    CASE
        WHEN curr.amount  <> prev.amount  THEN 'amount changed'
        WHEN curr.status  <> prev.status  THEN 'status changed'
        ELSE 'other'
    END                AS change_type
FROM cdc.dbo_Transactions_CT curr
JOIN cdc.dbo_Transactions_CT prev
    ON  curr.transaction_id = prev.transaction_id
    AND curr.__$operation   = 4   -- UPDATE after
    AND prev.__$operation   = 3   -- UPDATE before
ORDER BY curr.transaction_id;
GO


-- ============================================================
-- KROK 10: Net Changes – aktualny stan każdego rekordu
-- Pokazuje tylko ostatnią zmianę dla każdego transaction_id
-- ============================================================

DECLARE @from_lsn BINARY(10) = sys.fn_cdc_get_min_lsn('dbo_Transactions');
DECLARE @to_lsn   BINARY(10) = sys.fn_cdc_get_max_lsn();

SELECT
    __$operation,
    CASE __$operation
        WHEN 1 THEN 'DELETED'
        WHEN 2 THEN 'INSERTED'
        WHEN 4 THEN 'UPDATED'
    END         AS final_operation,
    transaction_id,
    customer_id,
    amount,
    status
FROM cdc.fn_cdc_get_net_changes_dbo_Transactions(@from_lsn, @to_lsn, 'all with mask')
ORDER BY transaction_id;
GO


-- ============================================================
-- KROK 11: Podsumowanie zmian (przydatne w dashboardzie)
-- ============================================================

SELECT
    CASE __$operation
        WHEN 1 THEN 'DELETE'
        WHEN 2 THEN 'INSERT'
        WHEN 3 THEN 'UPDATE (before)'
        WHEN 4 THEN 'UPDATE (after)'
    END         AS operation,
    COUNT(*)    AS count
FROM cdc.dbo_Transactions_CT
GROUP BY __$operation
ORDER BY __$operation;
GO


-- ============================================================
-- CZYSZCZENIE (opcjonalne – uruchomić tylko jeśli chcesz reset)
-- ============================================================

-- EXEC sys.sp_cdc_disable_table
--     @source_schema = N'dbo',
--     @source_name   = N'Transactions',
--     @capture_instance = N'dbo_Transactions';
-- GO

-- EXEC sys.sp_cdc_disable_db;
-- GO

-- USE master;
-- DROP DATABASE CDC_Demo;
-- GO
