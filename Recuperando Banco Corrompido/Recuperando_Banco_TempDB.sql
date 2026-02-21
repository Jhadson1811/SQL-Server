/*************************************************************************************************************************************
 Autor: Jhadson Santos
 
Assunto: O SQL Server possui alguns bancos de sistema, o objetivo do script é simular a recuperação do Banco TempDB, Um workspace para 
manter conjuntos de resultados temporários ou intermediários. Esse banco de dados é recriado sempre que uma instância do SQL Server é 
iniciada. Portanto, ele não é recuperado por Backup. 

Problema: Caminho inválido ou disco indisponível, o serviço do SQL Server não inicializa nestes cenários. É preciso acessar o SQL Server
com o modo SINGLE USER para inserir um novo caminho de inicialização do TempDB. 

Material de apoio: 
 https://learn.microsoft.com/pt-br/sql/relational-databases/backup-restore/back-up-and-restore-of-system-databases-sql-server?view=sql-server-ver17
**************************************************************************************************************************************/

USE tempdb 
GO 

CREATE TABLE temporaria (collumn varchar(10))
-- Reinicie o serviço do SQL Server para conferir o banco TEMPDB recriado. 

--Movendo os arquivos do Banco TempDB para outro diretório
EXEC sp_helpdb tempdb

ALTER DATABASE tempdb MODIFY FILE (name = 'tempdev', filename = 'C:\MSSQL_TEMPDB\tempdb.mdf')
ALTER DATABASE tempdb MODIFY FILE (name = 'temp2', filename = 'C:\MSSQL_TEMPDB\tempdb_mssql_2.ndf')
ALTER DATABASE tempdb MODIFY FILE (name = 'temp3', filename = 'C:\MSSQL_TEMPDB\tempdb_mssql_3.ndf')
ALTER DATABASE tempdb MODIFY FILE (name = 'temp4', filename = 'C:\MSSQL_TEMPDB\tempdb_mssql_4.ndf')
ALTER DATABASE tempdb MODIFY FILE (name = 'temp5', filename = 'C:\MSSQL_TEMPDB\tempdb_mssql_5.ndf')
ALTER DATABASE tempdb MODIFY FILE (name = 'temp6', filename = 'C:\MSSQL_TEMPDB\tempdb_mssql_6.ndf')
ALTER DATABASE tempdb MODIFY FILE (name = 'templog', filename = 'C:\MSSQL_TEMPDB\templog.ldf')

-- Renomear a pasta MSSQL_TEMPDB e mostrar o erro na inicialização
-- Iniciar o SQL Server com -f -m e alterar a localização da TEMPDB

/*************** Retorna para o diretório de origem ****************/
ALTER DATABASE tempdb MODIFY FILE (name = 'tempdev', filename = 'C:\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\tempdb.mdf')
ALTER DATABASE tempdb MODIFY FILE (name = 'temp2', filename = 'C:\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\tempdb_mssql_2.ndf')
ALTER DATABASE tempdb MODIFY FILE (name = 'temp3', filename = 'C:\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\tempdb_mssql_3.ndf')
ALTER DATABASE tempdb MODIFY FILE (name = 'temp4', filename = 'C:\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\tempdb_mssql_4.ndf')
ALTER DATABASE tempdb MODIFY FILE (name = 'temp5', filename = 'C:\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\tempdb_mssql_5.ndf')
ALTER DATABASE tempdb MODIFY FILE (name = 'temp6', filename = 'C:\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\tempdb_mssql_6.ndf')
ALTER DATABASE tempdb MODIFY FILE (name = 'templog', filename = 'C:\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\templog.ldf')