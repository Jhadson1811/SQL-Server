/*****************************************************************************************************************************
 Autor: Jhadson Santos

 Assunto: Script para conferir o uso dos indíces, a primeira consulta permite conferir a quantidade de uso das operações SEEK, 
 SCAN e LooKup, a segunda permite conferir a estrutura de colunas de cada índice e a terceira os índices duplicados. 
 
******************************************************************************************************************************/

USE AdventureWorks 
GO 

/******************** Verifica Indices *************************/


-- Quantidade de operações SEEK, SCANS e LOOKUPS 
     SELECT OBJECT_NAME(i.object_id) Tabela, 
            i.name,
            i.index_id, 
            i.type, 
            i.type_desc, 
            i.is_primary_key, 
            i.fill_factor, 
            ius.user_seeks, 
            ius.user_scans, 
            ius.user_lookups, 
            ius.user_updates, 
            ius.user_seeks + ius.user_scans + ius.user_lookups as totalOperacoes
       FROM sys.dm_db_index_usage_stats ius 
       JOIN sys.indexes i
         ON ius.object_id = i.object_id
        AND ius.index_id = i.index_id
      WHERE OBJECTPROPERTY(ius.[object_id],'IsUserTable') = 1 
   ORDER BY totalOperacoes desc


-- Estrutura de colunas do índice
       select s.name AS schema_name,
              t.name AS tabela,
              i.name, 
              STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) as colunas_indice
         from sys.index_columns ic
         join sys.indexes i 
           on ic.object_id = i.object_id 
          and ic.index_id = i.index_id 
         JOIN sys.columns c 
           on ic.object_id = c.object_id 
          and ic.column_id = c.column_id
          JOIN sys.tables t 
            ON i.object_id = t.object_id
          JOIN sys.schemas s
            ON t.schema_id = s.schema_id
         WHERE ic.is_included_column = 0
           AND i.name IS NOT NULL
      GROUP BY s.name,
               t.name, 
               i.name,
               i.type_desc
      ORDER BY s.name,
               t.name,
               i.name, 
               i.type_desc;

-- Índices duplicados 
WITH Indices as (
    
    select s.name AS schema_name,
              t.name as tabela,
              i.name as indice, 
              STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) as colunas_indice
         from sys.index_columns ic
         join sys.indexes i 
           on ic.object_id = i.object_id 
          and ic.index_id = i.index_id 
         JOIN sys.columns c 
           on ic.object_id = c.object_id 
          and ic.column_id = c.column_id
          JOIN sys.tables t 
            ON i.object_id = t.object_id
          JOIN sys.schemas s
            ON t.schema_id = s.schema_id
         where ic.is_included_column = 0
           AND i.name IS NOT NULL
      group by s.name,
               t.name, 
               i.name,
               i.type_desc    
), 
   Indices_duplicados as (
    
    select Indices.tabela, 
           Indices.colunas_indice, 
           count(*) qtde_linhas
      from Indices 
  group by Indices.tabela, 
           Indices.colunas_indice
    having count(*) > 1

   )
 
 select i.tabela, 
        i.indice, 
        i.colunas_indice
   from Indices i 
   join Indices_duplicados id 
     on i.tabela = id.tabela
    and i.colunas_indice = id.colunas_indice