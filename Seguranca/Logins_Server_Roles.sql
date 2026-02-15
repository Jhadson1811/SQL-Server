/********************************************************
 Autor: Jhadson Santos
 
Assunto: Gerenciamento de Logins e Server Roles

Material de apoio: 
 https://learn.microsoft.com/en-us/sql/relational-databases/security/authentication-access/create-a-login?view=sql-server-ver17
 https://learn.microsoft.com/en-us/sql/t-sql/statements/create-login-transact-sql?view=sql-server-ver17
 https://learn.microsoft.com/en-us/sql/t-sql/statements/create-server-role-transact-sql?view=sql-server-ver17
 https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-server-role-transact-sql?view=sql-server-ver17
*********************************************************/

Use master
GO

-- Cria Login SQL Server 
CREATE LOGIN App_Login1 WITH PASSWORD = '<Pa$$Word>', CHECK_POLICY = ON , CHECK_EXPIRATION = ON 
CREATE LOGIN App_Login2 WITH PASSWORD = '<Pa$$Word>', CHECK_POLICY = ON , CHECK_EXPIRATION = ON
GO 

/*********************************************************
************ Applies to SQL Server logins only ***********

CHECK_POLICY = Specifies that the Windows password policies 
of the computer on which SQL Server is running should be 
enforced on this login.

CHECK_EXPIRATION =  Specifies whether password expiration 
policy should be enforced on this login. The default value 
is OFF.
++++++++++++++++++++++++++++++++++++++++++++++++++++++****/

-- Desabilita Login SQL Server
ALTER LOGIN App_Login1 DISABLE
GO

-- Cria Login com uma senha que deve ser trocada no primeiro login 
CREATE LOGIN App_Login3 WITH PASSWORD = '<Pa$$Word>'
    MUST_CHANGE, CHECK_EXPIRATION = ON;
GO

/************** Gerenciamento de Roles ********************/

-- Verifica as permissões atuais do Login 
EXECUTE AS LOGIN = 'App_Login2'
SELECT * 
  FROM sys.fn_my_permissions (null, 'SERVER') 
REVERT 

-- Adiciona Login a um Role
ALTER SERVER ROLE diskadmin ADD MEMBER App_Login2
GO

SELECT IS_SRVROLEMEMBER ('diskadmin', 'App_Login1') 
SELECT IS_SRVROLEMEMBER ('diskadmin', 'App_Login2') 
/*********************************************************
DISKADMIN = Members of the diskadmin fixed server role can 
manage disk files.
*********************************************************/

-- Lista de roles que um login faz parte
SELECT spr.name as Role_Name, 
       spm.name as Member_Name
  FROM sys.server_role_members rm
  JOIN sys.server_principals spr ON spr.principal_id = rm.role_principal_id
  JOIN sys.server_principals spm ON spm.principal_id = rm.member_principal_id
--WHERE spm.name = 'App_Login2'
 ORDER BY role_name, member_name

 -- Exclui Objetos 
 DROP LOGIN App_Login1
 DROP LOGIN App_Login2
 DROP LOGIN App_Login3