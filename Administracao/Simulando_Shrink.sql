/**********************************************
 Autor: Jhadson Santos

 Simulando Shrink
 Material de apoio: 
 https://learn.microsoft.com/en-us/sql/relational-databases/databases/shrink-a-database?view=sql-server-ver16
 https://learn.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-shrinkdatabase-transact-sql?view=sql-server-ver16
***********************************************/

use master 
go 

DROP DATABASE IF Exists DB_Shrink 
go 
CREATE DATABASE DB_Shrink 
go
ALTER DATABASE DB_Shrink SET RECOVERY FULL
go

-- Cria tabela no banco DB_Shrink 
DROP TABLE IF Exists TB_Shrink 
go 
CREATE TABLE DB_Shrink.dbo.TB_Shrink 
(
	tb_Shrink_ID int identity CONSTRAINT pk_tb_Shrink PRIMARY KEY, 
	grandeColuna nchar(2000), 
	bigIntColuna bigint
)

set nocount on

use DB_Shrink
go

SELECT name AS Name, size * 8 /1024. as Tamanho_MB,  
	   FILEPROPERTY(name,'SpaceUsed') * 8 /1024. as Espaco_Utilizado_MB,
       CAST(FILEPROPERTY(name,'SpaceUsed') as decimal(10,4))
       /CAST(size as decimal(10,4)) * 100 as Percentual_Utilizado
  FROM sys.database_files
/*
Name			Tamanho_MB	Espaco_Utilizado_MB	Percentual_Utilizado
DB_TesteLog		6.250000	4.187500			67.000000000000000
DB_TesteLog_log	2.250000	1.195312			53.125000000000000
*/

-- Inclui 150.000 linhas na tabela TB_Shrink
INSERT INTO DB_Shrink.dbo.TB_Shrink (grandeColuna, bigIntColuna)
VALUES ('TESTE', 112233)
go 150000

SELECT name AS Name, size * 8 /1024. as Tamanho_MB,  
	   FILEPROPERTY(name,'SpaceUsed') * 8 /1024. as Espaco_Utilizado_MB,
       CAST(FILEPROPERTY(name,'SpaceUsed') as decimal(10,4))
       /CAST(size as decimal(10,4)) * 100 as Percentual_Utilizado
  FROM sys.database_files
/*
Name			Tamanho_MB	Espaco_Utilizado_MB	Percentual_Utilizado
DB_TesteLog		648.000000	592.062500			91.367669753086400
DB_TesteLog_log	392.000000	240.484375			61.348054846938700
*/

-- Reduzindo o espaço, mas mantém 10% de espaço livre
DBCC SHRINKDATABASE('DB_Shrink', 10)

SELECT name AS Name, size * 8 /1024. as Tamanho_MB,  
	   FILEPROPERTY(name,'SpaceUsed') * 8 /1024. as Espaco_Utilizado_MB,
       CAST(FILEPROPERTY(name,'SpaceUsed') as decimal(10,4))
       /CAST(size as decimal(10,4)) * 100 as Percentual_Utilizado
  FROM sys.database_files
/*
Name			Tamanho_MB	Espaco_Utilizado_MB	Percentual_Utilizado
DB_TesteLog		648.000000	592.062500			91.367669753086400
DB_TesteLog_log	72.000000	0.421875			0.585937500000000
*/

-- Excluindo 50% das linhas 
DELETE TOP(75000) DB_Shrink.dbo.TB_Shrink

SELECT name AS Name, size * 8 /1024. as Tamanho_MB,  
	   FILEPROPERTY(name,'SpaceUsed') * 8 /1024. as Espaco_Utilizado_MB,
       CAST(FILEPROPERTY(name,'SpaceUsed') as decimal(10,4))
       /CAST(size as decimal(10,4)) * 100 as Percentual_Utilizado
  FROM sys.database_files
/*
Name			Tamanho_MB	Espaco_Utilizado_MB	Percentual_Utilizado
DB_TesteLog		648.000000	298.562500			46.074459876543200
DB_TesteLog_log	1544.000000	400.015625			25.907747733160600
*/

USE DB_Shrink
go
DBCC SHRINKFILE (N'DB_Shrink', 350)

/*
Name			Tamanho_MB	Espaco_Utilizado_MB	Percentual_Utilizado
DB_TesteLog		350.000000	298.562500			85.285714285714200
DB_TesteLog_log	1544.000000	9.390625			0.608201101036200
*/

-- Exclui Banco DB_Shrink
use master 
go 
DROP DATABASE IF Exists DB_Shrink
