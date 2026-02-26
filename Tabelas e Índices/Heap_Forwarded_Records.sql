/***********************************************************************************************************************************
 Autor: Jhadson Santos
 
 Assunto: O objetivo do script é simular o Forwarded Records em uma tabela Heap, em uma tabela sem a presença de um índice clustered, 
 as linhas são armazenadas sem ordem lógica, pode ocorrer de uma linha já inserida (Pagina A) receber uma atualização que excede o 
 tamanho da página, com isso, a linha é movida para outra página (Pagina B), deixando um ponteiro (Forwarding Pointer) na página de 
 origem apontando para a nova localização. 

 Antes do Forwarded Records: IAM -> Página A -> Linha
 Depois do Forwarded Records: IAM -> Página A -> Ponteiro -> Página B -> Linha 

 Material de apoio: 
 https://learn.microsoft.com/en-us/sql/relational-databases/indexes/heaps-tables-without-clustered-indexes?view=sql-server-ver17
 https://learn.microsoft.com/pt-pt/sql/relational-databases/system-dynamic-management-views/sys-dm-db-index-physical-stats-transact-sql?view=sql-server-ver17
*************************************************************************************************************************************/

USE master 
GO 

/******************* Prepara Banco **********************/

DROP DATABASE IF EXISTS DB_Heap
GO 
CREATE DATABASE DB_Heap
GO 
ALTER DATABASE DB_Heap SET RECOVERY SIMPLE 
GO 

USE DB_Heap
GO 

DROP TABLE IF EXISTS dbo.TB_ForwardedRecords
GO 
CREATE TABLE dbo.TB_ForwardedRecords 
(
	ID INT IDENTITY(1,1), 
	Nome VARCHAR(60), 
	Descricao VARCHAR(8000)
)
GO 

-- Inserção de algumas linhas 
INSERT INTO dbo.TB_ForwardedRecords(Nome, Descricao) VALUES 
('Linha 1', REPLICATE('A', 2000)), 
('Linha 2', REPLICATE('B', 2000)),
('Linha 2', REPLICATE('C', 2000)),
('Linha 2', REPLICATE('D', 2000)),
('Linha 2', REPLICATE('F', 2000)) 
GO 

-- Consumo de páginas no TABLE SCAN
SET STATISTICS IO ON 
SELECT * FROM dbo.TB_ForwardedRecords
-- Table 'TB_ForwardedRecords'. Scan count 1, logical reads 2
SET STATISTICS IO OFF


-- Verifica Forwarded Records
SELECT	a.index_type_desc, 
        a.page_count,
		a.avg_page_space_used_in_percent,
		a.record_count, a.forwarded_record_count
   FROM sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID('dbo.TB_ForwardedRecords', 'U'),0,NULL,'DETAILED') as a

-- forwarded_record_count = 0

-- Provoca Forwarded Records 
UPDATE dbo.TB_ForwardedRecords
   SET Descricao = REPLICATE('X', 7000)
 WHERE ID = 1
GO 

-- Verifica Forwarded Records
SELECT	a.index_type_desc, 
        a.page_count,
		a.avg_page_space_used_in_percent,
		a.record_count, a.forwarded_record_count
   FROM sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID('dbo.TB_ForwardedRecords', 'U'),0,NULL,'DETAILED') as a

-- forwarded_record_count = 1

-- Consumo de páginas no TABLE SCAN
SET STATISTICS IO ON 
SELECT * FROM dbo.TB_ForwardedRecords
--Table 'TB_ForwardedRecords'. Scan count 1, logical reads 4
SET STATISTICS IO OFF

-- Retorna o endereço de todas as páginas que compôe a tabela
SELECT a.allocation_unit_type_desc,
	   a.is_allocated,
	   a.is_iam_page,
	   a.allocated_page_page_id,
	   a.page_free_space_percent
  FROM sys.dm_db_database_page_allocations(DB_ID(),OBJECT_ID('dbo.TB_ForwardedRecords', 'U'),0,NULL,'DETAILED') as a
 WHERE a.is_allocated = 1
 ORDER BY a.page_type DESC, a.allocated_page_page_id
-- 1a EXEC: Páginas 80(IAM) 320, 321, 322

-- Retorna em que página cada linha está
SELECT b.*, 
	   a.*
  FROM dbo.TB_ForwardedRecords as a
 CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%) AS b

-- Visualiza o conteúdo das páginas 
DBCC TRACEON(3604) 
DBCC PAGE(DB_Heap, 1, 320, 3)
/******************************************************************************
-- O registro 'Linha 1' saiu da pagina 320 e foi direcionado para a pagina 322

Record Type = FORWARDING_STUB       Record Attributes =                 Record Size = 9

Memory Dump @0x000000F7A15F8060

0000000000000000:   04420100 00010000 00                          .B.......
Forwarding to  =  file 1 page 322 slot 0 
******************************************************************************/

DBCC PAGE(DB_Heap, 1, 321, 3)

DBCC PAGE(DB_Heap, 1, 322, 3)
/******************************************************************************
-- O registro 'Linha 1' presente na página 322

Record Type = FORWARDED_RECORD      Record Attributes =  NULL_BITMAP VARIABLE_COLUMNS
Record Size = 7036                  
Memory Dump @0x000000F7A1FF8060

0000000000000000:   32000800 01000000 03000003 001a0072 1b7c9b4c  2..............r.|?L
0000000000000014:   696e6861 20315858 58585858 58585858 58585858  inha 1XXXXXXXXXXXXXX
0000000000000028:   58585858 58585858 58585858 58585858 58585858  XXXXXXXXXXXXXXXXXXXX
******************************************************************************/

USE master 
GO 

-- Exclui Banco
DROP DATABASE IF EXISTS DB_Heap