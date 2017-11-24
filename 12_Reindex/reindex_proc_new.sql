use dba
go

-- GMKT2008
/*************************************************************************  
* : dbo.up_dba_reindex_mon_reindex_detail
* 작성정보	: 2015-07-14 by choi bo ra
* 관련페이지:  
* 내용		:  진행 중인 대상 LIST

* 수정정보	: 
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_reindex_mon_reindex_detail
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
SELECT  A.TARGET_SEQ
    ,A.MOD
		,A.DB_NAME
		,A.TABLE_NAME
		,A.INDEX_NAME
		,A.EXEC_START_DT
		,A.EXEC_END_DT
		,DATEDIFF(MI,A.EXEC_START_DT, A.EXEC_END_DT ) AS DIFF_MIN
		,B.INDEX_TYPE_DESC
		,B.ISUNIQUE
		,B.ROW_COUNT
		,B.INDEX_SIZE_KB /1024 AS [INDEX_SIZE_MB]
		,A.CURRENT_INDEX_SIZE_KB /1024 AS [CURRENT_INDEX_SIZE_MB]
		,A.INDEX_SEQ
		,A.LOG_SEQ
		,A.PAST_AVG_FRAGMENTATION_IN_PERCENT
		,A.PAST_AVG_PAGE_SPACE_USED_IN_PERCENT
		,A.REG_DT
		,A.EXEC_SCRIPT
FROM DBA.DBO.DBA_REINDEX_TARGET_LIST A WITH(NOLOCK)
INNER JOIN DBA.DBO.DBA_REINDEX_TOTAL_LIST B WITH(NOLOCK) ON A.INDEX_SEQ = B.INDEX_SEQ
where ( A.REG_DT > DATEADD(DD,-7,GETDATE()) 
	OR EXEC_END_DT IS NULL  OR EXEC_END_DT > CONVERT(VARCHAR(10), GETDATE(), 121)
	) AND AUTO_YN ='Y'

go


/*****************************************************************************************************************   
. 작 성 자: 전세환   
. 작 성 일: 2015-02-02   
. 유지보수: GmarketDBA팀 전세환   
. 기능구분: REINDEX 진행
. 실행예제    
  - exec UP_DBA_TARGET_LIST_REINDEX 
*****************************************************************************************************************   
변경내역:   
        수정일자        수정구분        수정자        수정내용   
==========================================================================   
       2015-02-02                    전세환        신규생성 
	   2015-11-04					 최보라		  자동 REINDEX 대상만 , MOD 1일 경우 큰 테이블만 진행 함.
	   2014-11-06					 최보라		  INDEX 번호를 잘 못 가져오는 버그 수정
*****************************************************************************************************************/   
ALTER PROCEDURE dbo.UP_DBA_TARGET_LIST_REINDEX
	 @MOD		INT  = NULL

AS
BEGIN
	set nocount on 


	IF @MOD IS NULL SET @MOD =99

