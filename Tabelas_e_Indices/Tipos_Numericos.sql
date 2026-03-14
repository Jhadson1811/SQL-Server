/********************************************************
 Autor: Jhadson Santos
 
Assunto: O objetivo do script é apresentar o uso dos principais tipos de dados númerico no SQL Server.

Tipos de dados: bigint, int, smallint, tinyint
decimal, float
money, smallmoney
Material de apoio: 
 https://learn.microsoft.com/en-us/sql/t-sql/data-types/int-bigint-smallint-and-tinyint-transact-sql?view=sql-server-ver16
 https://learn.microsoft.com/en-us/sql/t-sql/data-types/decimal-and-numeric-transact-sql?view=sql-server-ver17
 https://learn.microsoft.com/en-us/sql/t-sql/data-types/float-and-real-transact-sql?view=sql-server-ver17
*********************************************************/


/*******************************************************************************************

bigint -> Range = -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807 Storage 8 bytes	  
int -> Range = -2,147,483,648 to 2,147,483,647 Storage 4 bytes
smallint -> Range = -32,768 to 32,767 Storage 2 bytes
tinyint -> Range = 0 to 255 Storage 1 bytes

*******************************************************************************************/

USE master 
GO 

/******************* Prepara Banco **********************/

DROP DATABASE IF EXISTS DB_tiposNumericos
GO
CREATE DATABASE DB_tiposNumericos
GO 

DROP TABLE IF EXISTS DB_tiposNumericos.dbo.TiposNumericos
CREATE TABLE DB_tiposNumericos.dbo.TiposNumericos (
    Col_TinyInt TINYINT,
    Col_SmallInt SMALLINT,
    Col_Int INT,
    Col_BigInt BIGINT,
    Col_Decimal DECIMAL(1,0),
    Col_Float FLOAT,
    Col_Real REAL,
    Col_Money MONEY
);

INSERT INTO DB_tiposNumericos.dbo.TiposNumericos VALUES
-- Range mínimo para cada tipo de dado númerico 
(0, -32768, -2147483648, -9223372036854775808, -9, - 1.79E+308, - 3.40E+38, -922337203685477.5808 ),
-- Range máximo para cada tipo de dado númerico (Exceto Decimal, pois depende da precisao e escala Decimal(p, s))  
(255, -32767, -2147483647, 9223372036854775807, 9, 1.79E+308,  3.40E+38, -922337203685477.5807 )


SELECT Col_TinyInt,
       Col_SmallInt,
       Col_Int,
       Col_BigInt,
       Col_Decimal,
       Col_Float,
       Col_Real,
       Col_Money 
  FROM DB_tiposNumericos.dbo.TiposNumericos
--DROP DB_tiposNumericos.dbo.TiposNumericos


/*******************
 BIGINT
********************/
DECLARE @bigint bigint 
    SET @bigint = 9223372036854775807 + 1
 SELECT @bigint
/*
 Msg 8115, Level 16, State 2, Line 67
Arithmetic overflow error converting expression to data type bigint.
*/


/*******************
 INT
********************/
DECLARE @int int 
    SET @int = -2147483648
 SELECT @int

/*******************
 SMALLINT
********************/
DECLARE @SmallInt smallint 
    SET @SmallInt = -32.768
 SELECT @SmallInt

/*******************
 TINYINT
********************/
DECLARE @tinyint tinyint 
    SET @tinyint = 222
 SELECT @tinyint


/*********************************************************
 decimal [ ( p [ , s ] ) ] and numeric [ ( p [ , s ] ) ]
 p (precision) s (scale)
 Precision	Storage bytes
  1 - 9	        5
  10-19	        9
  20-28	       13
  29-38	       17
*********************************************************/

-- decimal(12,4) = 99999999.9999
DECLARE @Teste1 decimal(12,4) = 9999.9999
DECLARE @Teste2 numeric(12,4) = 9999.9999
SELECT @Teste1, @Teste2
GO

-- Arredonda se excede as casas decimais
DECLARE @Teste1 decimal(12,4) = 9999.999888
 SELECT @Teste1
-- 9999.999888 -> 9999.9999
GO

/*********************************************************
 money Range -922,337,203,685,477.5808 to 922,337,203,685,477.5807 8 bytes
 smallmoney Range -214,748.3648 to 214,748.3647 4 bytes
*********************************************************/

-- Máximo de precisão 4 casas decimais
DECLARE @Teste1 money = 9999.999888
DECLARE @Teste2 smallmoney = 9999.999888
SELECT @Teste1, @Teste2
-- 9999.999888 -> 9999,9999
GO

/*********************************************************
 float [ (n) ] Where n is the number of bits that are used 
 to store...
 n value	Precision	Storage size
 1-24	    7 digits	    4 bytes
 25-53	   15 digits	    8 bytes
*********************************************************/

DECLARE @Teste1 float(25) = 10.12345678901234567891
DECLARE @Teste2 real = 10.12345678901234567891
SELECT @Teste1, @Teste2
GO

/***************************************************************
 PROBLEMA FLOAT: Não é preciso para comparações, SQL Server armazena
 uma aproximação. 

 Pode causar problemas para valores financeiros, use DECIMAL.
****************************************************************/
DECLARE @Teste1 float = 0.1
DECLARE @Teste2 float = 0.2

SELECT CASE WHEN @Teste1 + @Teste2 = 0.3 THEN 1 ELSE 0 END
GO

-- Com DECIMAL funciona
DECLARE @Teste1 decimal(10,1) = 0.1
DECLARE @Teste2 decimal(10,1) = 0.2

SELECT CASE WHEN @Teste1 + @Teste2 = 0.3 THEN 1 ELSE 0 END
GO

-- Exclui Banco
DROP DATABASE IF EXISTS DB_tiposNumericos
GO 