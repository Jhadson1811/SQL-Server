/*****************************************************************************************************************************
 Autor: Jhadson Santos

 Assunto: O Covering Index é uma estratégia de indexação, consiste em criar uma cobertura total dos campos solicitados na query. 
 Dessa forma, não ocorre acesso DataPage (Table) e nem operações de Bookmark lookup. Consequentemente, redução de logical reads, 
 uso de CPU e tempo de resposta. 
 
 Objetivo: Demonstrar estratégias de Covering Index e a criação de índices para os operadores AND e OR. 

******************************************************************************************************************************/

USE master 
GO 

/******************** Prepara Banco *************************/

DROP DATABASE IF EXISTS DB_CoveringIndex 
GO 
CREATE DATABASE DB_CoveringIndex
GO 


/*************************************
 Cria tabela no Banco DB_CoveringIndex
**************************************/

DROP TABLE IF EXISTS dbo.TransactionHistory
SELECT TransactionID, ProductID, ReferenceOrderID, ReferenceOrderlineID, TransactionDate, TransactionType, 
Quantity, ActualCost, ModifiedDate
  INTO dbo.TransactionHistory
  FROM AdventureWorks.Production.TransactionHistory

-- IX_TransactionHistory_ReferenceOrderID indice não cobre a consulta 
 CREATE INDEX IX_TransactionHistory_ReferenceOrderID ON dbo.TransactionHistory(ReferenceOrderID) 

 SET STATISTICS IO ON 

 SELECT ReferenceOrderID, ProductID, TransactionDate, ActualCost
   FROM dbo.TransactionHistory WITH(INDEX(IX_TransactionHistory_ReferenceOrderID))
  WHERE ReferenceOrderID BETWEEN 41590 AND 57000
-- Qt linhas 28.996
-- Table Scan -> Table 'TransactionHistory'. Scan count 1, logical reads 790
-- Index Seek + RID Lookup Table 'TransactionHistory'. Scan count 7, logical reads 29198

/*************************************************************
     Recriando o índice com a estratégia Covering Index
**************************************************************/

 CREATE INDEX IX_TransactionHistory_ReferenceOrderID ON dbo.transactionHistory(ReferenceOrderID)
 INCLUDE (ProductID, TransactionDate, ActualCost) 
 WITH DROP_EXISTING 

  SELECT ReferenceOrderID, ProductID, TransactionDate, ActualCost
   FROM dbo.TransactionHistory --WITH(INDEX(0))
  WHERE ReferenceOrderID BETWEEN 41590 AND 57000
-- Qt linhas 28.996
-- Index Seek -> Table 'TransactionHistory'. Scan count 1, logical reads 141
-- Table Scan -> Table 'TransactionHistory'. Scan count 1, logical reads 790

DROP INDEX dbo.transactionHistory.IX_TransactionHistory_ReferenceOrderID

/*************************************************************
     Estratégia de Indexação para o operador AND
     Indicado definir o índice na cláusula mais seletiva
**************************************************************/

CREATE INDEX IX_TransactionHistory_ReferenceOrderID ON dbo.transactionHistory(ReferenceOrderID) 
INCLUDE (ProductID, TransactionDate, ActualCost)

CREATE INDEX IX_TransactionHistory_ProductID ON dbo.transactionHistory(ProductID) 
INCLUDE (ReferenceOrderID, TransactionDate, ActualCost)

SELECT * FROM dbo.TransactionHistory where ProductID = 800
--Table 'TransactionHistory'. Scan count 1, logical reads 790
SELECT * FROM dbo.TransactionHistory where ReferenceOrderID = 57593
--Table 'TransactionHistory'. Scan count 1, logical reads 6

-- O otimizador vai escolher o índice mais seletivo 
SELECT ReferenceOrderID, 
       ProductID, 
       TransactionDate, 
       ActualCost
  FROM dbo.TransactionHistory WITH(INDEX(IX_TransactionHistory_ProductID))
 WHERE ProductID = 800 AND ReferenceOrderID = 57593
-- Index Seek: Table 'TransactionHistory'. Scan count 1, logical reads 3
-- Utilizou o índice IX_TransactionHistory_ReferenceOrderID

-- Ao forçar o uso do índice IX_TransactionHistory_ProductID
-- Table 'TransactionHistory'. Scan count 1, logical reads 5

DROP INDEX dbo.TransactionHistory.IX_TransactionHistory_ReferenceOrderID
DROP INDEX dbo.TransactionHistory.IX_TransactionHistory_ProductID


/*************************************************************
  Estratégia de Indexação para o operador OR
  Indicado definir um índice para cada cláusula, se não faz Scan
**************************************************************/

-- Estratégia Indexação para OR
CREATE INDEX IX_TransactionHistory_ReferenceOrderID ON dbo.transactionHistory(ReferenceOrderID) 
INCLUDE (ProductID, TransactionDate, ActualCost)

-- Estratégia Indexação para OR
CREATE INDEX IX_TransactionHistory_ProductID ON dbo.transactionHistory(ProductID) 
INCLUDE (ReferenceOrderID, TransactionDate, ActualCost)

SELECT ReferenceOrderID, 
       ProductID, 
       TransactionDate, 
       ActualCost
  FROM dbo.TransactionHistory WITH(INDEX(IX_TransactionHistory_ReferenceOrderID))
 WHERE ProductID = 800 OR ReferenceOrderID = 57593

 -- Indíce selecionado pelo Otimizador = IX_TransactionHistory_ProductID
 -- Index Seek -> Table 'TransactionHistory'. Scan count 2, logical reads 8
 
 -- Sem índice  
 -- Table Scan -> Table 'TransactionHistory'. Scan count 1, logical reads 790

 -- Forcando o usdo do índice IX_TransactionHistory_ReferenceOrderID
 -- Index Scan -> Table 'TransactionHistory'. Scan count 1, logical reads 539

 -- Exclui Banco 

 USE master
 go 

 DROP DATABASE IF EXISTS DB_CoveringIndex
 GO 