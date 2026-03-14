/********************************************************
 Autor: Jhadson Santos
 
 Assunto: O objetivo do script é percorrer as páginas do índice clustered, simulando a navegação 
 Root Page -> Intermediate Level -> Leaf Level (Data Page)

 Material de apoio: 
 https://learn.microsoft.com/pt-br/sql/relational-databases/indexes/clustered-and-nonclustered-indexes-described?view=sql-server-ver17
 https://learn.microsoft.com/pt-br/sql/relational-databases/sql-server-index-design-guide?view=sql-server-ver17
*********************************************************/

USE master 
GO 

/******************* Prepara Banco **********************/

DROP DATABASE IF EXISTS DB_IndiceClustered
GO
CREATE DATABASE DB_IndiceClustered
GO 

DROP TABLE IF EXISTS [DB_IndiceClustered].[dbo].[Customer]
GO 
CREATE TABLE [DB_IndiceClustered].[dbo].[Customer](
	[CustomerID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PersonID] [int] NULL,
	[StoreID] [int] NULL,
	[TerritoryID] [int] NULL,
	[AccountNumber] varchar(10),
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL
 )

 CREATE CLUSTERED INDEX  IX_CustomerID ON [DB_IndiceClustered].[dbo].[Customer] (CustomerID)
 GO 

 INSERT INTO DB_IndiceClustered.dbo.Customer (PersonID, StoreID, TerritoryID, AccountNumber, rowguid, ModifiedDate) 
 SELECT PersonID, StoreID, TerritoryID, AccountNumber, rowguid, ModifiedDate
   FROM AdventureWorks.Sales.Customer
 GO 100

 SELECT * FROM DB_IndiceClustered.dbo.Customer 

 USE DB_IndiceClustered
 GO 

 SET STATISTICS IO ON 
 GO 
 SELECT AccountNumber
   FROM dbo.Customer
  WHERE CustomerID = 7500 -- AccountNumber AW00017798
 SET STATISTICS IO OFF
 --logical reads 2

-- Verifica a profundidade do índice
/* 
	1 ? só leaf
	2 ? root + leaf
	3 ? root + intermediate + leaf
*/ 

SELECT index_type_desc,
       index_depth,
       page_count
  FROM sys.dm_db_index_physical_stats
(
    DB_ID(),
    OBJECT_ID('dbo.Customer'),
    1,
    NULL,
    'DETAILED'
);
GO

-- Encontrando a ROOT PAGE
CREATE TABLE #IND
(
    PageFID INT,
    PagePID INT,
    IAMFID INT,
    IAMPID INT,
    ObjectID INT,
    IndexID INT,
    PartitionNumber INT,
    PartitionID BIGINT,
    iam_chain_type VARCHAR(30),
    PageType INT,
    IndexLevel INT,
    NextPageFID INT,
    NextPagePID INT,
    PrevPageFID INT,
    PrevPagePID INT
);

INSERT INTO #IND
EXEC ('DBCC IND (''DB_IndiceClustered'', ''Customer'', 1)');


-- Encontre a página com o maior IndexLevel = ROOT
SELECT *
  FROM #IND
 WHERE IndexLevel = (SELECT MAX(IndexLevel) FROM #IND);


--Nivel Raiz
DBCC TRACEON (3604);
GO
DBCC PAGE ('DB_IndiceClustered', 1, 16258, 3);
GO
-- Busca AccountNumber AW00017798 CustomerID 7500
/*
	ChildPageId 16256 -> CustomerID NULL
	ChildPageId 16257 -> CustomerID 77005
*/

--Nivel Intermediario
-- Busca AccountNumber AW00017798 CustomerID 7500
DBCC PAGE ('DB_IndiceClustered', 1, 16256, 3);
GO
-- Busca AccountNumber AW00017798 CustomerID 7500
/*
	ChildPageId 16540 -> CustomerID 7441
	ChildPageId 16541 -> CustomerID 7565
*/

--Nivel Folha
-- Registro encontrado
DBCC PAGE ('DB_IndiceClustered', 1, 16540, 3);
GO
-- Busca AccountNumber AW00017798 CustomerID 7500
/*
Record Type = PRIMARY_RECORD        Record Attributes =  NULL_BITMAP VARIABLE_COLUMNS
Record Size = 63                    
Memory Dump @0x00000035441F8EE5

0000000000000000:   30002c00 4c1d0000 bb350000 4c030000 0a000000  0.,.L...»5..L.......
0000000000000014:   cd248968 037aba42 97d43d5c 9ada32a3 736db900  Í$?h.zºB?Ô=\?Ú2£sm¹.
0000000000000028:   349b0000 08000802 0035003f 00415730 30303137  4?.......5.?.AW00017
000000000000003C:   373938                                        798    

Slot 59 Column 0 Offset 0x0 Length 4 Length (physical) 0
*/

USE master
GO

-- Exclui Banco
DROP DATABASE IF EXISTS DB_IndiceClustered
GO