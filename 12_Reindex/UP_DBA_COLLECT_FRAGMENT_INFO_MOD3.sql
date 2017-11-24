use dba
go




/*****************************************************************************************************************   
. 작 성 자: 전세환   
. 작 성 일: 2015-02-02   
. 유지보수: GmarketDBA팀 전세환   
. 기능구분: DBA_REINDEX_INFO_LOG 기반으로 단편화 정보 수집
. 실행예제    
  - exec UP_DBA_COLLECT_FRAGMENT_INFO_MOD0 
*****************************************************************************************************************   
변경내역:   
        수정일자        수정구분        수정자        수정내용   
==========================================================================   
       2015-02-02                    전세환        신규생성 
*****************************************************************************************************************/   
ALTER PROCEDURE dbo.UP_DBA_COLLECT_FRAGMENT_INFO_MOD0
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @currIndex BIGINT 

	DECLARE ReindexTargets CURSOR READ_ONLY
		FOR
			--끝나지 않은 entry 로 LOG_SEQ 기준으로 처리
			--mod 0
			SELECT A.LOG_SEQ FROM DBA_REINDEX_INFO_LOG A WITH(NOLOCK)
				INNER JOIN DBA_REINDEX_TOTAL_LIST B WITH(NOLOCK) ON A.INDEX_SEQ = B.INDEX_SEQ
			WHERE LOG_SEQ % 3 = 0 AND EXEC_END_DT IS NULL
			ORDER BY LOG_SEQ
		OPEN ReindexTargets

		FETCH NEXT FROM ReindexTargets INTO @currIndex
		WHILE ( @@fetch_status <> -1 ) 
			BEGIN
				declare @DB_NM varchar(20)
				declare @SCHEMA_NM varchar(50)
				declare @TABLE_NM varchar(300)
				declare @INDEX_ID bigint

				SELECT @DB_NM = DB_NAME, @SCHEMA_NM = SCHEMA_NAME, @TABLE_NM = TABLE_NAME, @INDEX_ID = INDEX_ID
				FROM DBA_REINDEX_TOTAL_LIST A WITH(NOLOCK) 
				INNER JOIN DBA_REINDEX_INFO_LOG B WITH(NOLOCK) ON A.INDEX_SEQ = B.INDEX_SEQ
				WHERE B.LOG_SEQ = @currIndex

				declare @table varchar(300)
				set @table = '['+@DB_NM+'].['+@SCHEMA_NM+'].['+@TABLE_NM+']'

				UPDATE DBA..DBA_REINDEX_INFO_LOG 
					SET DBA_REINDEX_INFO_LOG.EXEC_START_DT = GETDATE()
				WHERE DBA_REINDEX_INFO_LOG.LOG_SEQ = @currIndex
			
				begin try

					
				SELECT * INTO #T
				FROM sys.dm_db_index_physical_stats(DB_ID(@DB_NM), OBJECT_ID(@table), @INDEX_ID, NULL, 'DETAILED')
				
				IF @@ROWCOUNT = 0 
				BEGIN
					delete DBA..DBA_REINDEX_INFO_LOG  where LOG_SEQ = @currIndex
					
				END
				ELSE 
				BEGIN
					
					UPDATE DBA..DBA_REINDEX_INFO_LOG 
						SET DBA_REINDEX_INFO_LOG.ALLOC_UNIT_TYPE_DESC = B.ALLOC_UNIT_TYPE_DESC
						,DBA_REINDEX_INFO_LOG.INDEX_DEPTH = B.INDEX_DEPTH
						,DBA_REINDEX_INFO_LOG.INDEX_LEVEL = B.INDEX_LEVEL
						,DBA_REINDEX_INFO_LOG.AVG_FRAGMENTATION_IN_PERCENT = B.AVG_FRAGMENTATION_IN_PERCENT
						,DBA_REINDEX_INFO_LOG.FRAGMENT_COUNT = B.FRAGMENT_COUNT
						,DBA_REINDEX_INFO_LOG.AVG_FRAGMENT_SIZE_IN_PAGES = B.AVG_FRAGMENT_SIZE_IN_PAGES
						,DBA_REINDEX_INFO_LOG.PAGE_COUNT = B.PAGE_COUNT
						,DBA_REINDEX_INFO_LOG.AVG_PAGE_SPACE_USED_IN_PERCENT = B.AVG_PAGE_SPACE_USED_IN_PERCENT
						,DBA_REINDEX_INFO_LOG.RECORD_COUNT = B.RECORD_COUNT
						,DBA_REINDEX_INFO_LOG.GHOST_RECORD_COUNT = B.GHOST_RECORD_COUNT
						,DBA_REINDEX_INFO_LOG.VERSION_GHOST_RECORD_COUNT = B.VERSION_GHOST_RECORD_COUNT
						,DBA_REINDEX_INFO_LOG.MIN_RECORD_SIZE_IN_BYTES = B.MIN_RECORD_SIZE_IN_BYTES
						,DBA_REINDEX_INFO_LOG.MAX_RECORD_SIZE_IN_BYTES = B.MAX_RECORD_SIZE_IN_BYTES
						,DBA_REINDEX_INFO_LOG.AVG_RECORD_SIZE_IN_BYTES = B.AVG_RECORD_SIZE_IN_BYTES
						,DBA_REINDEX_INFO_LOG.FORWARDED_RECORD_COUNT = B.FORWARDED_RECORD_COUNT
						,DBA_REINDEX_INFO_LOG.COMPRESSED_PAGE_COUNT = B.COMPRESSED_PAGE_COUNT
						,DBA_REINDEX_INFO_LOG.EXEC_END_DT = GETDATE()
					FROM (
						select top 1 * from #T ORDER BY record_count desc
					) B
					WHERE DBA_REINDEX_INFO_LOG.LOG_SEQ = @currIndex
				END

				END TRY
				BEGIN CATCH
				
					IF ERROR_NUMBER() = 2561  -- 인덱스가 없음으로 삭제 
					BEGIN
						DELETE DBA..DBA_REINDEX_INFO_LOG  WHERE LOG_SEQ = @CURRINDEX
						DROP TABLE #T
						FETCH NEXT FROM REINDEXTARGETS INTO @CURRINDEX
					END
				END CATCH


				
				drop table #T
			
				--SELECT @currIndex
				FETCH NEXT FROM ReindexTargets INTO @currIndex
			END

		CLOSE ReindexTargets
		DEALLOCATE ReindexTargets
