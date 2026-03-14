/*****************************************************************************************************************************
 Autor: Jhadson Santos
 
 Assunto: Para executar consultas, o SQL Server deve analisar a instrução para determinar a melhor maneira de acessar os dados 
 necessários e processá-los. Para isso, o Otimizador de Consultas utiliza as estatísticas do banco de dados para definir um ou 
 mais planos de execução. 

 Objetivo: Demonstrar as formas de uso do Plano de Execução.

 Material de apoio: 
 https://learn.microsoft.com/pt-br/sql/relational-databases/performance/execution-plans?view=sql-server-ver16
 https://learn.microsoft.com/pt-br/sql/relational-databases/performance/display-an-actual-execution-plan?view=sql-server-ver16
 https://learn.microsoft.com/pt-br/sql/relational-databases/query-processing-architecture-guide?view=sql-server-ver16
******************************************************************************************************************************/

USE master 
GO 

/******************** Prepara Banco *************************/

DROP DATABASE IF EXISTS DB_PlanExecute 
GO 
CREATE DATABASE DB_PlanExecute
GO 

/******************* Plano de Execução **********************/

-- Formas de monstrar o Plano de Execução 

-- Texto
SET STATISTICS IO ON
SET STATISTICS IO OFF

SET STATISTICS TIME ON
SET STATISTICS TIME OFF

SET STATISTICS PROFILE ON
SET STATISTICS PROFILE OFF

-- XML
SET STATISTICS XML ON
SET STATISTICS XML OFF

-- Plano Estimado 

-- Texto
SET SHOWPLAN_ALL ON 
SET SHOWPLAN_ALL OFF

-- XML
SET SHOWPLAN_XML ON
SET SHOWPLAN_XML OFF


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
/* 
	Table 'Person'. Scan count 1, logical reads 108
	Table 'PersonCreditCard'. Scan count 1, logical reads 62
	Table 'CreditCard'. Scan count 1, logical reads 189

	Total IO: 359  * 8kb = 2872 kb = 2,80 MB
*/

SELECT h.SalesOrderID, 
	   h.OrderDate, 
	   h.[Status], 
	   h.CustomerID, 
	   p.FirstName, 
	   p.LastName
  FROM AdventureWorks.Sales.Customer c
  JOIN AdventureWorks.Sales.SalesOrderHeader h ON c.CustomerID = h.CustomerID
  JOIN AdventureWorks.Person.Person p ON p.BusinessEntityID = c.PersonID
 WHERE h.OrderDate = '20080501'
 /* 
	Table 'Person'. Scan count 1, logical reads 108
	Table 'SalesOrderHeader'. Scan count 1, logical reads 689
	Table 'Customer'. Scan count 1, logical reads 123

	Total IO: 920  * 8kb = 7360 kb = 7,18 MB
 */

-- Plano Estimado 

-- Texto
SET SHOWPLAN_ALL ON 
SET SHOWPLAN_ALL OFF

-- XML
SET SHOWPLAN_XML ON
SET SHOWPLAN_XML OFF

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

  
/*************************************
 Cria tabela no Banco DB_PlanExecute
**************************************/
USE DB_PlanExecute
GO 

DROP TABLE IF EXISTS dbo.Person 
SELECT BusinessEntityID, 'M' as PersonType, FirstName, LastName
  INTO dbo.Person
  FROM AdventureWorks.Person.Person

SET STATISTICS IO ON

-- Tabela Heap -> Table Scan
SELECT BusinessEntityID, PersonType, FirstName, LastName
  FROM dbo.Person
--Table 'Person'. Scan count 1, logical reads 112

-- Tabela com Índice Clustered -> Clustered Index Scan = Table Scan
CREATE UNIQUE CLUSTERED INDEX IX_Person_BusinessEntityID ON dbo.Person (BusinessEntityID) 

SELECT BusinessEntityID, PersonType, FirstName, LastName
  FROM dbo.Person
--Table 'Person'. Scan count 1, logical reads 114

-- clustered Index Seek 
SELECT BusinessEntityID, PersonType, FirstName, LastName
  FROM dbo.Person
 WHERE BusinessEntityID = 9995
--Table 'Person'. Scan count 0, logical reads 2

-- NonClustered Index Seek 
CREATE INDEX IX_Person_FirstName ON dbo.Person (FirstName) 

SELECT BusinessEntityID, PersonType, FirstName, LastName
  FROM dbo.Person
 WHERE FirstName = 'Carolyn'
-- Table 'Person'. Scan count 1, logical reads 114

DROP INDEX dbo.Person.IX_Person_BusinessEntityID
DROP INDEX dbo.Person.IX_Person_FirstName

-- Bookmark lookup com RID Lookup
CREATE INDEX IX_Person_FirsName ON dbo.Person(FirstName) 

SELECT BusinessEntityID, PersonType, FirstName, LastName
  FROM dbo.Person WITH(INDEX(IX_Person_FirsName))
 WHERE FirstName = 'Carolyn'
-- Table 'Person'. Scan count 1, logical reads 45

-- Bookmark lookup com Key Lookup 
CREATE UNIQUE CLUSTERED INDEX IX_Person_BusinessEntityID ON dbo.Person(BusinessEntityID) 

SELECT BusinessEntityID, PersonType, FirstName, LastName
  FROM dbo.Person WITH(INDEX(IX_Person_FirsName))
 WHERE FirstName = 'Carolyn'
-- Table 'Person'. Scan count 1, logical reads 100


-- Exclui Banco 
DROP DATABASE IF EXISTS DB_PlanExecute
GO 