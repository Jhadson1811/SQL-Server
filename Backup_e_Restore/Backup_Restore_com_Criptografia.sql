/********************************************************
 Autor: Jhadson Santos
 
 Assunto: Configuração de Backup usando Criptografia
 Material de apoio: 
 https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/backup-encryption?view=sql-server-ver17
*********************************************************/

USE master
GO 

-- Cria Master Key
-- DROP MASTER KEY
CREATE MASTER KEY ENCRYPTION BY PASSWORD= '<P4ssW0rd>';
GO

-- Exporta Master Key 
OPEN MASTER KEY DECRYPTION BY PASSWORD= '<P4ssW0rd>'

BACKUP MASTER KEY TO FILE = 'C:\BKP\master.key' 
ENCRYPTION BY PASSWORD= '<P4ssW0rd>'
GO 

-- Cria Certificado
-- DROP CERTIFICATE MyServerCert
CREATE CERTIFICATE MyServerCert WITH SUBJECT = 'Certificado para Backup Criptografado', EXPIRY_DATE = '99991231'
GO

-- Exporta Certificado 
BACKUP CERTIFICATE MyServerCert TO FILE = 'C:\BKP\MyServerCert.cer'
WITH PRIVATE KEY (FILE = 'C:\BKP\MyServerCert.key',
ENCRYPTION BY PASSWORD= '<P4ssW0rd>') 

-- Backup Criptografado
BACKUP DATABASE AdventureWorks TO DISK = 'C:\BKP\AdventureWorks_Encrypt.bak' WITH compression, stats = 10,
ENCRYPTION (ALGORITHM = AES_256, SERVER CERTIFICATE = MyServerCert)


/********************************************
 Restore do Certificado na mesma Instancia 
 do SQL Server 

 Restoring the encrypted backup: SQL Server restore doesn't require any encryption parameters to be specified during restores. 
 It does require that the certificate or the asymmetric key used to encrypt the backup file is available on the instance that 
 you're restoring to
*********************************************/


RESTORE DATABASE AdventureWorks_Encrypt FROM DISK = 'C:\BKP\AdventureWorks_Encrypt.bak' WITH recovery, stats = 10,
MOVE 'AdventureWorks2012_Data' TO 'C:\MSSQL_Data\AdventureWorks_Encrypt.mdf',
MOVE 'AdventureWorks2012_Log' TO 'C:\MSSQL_Data\AdventureWorks_Encrypt_log.ldf'


/********************************************
 Tentativa de Restore em uma Instância sem o certificado

 If you're restoring the encrypted backup to a different instance, you must make sure that the certificate is available on that instance.
*********************************************/

RESTORE DATABASE AdventureWorks_Encrypt FROM DISK = 'C:\BKP\AdventureWorks_Encrypt.bak' WITH recovery, stats = 10,
MOVE 'AdventureWorks2012_Data' TO 'C:\MSSQL_Data\AdventureWorks_Encrypt.mdf',
MOVE 'AdventureWorks2012_Log' TO 'C:\MSSQL_Data\AdventureWorks_Encrypt_log.ldf'

/********************************************
ERRO GERADO
Msg 33111, Level 16, State 3, Line 1
Cannot find server certificate with thumbprint '0x13132C8ABDFA3A573CA3B495E4163990D4BF8605'.
Msg 3013, Level 16, State 1, Line 1
RESTORE DATABASE is terminating abnormally.
********************************************/


/********************************************
  Restore do Certificado em Outra Instância
*********************************************/

CREATE MASTER KEY ENCRYPTION BY PASSWORD= '<P4ssW0rd>'

CREATE CERTIFICATE MyServerCert FROM FILE = 'C:\BKP\MyServerCert.cer' 
WITH PRIVATE KEY ( FILE = 'C:\BKP\MyServerCert.key', 
DECRYPTION BY PASSWORD = '<P4ssW0rd>')

RESTORE DATABASE AdventureWorks_Encrypt FROM DISK = 'C:\BKP\AdventureWorks_Encrypt.bak' WITH recovery, stats = 10,
MOVE 'AdventureWorks2012_Data' TO 'C:\MSSQL_Data\AdventureWorks_Encrypt.mdf',
MOVE 'AdventureWorks2012_Log' TO 'C:\MSSQL_Data\AdventureWorks_Encrypt_log.ldf'

/********************************************
RESTORE FEITO COM SUCESSO
Processed 24800 pages for database 'AdventureWorks_Encrypt', file 'AdventureWorks2012_Data' on file 1.
Processed 2 pages for database 'AdventureWorks_Encrypt', file 'AdventureWorks2012_Log' on file 1.
RESTORE DATABASE successfully processed 24802 pages in 1.192 seconds (162.551 MB/sec).
********************************************/


-- Exclui objetos
DROP CERTIFICATE MyServerCert
DROP MASTER KEY 
DROP DATABASE AdventureWorks_Encrypt