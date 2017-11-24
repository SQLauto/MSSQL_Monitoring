/*****************************************************************************************************************   
. 작 성 자: 전세환   
. 작 성 일: 2015-02-02   
. 유지보수: GmarketDBA팀 전세환   
. 기능구분: REINDEX 작업 Kill
. 실행예제    
  - exec UP_DBA_KILL_REINDEX_PROCESS 
*****************************************************************************************************************   
변경내역:   
        수정일자        수정구분        수정자        수정내용   
==========================================================================   
       2015-02-02                    전세환        신규생성 
*****************************************************************************************************************/   
CREATE PROCEDURE dbo.UP_DBA_KILL_REINDEX_PROCESS

AS
BEGIN
	SET NOCOUNT ON

	DECLARE @TARGET_SEQ BIGINT
	DECLARE @DB_NAME VARCHAR(20)
	DECLARE @TABLE_NAME VARCHAR(100)
	DECLARE @SQL NVARCHAR(4000)

	DECLARE @currDB SYSNAME 


		DECLARE DBs CURSOR READ_ONLY
		FOR
			SELECT TARGET_SEQ
				FROM DBA_REINDEX_MOD_META WITH(NOLOCK)
		OPEN DBs

		FETCH NEXT FROM DBs INTO @currDB

		WHILE ( @@fetch_status <> -1 ) 
		BEGIN

			SELECT TOP 1 @TARGET_SEQ = @currDB, @DB_NAME=DB_NAME, @TABLE_NAME=TABLE_NAME FROM DBA_REINDEX_MOD_META WITH(NOLOCK)
				WHERE TARGET_SEQ = @currDB

			SET @SQL ='
			USE '+@DB_NAME+';

			UPDATE DBA..DBA_REINDEX_TARGET_LIST
				SET PERCENTAGE = (
			SELECT TOP 1 ISNULL((B.ROWS*1.0)/A.rows * 100.0,100) as percentage
			FROM SYS.PARTITIONS A WITH(NOLOCK) JOIN SYS.PARTITIONS B WITH(NOLOCK) 
				ON A.OBJECT_ID=B.OBJECT_ID AND A.INDEX_ID=B.INDEX_ID 
				AND A.PARTITION_NUMBER=B.PARTITION_NUMBER AND A.ROWS<>B.ROWS
			WHERE A.OBJECT_ID=OBJECT_ID('''+@TABLE_NAME+''')
				AND A.ROWS-B.ROWS>0)
			WHERE TARGET_SEQ='+CONVERT(varchar(10),@TARGET_SEQ)+'
			'
			EXEC sp_executesql @SQL

			SELECT @currDB
			FETCH NEXT FROM DBs INTO @currDB
		END

	CLOSE DBs
	DEALLOCATE DBs

	WHILE 1 = 1
	BEGIN 
		select @SQL = N'KILL '+ CONVERT(nvarchar(10), r.session_id)
			from sys.dm_exec_requests r
				inner join sys.dm_exec_sessions s on r.session_id = s.session_id
			--cross apply sys.dm_exec_sql_text(sql_handle) as qt
						left outer join msdb.dbo.sysjobs j
							on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
														substring(left(j.job_id,8),5,2) +
														substring(left(j.job_id,8),3,2) +
														substring(left(j.job_id,8),1,2))
			where r.session_id != @@spid and j.name in
				('[DBA] REINDEX AUTOMATION - REINDEX MOD0','[DBA] REINDEX AUTOMATION - REINDEX MOD1','[DBA] REINDEX AUTOMATION - REINDEX MOD2')
			order by r.cpu_time DESC

		IF @@ROWCOUNT = 0
		BEGIN
			BREAK;
		END

		EXEC sp_executesql @SQL
	END


	IF exists( 
	SELECT top 1 sj.name
	FROM msdb.dbo.sysjobactivity AS sja
	INNER JOIN msdb.dbo.sysjobs AS sj ON sja.job_id = sj.job_id
	WHERE sja.start_execution_date IS NOT NULL
	   AND sja.stop_execution_date IS NULL
	   AND sj.name = '[DBA] REINDEX AUTOMATION - REINDEX MOD0') 
 	EXEC msdb..sp_stop_job '[DBA] REINDEX AUTOMATION - REINDEX MOD0'
 	
 		IF exists( 
	SELECT top 1 sj.name
	FROM msdb.dbo.sysjobactivity AS sja
	INNER JOIN msdb.dbo.sysjobs AS sj ON sja.job_id = sj.job_id
	WHERE sja.start_execution_date IS NOT NULL
	   AND sja.stop_execution_date IS NULL
	   AND sj.name = '[DBA] REINDEX AUTOMATION - REINDEX MOD1') 
 	EXEC msdb..sp_stop_job '[DBA] REINDEX AUTOMATION - REINDEX MOD1'
 	
 		IF exists( 
	SELECT top 1 sj.name
	FROM msdb.dbo.sysjobactivity AS sja
	INNER JOIN msdb.dbo.sysjobs AS sj ON sja.job_id = sj.job_id
	WHERE sja.start_execution_date IS NOT NULL
	   AND sja.stop_execution_date IS NULL
	   AND sj.name = '[DBA] REINDEX AUTOMATION - REINDEX MOD2') 
 	EXEC msdb..sp_stop_job '[DBA] REINDEX AUTOMATION - REINDEX MOD2'


	TRUNCATE TABLE DBA_REINDEX_MOD_META

END





