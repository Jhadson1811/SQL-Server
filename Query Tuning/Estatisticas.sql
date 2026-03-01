/*****************************************************************************************************************************
 Autor: Jhadson Santos
 
 Assunto: Para executar consultas, o SQL Server deve analisar a instrução para determinar a melhor maneira de acessar os dados 
 necessários e processá-los. Para isso, o Otimizador de Consultas utiliza as estatísticas do banco de dados para definir um ou 
 mais planos de execução. 

 Objetivo: Demonstrar o impacto do uso do Histograma ao gerar o Plano de Execução.

 Material de apoio: 
 https://learn.microsoft.com/pt-br/sql/relational-databases/statistics/statistics?view=sql-server-ver16
 https://www.sqlservercentral.com/articles/sql-server-trace-flags-complete-list-3
******************************************************************************************************************************/

USE master 
GO 

/******************** Prepara Banco *************************/

DROP DATABASE IF EXISTS DB_Estatistica 
GO 
CREATE DATABASE DB_Estatistica
GO 

/********************* Trivial Plan *************************/

USE DB_Estatistica
GO

-- Aba Messages
DBCC TRACEON(3604) -- Habilita saída em "Messages" (for message output to the console)
DBCC TRACEON(8605) -- Mostra a árvore de otimização da consulta Otimizador (Displays logical and physical trees used during the optimization process)
DBCC TRACEON(8675) -- Habilita mostrar as fases do Otimizador (Displays the query optimization phases for a specific optimization)

DBCC TRACEOFF(3604)
DBCC TRACEOFF(8605)
DBCC TRACEOFF(8675)

-- Verifica a ocorrência de consultas executadas com Trivial Plan
SELECT * 
  FROM sys.dm_exec_query_optimizer_info
 WHERE counter = 'trivial plan'

-- Trivial Plan
-- Ative o plano de execução atual (CTRL + M) 
-- Properties Windows (f4)
-- Selecione o SELECT no plano de execução (Optimization Level = TRIVIAL)
SELECT * 
  FROM AdventureWorks.Person.Person

-- Ativando os TraceFlags na query 
SELECT * 
  FROM AdventureWorks.Person.Person
OPTION (RECOMPILE, QUERYTRACEON 3604, QUERYTRACEON 8605, QUERYTRACEON 8675) 

-- Full Plan (Optimization Level = FULL)
 SELECT cc.CreditCardID, 
		cc.CardType, 
		p.BusinessEntityID, 
		p.FirstName, 
		p.LastName
   FROM AdventureWorks.Sales.CreditCard cc
   JOIN AdventureWorks.Sales.PersonCreditCard pc 
     ON cc.CreditCardID = pc.CreditCardID
   JOIN AdventureWorks.Person.Person p
     ON pc.BusinessEntityID = p.BusinessEntityID 
  WHERE cc.ExpYear = '2007'
 OPTION (RECOMPILE, QUERYTRACEON 3604, QUERYTRACEON 8605, QUERYTRACEON 8675) 

/*************************************
 Cria tabela no Banco DB_Estatistica
**************************************/

DROP TABLE IF EXISTS dbo.Person 
SELECT BusinessEntityID, 'M' as PersonType, FirstName, LastName
  INTO dbo.Person
  FROM AdventureWorks.Person.Person

-- Person Type 19972 = 'M'
SELECT COUNT(*), 
	   PersonType
  FROM dbo.Person
 GROUP BY PersonType

UPDATE dbo.Person
   SET PersonType = 'F'
 WHERE FirstName = 'Lanna'

-- Person Type 19971 = 'M' 1 = 'F'
SELECT COUNT(*), 
	   PersonType
  FROM dbo.Person
 GROUP BY PersonType

CREATE INDEX IX_Person_PersonType ON dbo.Person(PersonType)

SET STATISTICS IO ON 

/****************************************************
 TABLE SCAN selecionado pelo otimizador 
 Table 'Person'. Scan count 1, logical reads 112
****************************************************/
SELECT * 
  FROM dbo.Person 
 WHERE PersonType = 'M'

 /****************************************************
 Força o uso do índice nonclustered
 Table 'Person'. Scan count 1, logical reads 2002
****************************************************/
 SELECT * 
   FROM dbo.Person WITH(INDEX(IX_Person_PersonType))
  WHERE PersonType = 'M'


-- Plano de Execução 1) FULL TABLE SCAN 

SELECT rows as QtdLinhas, 
       data_pages Paginas8k 
  FROM sys.partitions p join sys.allocation_units a 
    ON p.hobt_id = a.container_id
 WHERE p.[object_id] = object_id('dbo.Person') and index_id < 2
-- QtdLinhas	Paginas8k
-- 19972		112


-- Plano de Execução 2) Index Seek + BookMark lookup 
-- Table 'Person'. Scan count 1, logical reads 2002


DBCC SHOW_STATISTICS ("dbo.Person", IX_Person_PersonType)
/* 
RANGE_HI_KEY	RANGE_ROWS	EQ_ROWS
       F	       0	      1
       M	       0	     19971
*/

/****************************************************
   Inverte a frequencia do campo PersonType
****************************************************/

UPDATE dbo.Person
   SET PersonType = CASE
						WHEN PersonType = 'F' THEN 'M'
						WHEN PersonType = 'M' THEN 'F'
                    END 
 WHERE PersonType IN('F', 'M')

 /***********************************
 Atualizando Estatísticas
************************************/
-- Atualiza todas as estatísticas da tabela Person
UPDATE STATISTICS dbo.Person

-- Atualiza a estatística do índice IX_Person_PersonType na tabela Person com SAMPLE
UPDATE STATISTICS dbo.Person(IX_Person_PersonType) WITH SAMPLE 50 PERCENT

-- Atualiza a estatística do índice IX_Person_PersonType na tabela Person com FULLSCAN
UPDATE STATISTICS dbo.Person(IX_Person_PersonType) WITH FULLSCAN

DBCC SHOW_STATISTICS ("dbo.Person", IX_Person_PersonType)
/* 
RANGE_HI_KEY	RANGE_ROWS	EQ_ROWS
       F	       0	     19971
       M	       0	       1
*/

-- O Otimizador escolhe o segundo plano devido a seletividade (Index Seek + BookMark lookup)
SELECT * 
  FROM dbo.Person 
 WHERE PersonType = 'M'
-- Table 'Person'. Scan count 1, logical reads 5

-- Exclui Banco 
DROP DATABASE IF EXISTS DB_Estatistica
GO 