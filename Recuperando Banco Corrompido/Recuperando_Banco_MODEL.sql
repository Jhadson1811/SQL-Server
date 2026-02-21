/*************************************************************************************************************************************
 Autor: Jhadson Santos
 
Assunto: O SQL Server possui alguns bancos de sistema, o objetivo do script é simular a recuperação do Banco MODEL, O modelo para todos 
os bancos de dados criados na instância do SQL Server.

Problema: Se banco Modelo corromper, não é possível criar o Banco TempDB ao reiniciar a instância do SQL Server

Material de apoio: 
 https://learn.microsoft.com/pt-br/sql/relational-databases/backup-restore/back-up-and-restore-of-system-databases-sql-server?view=sql-server-ver17
**************************************************************************************************************************************/

USE master 
GO 

-- Inicialize o SQL Server com o parametro de inicialização -t3608
-- TRACE FLAG 3608 permite inicializar a instância sem o TEMPDB
/*****************************************************************
TRACE FLAG 3608: Function: Prevents SQL Server from automatically 
starting and recovering any database except the master database. 
If activities that require tempdb are initiated, then model is 
recovered and tempdb is created. Other databases will be started 
and recovered when accessed
*****************************************************************/

-- Realize o Backup no SQLCMD 
BACKUP DATABASE master TO DISK = 'C:\BKP\master.bak' WITH format,compression
BACKUP DATABASE msdb TO DISK = 'C:\BKP\msdb.bak' WITH format,compression

/************************************************************
 1) Rebuild
 cd C:\Program Files\Microsoft SQL Server\170\Setup Bootstrap\SQL2025
 setup /QUIET /ACTION=REBUILDDATABASE /INSTANCENAME=InstanceName /SQLSYSADMINACCOUNTS=accounts [ /SAPWD= StrongPassword ] [ /SQLCOLLATION=CollationName ]

 2) Inicie a instância com os parametros de inicialização -f e -m

 3) Restore com o SQLCMD
************************************************************/

-- Restore Banco Master
RESTORE DATABASE master FROM DISK = 'C:\BKP\master.bak' WITH REPLACE

-- Restore MSDB
RESTORE DATABASE msdb FROM DISK = 'C:\BKP\msdb.bak' WITH recovery, REPLACE