/*************************************************************************************************************************************
 Autor: Jhadson Santos
 
Assunto: O SQL Server possui limite de 8060 bytes para linhas em tabelas com campos fixos. No entanto, é permitido exceder esse limite 
para campos variáveis.O SQL Server, permite o estouro de linha, quando o valor de 8060 bytes é ultrapassado, o SQL Server Database Engine 
move a coluna de registro com a maior largura para outra página na unidade de alocação ROW_OVERFLOW_DATA, mantendo um ponteiro de 24 bytes 
na página original.

Objetivo: Demonstrar a restrição de 8060 bytes para linha em uma tabela com campos fixos, e exemplificar o estouro de linha para registros 
que ultrapassam a quantidade de 8060 bytes. 

Material de apoio: 
 https://learn.microsoft.com/en-us/previous-versions/sql/sql-server-2008-r2/ms186981(v=sql.105)
 https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-service-capacity-limits
 https://learn.microsoft.com/en-us/sql/relational-databases/pages-and-extents-architecture-guide?view=sql-server-ver17#large-row-support
**************************************************************************************************************************************/

USE DB_TESTE 
GO 


/*****************************************************************
 Tabela com tamanho de linha superior a 8060 bytes
*****************************************************************/

DROP TABLE IF EXISTS dbo.Teste_Fixo 
GO 
CREATE TABLE dbo.Teste_Fixo
(
	Col1 char(2000), 
	Col2 char(2000), 
	Col3 char(2000), 
	Col4 char(2000), 
	Col5 char(61)
)

/*
Msg 1701, Level 16, State 1, Line 28
Creating or altering table 'Teste_Fixo' failed because the minimum row size would be 8068, including 7 bytes of internal overhead. 
This exceeds the maximum allowable table row size of 8060 bytes.
*/

DROP TABLE IF EXISTS dbo.Teste_Fixo 
GO 
CREATE TABLE dbo.Teste_Fixo
(
	Col1 char(2000), 
	Col2 char(2000), 
	Col3 char(2000), 
	Col4 char(2000), 
	Col5 char(52)  -- Tira os 7 bytes of internal overhead
)

/* 
Commands completed successfully.
Completion time: 2026-02-23T20:35:25.3676047-03:00
*/


/*****************************************************************
 Tabela com tamanho de linha superior a 8060 bytes e com colunas 
 de tamanho variável 
*****************************************************************/

DROP TABLE IF EXISTS dbo.Teste_Variavel 
GO 
CREATE TABLE dbo.Teste_Variavel 
(
	Col1 char(2000), 
	Col2 char(2000), 
	Col3 char(2000), 
	Col4 varchar(2000), -- varchar pode ser armazenado off-row
	Col5 varchar(2000)  -- varchar pode ser armazenado off-row
)

/* 
Commands completed successfully.
Completion time: 2026-02-23T20:40:19.5233246-03:00
*/

SELECT object_name(object_id) Nome,
       partition_number pnum,
       hobt_id,rows,
       a.allocation_unit_id au_id,a.[type], 
	   a.total_pages pages
  FROM sys.partitions p JOIN sys.system_internals_allocation_units a
    ON p.partition_id = a.container_id
 WHERE object_name(object_id) LIKE '%Teste%'

 /*
- Type 3 indica que o valor de uma coluna varchar() ultrapassou o limite dos 8060 bytes,
  deixando um ponteiro junto da linha e armazenando as informacoes em paginas out-of-row.
- Type 2 (max)
- Type 1 indica pagina dentro da linha.
*/


-- -- Paginas Tipo 1, 2 e 3 
DROP TABLE IF EXISTS dbo.Teste_Variavel_Max
GO 
CREATE TABLE dbo.Teste_Variavel_Max
(
	Col1 char(2000), 
	Col2 char(2000), 
	Col3 char(2000), 
	Col4 varchar(2000), -- varchar pode ser armazenado off-row
	Col5 varchar(max)  -- varchar pode ser armazenado off-row
)

-- Exclui tabelas
DROP TABLE IF exists dbo.Teste_Fixo
DROP TABLE IF exists dbo.Teste_Variavel
DROP TABLE IF exists dbo.Teste_Variavel_Max

