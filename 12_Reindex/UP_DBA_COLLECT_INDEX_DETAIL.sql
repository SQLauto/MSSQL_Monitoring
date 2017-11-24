
/*****************************************************************************************************************   
.   :    
.   : 2015-02-02   
. : GmarketDBA    
. : DB  Index  
.     
  - exec UP_DBA_COLLECT_INDEX_DETAIL 'REFER'
*****************************************************************************************************************   
:   
                                   
==========================================================================   
       2015-02-02    
	   2015-06-03 최보라, swap 되는 테이블 때문에 object_name으로 검색, object_id는 update 되어야 함.                         
*****************************************************************************************************************/    

ALTER PROCEDURE dbo.UP_DBA_COLLECT_INDEX_DETAIL
	@DBName varchar(100) 
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @sql nvarchar(MAX)

	SET @sql ='
	USE ['+@DBName+'];
	

	SELECT DISTINCT
					so.object_id ,
					SCHEMA_NAME(so.schema_id) AS SchemaName ,
					OBJECT_NAME(so.object_id) TableName ,
					si.Name AS IndexName ,
					si.index_id ,
					CAST(''ON'' AS VARCHAR(3)) AS ONLINEopt, -- CAST(NULL AS VARCHAR(3)) AS ONLINEopt ,
					si.type AS IndexType ,
					--p.partition_number AS partition_number,
					si.type_desc AS IndexTypeDesc ,
					is_disabled AS IsDisabled ,
					is_hypothetical AS IsHypothetical,
					ssi.rowcnt AS RowCnt,
					0 AS INDEX_SIZE_KB,
					si.IS_UNIQUE AS IsUnique,
					0 as unused_index_size_kb
			INTO    #T
			FROM    sys.indexes si WITH ( NOLOCK )
					INNER JOIN sys.objects so WITH ( NOLOCK )
					ON si.object_id = so.object_id
					INNER JOIN sys.sysindexes ssi WITH (NOLOCK)
					ON si.object_id = ssi.id and ssi.indid = si.index_id 
					--INNER JOIN sys.partitions p WITH ( NOLOCK )
					--ON si.object_id = so.object_id
			WHERE   ( so.type = ''U''
					  OR so.type = ''V''
					)
					AND so.is_ms_shipped <> 1
					--AND ssi.RowCnt > 0; 
			UPDATE A
				SET INDEX_SIZE_KB =  IndexSizeKB
					,	UNUSED_index_SIZE_KB = UNSUED_INDEX_SIZE_KB
				FROM #T A WITH(NOLOCK) 
				INNER JOIN(
					select A.object_id, A.index_id, SUM(B.used_page_count) * 8   AS IndexSizeKB, SUM(RESERVED_PAGE_COUNT-USED_PAGE_COUNT) * 8 AS UNSUED_INDEX_SIZE_KB
					from #T A WITH(NOLOCK)
					INNER JOIN sys.dm_db_partition_stats B WITH(NOLOCK) ON A.object_id = B.object_id and A.index_id = B.index_id
					group by A.object_id, A.index_id
				) AS B ON A.object_id = B.object_id and A.index_id = B.index_id;
				
			UPDATE  T
			SET     ONLINEopt = ''OFF''
			FROM    #T T
					INNER JOIN sys.all_columns AC
					ON T.object_id = AC.object_id
			WHERE   ( AC.system_type_id IN ( 34, 35, 99, 241 )
					  OR AC.max_length = -1
					)
					AND T.index_id = 1;
			UPDATE  T
			SET     ONLINEopt = ''OFF''
			FROM    #T T
					INNER JOIN sys.indexes si WITH ( NOLOCK )
					ON T.index_id = si.index_id
					   AND T.object_id = si.object_id
					INNER JOIN sys.index_columns ic WITH ( NOLOCK )
					ON si.object_id = ic.object_id
					   AND si.index_id = ic.index_id
					   AND ic.index_id = T.index_id -- Just mark the one index with the LOB column offline, not all indexes.
					INNER JOIN sys.columns sc WITH ( NOLOCK )
					ON si.object_id = sc.object_id
					   AND sc.column_id = ic.column_id
			-- is lob column
			WHERE   sc.system_type_id IN ( 34, 35, 99, 241 )
					OR sc.max_length = -1;

			--For the initial load, need to insert all index info
			declare @count int
			SELECT @count=COUNT(*) FROM DBA..DBA_REINDEX_TOTAL_LIST WITH(NOLOCK)
			if (@count = 0)
			BEGIN
				INSERT INTO DBA..DBA_REINDEX_TOTAL_LIST
				SELECT '''+@DBName+'''
				,SchemaName
				,TableName
				,IndexName
				,OBJECT_ID
				,INDEX_ID
				--,partition_number
				,1
				,IndexType
				,IndexTypeDesc
				,IsUnique
				, 
				CASE  IsDisabled
					WHEN 0 THEN ''N''
					ELSE ''Y''
				END
				,
				CASE  IsHypothetical
					WHEN 0 THEN ''N''
					ELSE ''Y''
				END
				,RowCnt
				,INDEX_SIZE_KB
				,GETDATE()
				,GETDATE()
				,unused_index_size_kb
				FROM #T 
				WHERE IndexType <> 0
				;
			END
			ELSE
			BEGIN
				--When there is an corresponding index, update
				update A
				SET 
					INDEX_TYPE = B.IndexType
					,INDEX_TYPE_DESC = B.IndexTypeDesc
					,DISABLED_YN = 
							CASE  B.IsDisabled
								WHEN 0 THEN ''N''
								ELSE ''Y''
							END
					,HYPOTHETICAL_YN =
							CASE  B.IsHypothetical
								WHEN 0 THEN ''N''
								ELSE ''Y''
							END
					,CHG_DT = GETDATE()
					,ROW_COUNT = RowCnt
					,A.INDEX_SIZE_KB = B.INDEX_SIZE_KB
					,A.IsUnique = B.IsUnique
					,A.unused_index_size_kb = B.unused_index_size_kb
					,a.object_id = b.object_id
				FROM DBA..DBA_REINDEX_TOTAL_LIST A WITH(NOLOCK) 
				INNER JOIN #T B WITH(NOLOCK) ON A.DB_NAME = '''+@DBName+''' and A.TABLE_NAME = B.TABLENAME and A.INDEX_ID = B.INDEX_ID --and A.PARTITION_NUMBER = B.partition_number

				--when there is no corresponding index, insert
				INSERT INTO DBA..DBA_REINDEX_TOTAL_LIST
				SELECT '''+@DBName+'''
				,SchemaName
				,TableName
				,IndexName
				,OBJECT_ID
				,INDEX_ID
				--,partition_number
				,1
				,IndexType
				,IndexTypeDesc
				,IsUnique
				, 
				CASE  IsDisabled
					WHEN 0 THEN ''N''
					ELSE ''Y''
				END
				,
				CASE  IsHypothetical
					WHEN 0 THEN ''N''
					ELSE ''Y''
				END
				,rowcnt
				,INDEX_SIZE_KB
				,GETDATE()
				,GETDATE()
				,UNUSED_INDEX_SIZE_KB
				FROM
				(
					select A.*, B.reg_dt as REG_DT 
						FROM #T A WITH(NOLOCK) 
						LEFT JOIN DBA..DBA_REINDEX_TOTAL_LIST B WITH(NOLOCK) ON B.DB_NAME = '''+@DBName+''' and A.TABLENAME = B.TABLE_NAME and A.INDEX_ID = B.INDEX_ID 
						--and A.PARTITION_NUMBER = B.partition_number
					WHERE A.IndexType <> 0
				) AS C
				WHERE C.reg_dt is null

			END

	DROP TABLE #T
	'

--select @sql
EXEC sp_executesql @sql
END

