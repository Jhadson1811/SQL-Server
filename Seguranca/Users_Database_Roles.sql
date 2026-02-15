/********************************************************
 Autor: Jhadson Santos
 
Assunto: Criacao de usuários de Banco de Dados e Database Roles

Material de apoio: 
 https://learn.microsoft.com/en-us/sql/relational-databases/security/authentication-access/create-a-database-user?view=sql-server-ver17
 https://learn.microsoft.com/en-us/sql/t-sql/statements/create-user-transact-sql?view=sql-server-ver17
 https://learn.microsoft.com/en-us/sql/relational-databases/security/authentication-access/database-level-roles?view=sql-server-ver17
*********************************************************/

USE master
GO 

/******************* Prepara Banco **********************/

DROP DATABASE IF EXISTS DB_USERS 
GO 
CREATE DATABASE DB_USERS 
GO 

-- Cria login 

CREATE LOGIN App_Login1 WITH PASSWORD = '<Pa$$Word>', CHECK_POLICY = ON, CHECK_EXPIRATION = ON
GO 

USE DB_USERS 
GO 

-- Cria usuário
CREATE USER User1 FOR LOGIN App_Login1

-- Verifica se o usuário pertence a um role 
EXECUTE AS USER = 'User1'
SELECT IS_MEMBER('public') AS is_public_member 
REVERT 
GO 

EXECUTE AS USER = 'User1'
SELECT IS_MEMBER('db_datareader') AS is_public_member 
REVERT 
GO 

-- Add usuário em dois databases roles
ALTER ROLE db_datareader ADD MEMBER User1
GO 
ALTER ROLE db_ddladmin ADD MEMBER User1
GO 

/*********************************************************

DB_DATAREADER = Members of the db_datareader fixed database 
role can read all data from all user tables and views. 
User objects can exist in any schema except sys and INFORMATION_SCHEMA.

DB_DDLADMIN = Definition Language (DDL) command in a database. 
Members of this role can potentially elevate their privileges 
by manipulating code that might get executed under high privileges 
and their actions should be monitored.
++++++++++++++++++++++++++++++++++++++++++++++++++++++****/

-- Verifica os Roles do usuário 
SELECT rdp.name AS role_name, 
       rdm.name AS member_name
  FROM sys.database_role_members AS rm
  JOIN sys.database_principals AS rdp
    ON rdp.principal_id = rm.role_principal_id
  JOIN sys.database_principals AS rdm
    ON rdm.principal_id = rm.member_principal_id
 WHERE rdm.name = 'User1'
 ORDER BY role_name, member_name

 -- Exclui objetos 
 USE DB_USERS 
 GO 
 DROP USER User1 

 USE master
 GO 
 DROP LOGIN App_Login1

 DROP DATABASE IF EXISTS DB_USERS 