/********************************************************
 Autor: Jhadson Santos
 
Assunto: O objetivo do script é apresentar o uso dos principais tipos de dados e funções de data e hora no SQL Server.

Tipos de dados: time, date, smalldatetime, datetime, datetime2, datetimeoffset
Funções: DATEADD, DATEDIFF, SET DATEFORMAT

Material de apoio: 
 https://learn.microsoft.com/en-us/sql/t-sql/functions/date-and-time-data-types-and-functions-transact-sql?view=sql-server-ver16
 https://learn.microsoft.com/en-us/sql/t-sql/statements/set-dateformat-transact-sql?view=sql-server-ver16
*********************************************************/


/*******************************************************************************************
	  
time -> Format = HH:mm:ss[.nnnnnnn] Accuracy 100 nanoseconds
date -> Format = yyyy-MM-dd Accuracy 1 day
smalldatetime -> Format = yyyy-MM-dd HH:mm:ss Accuracy 1 minute
datetime -> Format = yyyy-MM-dd HH:mm:ss[.nnn] Accuracy 0.00333 second
datetime2 -> Format = yyyy-MM-dd HH:mm:ss[.nnnnnnn] Accuracy 100 nanoseconds
datetimeoffset -> Format = yyyy-MM-dd HH:mm:ss[.nnnnnnn] [+|-]HH:mm Accuracy 100 nanoseconds

*******************************************************************************************/

USE master
GO 

/******************* Prepara Banco **********************/

DROP DATABASE IF EXISTS DB_DateAndTime
GO
CREATE DATABASE DB_DateAndTime
GO 

DROP TABLE IF EXISTS DB_DateAndTime.dbo.TB_Clientes
GO
CREATE TABLE DB_DateAndTime.dbo.TB_Clientes
(
	Cliente_ID int identity CONSTRAINT pk_clientes PRIMARY KEY, 
	Nome char(1000), 
	Telefone char(20), 
	HoraCadastro time not null, 
	DataHoraCadastro datetime not null,
	DiaCadastro date not null
)
GO 

INSERT INTO DB_DateAndTime.dbo.TB_Clientes (Nome, Telefone, HoraCadastro, DataHoraCadastro, DiaCadastro) 
VALUES ('Ana', '1111-1111', '12:59:00.000', '2026-02-19 12:59:000', '2026-02-19'),
('Bia', '2222-2222', '14:37:00.000', '2026-03-11 14:37:000', '2026-02-19'), 
('Carla', '3333-3333', '10:28:00.000', '2025-12-19 10:28:000', '2026-02-19') 
GO 

SELECT Nome, 
       Telefone, 
	   HoraCadastro, 
	   DataHoraCadastro, 
	   DiaCadastro
  FROM DB_DateAndTime.dbo.TB_Clientes
--DROP DB_DateAndTime.dbo.TB_Clientes

/*******************
 TIME
********************/
DECLARE @Hora time 
    SET @Hora = '15:57:28' -- 00:00:00.0000000 through 23:59:59.9999999
 SELECT @Hora

/*******************
 DATETIME
********************/
DECLARE @DataHora_datetime datetime 
    SET @DataHora_datetime = '17520101' -- 1753-01-01 through 9999-12-31
 SELECT @DataHora_datetime
/*
Msg 242, Level 16, State 3, Line 72
The conversion of a varchar data type to a datetime data type resulted in an out-of-range value.
*/ 

/*******************
 DATETIME2
********************/
DECLARE @DataHora_datetime2 datetime2 
    SET @DataHora_datetime2 = '17520101' -- 0001-01-01 00:00:00.0000000 through 9999-12-31 23:59:59.9999999
 SELECT @DataHora_datetime2

-- Precisão hora
DECLARE @DataHora3 datetime2(3)
    SET @DataHora3 = '2026-02-19 21:43:00.1234567'
 SELECT [datetime2(3)] = @DataHora3
-- 2004-02-27 16:14:00.123

DECLARE @DataHora7 datetime2(7)
    SET @DataHora7 = '2026-02-19 21:43:00.1234567'
 SELECT [datetime2(7)] = @DataHora7
-- 2004-02-27 16:14:00.1234567


DECLARE @dt datetimeoffset(0)
    SET @dt = '2026-02-19 21:45:00 -3:00' --Brasilia -- 0001-01-01 00:00:00.0000000 through 9999-12-31 23:59:59.9999999 (in UTC)
 SELECT @dt

 DECLARE @dt1 datetimeoffset(0)
    SET @dt1 = '2026-02-19 21:45:00 +8:00'  --Australia -- 0001-01-01 00:00:00.0000000 through 9999-12-31 23:59:59.9999999 (in UTC)
 SELECT @dt1

SELECT @dt,@dt1,DATEDIFF(hh,@dt,@Dt1) 'Diferença Fuso Brasilia e Australia -11'

/*********************************************************
 DATEADD (<datepart>, <number>, <date> )
 The DATEADD function returns a new datetime value by adding an interval to the specified datepart of the specified date.
*********************************************************/
SELECT Cliente_ID, 
       DataHoraCadastro, 
	   dateadd(yy,-2,DataHoraCadastro) as Menos_2anos,
       dateadd(mm,3,DataHoraCadastro) as Mais_3meses,
       dateadd(dd,20,DataHoraCadastro) as Mais_20dias
  FROM DB_DateAndTime.dbo.TB_Clientes

/*********************************************************
 DATEDIFF ( <datepart>, <startdate>, <enddate> )
 The DATEDIFF function returns the number of date or time datepart boundaries, crossed between two specified dates.
*********************************************************/

DECLARE @Data_Cadastro datetime = '20250219'
DECLARE @Data_Inativacao datetime = '20260219'

SELECT datediff(day,@Data_Cadastro,@Data_Inativacao) as Dif_Dias,
       datediff(month,@Data_Cadastro,@Data_Inativacao) as Dif_Mes

/*********************************************************
 SET DATEFORMAT { format | @format_var }   
 Is the order of the date parts. Valid parameters are mdy, dmy, ymd, ydm, myd, and dym. 
*********************************************************/


       -- Padrão mdy
DECLARE @Mes13 date = '13/12/2018'
 SELECT @Mes13
/*
Msg 241, Level 16, State 1, Line 92
Conversion failed when converting date and/or time from character string.
*/

DECLARE @Mes12 date = '12/20/2018'
 SELECT @Mes12
GO

-- Troca para dmy
SET DATEFORMAT dmy

DECLARE @Mes12 date = '20/12/2018'
 SELECT @Mes12

DECLARE @Mes20 date = '12/20/2018'
 SELECT @Mes20
/*
Msg 241, Level 16, State 1, Line 156
Conversion failed when converting date and/or time from character string.
*/

DECLARE @ANSI_Padrao date = '20231218' -- ANSI sempre funciona ymd
SELECT @ANSI_Padrao
go

-- Retorna para o padrão
SET DATEFORMAT mdy

-- Exclui Banco
DROP DATABASE IF EXISTS DB_DateAndTime
GO 