/********************************************************
 Autor: Jhadson Santos
 
 Assunto: Usando a funcionalidade de Marked Transaction no Restore
 Material de apoio: 
 https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/restore-a-database-to-a-marked-transaction-sql-server-management-studio?view=sql-server-ver17
 https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/use-marked-transactions-to-recover-related-databases-consistently?view=sql-server-ver17
*********************************************************/

USE master
GO

/******************* Prepara Banco **********************/

DROP DATABASE IF EXISTS DB_MarkedTransaction
GO 
CREATE DATABASE DB_MarkedTransaction
GO 

USE DB_MarkedTransaction
GO 

DROP TABLE IF EXISTS TB_Clientes
GO
CREATE TABLE dbo.TB_Clientes
(
	Cliente_ID int identity CONSTRAINT pk_clientes PRIMARY KEY, 
	Nome varchar(50), 
	Telefone varchar(20)
)

/******************** Backup FULL ***********************/

INSERT INTO dbo.TB_Clientes(Nome, Telefone) VALUES ('Ana', '1111-1111') 
GO 

BACKUP DATABASE DB_MarkedTransaction TO DISK = 'C:\BKP\DB_MarkedTransaction.bak' WITH format, compression, stats=5
GO

/********************* Backup LOG ************************/

INSERT INTO dbo.TB_Clientes(Nome, Telefone) VALUES ('Bia', '2222-2222') 

BEGIN TRANSACTION MarkedTransaction1 WITH MARK 'Transacao 1'
INSERT INTO dbo.TB_Clientes(Nome, Telefone) VALUES ('Carla', '3333-3333') 
INSERT INTO dbo.TB_Clientes(Nome, Telefone) VALUES ('Dani', '4444-4444') 
COMMIT 

INSERT INTO dbo.TB_Clientes(Nome, Telefone) VALUES ('Ellen', '5555-5555') 
GO

BEGIN TRANSACTION MarkedTransaction2 WITH MARK 'Transacao 2'
INSERT INTO dbo.TB_Clientes(Nome, Telefone) VALUES ('Fabi', '6666-6666') 
INSERT INTO dbo.TB_Clientes(Nome, Telefone) VALUES ('Gabi', '7777-7777') 
COMMIT 

INSERT INTO dbo.TB_Clientes(Nome, Telefone) VALUES ('Helena', '8888-8888') 
GO

SELECT * FROM msdb.dbo.logmarkhistory

SELECT * FROM dbo.TB_Clientes

BACKUP LOG DB_MarkedTransaction TO DISK = 'C:\BKP\DB_MarkedTransaction.trn' WITH format, compression
GO 
-- Completion time: 2026-02-14T12:28:22

/**********************************************************
 Restore pela transação marcada
***********************************************************/

ALTER DATABASE DB_MarkedTransaction SET single_user WITH rollback immediate

RESTORE DATABASE DB_MarkedTransaction_MARK FROM DISK = 'C:\BKP\DB_MarkedTransaction.bak' WITH file=1, norecovery, replace,
MOVE 'DB_MarkedTransaction' TO 'C:\MSSQL_Data\DB_MarkedTransaction_MARK.mdf',
MOVE 'DB_MarkedTransaction_log' TO 'C:\MSSQL_Data\DB_MarkedTransaction_MARK_log.ldf'

-- Restore no final da transacao marcada MarkedTransaction1
RESTORE LOG DB_MarkedTransaction_MARK FROM DISK = 'C:\BKP\DB_MarkedTransaction.trn' WITH stopatmark = 'MarkedTransaction1',
standby = 'C:\BKP\DB_MarkedTransaction_MARK.std'

SELECT * FROM DB_MarkedTransaction_MARK.dbo.Tb_Clientes

-- Restore antes do final da transacao marcada MarkedTransaction2
RESTORE LOG DB_MarkedTransaction_MARK FROM DISK = 'C:\BKP\DB_MarkedTransaction.trn' WITH stopbeforemark = 'MarkedTransaction2',
standby = 'C:\BKP\DB_MarkedTransaction_MARK.std'

SELECT * FROM DB_MarkedTransaction_MARK.dbo.Tb_Clientes

-- Restore no final da transacao marcada MarkedTransaction2
RESTORE LOG DB_MarkedTransaction_MARK FROM DISK = 'C:\BKP\DB_MarkedTransaction.trn' WITH stopatmark = 'MarkedTransaction2',
standby = 'C:\BKP\DB_MarkedTransaction_MARK.std'

SELECT * FROM DB_MarkedTransaction_MARK.dbo.Tb_Clientes

RESTORE LOG DB_MarkedTransaction_MARK WITH recovery

-- Exclui banco
use master
go
ALTER DATABASE DB_MarkedTransaction SET single_user WITH rollback immediate
DROP DATABASE IF exists DB_MarkedTransaction
ALTER DATABASE DB_MarkedTransaction_MARK SET single_user WITH rollback immediate
DROP DATABASE IF exists DB_MarkedTransaction_MARK
TRUNCATE TABLE msdb.dbo.logmarkhistory