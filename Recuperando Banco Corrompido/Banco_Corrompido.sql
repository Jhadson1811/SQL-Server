/********************************************************
 Autor: Jhadson Santos
 
Assunto: O objetivo do script é corromper um banco de dados e, em seguida, recuperá-lo por meio do DBCC CHECKDB. 
Para isso, alteramos a estrutura física de uma página de dados (data page), provocando uma inconsistência. 
Posteriormente, simulamos dois cenários: a recuperação com perda de dados (REPAIR_ALLOW_DATA_LOSS) e a recuperação sem perda de dados, 
aplicável a casos de corrupção em páginas de índice.

Material de apoio: 
 https://learn.microsoft.com/pt-br/sql/t-sql/database-console-commands/dbcc-checkdb-transact-sql?view=sql-server-ver16
 https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/database-file-operations/troubleshoot-dbcc-checkdb-errors
 https://techcommunity.microsoft.com/blog/sqlserver/how-to-use-dbcc-page/383094
*********************************************************/

USE master 
GO 

/******************* Prepara Banco **********************/

DROP DATABASE IF EXISTS DB_CHECKDB
GO 
CREATE DATABASE DB_CHECKDB
GO 

DROP TABLE IF EXISTS DB_CHECKDB.dbo.TB_Clientes
GO
CREATE TABLE DB_CHECKDB.dbo.TB_Clientes
(
	Cliente_ID int identity CONSTRAINT pk_clientes PRIMARY KEY, 
	Nome char(1000), 
	Telefone char(20)
)
GO 

INSERT INTO DB_CHECKDB.dbo.TB_Clientes VALUES 
('Ana', '1111-1111'),
('Bia', '2222-2222'),
('Carla', '3333-3333'),
('Dani', '4444-4444'),
('Ellen', '5555-5555'),
('Fabi', '6666-6666'),
('Gabi', '7777-7777'),
('Helena', '8888-8888'),
('Ingredi', '9999-9999'),
('Julia', '1010-1010')
GO 

CREATE UNIQUE INDEX ixu_Tb_clientes_Nome ON DB_CHECKDB.dbo.TB_clientes (Nome)
GO 

SELECT * FROM DB_CHECKDB.dbo.TB_Clientes 

-- Backup FULL e Backup LOG 
BACKUP DATABASE DB_CHECKDB TO DISK = 'C:\BKP\DB_CHECKDB.bak' WITH format, compression
BACKUP LOG DB_CHECKDB TO DISK = 'C:\BKP\DB_CHECKDB.trn' WITH format, compression 

/********************************************************
DBCC IND - Lista as páginas de um objeto no banco de dados
1  - Data Page
2  - Index Page
10 - IAM Page
********************************************************/

DBCC TRACEON (2588) -- Habilita o uso do DBCC HELP
DBCC HELP('IND')
DBCC IND(DB_CHECKDB, 'Tb_Clientes', -1) 

/*************** Corrompendo Data Page ******************/

DBCC TRACEON (2588) -- Habilita o uso do DBCC HELP
DBCC HELP('PAGE')

DBCC TRACEON (3604) -- Habilita o uso do DBCC PAGE
DBCC PAGE(DB_CHECKDB, 1, 240, 3) --WITH NO_INFOMSGS, TABLERESULTS 

/********************************************************
DBCC PAGE - Usado para examinar o conteúdo das páginas 
https://techcommunity.microsoft.com/blog/sqlserver/how-to-use-dbcc-page/383094
dbcc PAGE ( {'dbname' | dbid}, filenum, pagenum [, printopt={0|1|2|3} ])
********************************************************/

/********************************************************
NUNCA EXECUTE O COMANDO ABAIXO EM AMBIENTE DE PRODUCAO 
Não gera escrita no Transaction Log
Não tem ROLLBACK
********************************************************/
DBCC HELP ('WRITEPAGE')

ALTER DATABASE DB_CHECKDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DBCC WRITEPAGE ('DB_CHECKDB',1,240, 4000,1, 0x45, 1)
ALTER DATABASE DB_CHECKDB SET  MULTI_USER WITH NO_WAIT

SELECT * FROM DB_CHECKDB.dbo.Tb_Clientes WHERE Nome = 'Ana' -- Error 
SELECT * FROM DB_CHECKDB.dbo.Tb_Clientes WHERE Nome = 'Julia' -- OK 

-- TRUNCATE TABLE msdb..suspect_pages
SELECT * FROM msdb..suspect_pages

-- Verifica a integridade
DBCC CHECKDB (DB_CHECKDB) WITH NO_INFOMSGS ,TABLERESULTS

-- Corrige a inconsistência
ALTER DATABASE DB_CHECKDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DBCC CHECKDB (DB_CHECKDB,REPAIR_ALLOW_DATA_LOSS)
ALTER DATABASE DB_CHECKDB SET  MULTI_USER WITH NO_WAIT

-- Registros perdido após corrigir a inconsistência
SELECT * FROM DB_CHECKDB.dbo.Tb_Clientes

/*************** Corrompendo Indice ******************/

DBCC IND (DB_CHECKDB,'Tb_Clientes',-1)

ALTER DATABASE DB_CHECKDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DBCC WRITEPAGE ('DB_CHECKDB',1,280,4000,1, 0x45, 1)
ALTER DATABASE DB_CHECKDB SET  MULTI_USER WITH NO_WAIT

DBCC CHECKDB (DB_CHECKDB) WITH NO_INFOMSGS ,TABLERESULTS

ALTER DATABASE DB_CHECKDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DBCC CHECKDB (DB_CHECKDB,REPAIR_ALLOW_DATA_LOSS)
ALTER DATABASE DB_CHECKDB SET  MULTI_USER WITH NO_WAIT

-- Sem perda de dados para páginas de índices 
SELECT * FROM DB_CHECKDB.dbo.Tb_Clientes

-- Exclui banco
DROP DATABASE If exists DB_CHECKDB

