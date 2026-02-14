/********************************************************
 Autor: Jhadson Santos
 
 Assunto: Usando a funcionalidade de Point In Time no Restore
 Material de apoio: 
 https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/restore-a-sql-server-database-to-a-point-in-time-full-recovery-model?view=sql-server-ver17
 https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-headeronly-transact-sql?view=sql-server-ver17
*********************************************************/

USE master
GO

/******************* Prepara Banco **********************/

DROP DATABASE IF EXISTS DB_PointInTime
GO 
CREATE DATABASE DB_PointInTime
GO 

USE DB_PointInTime
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

INSERT INTO dbo.TB_Clientes(Nome, Telefone) VALUES ('Ana', '1111-1111') --2026-02-14T12:20:43
GO 

DECLARE @Arquivo VARCHAR(4000) 
SET @Arquivo = 'C:\BKP\DB_PointInTime_' + convert(char(8), getdate(), 112) + '_H' + replace(convert(char(8), getdate(), 108), ':', '') + '.bak'
--SELECT @Arquivo

BACKUP DATABASE DB_PointInTime TO DISK = @Arquivo WITH format, compression, stats=5
GO -- 2026-02-14T12:21:00

/********************* Backup LOG ************************/

INSERT INTO dbo.TB_Clientes(Nome, Telefone) VALUES ('Bia', '2222-2222') -- 2026-02-14T12:21:26
INSERT INTO dbo.TB_Clientes(Nome, Telefone) VALUES ('Carla', '3333-3333') -- 2026-02-14T12:23:48
INSERT INTO dbo.TB_Clientes(Nome, Telefone) VALUES ('Dani', '4444-4444') -- 2026-02-14T12:26:07


SELECT * FROM dbo.TB_Clientes

DECLARE @Arquivo VARCHAR(4000)
SET @Arquivo = 'C:\BKP\DB_PointInTime_' + convert(char(8), getdate(), 112) + '_H' + replace(convert(char(8), getdate(), 108), ':', '') + '.trn'


BACKUP LOG DB_PointInTime TO DISK = @Arquivo WITH format, compression
GO 
-- Completion time: 2026-02-14T12:28:22

/**********************************************************
 Restore STANDBY para permitir a leitura antes do Recovery
***********************************************************/

RESTORE DATABASE TestDB_Parcial FROM DISK = 'C:\BKP\DB_PointInTime_20260214_H122100.bak' WITH file=1, norecovery, replace,
MOVE 'DB_PointInTime' TO 'C:\MSSQL_Data\DB_PointInTime_Parcial.mdf',
MOVE 'DB_PointInTime_log' TO 'C:\MSSQL_Data\DB_PointInTime_Parcial_log.ldf'

RESTORE LOG TestDB_Parcial FROM DISK = 'C:\BKP\DB_PointInTime_20260214_H122822.trn' WITH  
standby = 'C:\BKP\DB_PointInTime_Parcial.std',
stopat = '20260214 12:21:27.000'
-- 2026-02-14T12:21:26

RESTORE LOG TestDB_Parcial FROM DISK = 'C:\BKP\DB_PointInTime_20260214_H122822.trn' WITH  
standby = 'C:\BKP\DB_PointInTime_Parcial.std',
stopat = '20260214 12:23:49.000'
-- 2026-02-14T12:23:48


RESTORE LOG TestDB_Parcial FROM DISK = 'C:\BKP\DB_PointInTime_20260214_H122822.trn' WITH  
standby = 'C:\BKP\DB_PointInTime_Parcial.std',
stopat = '20260214 12:26:08.000'
-- 2026-02-14T12:26:07

RESTORE LOG TestDB_Parcial WITH recovery

SELECT * FROM TestDB_Parcial.dbo.Tb_Clientes

-- Exclui banco
use master
go
ALTER DATABASE DB_PointInTime SET single_user WITH rollback immediate
DROP DATABASE IF exists DB_PointInTime
ALTER DATABASE TestDB_Parcial SET single_user WITH rollback immediate
DROP DATABASE IF exists TestDB_Parcial