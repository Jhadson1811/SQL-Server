/********************************************************
 Autor: Jhadson Santos
 
 Assunto: Configuração de Backup e Restore
 Material de apoio: 
 https://learn.microsoft.com/en-us/sql/t-sql/statements/backup-transact-sql?view=sql-server-ver16
 https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-addumpdevice-transact-sql?view=sql-server-ver17
*********************************************************/

USE master
GO

/******************* Prepara Banco **********************/

DROP DATABASE IF EXISTS DB_BACKUP 
GO
CREATE DATABASE DB_BACKUP 
GO 

-- Cria Device 
/*
sp_addumpdevice
    [ @devtype = ] 'devtype'
    , [ @logicalname = ] N'logicalname'
    , [ @physicalname = ] N'physicalname'
    [ , [ @cntrltype = ] cntrltype ]
    [ , [ @devstatus = ] 'devstatus' ]
[ ; ]
*/

EXEC master.dbo.sp_addumpdevice  
@devtype = N'disk', 
@logicalname = N'BackupMaster', 
@physicalname = N'C:\BKP\BackupMaster.bak'
go

-- Backup Device
BACKUP DATABASE master TO BackupMaster

-- Backup File 
BACKUP DATABASE master TO DISK = 'C:\BKP\BackupMaster.bak'

/********************************************************
    Habilita a compressão do Backup na Instância 
********************************************************/

EXEC sp_configure 'show advanced options', 1
RECONFIGURE 

EXEC sp_configure 'backup compression default', 1
RECONFIGURE 

USE DB_BACKUP 
GO 

DROP TABLE IF EXISTS TB_Clientes
GO
CREATE TABLE dbo.TB_Clientes
(
	Cliente_ID int identity CONSTRAINT pk_clientes PRIMARY KEY, 
	Nome varchar(50), 
	Telefone varchar(20)
)

INSERT INTO dbo.TB_Clientes (Nome, Telefone) VALUES 
('Ana', '1111-1111'), 
('Bia', '2222-2222'), 
('Carla', '3333-3333')
GO

SELECT * FROM DB_BACKUP.dbo.TB_Clientes

/******************* Backup FULL **********************/

BACKUP DATABASE DB_BACKUP TO DISK = 'C:\BKP\DB_BACKUP.bak' WITH FORMAT, compression, stats=5

/**************** Backup Differential ******************/

INSERT INTO dbo.TB_Clientes (Nome, Telefone) VALUES 
('Dani', '4444-4444')
GO

BACKUP DATABASE DB_BACKUP TO DISK = 'C:\BKP\DB_BACKUP.bak' WITH noinit, compression, differential 

/********************* Backup LOG ***********************/

INSERT INTO dbo.TB_Clientes (Nome, Telefone) VALUES 
('Ellen', '5555-5555')
GO

BACKUP LOG DB_BACKUP TO DISK = 'C:\BKP\DB_BACKUP.bak' WITH NOINIT, compression

/********************* BackupType ***********************/
/* 
1 = FULL
2 = Transaction log
4 = File
5 = Differential database
6 = Differential file
7 = Partial
8 = Differential partial
*/
RESTORE HEADERONLY FROM DISK = 'C:\BKP\DB_BACKUP.bak'

INSERT INTO dbo.TB_Clientes (Nome, Telefone) VALUES 
('Fabi', '6666-6666')
GO


/********************************************************
 GERANDO FALHA: Pare o serviço do SQL Server e altere o 
 nome do arquivo de dados
********************************************************/

USE master
GO

BACKUP LOG DB_BACKUP TO DISK = 'C:\BKP\DB_BACKUP.bak' WITH NOINIT, COMPRESSION, NO_TRUNCATE

/********************** RESTORE ************************/

-- Backup Info
RESTORE FILELISTONLY FROM DISK = 'C:\BKP\DB_BACKUP.bak' WITH file = 1

RESTORE DATABASE DB_BACKUP FROM DISK = 'C:\BKP\DB_BACKUP.bak' WITH file=1, norecovery, replace
RESTORE DATABASE DB_BACKUP FROM DISK = 'C:\BKP\DB_BACKUP.bak' WITH file=2, norecovery
RESTORE LOG DB_BACKUP FROM DISK = 'C:\BKP\DB_BACKUP.bak' WITH file=3, norecovery
RESTORE LOG DB_BACKUP FROM DISK = 'C:\BKP\DB_BACKUP.bak' WITH file=4, recovery

-- Nenhum registro perdido
SELECT * FROM DB_BACKUP.dbo.Tb_Clientes

-- Exclui banco
use master
go
DROP DATABASE IF exists DB_BACKUP