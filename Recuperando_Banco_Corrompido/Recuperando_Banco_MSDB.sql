/*************************************************************************************************************************************
 Autor: Jhadson Santos
 
Assunto: O SQL Server possui alguns bancos de sistema, o objetivo do script é simular a recuperação do Banco MSDB, o banco de dados usado 
pelo SQL Server Agent para agendar alertas e trabalhos e para registrar operadores. O msdb também contém tabelas de histórico, como as 
tabelas de histórico de backup e de restauração.

Material de apoio: 
 https://learn.microsoft.com/pt-br/sql/relational-databases/backup-restore/back-up-and-restore-of-system-databases-sql-server?view=sql-server-ver17
**************************************************************************************************************************************/

USE master 
GO 


/**************** Backup FULL MASTER ********************/

BACKUP DATABASE msdb TO DISK = 'C:\BKP\msdb.bak' WITH FORMAT, COMPRESSION 

/***************** Backup DIFF MSDB *********************/

BACKUP DATABASE msdb TO DISK = 'C:\BKP\msdb.dif' WITH FORMAT, COMPRESSION, DIFFERENTIAL 

/************** ERROR Backup LOG MSDB *******************/

BACKUP LOG msdb TO DISK = 'C:\BKP\msdb.trn' WITH FORMAT, COMPRESSION

-- Modelo de recuperação: Simples

/*
Msg 4208, Level 16, State 1, Line 26
The statement BACKUP LOG is not allowed while the recovery model is SIMPLE. Use BACKUP DATABASE or change the recovery model using ALTER DATABASE.
Msg 3013, Level 16, State 1, Line 26
BACKUP LOG is terminating abnormally
*/

/******************** RESTORE MSDB **********************/

RESTORE DATABASE msdb FROM DISK = 'C:\BKP\msdb.bak' WITH RECOVERY, REPLACE

/*
Msg 3101, Level 16, State 1, Line 39
Exclusive access could not be obtained because the database is in use.
Msg 3013, Level 16, State 1, Line 39
RESTORE DATABASE is terminating abnormally.
*/

-- Pare o Serviço do SQL Agent para efetuar o RESTORE do MSDB

RESTORE DATABASE msdb FROM DISK = 'C:\BKP\msdb.bak' WITH NORECOVERY, REPLACE 
RESTORE DATABASE msdb FROM DISK = 'C:\BKP\msdb.dif' WITH RECOVERY, REPLACE