while (1=1)
begin
	waitfor delay '00:00:01'
	--1. pick any index which is not performed currently
	DECLARE @TARGET_SEQ bigint
	DECLARE @DB_NAME varchar(30)
	DECLARE @TABLE_NAME varchar(100)
	DECLARE @INDEX_NAME varchar(300)
	DECLARE @EXEC_SCRIPT nvarchar(4000)
	DECLARE @INDEX_SEQ INT

	--동일 테이블 제외, 동일 DB는 MAX 2개까지
	
	SELECT TOP 1 @TARGET_SEQ=TARGET_SEQ, @DB_NAME = DB_NAME, @TABLE_NAME = TABLE_NAME, @INDEX_NAME = INDEX_NAME, @EXEC_SCRIPT = EXEC_SCRIPT, @INDEX_SEQ= INDEX_SEQ
		FROM DBA_REINDEX_TARGET_LIST 
		WHERE TABLE_NAME NOT IN (SELECT TABLE_NAME FROM DBA_REINDEX_MOD_META)
			AND DB_NAME NOT IN (SELECT DB_NAME FROM 
							(
								SELECT DB_NAME AS DB_NAME, COUNT(*) AS COUNT FROM DBA_REINDEX_MOD_META GROUP BY DB_NAME
							) AS A WHERE COUNT > 2
				)
			AND EXEC_END_DT IS NULL
			AND AUTO_YN = 'Y'  -- 자동 실행 하는 것만 진행
			AND ISNULL(MOD,99) = (  CASE WHEN @MOD  = 1 THEN @MOD ELSE 99 END ) 
		ORDER BY TARGET_SEQ 

	--SELECT @TARGET_SEQ,@DB_NAME,@TABLE_NAME,@INDEX_NAME,@EXEC_SCRIPT, @INDEX_SEQ

	IF @TARGET_SEQ IS NULL
	BEGIN
		return;
	END

	--2. INSERT INTO META TABLE (TABLE EXECUTION IS OCCUPIED
	INSERT INTO DBA_REINDEX_MOD_META (TARGET_SEQ,DB_NAME,TABLE_NAME,INDEX_NAME)
	VALUES(@TARGET_SEQ,@DB_NAME,@TABLE_NAME,@INDEX_NAME)

	--3. PERFORM REINDEX
	UPDATE DBA_REINDEX_TARGET_LIST
		SET EXEC_START_DT = GETDATE()
	WHERE TARGET_SEQ = @TARGET_SEQ
	
	DECLARE @SQL nvarchar(4000)
	SET @SQL = N'SET QUERY_GOVERNOR_COST_LIMIT 0'+char(10)+@EXEC_SCRIPT

	--EXEC SP_EXECUTESQL @SQL
	--print @sql 

	begin try
		EXEC SP_EXECUTESQL @SQL
	end try
	begin catch

		UPDATE DBA_REINDEX_TARGET_LIST SET EXEC_END_DT = GETDATE(), PERCENTAGE = -1 WHERE DBA_REINDEX_TARGET_LIST.TARGET_SEQ = @TARGET_SEQ
		
		DELETE FROM DBA_REINDEX_MOD_META WHERE TARGET_SEQ = @TARGET_SEQ
		
		drop table #T
		drop table #T1
		continue;
	end catch;


	--4. GATHER INDEX INFO AFTER REINDEX

	DECLARE @INDEX_ID INT
	DECLARE @SCHEMA_NAME VARCHAR(50)

	SELECT TOP 1 @INDEX_ID=INDEX_ID,@SCHEMA_NAME=SCHEMA_NAME
	from DBA_REINDEX_TOTAL_LIST WITH(NOLOCK)
	--WHERE DB_NAME = @DB_NAME AND TABLE_NAME =@TABLE_NAME AND INDEX_NAME =@INDEX_NAME
	WHERE INDEX_SEQ = @INDEX_SEQ AND DB_NAME = @DB_NAME AND TABLE_NAME = @TABLE_NAME AND INDEX_NAME = @INDEX_NAME

	DECLARE @FULL_TABLE varchar(150)
	SET @FULL_TABLE = @DB_NAME+'.'+@SCHEMA_NAME+'.'+@TABLE_NAME

	SELECT * INTO #T
	FROM sys.dm_db_index_physical_stats(DB_ID(@DB_NAME), OBJECT_ID(@FULL_TABLE), @INDEX_ID, NULL, 'DETAILED')

	DECLARE @INDEX_SIZE bigint 

	SET @EXEC_SCRIPT = '
	select SUM(B.used_page_count) * 8 
			from '+@DB_NAME+'.sys.dm_db_partition_stats B WITH(NOLOCK) 
			WHERE OBJECT_ID = OBJECT_ID('''+@FULL_TABLE+''') and INDEX_ID = '+CONVERT(VARCHAR(5),@INDEX_ID)+'
	'

	CREATE TABLE #T1
	(
		size bigint
	)

	insert into #T1
	EXEC SP_EXECUTESQL @EXEC_SCRIPT

	SELECT @INDEX_SIZE = size FROM #T1 with(nolock)

	--5. UPDATE TARGET LIST
	UPDATE DBA_REINDEX_TARGET_LIST
	SET
	CURRENT_AVG_FRAGMENTATION_IN_PERCENT = B.AVG_FRAGMENTATION_IN_PERCENT
	,CURRENT_FRAGMENT_COUNT = B.FRAGMENT_COUNT
	,CURRENT_AVG_FRAGMENT_SIZE_IN_PAGES =B.AVG_FRAGMENT_SIZE_IN_PAGES
	,CURRENT_PAGE_COUNT = B.PAGE_COUNT
	,CURRENT_AVG_PAGE_SPACE_USED_IN_PERCENT = B.AVG_PAGE_SPACE_USED_IN_PERCENT
	,CURRENT_RECORD_COUNT = B.RECORD_COUNT
	,CURRENT_INDEX_SIZE_KB = @INDEX_SIZE
	,EXEC_END_DT = GETDATE()
	,PERCENTAGE =100
	FROM (
			select top 1 * from #T ORDER BY record_count desc
		) B
	WHERE DBA_REINDEX_TARGET_LIST.TARGET_SEQ = @TARGET_SEQ

	DELETE FROM DBA_REINDEX_MOD_META WHERE TARGET_SEQ = @TARGET_SEQ

	drop table #T
	drop table #T1


	-- Log Size Check
end


END
go

/*************************************************************************  
* 프로시저명: dbo.up_dba_reindex_mon_defrag
* 작성정보	: 2015-07-14 by choi bo ra
* 관련페이지:  
* 내용		:  조각화 대상의 인덱스의 단편화 수집 모니터링
						 전체 DB 에서 실행되어야 함. 
						 최근 일주일 동안 조사된 내역

* 수정정보	: 
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_reindex_mon_defrag
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
--1. mod별 처리 현황
select 
	count(*) as Total
   ,case when count(*) - sum( case when exec_end_dt is not null   then 1 else 0 end) > 0  then '진행중' 
	when count(*) - sum( case when exec_end_dt is not null   then 1 else 0 end)  is null then '대상없음' else'완료' end as status
	, sum( case when exec_end_dt is not null   then 1 else 0 end) AS [완료건수]
	, sum(case when exec_end_dt is null  and log_seq%3 = 0 then 1 else 0 end) as in_process_0
	, sum(case when exec_end_dt is not null and log_seq%3 = 0 then 1  else 0  end ) as complete_0
	, sum(case when exec_end_dt is null  and log_seq%3 = 1 then 1  else 0  end) as in_process_1
	, sum(case when exec_end_dt is not null and log_seq%3 = 1 then 1  else 0 end ) as complete_1
	, sum(case when exec_end_dt is null  and log_seq%3 = 2 then 1  else 0  end) as in_process_2
	, sum(case when exec_end_dt is not null and log_seq%3 = 2 then 1  else 0 end ) as complete_2
from dba_reindex_info_log  with(nolock)
where REG_DT >= dateadd(dd,-7, getdate())
and auto_yn='Y'



select  min(exec_start_dt) as min_start_dt
		, max(exec_end_dt) as max_end_dt
		,datediff(mi,min(a.exec_start_dt), isnull(max(a.exec_end_dt),getdate()) )  as diff_min
		,count(*) as count
from dba_reindex_info_log a with(nolock)
inner join dba_reindex_total_list b with(nolock) on a.index_seq = b.index_seq
where EXEC_START_DT >= dateadd(dd,-7, getdate())
go


/*****************************************************************************************************************   
.   :    
.   : 2015-02-02   
. : GmarketDBA    
. : DB  Index      
.     
  - exec UP_DBA_COLLECT_REINDEX_INFO_TARGET 
*****************************************************************************************************************   
:   
                                   
==========================================================================   
       2015-02-02   
       2015-06-03 by choi bo ra unused index 사이즈 변경량    
       2015-10-14 이예지 IAC dbadmin에 반영   
	   2015-11-18 최보라 싱크제외                   
*****************************************************************************************************************/   
ALTER PROCEDURE dbo.UP_DBA_COLLECT_REINDEX_INFO_TARGET
	@minRowCount int = 100000 --  Row 
	,@minDelCount int = 500 -- trans_basic_master  del_count  
	,@retentionRowPercentage int = 2 -- row /  row 
	,@updatePercentage int = 2 --  row / update  
	,@lookupPercentage int = 2 --  row / lookup 
	,@indexSizeRatio int = 2 -- index   
AS
BEGIN
	SET NOCOUNT ON

	--DECLARE @minRowCount int --  Row 
	--DECLARE @minDelCount int -- trans_basic_master  del_count  
	--DECLARE @retentionRowPercentage int -- row /  row 
	--DECLARE @updatePercentage int --  row / update  
	--DECLARE @lookupPercentage int --  row / lookup 
	--DECLARE @indexSizeRatio int -- index   

	--SET @minRowCount = 3000000
	--SET @minDelCount = 1000
	--SET @retentionRowPercentage = 10
	--SET @updatePercentage = 5
	--SET @lookupPercentage = 2
	--SET @indexSizeRatio = 2



	/*
	*IFF: The Length of dbo.DBA_REINDEX_INFO_LOG's unexecuted log entries > 30 
	*/

	DECLARE @unexecCnt int
	SELECT @unexecCnt = COUNT(*) FROM dbo.DBA_REINDEX_INFO_LOG WITH(NOLOCK) WHERE EXEC_END_DT IS NULL

	IF (@unexecCnt > 30)
	BEGIN
		PRINT 'The count of unexecuted entries are more than 30.'
		RETURN;
	END

	/*
	*IFF: TABLE Bigger than 1,000,000 rows & Retention with more than 1,000 delete per each & Deleted row (5days) / Total row > 10%
	*/

	SELECT A.*, B.DEL_COUNT AS DEL_COUNT, 0 AS DEL_ROW_COUNT
	INTO #T
		FROM dbo.DBA_REINDEX_TOTAL_LIST A WITH(NOLOCK) 
		INNER JOIN dbo.TRANS_BASIC_MASTER B WITH(NOLOCK) ON A.DB_NAME = B.DB_NAME AND A.TABLE_NAME = B.TABLE_NAME
	WHERE A.ROW_COUNT >= @minRowCount AND B.DEL_COUNT >= @minDelCount

	
	--WHEN THE REINDEX HAPPEND WITHIN A MONTH, EXCLUDE.
	DELETE FROM #T 
	WHERE INDEX_SEQ IN(
		SELECT DISTINCT INDEX_SEQ FROM dbo.DBA_REINDEX_INFO_LOG WITH(NOLOCK) 
		WHERE REG_DT > DATEADD(day,-20,getdate())
	)

	--Gather information of total deleted row counts in 5days
	UPDATE A
	SET A.DEL_ROW_COUNT =  B.DEL_ROW_COUNT
		FROM #T A WITH(NOLOCK)
		INNER JOIN (
			select A.DB_NAME, A.TABLE_NAME, SUM(B.ROW_COUNT) AS DEL_ROW_COUNT
				FROM #T A WITH(NOLOCK)
				INNER JOIN dbo.TRANS_BASIC_MASTER_LOG B WITH(NOLOCK) ON A.DB_NAME = B.DB_NAME AND A.TABLE_NAME = B.TABLE_NAME
				WHERE START_TIME > GETDATE()-5
				GROUP BY A.DB_NAME, A.TABLE_NAME
		) AS B ON A.DB_NAME = B.DB_NAME AND A.TABLE_NAME=B.TABLE_NAME
	
	--insert into targets when the ratio of total row counts and deleted row counts hits the certain level
	INSERT INTO dbo.DBA_REINDEX_INFO_LOG (INDEX_SEQ)
	SELECT DISTINCT INDEX_SEQ FROM #T WITH(NOLOCK) 
		WHERE ((DEL_ROW_COUNT * 1.0)/ROW_COUNT) * 100 > @retentionRowPercentage

	DROP TABLE #T

-- OR 조건. 

	/*
	* Accum of 5days of updates or lookups from INDEX_USAGE >  5% or 2% of total row count
	*/


	
		INSERT INTO dbo.DBA_REINDEX_INFO_LOG (INDEX_SEQ)
		SELECT distinct INDEX_SEQ
			FROM 
		(
			SELECT  B.INDEX_SEQ, B.ROW_COUNT, AVG(user_updates)+ AVG(system_updates) as UPDATE_COUNT, AVG(user_lookups)+AVG(system_lookups) as LOOKUP_COUNT
			, MAX(C.EXEC_START_DT) as EXEC_START_DT
				FROM INDEX_USAGE A with(nolock) 
				INNER JOIN dbo.DBA_REINDEX_TOTAL_LIST B WITH(NOLOCK) ON A.OBJECT_ID = B.OBJECT_ID AND A.index_id = B.INDEX_ID
				LEFT JOIN dbo.DBA_REINDEX_INFO_LOG C WITH(NOLOCK) ON B.INDEX_SEQ = C.INDEX_SEQ
			WHERE A.reg_date > getdate()-5 AND B.ROW_COUNT >= @minRowCount 
			GROUP BY B.INDEX_SEQ, A.database_name, A.object_name, A.index_name, B.ROW_COUNT	
		) AS A
		WHERE (EXEC_START_DT IS NULL OR EXEC_START_DT < GETDATE()-10)
		AND (((UPDATE_COUNT*1.0) / ROW_COUNT)*100 > @updatePercentage OR ((LOOKUP_COUNT*1.0) / ROW_COUNT)*100 > @lookupPercentage)
		AND INDEX_SEQ NOT IN(
			SELECT DISTINCT INDEX_SEQ FROM dbo.DBA_REINDEX_INFO_LOG WITH(NOLOCK) 
			WHERE REG_DT > DATEADD(day,-10,getdate()
			)
		)

		/*
		* Changes on current INDEX_SIZE 2 time larger than recorded INDEX_SIZE
		*/


		CREATE TABLE #T1
		(
			db_name		sysname,
			OBJECT_ID	bigint,
			INDEX_ID	bigint,
			ROW_COUNT	bigint,
			INDEX_SIZE_KB bigint, 
			UNUSED_INDEX_SIZE_KB BIGINT,
		)



		--collect index size info over all databases
		INSERT INTO #T1
		EXEC sp_MSforeachdb N'
			USE [?];
			select db_name(),object_id, index_id, row_count, SUM(B.used_page_count) * 8  AS INDEX_SIZE_KB, SUM(RESERVED_PAGE_COUNT-USED_PAGE_COUNT) * 8 AS UNSUED_INDEX_SIZE_KB
			from sys.dm_db_partition_stats B WITH(NOLOCK) 
			WHERE row_count > 100000 and B.used_page_count > 0 
			group by object_id, index_id, row_count'

		--insert into reindex table when the ratio of index_size / row_count hits certain level
		INSERT INTO DBA_REINDEX_INFO_LOG (INDEX_SEQ)
		SELECT distinct INDEX_SEQ 
		FROM(
				SELECT distinct  A.INDEX_SEQ, A.INDEX_SIZE_KB as INDEX_SIZE_KB_BEFORE, B.INDEX_SIZE_KB as INDEX_SIZE_KB_AFTER,  B.UNUSED_INDEX_SIZE_KB  AS UNUSED_INDEX_SIZE_KB_AFTER,
					A.ROW_COUNT as ROW_COUNT_BEFORE, B.ROW_COUNT as ROW_COUNT_AFTER, MAX(C.EXEC_START_DT) as EXEC_START_DT, A.UNUSED_INDEX_SIZE_KB AS  UNUSED_INDEX_SIZE_KB_BEFORE
				FROM dbo.DBA_REINDEX_TOTAL_LIST A WITH(NOLOCK)
					INNER JOIN #T1 B WITH(NOLOCK) ON A.DB_NAME = B.db_name and A.OBJECT_ID =B.OBJECT_ID  and A.INDEX_ID = B.INDEX_ID
					LEFT JOIN dbo.DBA_REINDEX_INFO_LOG C WITH(NOLOCK) ON A.INDEX_SEQ = C.INDEX_SEQ
				GROUP BY A.INDEX_SEQ, A.INDEX_SIZE_KB, A.ROW_COUNT,A.INDEX_SIZE_KB, B.INDEX_SIZE_KB, A.ROW_COUNT, B.ROW_COUNT, B.UNUSED_INDEX_SIZE_KB, A.UNUSED_INDEX_SIZE_KB
				) A
		WHERE INDEX_SIZE_KB_BEFORE >0 and ROW_COUNT_BEFORE>0   AND UNUSED_INDEX_SIZE_KB_BEFORE >0 
		AND (  (INDEX_SIZE_KB_AFTER*1.0 / INDEX_SIZE_KB_BEFORE) / (ROW_COUNT_AFTER*1.0 / ROW_COUNT_BEFORE) > @indexSizeRatio 
			  OR 
		  		 (UNUSED_INDEX_SIZE_KB_AFTER*1.0 / UNUSED_INDEX_SIZE_KB_BEFORE) > @indexSizeRatio
		  	
			  ) 
		AND (EXEC_START_DT IS NULL OR EXEC_START_DT < GETDATE()-10)
		AND INDEX_SEQ NOT IN(
			SELECT DISTINCT INDEX_SEQ FROM dbo.DBA_REINDEX_INFO_LOG WITH(NOLOCK) 
			WHERE REG_DT > DATEADD(day,-10,getdate())
			)


	drop table #T1

	-- 2016-05-13 추가 
	
	UPDATE DBA_REINDEX_INFO_LOG  SET AUTO_YN = 'N' 
	 from dba_reindex_info_log a with(nolock)
		inner join dba_reindex_total_list b with(nolock) on a.index_seq = b.index_seq
	where b.index_size_kb >= 50*1024*1024  --100GB
	and a.auto_yn ='Y'
	and a.REG_DT >= convert(nvarchar(10), getdate(),121)
END
go

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
ALTER PROCEDURE dbo.UP_DBA_KILL_REINDEX_PROCESS

AS
BEGIN
	SET NOCOUNT ON

	DECLARE @TARGET_SEQ BIGINT
	DECLARE @DB_NAME VARCHAR(20)
	DECLARE @TABLE_NAME VARCHAR(100)
	DECLARE @SQL NVARCHAR(4000)


	
	IF exists( 
	SELECT top 1 sj.name
	FROM msdb.dbo.sysjobactivity AS sja
	INNER JOIN msdb.dbo.sysjobs AS sj ON sja.job_id = sj.job_id
	WHERE sja.start_execution_date >=convert(date, getdate())
	   AND sja.stop_execution_date IS NULL
	   AND sj.name = '[DBA] REINDEX AUTOMATION - REINDEX MOD0') 
 	EXEC msdb..sp_stop_job '[DBA] REINDEX AUTOMATION - REINDEX MOD0'
 	
 		IF exists( 
	SELECT top 1 sja.*
	FROM msdb.dbo.sysjobactivity AS sja
	INNER JOIN msdb.dbo.sysjobs AS sj ON sja.job_id = sj.job_id
	WHERE sja.start_execution_date >=convert(date, getdate())
	   AND sja.stop_execution_date IS NULL
	   AND sj.name = '[DBA] REINDEX AUTOMATION - REINDEX MOD1') 
 	EXEC msdb..sp_stop_job '[DBA] REINDEX AUTOMATION - REINDEX MOD1'
 	
 		IF exists( 
	SELECT top 1 sj.name
	FROM msdb.dbo.sysjobactivity AS sja
	INNER JOIN msdb.dbo.sysjobs AS sj ON sja.job_id = sj.job_id
	WHERE sja.start_execution_date >=convert(date, getdate())
	   AND sja.stop_execution_date IS NULL
	   AND sj.name = '[DBA] REINDEX AUTOMATION - REINDEX MOD2') 
 	EXEC msdb..sp_stop_job '[DBA] REINDEX AUTOMATION - REINDEX MOD2'

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

			SET @SQL ='USE '+@DB_NAME+';

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




	TRUNCATE TABLE DBA_REINDEX_MOD_META

END
go

-- gmarket 

/*****************************************************************************************************************   
. 작 성 자: 전세환   
. 작 성 일: 2015-02-02   
. 유지보수: GmarketDBA팀 전세환   
. 기능구분: DB 전체 Index 정보 기반으로 단편화 조회 대상 추출
. 실행예제    
  - exec UP_DBA_COLLECT_REINDEX_TARGET_LIST 
*****************************************************************************************************************   
변경내역:   
        수정일자        수정구분        수정자        수정내용   
==========================================================================   
       2015-02-02                    전세환        신규생성 
	   2016-04-15					 최보라		  실행 시간 변경으로 인해 getate() + 1
*****************************************************************************************************************/   
ALTER PROCEDURE dbo.UP_DBA_COLLECT_REINDEX_TARGET_LIST
	@PAD_INDEX varchar(3) = 'OFF'
	,@FILLFACTOR int = 90
	,@SORT_IN_TEMPDB varchar(3) = 'OFF'
	,@IGNORE_DUP_KEY varchar(3) = 'OFF'
	,@STATISTICS_NORECOMPUTE varchar(3) = 'OFF'
	,@ONLINE varchar(3) = 'ON'
	,@ALLOW_ROW_LOCKS varchar(3) = 'ON'
	,@ALLOW_PAGE_LOCKS varchar(3) = 'ON'
	,@MAXDOP int = 8
	,@DATA_COMPRESSION varchar(10) = 'PAGE'

AS
BEGIN
	SET NOCOUNT ON
/*
declare @PAD_INDEX varchar(3)
declare @FILLFACTOR int
declare @SORT_IN_TEMPDB varchar(3)
declare @IGNORE_DUP_KEY varchar(3)
declare @STATISTICS_NORECOMPUTE varchar(3)
declare @ONLINE varchar(3)
declare @ALLOW_ROW_LOCKS varchar(3)
declare @ALLOW_PAGE_LOCKS varchar(3)
declare @MAXDOP int
declare @DATA_COMPRESSION varchar(10)

SET @PAD_INDEX = 'OFF'
SET @FILLFACTOR = 90
SET @SORT_IN_TEMPDB = 'OFF'
SET @IGNORE_DUP_KEY = 'OFF'
SET @STATISTICS_NORECOMPUTE = 'OFF'
SET @ONLINE = 'ON'
SET @ALLOW_ROW_LOCKS = 'ON'
SET @ALLOW_PAGE_LOCKS = 'ON'
SET @MAXDOP = 8
SET @DATA_COMPRESSION = 'PAGE'
*/

INSERT INTO DBA_REINDEX_TARGET_LIST
(
DB_NAME
,TABLE_NAME
,INDEX_NAME
,INDEX_SEQ
,LOG_SEQ
,EXEC_SCRIPT
,PAST_AVG_FRAGMENTATION_IN_PERCENT
,PAST_FRAGMENT_COUNT
,PAST_AVG_FRAGMENT_SIZE_IN_PAGES
,PAST_PAGE_COUNT
,PAST_AVG_PAGE_SPACE_USED_IN_PERCENT
,PAST_RECORD_COUNT
,PAST_INDEX_SIZE_KB
,REG_DT
)
select  B.DB_NAME, B.TABLE_NAME, B.INDEX_NAME, B.INDEX_SEQ, A.LOG_SEQ, '
USE ' + B.DB_NAME +';

ALTER INDEX '+ B.INDEX_NAME +' ON '+ B.TABLE_NAME +'
REBUILD WITH( PAD_INDEX = '+@PAD_INDEX+', FILLFACTOR = '+CONVERT(varchar(3),@FILLFACTOR)+', SORT_IN_TEMPDB = '+@SORT_IN_TEMPDB+
	'--, IGNORE_DUP_KEY = '+@IGNORE_DUP_KEY+char(10)+', STATISTICS_NORECOMPUTE = '+@STATISTICS_NORECOMPUTE+',ONLINE = '+@ONLINE+
	', ALLOW_ROW_LOCKS = '+@ALLOW_ROW_LOCKS+', ALLOW_PAGE_LOCKS = '+@ALLOW_PAGE_LOCKS+
	', MAXDOP = '+CONVERT(varchar(3),@MAXDOP)+', DATA_COMPRESSION = '+@DATA_COMPRESSION+')'
,AVG_FRAGMENTATION_IN_PERCENT,FRAGMENT_COUNT
,AVG_FRAGMENT_SIZE_IN_PAGES,PAGE_COUNT,AVG_PAGE_SPACE_USED_IN_PERCENT,RECORD_COUNT,INDEX_SIZE_KB, GETDATE()
from DBA_REINDEX_INFO_LOG A WITH(NOLOCK)
	INNER JOIN DBA_REINDEX_TOTAL_LIST B with(nolock) ON A.INDEX_SEQ = B.INDEX_SEQ
	LEFT JOIN DBA_REINDEX_TARGET_LIST AS T WITH(NOLOCK) ON A.INDEX_SEQ = T.INDEX_SEQ  AND T.EXEC_END_DT IS NULL
WHERE 
	--A.LOG_SEQ NOT IN (SELECT LOG_SEQ FROM DBA_REINDEX_TARGET_LIST  WITH(NOLOCK) WHERE EXEC_END_DT IS NOT NULL )
	(A.AVG_FRAGMENTATION_IN_PERCENT > 40 or A.AVG_PAGE_SPACE_USED_IN_PERCENT < 60)
	AND T.INDEX_SEQ IS NULL
	AND A.EXEC_END_DT >= DATEADD(DD,-7, CONVERT(NVARCHAR(10), GETDATE(), 121) ) AND 
	  A.EXEC_END_DT < DATEADD(DD,1, CONVERT(NVARCHAR(10), GETDATE()+1, 121) ) 
		
ORDER BY TABLE_NAME
END
go



/*************************************************************************  
* 프로시저명: dbo.up_dba_reindex_mon_reindex_job
* 작성정보	: 2015-07-14 by choi bo ra
* 관련페이지:  
* 내용		:   reindex job 실행 내역
* 수정정보	: 
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_reindex_mon_reindex_job
	@type  char(1) = 'A'
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
IF @TYPE = 'A'
BEGIN

SELECT   sj.name, max(sja.start_execution_date) as start_execution_date 
						,case when  isnull(max(sja.start_execution_date),getdate()-1) < convert(date,getdate()) then '미실행' 
		  when  max(sja.start_execution_date) >= convert(date,getdate()) and isnull(max(sja.stop_execution_date), getdate()-1) <  convert(date,getdate())  then '실행중'
		  when    isnull(max(run_status ),99) = 1 then '성공'
		  when    isnull(max(run_status ),99) = 1 then '실패'
		  when    isnull(max(run_status ),99) = 3 then '취소됨'
			end  [상태]
	FROM 
	 msdb.dbo.sysjobs AS sj  with(nolock)
	left join msdb.dbo.sysjobactivity AS sja   with(nolock) ON sja.job_id = sj.job_id
	left JOIN msdb.dbo.sysjobhistory as sh on sj.job_id = sh.job_id  and sh.run_date >= convert(int,convert(nvarchar(8), getdate(),112))
where sj.name like '%REINDEX AUTOMATION - REINDEX MOD%'
group by  sj.name
END
ELSE IF @TYPE = 'F'
	BEGIN
			SELECT   sj.name, max(sja.start_execution_date) as start_execution_date 
				, max(sja.stop_execution_date) as stop_execution_date
			,case when  isnull(max(sja.start_execution_date),getdate()-1) < convert(date,getdate()) then '미실행' 
			when  max(sja.start_execution_date) >= convert(date,getdate()) and max(sja.stop_execution_date) is null  then '실행중'
			when    isnull(max(run_status ),99) = 1 then '성공'
			when    isnull(max(run_status ),99) = 1 then '실패'
			when    isnull(max(run_status ),99) = 3 then '취소됨'
			end as [상태]
			FROM 
			 msdb.dbo.sysjobs AS sj  with(nolock)
			left join msdb.dbo.sysjobactivity AS sja   with(nolock) ON sja.job_id = sj.job_id
			left JOIN msdb.dbo.sysjobhistory as sh on sj.job_id = sh.job_id  and sh.run_date >= convert(int,convert(nvarchar(8), getdate(),112))
			where sj.name like '%REINDEX AUTOMATION - REINDEX MOD%'
			group by  sj.name
			having  max(run_status )  = 0
	END
ELSE IF @TYPE='I'
	BEGIN
		 select N'KILL '+ CONVERT(nvarchar(10), r.session_id) as session_id,  j.name
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
	END
go
/*************************************************************************  
* 프로시저명: dbo.up_dba_reindex_mon_defrag_job
* 작성정보	: 2015-07-14 by choi bo ra
* 관련페이지:  
* 내용		:  job 실행 내역
* 수정정보	: 
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_reindex_mon_defrag_job
	@type  char(1) = 'A'
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
IF @TYPE = 'A'
BEGIN

SELECT   sj.name, max(sja.start_execution_date) as start_execution_date 
	, max(sja.stop_execution_date) as stop_execution_date
				,case when  isnull(max(sja.start_execution_date),getdate()-1) < convert(date,getdate()) then '미실행' 
		  when  max(sja.start_execution_date) >= convert(date,getdate()) and isnull(max(sja.stop_execution_date), getdate()-1) <  convert(date,getdate())  then '실행중'
		  when    isnull(max(run_status ),99) = 1 then '성공'
		  when    isnull(max(run_status ),99) = 1 then '실패'
		  when    isnull(max(run_status ),99) = 3 then '취소됨'
			end  [상태]
	FROM msdb.dbo.sysjobactivity AS sja
	INNER JOIN msdb.dbo.sysjobs AS sj ON sja.job_id = sj.job_id
	left JOIN msdb.dbo.sysjobhistory as sh on sj.job_id = sh.job_id  and sh.run_date >= convert(int,convert(nvarchar(8), getdate()-1,112))
where sj.name like '%REINDEX AUTOMATION - DEFRAG%'
  group by  sj.name
	--having   max(sja.stop_execution_date) is null
END
ELSE IF @TYPE = 'F'
	BEGIN
			SELECT   sj.name, max(sja.start_execution_date) as start_execution_date 
			, max(sja.stop_execution_date) as stop_execution_date
				,case when  isnull(max(sja.start_execution_date),getdate()-1) < convert(date,getdate()) then '미실행' 
		  when  max(sja.start_execution_date) >= convert(date,getdate()) and isnull(max(sja.stop_execution_date), getdate()-1) <  convert(date,getdate())  then '실행중'
		  when    isnull(max(run_status ),99) = 1 then '성공'
		  when    isnull(max(run_status ),99) = 1 then '실패'
		  when    isnull(max(run_status ),99) = 3 then '취소됨'
			end  [상태]
			FROM msdb.dbo.sysjobactivity AS sja
			INNER JOIN msdb.dbo.sysjobs AS sj ON sja.job_id = sj.job_id
			left JOIN msdb.dbo.sysjobhistory as sh on sj.job_id = sh.job_id  and sh.run_date >= convert(int,convert(nvarchar(8), getdate()-1,112))
			where sj.name like '%REINDEX AUTOMATION - DEFRAG%'
		    group by  sj.name
		    having  max(run_status )  = 0
	END
go
/*************************************************************************  
* 프로시저명: dbo.up_dba_reindex_mon_reindex
* 작성정보	: 2015-07-14 by choi bo ra
* 관련페이지:  
* 내용		:  진행 중인 대상

* 수정정보	: 
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_reindex_mon_reindex
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
--1. mod  


select 
	 sum(case when exec_end_dt is null  or exec_end_dt > convert(varchar(10), getdate(), 121) then 1 end)   as total_cnt
	 ,isnull(sum( case when EXEC_END_DT is not null   then 1 else 0 end) ,0)as complete_cnt
    , case when count(*) - sum( case when EXEC_END_DT is not null   then 1 else 0 end) > 0  then '진행중' else '완료' end as status
	, isnull(sum(case when EXEC_END_DT is null  and MOD = 1 then 1 else 0 end) ,0) as in_process_0
	, isnull(sum(case when EXEC_END_DT is not null and MOD = 1  then 1  else 0  end )  ,0)as complete_0
	, isnull(sum(case when EXEC_END_DT is null  and TARGET_SEQ%2 = 0 then 1  else 0  end)  ,0)as in_process_1
	, isnull(sum(case when EXEC_END_DT is not null and TARGET_SEQ%2 = 0 then 1  else 0 end ) ,0) as complete_1
	, isnull(sum(case when EXEC_END_DT is null  and TARGET_SEQ%2 = 1 then 1  else 0  end) ,0) as in_process_2
	, isnull(sum(case when EXEC_END_DT is not null and TARGET_SEQ%2 = 1 then 1  else 0 end )  ,0)as complete_2
from DBO.DBA_REINDEX_TARGET_LIST  with(nolock)
where ( REG_DT > DATEADD(DD,-7,GETDATE())  
	--OR EXEC_START_DT >= CONVERT(DATE, GETDATE())
	OR EXEC_END_DT IS NULL  OR EXEC_END_DT > CONVERT(VARCHAR(10), GETDATE(), 121)
	)

	AND AUTO_YN = 'Y'

select  min(exec_start_dt) as min_start_dt
		, max(exec_end_dt) as max_end_dt
		,datediff(mi,min(a.exec_start_dt), isnull(max(a.exec_end_dt),getdate()) )  as diff_min
		,count(*) as count
from DBO.DBA_REINDEX_TARGET_LIST a with(nolock)
inner join dba.dbo.dba_reindex_total_list b with(nolock) on a.index_seq = b.index_seq
where ( A.REG_DT > DATEADD(DD,-7,GETDATE())  	
	--OR EXEC_END_DT  IS NULL
	OR EXEC_END_DT IS NULL  OR EXEC_END_DT > CONVERT(VARCHAR(10), GETDATE(), 121)
		)
	AND AUTO_YN = 'Y'
go
-- GMKT2008
	
/*****************************************************************************************************************   
. 작 성 자: 최보라   
. 작 성 일: 2015-11-04   
. 유지보수: 최보라
. 기능구분: REINDEX 대상 조정
. 실행예제    
  - exec UP_DBA_TARGET_LIST_REINDEX_UPDATE
*****************************************************************************************************************   
변경내역:   
        수정일자        수정구분        수정자        수정내용   
==========================================================================   

*****************************************************************************************************************/   
ALTER PROCEDURE dbo.UP_DBA_TARGET_LIST_REINDEX_UPDATE
	@RANK		INT, 
	@SIZE 		INT

AS
BEGIN
	set nocount on 
	-- INDEX_SIZE >= 300GB 이상은 자동으로 처리 하지 않음 
	UPDATE DBA_REINDEX_TARGET_LIST SET AUTO_YN = 'N'  WHERE PAST_INDEX_SIZE_KB >= @SIZE	 * 1024 *1024  AND EXEC_END_DT IS NULL
	
	

	SELECT @RANK = COUNT(*) / 3 -1 FROM DBA_REINDEX_TARGET_LIST WHERE EXEC_END_DT IS NULL
	
	IF @RANK =0  SET @RANK =1

	
	UPDATE  B
	SET MOD = 1 
	FROM 
		(	SELECT RANK() OVER  ( ORDER BY PAST_INDEX_SIZE_KB DESC ) AS RNK, TARGET_SEQ 
			FROM  DBA_REINDEX_TARGET_LIST  WITH(NOLOCK) 
			WHERE EXEC_END_DT IS NULL
			AND AUTO_YN='Y'
		) AS A
		JOIN DBA_REINDEX_TARGET_LIST AS B WITH(NOLOCK) ON A.TARGET_SEQ = B.TARGET_SEQ
	WHERE A.RNK <= @RANK
END
go

/*************************************************************************  
* 프로시저명: dbo.up_dba_reindex_mon_reindex_ing
* 작성정보	: 2015-07-14 by choi bo ra
* 관련페이지:  
* 내용		:  진행 중인 대상

* 수정정보	: 
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_reindex_mon_reindex_ing
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
--1. mod별 처리 현황
select * from DBA_REINDEX_MOD_META with(nolock)
go

/*************************************************************************  
* 프로시저명: dbo.up_dba_reindex_mon_defrag_detail
* 작성정보	: 2015-07-14 by choi bo ra
* 관련페이지:  
* 내용		:  조각화 대상의 인덱스의 단편화 수집 모니터링
						 전체 DB 에서 실행되어야 함. 
						 최근 일주일 동안 조사된 내역
						 상세 내역

* 수정정보	: 
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_reindex_mon_defrag_detail
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
select  log_seq % 3 as mod, a.LOG_SEQ,  b.index_seq, b.db_name, b.schema_name, b.table_name, b.index_name, b.row_count, b.index_size_kb, unused_index_size_kb
, a.* 
from dba_reindex_info_log a with(nolock)
inner join dba_reindex_total_list b with(nolock) on a.index_seq = b.index_seq
where  exec_end_dt is null
order by a.log_seq 



select  log_seq % 3 as mod, a.LOG_SEQ,  a.exec_start_dt,  a.exec_end_dt,  datediff(mi,a.exec_start_dt, isnull(a.exec_end_dt,getdate()) )as diff_min
, b.index_seq, b.db_name, b.schema_name, b.table_name, b.index_name, b.row_count, b.index_size_kb, unused_index_size_kb
, a.* 
from dba_reindex_info_log a with(nolock)
inner join dba_reindex_total_list b with(nolock) on a.index_seq = b.index_seq
where a.reg_dt >= dateadd(dd,-7, getdate())
order by a.exec_start_dt desc,a.log_seq
go
/*************************************************************************  
* 프로시저명: dbo.UP_DBA_REINDEX_TOTAL_LIST
* 작성정보	: 2015-08-26 최보라
* 관련페이지:  
* 내용		:  REINDEX 결과 

* 수정정보	: EXEC UP_DBA_REINDEX_TOTAL_LIST 10
**************************************************************************/
ALTER PROCEDURE dbo.UP_DBA_REINDEX_TOTAL_LIST
	@SERVER_ID 	INT
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/

SELECT @SERVER_ID AS SERVER_ID , *
FROM DBA_REINDEX_TARGET_LIST
--WHERE REG_DT >= DATEADD(WK, DATEDIFF(WK,0,GETDATE()), -2) -- SUNDAY
--AND REG_DT <= DATEADD(WK, DATEDIFF(WK,0,GETDATE()), 5) -- SATURDAY
go



/*************************************************************************  
* 프로시저명: dbo.up_dba_reindex_mon_reindex_process
* 작성정보	: 2015-07-14 by choi bo ra
* 관련페이지:  
* 내용		:  진행 인덱스 row 건수
* 수정정보	: 
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_reindex_mon_reindex_process
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/

IF NOT EXISTS( SELECT TOP 1 * FROM DBA.SYS.TABLES WHERE NAME = 'REINDEX_INDEX_PROCESS')
		CREATE TABLE REINDEX_INDEX_PROCESS
		( 
		TABLE_NAME nvarchar (128)   NULL   , 
		INDEX_NAME nvarchar (128)   NULL   , 
		ROWS bigint    NOT NULL   , 
		NEW_ROWS bigint    NOT NULL   , 
		DIFF_ROWS bigint    NULL   , 
		PARTITION_NUMBER int    NOT NULL   , 
		DATA_COMPRESSION_DESC nvarchar (60)   NULL  
		)  ON [PRIMARY]
ELSE 
	TRUNCATE TABLE DBA.DBO.REINDEX_INDEX_PROCESS


EXEC sp_MSforeachdb '
USE [?];
INSERT INTO DBA.DBO.REINDEX_INDEX_PROCESS
SELECT OBJECT_NAME(A.OBJECT_ID, DB_ID(R.DB_NAME) ) AS TABLE_NAME 
	, OBJECT_NAME(A.INDEX_ID, DB_ID(R.DB_NAME)) AS INDEX_NAME
	,A.ROWS , B.ROWS AS NEW_ROWS, A.ROWS-B.ROWS AS DIFF_ROWS
	,B.PARTITION_NUMBER, B.DATA_COMPRESSION_DESC
FROM SYS.PARTITIONS A WITH(NOLOCK) 
	JOIN SYS.PARTITIONS B WITH(NOLOCK)  ON A.OBJECT_ID=B.OBJECT_ID AND A.INDEX_ID=B.INDEX_ID AND A.PARTITION_NUMBER=B.PARTITION_NUMBER AND A.ROWS<>B.ROWS
	JOIN (SELECT DB_NAME, TABLE_NAME  FROM DBA.DBO.DBA_REINDEX_MOD_META WITH(NOLOCK) GROUP BY DB_NAME, TABLE_NAME)  AS  R ON R.TABLE_NAME =  OBJECT_NAME(A.OBJECT_ID, DB_ID(R.DB_NAME) )
WHERE A.ROWS-B.ROWS > 0
ORDER BY R.DB_NAME, R.TABLE_NAME, A.INDEX_ID'

SELECT * FROM DBA.DBO.REINDEX_INDEX_PROCESS
go
/*************************************************************************  
* 프로시저명: dbo.up_dba_reindex_monitoring
* 작성정보	: 2015-06-05 by choi bo ra
* 관련페이지:  
* 내용		: 

* 수정정보	: 조각화 진행 모니터링
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_reindex_monitoring
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/



SELECT convert(date,exec_end_dt) as [execute date]
	  , count(*) as total_cnt
	 , sum(case when exec_end_dt is not null then 1 else 0 end ) as [실행 건수]
	 , sum(case when exec_end_dt is null then 1 else 0 end )  as [남은 건수]
	 , datediff(mi, min(exec_start_dt), max(exec_end_dt)) as [소요분]
	 , round(  convert(money,1.0*  ( sum(PAST_INDEX_SIZE_KB)  - sum(CURRENT_INDEX_SIZE_KB) ) /sum(PAST_INDEX_SIZE_KB),2) * 100,0)  as [saved(%)]
	 , (sum(PAST_INDEX_SIZE_KB)  - sum(CURRENT_INDEX_SIZE_KB)  )  /1024  as [saved(MB)]
FROM DBA_REINDEX_TARGET_LIST A WITH(NOLOCK) 
WHERE exec_end_dt >= convert(nvarchar(10), getdate(), 121)
group by convert(date,exec_end_dt)


SELECT  b.target_seq %3 as mod, a.db_name, a.table_name, a.index_name, a.exec_start_dt, a.exec_end_dt
	 ,datediff(mi,a.exec_start_dt, isnull(a.exec_end_dt, getdate())) as diff_min, a.PAST_AVG_FRAGMENTATION_IN_PERCENT, a.CURRENT_AVG_FRAGMENTATION_IN_PERCENT
FROM DBA_REINDEX_TARGET_LIST A WITH(NOLOCK)
LEFT JOIN DBA_REINDEX_MOD_META B WITH(NOLOCK) ON A.TARGET_SEQ = B.TARGET_SEQ
WHERE exec_end_dt >= convert(nvarchar(10), getdate(), 121)
order by a.exec_start_dt
go
/*****************************************************************************************************************   
. 작 성 자: 전세환   
. 작 성 일: 2015-02-02   
. 유지보수: GmarketDBA팀 전세환   
. 기능구분: REINDEX 작업 Start
. 실행예제    
  - exec UP_DBA_START_REINDEX_PROCESS 
*****************************************************************************************************************   
변경내역:   
        수정일자        수정구분        수정자        수정내용   
==========================================================================   
       2015-02-02                    전세환        신규생성 
*****************************************************************************************************************/   
ALTER PROCEDURE dbo.UP_DBA_START_REINDEX_PROCESS

AS
BEGIN
	SET NOCOUNT ON

	EXEC msdb..sp_start_job '[DBA] REINDEX AUTOMATION - REINDEX MOD0'
	EXEC msdb..sp_start_job '[DBA] REINDEX AUTOMATION - REINDEX MOD1'
	EXEC msdb..sp_start_job '[DBA] REINDEX AUTOMATION - REINDEX MOD2'

END
go