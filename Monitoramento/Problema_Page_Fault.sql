/***********************************************************

Autor: Jhadson Santos 

Assunto: Simulando problema de Hard Page Fault - SQL Server

Objetivo: esgotar a memória disponível, fazer o Windows usar 
a paginação para disco. 

***********************************************************/

use master 
go 

/***********************************************************
 Prepara Teste
***********************************************************/

DROP DATABASE IF EXISTS DB_PageFault
go
CREATE DATABASE DB_PageFault
go

USE DB_PageFault
go 

EXEC sys.sp_configure 'show advanced options', 1;
RECONFIGURE;

EXEC sys.sp_configure N'max server memory (MB)', N'3000'
GO
RECONFIGURE WITH OVERRIDE
GO

--Cria tabela grande 

CREATE TABLE dbo.TesteMemoria (

	ID INT IDENTITY PRIMARY KEY, 
	texto CHAR(4000)
)
GO 

--Popula a tabela com muitos dados 

INSERT INTO dbo.TesteMemoria (texto) 
SELECT TOP (2000000) REPLICATE('X', 4000) 
FROM sys.objects a 
CROSS JOIN sys.objects B
go


/***********************************************************
Use SqlQueryStress para gerar diversas consultas ao mesmo 
tempo 
***********************************************************/

SELECT texto, 
	   COUNT(*) 
  FROM dbo.TesteMemoria
 GROUP BY texto
 ORDER BY COUNT(*) DESC;
 
 
 /***********************************************************

Monitore os contadores no PerfMon: 

Windows
Memory\Available MBytes
Memory\Page Reads/sec
Memory\Pages/sec
Memory\Page Faults/sec

SQL Server
SQLServer:Memory Manager\Memory Grants Pending
SQLServer:Buffer Manager\Page Life Expectancy
***********************************************************/
