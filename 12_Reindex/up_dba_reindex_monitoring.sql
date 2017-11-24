USE DBA
GO
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
from DBA.DBO.DBA_REINDEX_TARGET_LIST  with(nolock)
where ( REG_DT > DATEADD(DD,-7,GETDATE())  
	--OR EXEC_START_DT >= CONVERT(DATE, GETDATE())
	OR EXEC_END_DT IS NULL  OR EXEC_END_DT > CONVERT(VARCHAR(10), GETDATE(), 121)
	)

	AND AUTO_YN = 'Y'

select  min(exec_start_dt) as min_start_dt
		, max(exec_end_dt) as max_end_dt
		,datediff(mi,min(a.exec_start_dt), isnull(max(a.exec_end_dt),getdate()) )  as diff_min
		,count(*) as count
from DBA.DBO.DBA_REINDEX_TARGET_LIST a with(nolock)
inner join dba.dbo.dba_reindex_total_list b with(nolock) on a.index_seq = b.index_seq
where ( A.REG_DT > DATEADD(DD,-7,GETDATE())  	
	--OR EXEC_END_DT  IS NULL
	OR EXEC_END_DT IS NULL  OR EXEC_END_DT > CONVERT(VARCHAR(10), GETDATE(), 121)
		)
	AND AUTO_YN = 'Y'
GO


SELECT MOD, AUTO_YN , * 
 from DBA.DBO.DBA_REINDEX_TARGET_LIST  with(nolock)
where  ( REG_DT > DATEADD(DD,-7,GETDATE()) 
	--OR EXEC_START_DT >= CONVERT(DATE, GETDATE())
	OR EXEC_END_DT IS NULL  OR EXEC_END_DT > CONVERT(VARCHAR(10), GETDATE(), 121)
	)
	AND AUTO_YN = 'Y'
GO

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

GO


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
	
FROM DBA.DBO.DBA_REINDEX_TARGET_LIST A WITH(NOLOCK)
INNER JOIN DBA.DBO.DBA_REINDEX_TOTAL_LIST B WITH(NOLOCK) ON A.INDEX_SEQ = B.INDEX_SEQ
where ( A.REG_DT > DATEADD(DD,-7,GETDATE()) 
	OR EXEC_END_DT IS NULL  OR EXEC_END_DT > CONVERT(VARCHAR(10), GETDATE(), 121)
	) AND AUTO_YN ='Y'
GO

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
WHERE EXEC_END_DT > DATEADD(DD,-6, CONVERT(NVARCHAR(10), GETDATE(), 121) )




SELECT COUNT(*) AS REINDEX_COUNT
	, SUM(CASE WHEN EXEC_END_DT IS NOT NULL THEN 1 ELSE 0 END ) AS [완료건수]
	, COUNT(*)-SUM(CASE WHEN EXEC_END_DT IS NOT NULL THEN 1 ELSE 0 END ) AS [미완료건수]
	, SUM(PAST_INDEX_SIZE_KB -CURRENT_INDEX_SIZE_KB) /1024 as   [SAVED(MB)]
	, DATEDIFF(MI, MIN(EXEC_START_DT), MAX(EXEC_END_DT) ) AS [DIFF]
FROM DBA_REINDEX_TARGET_LIST WITH(NOLOCK)
WHERE EXEC_END_DT IS NULL OR EXEC_END_DT > DATEADD(DD,-6, CONVERT(NVARCHAR(10), GETDATE(), 121) )
GO