END


go


/*****************************************************************************************************************   
. 작 성 자: 전세환   
. 작 성 일: 2015-02-02   
. 유지보수: GmarketDBA팀 전세환   
. 기능구분: DBA_REINDEX_INFO_LOG 기반으로 단편화 정보 수집
. 실행예제    
  - exec UP_DBA_COLLECT_FRAGMENT_INFO_MOD0 
*****************************************************************************************************************   
변경내역:   
        수정일자        수정구분        수정자        수정내용   
==========================================================================   
       2015-02-02                    전세환        신규생성 
*****************************************************************************************************************/   
ALTER PROCEDURE dbo.UP_DBA_COLLECT_FRAGMENT_INFO_MOD0
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @currIndex BIGINT 

	DECLARE ReindexTargets CURSOR READ_ONLY
		FOR
			--끝나지 않은 entry 로 LOG_SEQ 기준으로 처리
			--mod 0
			SELECT A.LOG_SEQ FROM DBA_REINDEX_INFO_LOG A WITH(NOLOCK)
				INNER JOIN DBA_REINDEX_TOTAL_LIST B WITH(NOLOCK) ON A.INDEX_SEQ = B.INDEX_SEQ
			WHERE LOG_SEQ % 3 = 1 AND EXEC_END_DT IS NULL
			ORDER BY LOG_SEQ
		OPEN ReindexTargets

		FETCH NEXT FROM ReindexTargets INTO @currIndex
		WHILE ( @@fetch_status <> -1 ) 
			BEGIN
				declare @DB_NM varchar(20)
				declare @SCHEMA_NM varchar(50)
				declare @TABLE_NM varchar(300)
				declare @INDEX_ID bigint

				SELECT @DB_NM = DB_NAME, @SCHEMA_NM = SCHEMA_NAME, @TABLE_NM = TABLE_NAME, @INDEX_ID = INDEX_ID
				FROM DBA_REINDEX_TOTAL_LIST A WITH(NOLOCK) 
				INNER JOIN DBA_REINDEX_INFO_LOG B WITH(NOLOCK) ON A.INDEX_SEQ = B.INDEX_SEQ
				WHERE B.LOG_SEQ = @currIndex

				declare @table varchar(300)
				set @table = '['+@DB_NM+'].['+@SCHEMA_NM+'].['+@TABLE_NM+']'

				UPDATE DBA..DBA_REINDEX_INFO_LOG 
					SET DBA_REINDEX_INFO_LOG.EXEC_START_DT = GETDATE()
				WHERE DBA_REINDEX_INFO_LOG.LOG_SEQ = @currIndex
			
				begin try

					
				SELECT * INTO #T
				FROM sys.dm_db_index_physical_stats(DB_ID(@DB_NM), OBJECT_ID(@table), @INDEX_ID, NULL, 'DETAILED')
				
				IF @@ROWCOUNT = 0 
				BEGIN
					delete DBA..DBA_REINDEX_INFO_LOG  where LOG_SEQ = @currIndex
					
				END
				ELSE 
				BEGIN
					
					UPDATE DBA..DBA_REINDEX_INFO_LOG 
						SET DBA_REINDEX_INFO_LOG.ALLOC_UNIT_TYPE_DESC = B.ALLOC_UNIT_TYPE_DESC
						,DBA_REINDEX_INFO_LOG.INDEX_DEPTH = B.INDEX_DEPTH
						,DBA_REINDEX_INFO_LOG.INDEX_LEVEL = B.INDEX_LEVEL
						,DBA_REINDEX_INFO_LOG.AVG_FRAGMENTATION_IN_PERCENT = B.AVG_FRAGMENTATION_IN_PERCENT
						,DBA_REINDEX_INFO_LOG.FRAGMENT_COUNT = B.FRAGMENT_COUNT
						,DBA_REINDEX_INFO_LOG.AVG_FRAGMENT_SIZE_IN_PAGES = B.AVG_FRAGMENT_SIZE_IN_PAGES
						,DBA_REINDEX_INFO_LOG.PAGE_COUNT = B.PAGE_COUNT
						,DBA_REINDEX_INFO_LOG.AVG_PAGE_SPACE_USED_IN_PERCENT = B.AVG_PAGE_SPACE_USED_IN_PERCENT
						,DBA_REINDEX_INFO_LOG.RECORD_COUNT = B.RECORD_COUNT
						,DBA_REINDEX_INFO_LOG.GHOST_RECORD_COUNT = B.GHOST_RECORD_COUNT
						,DBA_REINDEX_INFO_LOG.VERSION_GHOST_RECORD_COUNT = B.VERSION_GHOST_RECORD_COUNT
						,DBA_REINDEX_INFO_LOG.MIN_RECORD_SIZE_IN_BYTES = B.MIN_RECORD_SIZE_IN_BYTES
						,DBA_REINDEX_INFO_LOG.MAX_RECORD_SIZE_IN_BYTES = B.MAX_RECORD_SIZE_IN_BYTES
						,DBA_REINDEX_INFO_LOG.AVG_RECORD_SIZE_IN_BYTES = B.AVG_RECORD_SIZE_IN_BYTES
						,DBA_REINDEX_INFO_LOG.FORWARDED_RECORD_COUNT = B.FORWARDED_RECORD_COUNT
						,DBA_REINDEX_INFO_LOG.COMPRESSED_PAGE_COUNT = B.COMPRESSED_PAGE_COUNT
						,DBA_REINDEX_INFO_LOG.EXEC_END_DT = GETDATE()
					FROM (
						select top 1 * from #T ORDER BY record_count desc
					) B
					WHERE DBA_REINDEX_INFO_LOG.LOG_SEQ = @currIndex
				END

				END TRY
				BEGIN CATCH
					
					IF ERROR_NUMBER() = 2561  -- 인덱스가 없음으로 삭제 
					BEGIN
						DELETE DBA..DBA_REINDEX_INFO_LOG  WHERE LOG_SEQ = @CURRINDEX
						DROP TABLE #T
						FETCH NEXT FROM REINDEXTARGETS INTO @CURRINDEX
					END
				END CATCH


				
				drop table #T
			
				--SELECT @currIndex
				FETCH NEXT FROM ReindexTargets INTO @currIndex
			END

		CLOSE ReindexTargets
		DEALLOCATE ReindexTargets
