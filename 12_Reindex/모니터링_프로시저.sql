use dba
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
   case when count(*) - sum( case when exec_end_dt is not null   then 1 else 0 end) > 0  then '진행중' 
	when count(*) - sum( case when exec_end_dt is not null   then 1 else 0 end)  is null then '대상없음' else'완료' end as status
	, sum(case when exec_end_dt is null  and log_seq%3 = 0 then 1 else 0 end) as in_process_0
	, sum(case when exec_end_dt is not null and log_seq%3 = 0 then 1  else 0  end ) as complete_0
	, sum(case when exec_end_dt is null  and log_seq%3 = 1 then 1  else 0  end) as in_process_1
	, sum(case when exec_end_dt is not null and log_seq%3 = 1 then 1  else 0 end ) as complete_1
	, sum(case when exec_end_dt is null  and log_seq%3 = 2 then 1  else 0  end) as in_process_2
	, sum(case when exec_end_dt is not null and log_seq%3 = 2 then 1  else 0 end ) as complete_2
from dba_reindex_info_log  with(nolock)
where EXEC_START_DT >= dateadd(dd,-7, getdate())



select  min(exec_start_dt) as min_start_dt
		, max(exec_end_dt) as max_end_dt
		,datediff(mi,min(a.exec_start_dt), isnull(max(a.exec_end_dt),getdate()) )  as diff_min
		,count(*) as count
from dba_reindex_info_log a with(nolock)
inner join dba_reindex_total_list b with(nolock) on a.index_seq = b.index_seq
where EXEC_START_DT >= dateadd(dd,-7, getdate())

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
select  log_seq % 3 as mod,  b.index_seq, b.db_name, b.schema_name, b.table_name, b.index_name, b.row_count, b.index_size_kb, unused_index_size_kb
, a.* 
from dba_reindex_info_log a with(nolock)
inner join dba_reindex_total_list b with(nolock) on a.index_seq = b.index_seq
where  exec_end_dt is null
order by log_seq 



select  log_seq % 3 as mod,  a.exec_start_dt,  a.exec_end_dt,  datediff(mi,a.exec_start_dt, isnull(a.exec_end_dt,getdate()) )as diff_min
, b.index_seq, b.db_name, b.schema_name, b.table_name, b.index_name, b.row_count, b.index_size_kb, unused_index_size_kb
, a.* 
from dba_reindex_info_log a with(nolock)
inner join dba_reindex_total_list b with(nolock) on a.index_seq = b.index_seq
where exec_start_dt >= dateadd(dd,-7, getdate())
order by log_seq
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
	 COUNT(*)  as total_cnt
	 ,isnull(sum( case when EXEC_END_DT is not null   then 1 else 0 end) ,0)as complete_cnt
    , case when count(*) - sum( case when EXEC_END_DT is not null   then 1 else 0 end) > 0  then '' else'' end as status
	, isnull(sum(case when EXEC_END_DT is null  and TARGET_SEQ%3 = 0 then 1 else 0 end) ,0) as in_process_0
	, isnull(sum(case when EXEC_END_DT is not null and TARGET_SEQ%3 = 0 then 1  else 0  end )  ,0)as complete_0
	, isnull(sum(case when EXEC_END_DT is null  and TARGET_SEQ%3 = 1 then 1  else 0  end)  ,0)as in_process_1
	, isnull(sum(case when EXEC_END_DT is not null and TARGET_SEQ%3 = 1 then 1  else 0 end ) ,0) as complete_1
	, isnull(sum(case when EXEC_END_DT is null  and TARGET_SEQ%3 = 2 then 1  else 0  end) ,0) as in_process_2
	, isnull(sum(case when EXEC_END_DT is not null and TARGET_SEQ%3 = 2 then 1  else 0 end )  ,0)as complete_2
from DBA.DBO.DBA_REINDEX_TARGET_LIST  with(nolock)
where  REG_DT > DATEADD(DD,-7,GETDATE()) 
	OR EXEC_START_DT >= CONVERT(DATE, GETDATE())

select  min(exec_start_dt) as min_start_dt
		, max(exec_end_dt) as max_end_dt
		,datediff(mi,min(a.exec_start_dt), isnull(max(a.exec_end_dt),getdate()) )  as diff_min
		,count(*) as count
