/********************************************************
 Autor: Jhadson Santos
 
 Assunto: Configuração do Transparent Data Encryption (TDE)
 Material de apoio: 
 https://learn.microsoft.com/pt-br/sql/relational-databases/security/encryption/transparent-data-encryption?view=sql-server-ver16
 https://learn.microsoft.com/pt-br/sql/t-sql/statements/create-certificate-transact-sql?view=sql-server-ver16
*********************************************************/

USE master
GO

/******************* Prepara Banco **********************/

DROP DATABASE IF EXISTS DB_TDE
GO
CREATE DATABASE DB_TDE
GO 

USE DB_TDE
GO

DROP TABLE IF EXISTS TB_Clientes
GO
CREATE TABLE dbo.TB_Clientes
(
	Cliente_ID int identity CONSTRAINT pk_clientes PRIMARY KEY, 
	Nome varchar(50), 
	Telefone varchar(20)
)

INSERT INTO dbo.TB_Clientes (Nome, Telefone) VALUES 
('Ana', '1111-1111'), 
('Bia', '2222-2222'), 
('Carla', '3333-3333')
GO

SELECT * FROM dbo.TB_Clientes

/******************* Habilitar a TDE ********************/

/*
Aplica-se a: SQL Server.

1. Crie uma chave mestra.
2. Crie ou obtenha um certificado protegido pela chave mestra.
3. Crie uma chave de criptografia de banco de dados e proteja-a usando o certificado.
4. Defina o banco de dados para usar criptografia.
*/

USE master
GO 

-- Cria Master Key
-- DROP MASTER KEY
CREATE MASTER KEY ENCRYPTION BY PASSWORD= '<P4ssW0rd>';
GO

-- Cria Certificado
-- DROP CERTIFICATE MyServerCert
CREATE CERTIFICATE MyServerCert WITH SUBJECT = 'Certificado para TDE - BancoTDE', EXPIRY_DATE = '99991231'
GO

-- Gera Backup do Certificado 
BACKUP CERTIFICATE MyServerCert TO FILE = 'C:\TDE\Backup\MyServerCert.cer'
WITH PRIVATE KEY (FILE = 'C:\TDE\Backup\MyServerCert.key', 
ENCRYPTION BY PASSWORD = '<P4ssW0rd>')


/*************** Habilitando TDE ******************/ 

USE DB_TDE;
GO

CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_256
    ENCRYPTION BY SERVER CERTIFICATE MyServerCert;
GO

ALTER DATABASE DB_TDE
    SET ENCRYPTION ON;
GO

/**************************
Gera Backup com criptografia
***************************/

BACKUP DATABASE DB_TDE TO DISK = 'C:\TDE\Backup\DB_TDE.bak' WITH INIT, COMPRESSION
GO

-- Status do Banco criptografado
SELECT name as Banco, is_encrypted 
  FROM sys.databases 
 WHERE name = 'DB_TDE'

/*******************************
Erro ao restaurar o Backup em outra 
Instancia do SQL Server
********************************/

RESTORE DATABASE DB_TDE FROM DISK = 'C:\TDE\Backup\DB_TDE.bak' WITH
move 'DB_TDE' to 'C:\Program Files\Microsoft SQL Server\MSSQL17.NAMED\MSSQL\DATA\DB_TDE.mdf',
move 'DB_TDE_Log' to 'C:\Program Files\Microsoft SQL Server\MSSQL17.NAMED\MSSQL\DATA\DB_TDE_Log.ldf'

/*
Msg 33111, Level 16, State 3, Line 1
Cannot find server certificate with thumbprint '0x6F5817AAE09470E6685F7E2CB9529173D4FD10A3'.
Msg 3013, Level 16, State 1, Line 1
RESTORE DATABASE is terminating abnormally
*/

-- Cria Master Key
USE master
GO
-- DROP MASTER KEY
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<P4ssW0rd>'
GO

-- Importa Certificado
-- DROP CERTIFICATE MyServerCert
CREATE CERTIFICATE MyServerCert FROM FILE = 'C:\TDE\Backup\MyServerCert.cer'
WITH PRIVATE KEY ( FILE = 'C:\TDE\Backup\MyServerCert.key', 
DECRYPTION BY PASSWORD = '<P4ssW0rd>')
GO

-- Restaura o banco com sucesso

RESTORE DATABASE DB_TDE FROM DISK = 'C:\TDE\Backup\DB_TDE.bak' WITH
move 'DB_TDE' to 'C:\Program Files\Microsoft SQL Server\MSSQL17.NAMED\MSSQL\DATA\DB_TDE.mdf',
move 'DB_TDE_Log' to 'C:\Program Files\Microsoft SQL Server\MSSQL17.NAMED\MSSQL\DATA\DB_TDE_Log.ldf'

-- DROP
USE master
go
DROP DATABASE IF exists DB_TDE
DROP CERTIFICATE MyServerCert
DROP MASTER KEY