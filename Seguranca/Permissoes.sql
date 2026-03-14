/********************************************************
 Autor: Jhadson Santos
 
 Assunto: Controle de permissões 

 Material de apoio: 
 https://learn.microsoft.com/en-us/sql/t-sql/statements/grant-server-permissions-transact-sql?view=sql-server-ver16
*********************************************************/

USE master
GO 

-- Cria login 
CREATE LOGIN App_Login1 WITH PASSWORD = '<Pa$$Word>', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF
GO 

/******************* Prepara Banco **********************/

DROP DATABASE IF EXISTS DB_TESTE 
GO 
CREATE DATABASE DB_TESTE 
GO 
USE DB_TESTE
GO 

/******************* Cria Objetos **********************/
/*******************************************************
    
    Tabela - dbo.Pessoa
    Tabela - RH.Empregado
    Tabela - RH.EmpregadoHistPagamento
    Tabela - Vendas.Venda 
    Tabela - Vendas.VendasDetalhe
    
    View - Vendas.vw_Venda

    Stored Procedure: 
        Vendas.spu_Venda
        Vendas.spu_VendasDetalhe

********************************************************/


DROP TABLE IF EXISTS dbo.Pessoa
GO 
CREATE TABLE dbo.Pessoa 
(
    ID int not null constraint pk_pessoa primary key, 
    PrimeiroNome varchar(50), 
    SegundoNome varchar(50), 
    UltimoNome varchar(50)
)
GO 

INSERT INTO dbo.Pessoa (ID, PrimeiroNome, SegundoNome, UltimoNome)
SELECT BusinessEntityID, FirstName, MiddleName, LastName
FROM AdventureWorks.Person.Person
GO 

CREATE SCHEMA RH
GO

DROP TABLE IF EXISTS RH.Empregado
GO 
CREATE TABLE RH.Empregado
(
    ID int not null constraint pk_empregado primary key,
    LoginID varchar(256), 
    Sexo char(1), 
    Profissao varchar(50) 
)
GO 

INSERT INTO RH.Empregado (ID, LoginID, Sexo, Profissao) 
SELECT BusinessEntityID, LoginID, Gender,JobTitle
  FROM AdventureWorks.HumanResources.Employee
GO

DROP TABLE IF EXISTS RH.EmpregadoHistPagamento
go 
CREATE TABLE RH.EmpregadoHistPagamento
(
    ID int not null, 
    DataAltTaxa datetime, 
    Taxa money not null, 
    DataHora datetime not null, 
    constraint pk_EmpHistPag primary key(ID, DataAltTaxa) 
)
GO 

INSERT INTO RH.EmpregadoHistPagamento(ID, DataAltTaxa, Taxa, DataHora) 
SELECT BusinessEntityID, RateChangeDate, Rate, ModifiedDate
  FROM AdventureWorks.HumanResources.EmployeePayHistory
GO 


CREATE SCHEMA Vendas 
GO 

SELECT * INTO Vendas.Vendas FROM AdventureWorks.Sales.SalesOrderHeader
SELECT * INTO Vendas.VendasDetalhe FROM AdventureWorks.Sales.SalesOrderDetail
GO 

CREATE VIEW Vendas.vw_Venda 
as
SELECT a.*,b.SalesOrderDetailID,b.ProductID, b.LineTotal
FROM Vendas.Vendas a
JOIN Vendas.VendasDetalhe b ON a.SalesOrderID = b.SalesOrderID
go

go
CREATE or ALTER PROC Vendas.spu_Venda 
@SalesOrderID int
as
SELECT a.*
FROM Vendas.Vendas a
WHERE a.SalesOrderID = @SalesOrderID
go

go
CREATE or ALTER PROC Vendas.spu_Venda_Detalhe 
@SalesOrderID int
as
SELECT b.*
FROM Vendas.VendasDetalhe b
WHERE b.SalesOrderID = @SalesOrderID
go

/******************* Objetos Criados **********************/


EXECUTE AS USER = 'App_Login1'
SELECT * FROM RH.Empregado
REVERT 
GO 
/* 
Msg 15517, Level 16, State 1, Line 132
Cannot execute as the database principal because the principal "App_Login1" does not exist, 
this type of principal cannot be impersonated, or you do not have permission.
*/

-- Tentativa de conexão no banco DB_TESTE
/* 
Login failed for user 'App_Login1'. (Microsoft SQL Server, Error: 18456)
Connection Id 503d2cf9-5340-45f2-bad2-a20e50777d13 at 2026-02-26 23:14:11Z
*/

-- Concede acesso a qualquer banco
USE master
GO 
GRANT CONNECT ANY DATABASE TO App_Login1
--REVOKE CONNECT ANY DATABASE TO App_Login1

USE DB_TESTE
GO 

-- Cria usuário no Banco DB_TESTE
CREATE USER App_Login1 FOR LOGIN App_Login1
GO 

EXECUTE AS USER = 'App_Login1'
REVERT

SELECT * FROM dbo.Pessoa
SELECT * FROM RH.Empregado
SELECT * FROM RH.EmpregadoHistPagamento
SELECT * FROM Vendas.vw_Venda
 
EXEC Vendas.spu_Venda @SalesOrderID = 53478
EXEC Vendas.spu_Venda_Detalhe @SalesOrderID = 53478

-- Permissão no nível do SCHEMA
GRANT EXECUTE ON SCHEMA::Vendas TO App_Login1
REVOKE EXECUTE ON SCHEMA::Vendas TO App_Login1
GRANT EXECUTE ON SCHEMA::RH TO App_Login1
REVOKE EXECUTE ON SCHEMA::RH TO App_Login1


GRANT SELECT ON SCHEMA::Vendas TO App_Login1
DENY SELECT ON Vendas.vw_Venda TO App_Login1
GRANT SELECT ON SCHEMA::RH TO App_Login1
DENY SELECT ON RH.EmpregadoHistPagamento TO App_Login1

-- Permissão no nível do Objeto
GRANT EXECUTE ON OBJECT::Vendas.spu_Venda TO App_Login1
REVOKE EXECUTE ON Vendas.spu_Venda FROM App_Login1

GRANT SELECT ON dbo.Pessoa TO App_Login1

/*************************
 Views de Catálogo
**************************/
SELECT dp.name as usuarioBD,
       obj.name as Objeto,
       perms.state_desc as [Status],
       [permission_name] as Permissao
  FROM sys.database_permissions perms
  JOIN sys.database_principals dp ON perms.grantee_principal_id = dp.principal_id
  JOIN sys.objects obj ON perms.major_id = obj.object_id
 ORDER BY usuarioBD

 -- Exclui objetos 
 DROP DATABASE IF EXISTS DB_TESTE 