from DBA.DBO.DBA_REINDEX_TARGET_LIST a with(nolock)
inner join dba.dbo.dba_reindex_total_list b with(nolock) on a.index_seq = b.index_seq
where  A.REG_DT > DATEADD(DD,-7,GETDATE()) 
	OR EXEC_START_DT >= CONVERT(DATE, GETDATE())


go

/*************************************************************************  
* : dbo.up_dba_reindex_mon_reindex_detail
* 작성정보	: 2015-07-14 by choi bo ra
* 관련페이지:  
* 내용		:  진행 중인 대상 LIST

* 수정정보	: 
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_reindex_mon_reindex_detail
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
SELECT  A.TARGET_SEQ
		,A.DB_NAME
		,A.TABLE_NAME
		,A.INDEX_NAME
		,B.INDEX_TYPE_DESC
		,B.ISUNIQUE
		,B.ROW_COUNT
		,B.INDEX_SIZE_KB /1024 AS [INDEX_SIZE_MB]
		,A.CURRENT_INDEX_SIZE_KB /1024 AS [CURRENT_INDEX_SIZE_MB]
		,A.INDEX_SEQ
		,A.LOG_SEQ
		,A.PAST_AVG_FRAGMENTATION_IN_PERCENT
		,A.PAST_AVG_PAGE_SPACE_USED_IN_PERCENT
		,A.EXEC_START_DT
		,A.EXEC_END_DT
	
FROM DBA.DBO.DBA_REINDEX_TARGET_LIST A WITH(NOLOCK)
INNER JOIN DBA.DBO.DBA_REINDEX_TOTAL_LIST B WITH(NOLOCK) ON A.INDEX_SEQ = B.INDEX_SEQ
where  A.REG_DT > DATEADD(DD,-7,GETDATE()) 
	OR EXEC_START_DT >= CONVERT(DATE, GETDATE())



go




/*************************************************************************  
* 프로시저명: dbo.up_dba_reindex_mon_reindex_ing
* 작성정보	: 2015-07-14 by choi bo ra
* 관련페이지:  
* 내용		:  진행 중인 대상

* 수정정보	: 
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_reindex_mon_reindex_ing
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
--1. mod별 처리 현황
select * from DBA_REINDEX_MOD_META with(nolock)
go



/*************************************************************************  
* 프로시저명: dbo.up_dba_reindex_mon_reindex_complete
* 작성정보	: 2015-07-14 by choi bo ra
* 관련페이지:  
* 내용		:  완료 대상
* 수정정보	: 
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_reindex_mon_reindex_complete
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/

SELECT DB_NAME
	 ,TABLE_NAME,INDEX_NAME,PAST_AVG_FRAGMENTATION_IN_PERCENT
	, EXEC_START_DT, EXEC_END_DT
	, CURRENT_AVG_FRAGMENTATION_IN_PERCENT
	, (PAST_INDEX_SIZE_KB -CURRENT_INDEX_SIZE_KB) /1024 as   [SAVED(MB)]
	, PAST_INDEX_SIZE_KB
	, CURRENT_INDEX_SIZE_KB
FROM DBA_REINDEX_TARGET_LIST WITH(NOLOCK)
WHERE EXEC_START_DT >= CONVERT(DATE, GETDATE())
	OR REG_DT > DATEADD(DD,-7,GETDATE()) 


SELECT COUNT(*) AS REINDEX_COUNT
	, SUM(CASE WHEN EXEC_END_DT IS NOT NULL THEN 1 ELSE 0 END ) AS [완료건수]
	, COUNT(*)-SUM(CASE WHEN EXEC_END_DT IS NOT NULL THEN 1 ELSE 0 END ) AS [미완료건수]
	, SUM(PAST_INDEX_SIZE_KB -CURRENT_INDEX_SIZE_KB) /1024 as   [SAVED(MB)]
	, DATEDIFF(MI, MIN(EXEC_START_DT), MAX(EXEC_END_DT) ) AS [DIFF]
FROM DBA_REINDEX_TARGET_LIST WITH(NOLOCK)
WHERE EXEC_START_DT >= CONVERT(DATE, GETDATE())
	OR REG_DT > DATEADD(DD,-7,GETDATE()) 

go



/*************************************************************************  
* 프로시저명: dbo.up_dba_reindex_mon_reindex_process
* 작성정보	: 2015-07-14 by choi bo ra
* 관련페이지:  
* 내용		:  진행 인덱스 row 건수
* 수정정보	: 
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_reindex_mon_reindex_process
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
* 프로시저명: dbo.up_dba_reindex_mon_defrag_job
* 작성정보	: 2015-07-14 by choi bo ra
* 관련페이지:  
* 내용		:  job 실행 내역
* 수정정보	: 
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_reindex_mon_defrag_job
	@type  char(1) = 'A'
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
IF @TYPE = 'A'
BEGIN

SELECT   sj.name, min(sja.start_execution_date) as start_execution_date 
	, max(sja.stop_execution_date) as stop_execution_date
			when 99  then  
								case when  isnull(max(sja.stop_execution_date),getdate()-1) < convert(date,getdate()) then '미실행' else '성공' end 
				end  as [상태]
	FROM msdb.dbo.sysjobactivity AS sja
	INNER JOIN msdb.dbo.sysjobs AS sj ON sja.job_id = sj.job_id
	left JOIN msdb.dbo.sysjobhistory as sh on sj.job_id = sh.job_id  and sh.run_date >= convert(int,convert(nvarchar(8), getdate()-1,112))
where sj.name like '%REINDEX AUTOMATION - DEFRAG%'
  group by  sj.name
	--having   max(sja.stop_execution_date) is null
END
ELSE IF @TYPE = 'F'
	BEGIN
			SELECT   sj.name, min(sja.start_execution_date) as start_execution_date 
			, max(sja.stop_execution_date) as stop_execution_date
				when 99  then  
								case when  isnull(max(sja.stop_execution_date),getdate()-1) < convert(date,getdate()) then '미실행' else '성공' end 
				end  as [상태]
			FROM msdb.dbo.sysjobactivity AS sja
			INNER JOIN msdb.dbo.sysjobs AS sj ON sja.job_id = sj.job_id
			left JOIN msdb.dbo.sysjobhistory as sh on sj.job_id = sh.job_id  and sh.run_date >= convert(int,convert(nvarchar(8), getdate()-1,112))
			where sj.name like '%REINDEX AUTOMATION - DEFRAG%'
		    group by  sj.name
		    having  max(run_status )  = 0
	END
go


/*************************************************************************  
* 프로시저명: dbo.up_dba_reindex_mon_reindex_job
* 작성정보	: 2015-07-14 by choi bo ra
* 관련페이지:  
* 내용		:   reindex job 실행 내역
* 수정정보	: 
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_reindex_mon_reindex_job
	@type  char(1) = 'A'
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
IF @TYPE = 'A'
BEGIN

SELECT   sj.name, min(sja.start_execution_date) as start_execution_date 
	, max(sja.stop_execution_date) as stop_execution_date
	,case  isnull(max(run_status ),99)  when 1 then '성공' when 0 then '실패' when 3 then '취소됨' 
		when 99  then  
					case when  isnull(max(sja.stop_execution_date),getdate()-1) < convert(date,getdate()) then '미실행' else '성공' end 
	end  as [상태]
	FROM 
	 msdb.dbo.sysjobs AS sj  with(nolock)
	left join msdb.dbo.sysjobactivity AS sja   with(nolock) ON sja.job_id = sj.job_id
	left JOIN msdb.dbo.sysjobhistory as sh on sj.job_id = sh.job_id  and sh.run_date >= convert(int,convert(nvarchar(8), getdate(),112))
where sj.name like '%REINDEX AUTOMATION - REINDEX MOD%'
group by  sj.name
END
ELSE IF @TYPE = 'F'
	BEGIN
			SELECT   sj.name, min(sja.start_execution_date) as start_execution_date 
				, max(sja.stop_execution_date) as stop_execution_date
				,case  isnull(max(run_status ),99)  when 1 then '성공' when 0 then '실패' when 3 then '취소됨' 
					when 99  then  
								case when  isnull(max(sja.stop_execution_date),getdate()-1) < convert(date,getdate()) then '미실행' else '성공' end 
				end  as [상태]
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