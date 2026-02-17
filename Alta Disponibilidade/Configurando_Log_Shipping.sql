/********************************************************
 Autor: Jhadson Santos
 
Assunto: O objetivo do script é configurar a solução de alta disponibilidade Log Shipping do SQL Server, este tipo 
de solução permite manter bases secundárias sincronizadas com uma base primária, por meio do envio automático dos 
backups do transaction log. 


	Log shipping consists of three operations:

		1. Back up the transaction log at the primary server instance.
        2. Copy the transaction log file to the secondary server instance.
        3. Restore the log backup on the secondary server instance.

Material de apoio: 
 https://learn.microsoft.com/en-us/sql/database-engine/log-shipping/about-log-shipping-sql-server?view=sql-server-ver16
 https://learn.microsoft.com/en-us/sql/database-engine/log-shipping/configure-log-shipping-sql-server?view=sql-server-ver17&tabs=ssms
*********************************************************/

USE master
GO 

/******************* Prepara Banco **********************/

DROP DATABASE IF EXISTS DB_LogShipping
GO 
CREATE DATABASE DB_LogShipping
GO 
ALTER AUTHORIZATION ON DATABASE::DB_LogShipping TO sa 
GO 

DROP TABLE IF EXISTS DB_LogShipping.dbo.TB_Clientes
GO
CREATE TABLE DB_LogShipping.dbo.TB_Clientes
(
	Cliente_ID int identity CONSTRAINT pk_clientes PRIMARY KEY, 
	Nome char(1000), 
	Telefone char(20)
)
GO 

INSERT INTO DB_LogShipping.dbo.TB_Clientes VALUES 
('Ana', '1111-1111'),
('Bia', '2222-2222'),
('Carla', '3333-3333'),
('Dani', '4444-4444'),
('Ellen', '5555-5555'),
('Fabi', '6666-6666'),
('Gabi', '7777-7777'),
('Helena', '8888-8888'),
('Ingredi', '9999-9999'),
('Julia', '1010-1010')
GO 

SELECT * FROM DB_LogShipping.dbo.TB_Clientes
GO 

/********************************************************
 *********** Configuração do Log Shipping ***************

  1. Configurar o banco de dados com Recovery Model FULL
  2. Criar pasta compartilhada entre os servidores
  3. Permissão Read/Write na pasta compartilhada para a 
	 conta de serviço do SQL Server Agent
  4. Fazer o Backup FULL do banco no Servidor primário
  5. Copiar e Restaurar o Backup FULL no Servidor secundário, 
     utlizando a cláusula NORECOVERY
  6. Habilitar o Log Shipping na propriedades do banco de 
     dados.
********************************************************/

-- 1. Configurar o banco de dados com Recovery Model FULL

SELECT name as Banco,
	   recovery_model_desc
  FROM sys.databases
 WHERE name = 'DB_LogShipping'

ALTER DATABASE DB_LogShipping SET RECOVERY FULL

-- 2. Criar pasta compartilhada entre os servidores 

/*********************************************************
   Criar duas pastas:
    - Origem  -> C:\LogShipping
    - Destino -> C:\LogShipping

   Pasta compartilhada:
   - Origem  -> \\192.168.1.8\LogShipping
   - Destino -> \\192.168.1.10\LogShipping
*********************************************************/

-- 3. Permissão Read/Write na pasta compartilhada para a conta de serviço do SQL Server Agent

-- 4. Fazer o Backup FULL do banco no Servidor primário
BACKUP DATABASE DB_LogShipping TO DISK = '\\192.168.1.10\LogShipping\Sinc\DB_LogShipping.bak'
WITH FORMAT, COMPRESSION, STATS=5

-- 5. Copiar e Restaurar o Backup FULL no Servidor secundário, utlizando a cláusula NORECOVERY
RESTORE DATABASE DB_LogShipping FROM DISK = 'C:\LogShipping\Sinc\DB_LogShipping.bak'
WITH norecovery, replace,
MOVE 'DB_LogShipping' TO 'C:\MSSQL_\DB_LogShipping.mdf',
MOVE 'DB_LogShipping_Log' TO 'C:\MSSQL_\DB_LogShipping_Log.ldf'

-- 6. Habilitar o Log Shipping na propriedades do banco de dados.
--https://learn.microsoft.com/en-us/sql/database-engine/log-shipping/configure-log-shipping-sql-server?view=sql-server-ver17&tabs=ssms

