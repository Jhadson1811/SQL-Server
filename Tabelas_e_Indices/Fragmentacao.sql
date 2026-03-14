/*****************************************************************************************************************
 Autor: Jhadson Santos
 
 Assunto: O índice clustered defini a ordem física dos dados na tabela. A definição de um índice clustered não 
 sequencial aumenta a frequência de divisão de páginas (Page Splits), pois ocorre a inserção de registros no meio 
 da árvore B, como consequência, temos o aumento de IO, fragmentação e baixa perfomance ao efetuar operações de INSERT. 


 Objetivo: O objetivo do script é comparar o uso de um índice clustered para uma PK sequencial e não sequencial. 

 Material de apoio: 
 https://learn.microsoft.com/pt-br/sql/relational-databases/indexes/reorganize-and-rebuild-indexes?view=sql-server-ver17
*******************************************************************************************************************/

USE master 
GO 

/******************* Prepara Banco **********************/

DROP DATABASE IF EXISTS DB_Fragmentacao
GO 
CREATE DATABASE DB_Fragmentacao
GO 

USE DB_Fragmentacao
GO

-- Cria tabela com a índice clustered sequencial 
DROP TABLE IF EXISTS dbo.Cliente_PkSequencial
GO 
CREATE TABLE dbo.Cliente_PkSequencial
(
	ClienteID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Cliente_Identity PRIMARY KEY CLUSTERED(ClienteID), 
	Nome VARCHAR(30) NOT NULL, 
	CPF VARCHAR(14) NOT NULL, 
	DataNascimento DATE NOT NULL,
	OBS CHAR(3000) NOT NULL
)

-- Cria tabela com a índice clustered não sequencial 
DROP TABLE IF EXISTS dbo.Cliente_PkRandom
GO 
CREATE TABLE dbo.Cliente_PkRandom
(
	ClienteID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() CONSTRAINT PK_Cliente_GUID PRIMARY KEY CLUSTERED(ClienteID), 
	Nome VARCHAR(30) NOT NULL, 
	CPF VARCHAR(14) NOT NULL, 
	DataNascimento DATE NOT NULL,
	OBS CHAR(3000) NOT NULL
)



/*********************************************************
    Inclui 100.000 linhas nas duas tabelas 
*********************************************************/

SET NOCOUNT ON 
GO

-- Inclui 100.000 linhas na PK sequencial ( 1min e 21s)
DECLARE @i int = 20000

WHILE @i <= 120000 
BEGIN	
	INSERT INTO dbo.Cliente_PkSequencial(Nome, CPF, DataNascimento, OBS) 
	VALUES ('Fragmentacao', ltrim(str(cast(rand(@i)*1000000000 as int))), GETDATE(), 'Campo OBS fixo 3000 bytes') 

	SET @i += 1
END 
GO 

-- Inclui 100.000 linhas na PK não sequencial ( 3min e 08s)
DECLARE @i int = 20000

WHILE @i <= 120000 
BEGIN	
	INSERT INTO dbo.Cliente_PkRandom(Nome, CPF, DataNascimento, OBS) 
	VALUES ('Fragmentacao', ltrim(str(cast(rand(@i)*1000000000 as int))), GETDATE(), 'Campo OBS fixo 3000 bytes') 

	SET @i += 1
END 
GO 

/*************** Analisa Fragmentacao *******************/

SELECT a.index_type_desc, 
	   a.index_level ,
	   a.page_count,
	   a.record_count, 
	   a.avg_page_space_used_in_percent,
	   a.forwarded_record_count,
       a.avg_fragmentation_in_percent
  FROM sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID('dbo.Cliente_PkSequencial', 'U'),NULL,NULL,'DETAILED') as a
-- Fragmentação Externa: 0.37%

SELECT a.index_type_desc, 
	   a.index_level ,
	   a.page_count,
	   a.record_count, 
	   a.avg_page_space_used_in_percent,
	   a.forwarded_record_count,
       a.avg_fragmentation_in_percent
  FROM sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID('dbo.Cliente_PkRandom', 'U'),NULL,NULL,'DETAILED') as a
-- Fragmentação Externa: 0.99%

-- Rebuild do índice random com o fator de preechimento 60%
ALTER INDEX PK_Cliente_GUID ON dbo.Cliente_PkRandom REBUILD WITH (FILLFACTOR = 60)
-- Fragmentação Externa: 0.01%

--Insere 10.000 registros após o Rebuild com o fator de preechimento
DECLARE @i int = 110000

WHILE @i <= 120000 
BEGIN	
	INSERT INTO dbo.Cliente_PkRandom(Nome, CPF, DataNascimento, OBS) 
	VALUES ('Fragmentacao', ltrim(str(cast(rand(@i)*1000000000 as int))), GETDATE(), 'Campo OBS fixo 3000 bytes') 

	SET @i += 1
END 
GO 
-- Fragmentação Externa: 0.30%

USE master
GO

-- Exlui Banco 
DROP DATABASE IF EXISTS DB_Fragmentacao
GO