END
go

/*****************************************************************************************************************   
. 작 성 자: 전세환   
. 작 성 일: 2015-02-02   
. 유지보수: GmarketDBA팀 전세환   
. 기능구분: DBA_REINDEX_INFO_LOG 기반으로 단편화 정보 수집
. 실행예제    
  - exec UP_DBA_COLLECT_FRAGMENT_INFO_MOD0 
*****************************************************************************************************************   
변경내역:   
        수정일자        수정구분        수정자        수정내용   
==========================================================================   
       2015-02-02                    전세환        신규생성 
*****************************************************************************************************************/   
ALTER PROCEDURE dbo.UP_DBA_COLLECT_FRAGMENT_INFO_MOD0
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @currIndex BIGINT 

	DECLARE ReindexTargets CURSOR READ_ONLY
		FOR
			--끝나지 않은 entry 로 LOG_SEQ 기준으로 처리
			--mod 0
			SELECT A.LOG_SEQ FROM DBA_REINDEX_INFO_LOG A WITH(NOLOCK)
				INNER JOIN DBA_REINDEX_TOTAL_LIST B WITH(NOLOCK) ON A.INDEX_SEQ = B.INDEX_SEQ
			WHERE LOG_SEQ % 3 = 2 AND EXEC_END_DT IS NULL
			ORDER BY LOG_SEQ
		OPEN ReindexTargets

		FETCH NEXT FROM ReindexTargets INTO @currIndex
		WHILE ( @@fetch_status <> -1 ) 
			BEGIN
				declare @DB_NM varchar(20)
				declare @SCHEMA_NM varchar(50)
				declare @TABLE_NM varchar(300)
				declare @INDEX_ID bigint

				SELECT @DB_NM = DB_NAME, @SCHEMA_NM = SCHEMA_NAME, @TABLE_NM = TABLE_NAME, @INDEX_ID = INDEX_ID
				FROM DBA_REINDEX_TOTAL_LIST A WITH(NOLOCK) 
				INNER JOIN DBA_REINDEX_INFO_LOG B WITH(NOLOCK) ON A.INDEX_SEQ = B.INDEX_SEQ
				WHERE B.LOG_SEQ = @currIndex

				declare @table varchar(300)
				set @table = '['+@DB_NM+'].['+@SCHEMA_NM+'].['+@TABLE_NM+']'

				UPDATE DBA..DBA_REINDEX_INFO_LOG 
					SET DBA_REINDEX_INFO_LOG.EXEC_START_DT = GETDATE()
				WHERE DBA_REINDEX_INFO_LOG.LOG_SEQ = @currIndex
			
				begin try

					
				SELECT * INTO #T
				FROM sys.dm_db_index_physical_stats(DB_ID(@DB_NM), OBJECT_ID(@table), @INDEX_ID, NULL, 'DETAILED')
				
				IF @@ROWCOUNT = 0 
				BEGIN
					delete DBA..DBA_REINDEX_INFO_LOG  where LOG_SEQ = @currIndex
					
				END
				ELSE 
				BEGIN
					
					UPDATE DBA..DBA_REINDEX_INFO_LOG 
						SET DBA_REINDEX_INFO_LOG.ALLOC_UNIT_TYPE_DESC = B.ALLOC_UNIT_TYPE_DESC
						,DBA_REINDEX_INFO_LOG.INDEX_DEPTH = B.INDEX_DEPTH
						,DBA_REINDEX_INFO_LOG.INDEX_LEVEL = B.INDEX_LEVEL
						,DBA_REINDEX_INFO_LOG.AVG_FRAGMENTATION_IN_PERCENT = B.AVG_FRAGMENTATION_IN_PERCENT
						,DBA_REINDEX_INFO_LOG.FRAGMENT_COUNT = B.FRAGMENT_COUNT
						,DBA_REINDEX_INFO_LOG.AVG_FRAGMENT_SIZE_IN_PAGES = B.AVG_FRAGMENT_SIZE_IN_PAGES
						,DBA_REINDEX_INFO_LOG.PAGE_COUNT = B.PAGE_COUNT
						,DBA_REINDEX_INFO_LOG.AVG_PAGE_SPACE_USED_IN_PERCENT = B.AVG_PAGE_SPACE_USED_IN_PERCENT
						,DBA_REINDEX_INFO_LOG.RECORD_COUNT = B.RECORD_COUNT
						,DBA_REINDEX_INFO_LOG.GHOST_RECORD_COUNT = B.GHOST_RECORD_COUNT
						,DBA_REINDEX_INFO_LOG.VERSION_GHOST_RECORD_COUNT = B.VERSION_GHOST_RECORD_COUNT
						,DBA_REINDEX_INFO_LOG.MIN_RECORD_SIZE_IN_BYTES = B.MIN_RECORD_SIZE_IN_BYTES
						,DBA_REINDEX_INFO_LOG.MAX_RECORD_SIZE_IN_BYTES = B.MAX_RECORD_SIZE_IN_BYTES
						,DBA_REINDEX_INFO_LOG.AVG_RECORD_SIZE_IN_BYTES = B.AVG_RECORD_SIZE_IN_BYTES
						,DBA_REINDEX_INFO_LOG.FORWARDED_RECORD_COUNT = B.FORWARDED_RECORD_COUNT
						,DBA_REINDEX_INFO_LOG.COMPRESSED_PAGE_COUNT = B.COMPRESSED_PAGE_COUNT
						,DBA_REINDEX_INFO_LOG.EXEC_END_DT = GETDATE()
					FROM (
						select top 1 * from #T ORDER BY record_count desc
					) B
					WHERE DBA_REINDEX_INFO_LOG.LOG_SEQ = @currIndex
				END

				END TRY
				BEGIN CATCH
					
					IF ERROR_NUMBER() = 2561  -- 인덱스가 없음으로 삭제 
					BEGIN
						DELETE DBA..DBA_REINDEX_INFO_LOG  WHERE LOG_SEQ = @CURRINDEX
						DROP TABLE #T
						FETCH NEXT FROM REINDEXTARGETS INTO @CURRINDEX
					END
				END CATCH


				
				drop table #T
			
				--SELECT @currIndex
				FETCH NEXT FROM ReindexTargets INTO @currIndex
			END

		CLOSE ReindexTargets
		DEALLOCATE ReindexTargets
END


go
