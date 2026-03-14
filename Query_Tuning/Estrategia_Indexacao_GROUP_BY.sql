/*****************************************************************************************************************************
 Autor: Jhadson Santos
 
 Assunto: Estratégias de índices para GROUP BY
******************************************************************************************************************************/

USE master 
GO 

/******************** Prepara Banco *************************/

DROP DATABASE IF EXISTS DB_Teste
GO 
CREATE DATABASE DB_Teste
GO 

/********************* Cria Tabelas *************************/

USE DB_Teste
GO

DROP TABLE IF EXISTS dbo.Person
GO 
SELECT BusinessEntityID, PersonType, FirstName, MiddleName, 
LastName, ModifiedDate INTO dbo.Person FROM AdventureWorks.Person.Person

DROP TABLE IF EXISTS dbo.Customer 
SELECT * INTO dbo.Customer from AdventureWorks.Sales.Customer

/************************************************************
                  GROUP BY com JOIN 
*************************************************************/
       set statistics io on 

       SELECT c.TerritoryID, 
              p.FirstName, 
              count(p.FirstName) qtdeNomePorRegiao
         FROM dbo.Customer c
         JOIN dbo.Person p
           ON c.PersonID = p.BusinessEntityID
        WHERE p.ModifiedDate >= '20050101' AND p.ModifiedDate < '20070101'
     GROUP BY TerritoryID, 
              FirstName
     ORDER BY TerritoryID, 
              FirstName

 /*
 ---- Consulta sem índíces ----
 Table 'Customer'. Scan count 1, logical reads 155
 Table 'Person'. Scan count 1, logical reads 146   2.35MB
 */


 CREATE INDEX dta_index_Customer ON [dbo].[Customer]([PersonID] ASC, [TerritoryID] ASC)
 CREATE INDEX dta_index_Person ON [dbo].[Person]([BusinessEntityID] ASC,[ModifiedDate] ASC,[FirstName] ASC)
 DROP INDEX dta_index_Customer ON dbo.Customer
 DROP INDEX dta_index_Person ON dbo.Person
  /*
 ---- Consulta executada com a sugestão do Database Engine Tuning Advisor (DTA)
 Table 'Person'. Scan count 1, logical reads 106
 Table 'Customer'. Scan count 1, logical reads 56  1.26MB
 */


 CREATE INDEX IX_Person_BusinessEntityID ON dbo.Person(BusinessEntityID)
 CREATE INDEX IX_Customer_PersonID ON dbo.Customer(PersonID) 
 DROP INDEX IX_Person_BusinessEntityID ON dbo.Person 
 DROP INDEX IX_Customer_PersonID on dbo.Customer

  /*
 Table 'Customer'. Scan count 1, logical reads 155
 Table 'Person'. Scan count 1, logical reads 145  2.34MB
 */

 CREATE INDEX IX_Person_BusinessEntityID_ModifiedDate ON dbo.Person(ModifiedDate, BusinessEntityID)
 CREATE INDEX IX_Customer_PersonID_TerritoryID ON dbo.Customer(PersonID, TerritoryID) 

 DROP INDEX IX_Person_BusinessEntityID_ModifiedDate ON dbo.Person
 DROP INDEX IX_Customer_PersonID_TerritoryID ON dbo.Customer

 /*
 Table 'Customer'. Scan count 1, logical reads 146
 Table 'Person'. Scan count 1, logical reads 56  1.57MB
 */

 CREATE INDEX IX_Person_BusinessEntityID_ModifiedDate ON dbo.Person(ModifiedDate, BusinessEntityID)
 INCLUDE (FirstName)

 DROP INDEX IX_Person_BusinessEntityID_ModifiedDate ON dbo.Person

  /*
 Table 'Customer'. Scan count 1, logical reads 26
 Table 'Person'. Scan count 1, logical reads 56  0.64MB
 */

/************************************************************
                  GROUP BY com uma tabela
*************************************************************/

    SELECT COUNT(p.BusinessEntityID) qtdeNomes, 
           p.FirstName
      FROM Person p
     WHERE p.ModifiedDate >= '20050101' AND p.ModifiedDate < '20070101'
  GROUP BY p.FirstName
  ORDER BY qtdeNomes desc

 /*
   Sem índice algum
   Table 'Person'. Scan count 1, logical reads 145  1.13MB
 */

  CREATE INDEX IX_Person_FirstName_ModifiedDate ON dbo.Person(FirstName, ModifiedDate) 
  CREATE INDEX IX_Person_ModifiedDate_FirstName ON dbo.Person(ModifiedDate, FirstName) 


  -- 50% cost
    SELECT COUNT(p.BusinessEntityID) qtdeNomes, 
           p.FirstName
      FROM Person p
     WHERE p.ModifiedDate >= '20050101' AND p.ModifiedDate < '20070101'
  GROUP BY p.FirstName
  ORDER BY qtdeNomes desc

  --50% cost
     SELECT COUNT(p.BusinessEntityID) qtdeNomes, 
           p.FirstName
      FROM Person p with(index(IX_Person_FirstName_ModifiedDate))
     WHERE p.ModifiedDate >= '20050101' AND p.ModifiedDate < '20070101' 
  GROUP BY p.FirstName
  ORDER BY qtdeNomes desc


-- Exclui Banco 
DROP DATABASE IF EXISTS DB_Teste
GO 

