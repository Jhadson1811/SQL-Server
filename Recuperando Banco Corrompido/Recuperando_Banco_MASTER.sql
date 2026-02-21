/*************************************************************************************************************************************
 Autor: Jhadson Santos
 
Assunto: O SQL Server possui alguns bancos de sistema, o objetivo do script é simular a recuperação do Banco Master, o banco de dados que 
registra todas as informações de nível de sistema para um sistema SQL Server.

Dois cenários: 
 1. O SQL Server inicializa. 
	Restaure o Backup da Master com a instância em modo monousuário.
 2. O SQL Server não inicializa. 
	Realize o REBUILD dos Bancos de Sistema
	Restaure o Backup da Master com a instância em modo monousuário.

 Por que é importante ter backups regulares do Banco Master? O Banco armazena todas as informações a nível de sistema do SQL Server. Exemplos: 
	1. Configurações da instância
	2. Lista de banco de dados
	3. Logins e seus SID
	4. Configurações de servidor e endereços de arquivos
	5. Referências de jobs, linked servers, configurações de segurança. 

Material de apoio: 
 https://learn.microsoft.com/pt-br/sql/relational-databases/backup-restore/back-up-and-restore-of-system-databases-sql-server?view=sql-server-ver17
 https://learn.microsoft.com/pt-br/sql/relational-databases/backup-restore/restore-the-master-database-transact-sql?view=sql-server-ver17
 https://learn.microsoft.com/pt-br/sql/database-engine/configure-windows/database-engine-service-startup-options?view=sql-server-ver17
**************************************************************************************************************************************/

USE master 
GO 

/******************* Prepara Banco **********************/

DROP DATABASE IF EXISTS DB_TESTE 
GO 
CREATE DATABASE DB_TESTE
GO 

CREATE LOGIN TESTE1 WITH PASSWORD = '<P4ssW0rd>'
GO 

/**************** Backup FULL MASTER ********************/

BACKUP DATABASE master TO DISK = 'C:\BKP\master.bak' WITH FORMAT, COMPRESSION 

/************* ERROR Backup DIFF MASTER *****************/

BACKUP DATABASE master TO DISK = 'C:\BKP\master.bak' WITH FORMAT, COMPRESSION, DIFFERENTIAL 

/*
Msg 3024, Level 16, State 0, Line 46
You can only perform a full backup of the master database. Use BACKUP DATABASE to back up the entire master database.
Msg 3013, Level 16, State 1, Line 46
BACKUP DATABASE is terminating abnormally.
*/

/**************** 1° Cenário de Recuperação ******************/
/************************************************************
1. O SQL Server inicializa. 
   Restaure o Backup da Master com a instância em modo monousuário.

Inicie uma instância de servidor no modo de usuário único.
 Iniciar a instância com os parâmetros de inicialiazação -f e -m 
 -f = Inicia uma instância do SQL Server com configuração mínima.
 -m = Inicia uma instância do SQL Server em modo de usuário único.

 Ou 

cd C:\Program Files\Microsoft SQL Server\MSSQLXX.instance\MSSQL\Binn
sqlservr -c -f -s <instance> -mSQLCMD
  O -mSQLCMD parâmetro garante que somente o sqlcmd possa se conectar ao SQL Server.
  Para um nome de instância padrão, use -s MSSQLSERVER
  -c inicia o SQL Server como um aplicativo para ignorar o Gerenciador 
   de Controle de Serviço a fim de reduzir o tempo de inicialização

*************************************************************/

/*
Abra o SQLCMD e execute o RESTORE do Backup
*/

RESTORE DATABASE master FROM DISK = 'C:\BKP\master.bak' WITH REPLACE

/*
Processed 552 pages for database 'master', file 'master' on file 1.
Processed 2 pages for database 'master', file 'mastlog' on file 1.
The master database has been successfully restored. Shutting down SQL Server.
SQL Server is terminating this process.
*/

--Remove os parametros de inicialiazação no SQL Configuration
--Inicialize o serviço da Instância no SQL Configuration

/**************** 2° Cenário de Recuperação ******************/
/************************************************************
2. O SQL Server não inicializa. 
	Realize o REBUILD dos Bancos de Sistema
	Restaure o Backup da Master com a instância em modo monousuário.

 Rebuild
 cd C:\Program Files\Microsoft SQL Server\170\Setup Bootstrap\SQL2025
 setup /QUIET /ACTION=REBUILDDATABASE /INSTANCENAME=InstanceName /SQLSYSADMINACCOUNTS=accounts [ /SAPWD= StrongPassword ] [ /SQLCOLLATION=CollationName ]
************************************************************/

RESTORE DATABASE master FROM DISK = 'C:\BKP\master.bak' WITH REPLACE

