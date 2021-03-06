USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_memory_grant_ms]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*************************************************************************  
* 프로시저명  : dbo.up_mon_collect_memory_grant_ms
* 작성정보    : 2013-06-21 서은미
* 관련페이지  :  
* 내용        : ms report용 memory grant query collect
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_collect_memory_grant_ms] 
AS
/* COMMON DECLARE */
SET NOCOUNT ON

SET QUERY_GOVERNOR_COST_LIMIT 1000
 
/* 아래 성능 카운터 조건에 해당할 때, 실행 중인 쿼리에 대해서 아래 조건에 만족하는 쿼리를 수집함 */ 
IF EXISTS (
              SELECT 1
              FROM sys.dm_os_performance_counters with(nolock)
              WHERE counter_name = 'Memory Grants Outstanding' AND cntr_value >= 100
              )
       AND EXISTS (
              SELECT 1
              FROM sys.dm_os_performance_counters with(nolock)
              WHERE counter_name = 'Cache Objects in use' AND instance_name = 'Temporary Tables & Table Variables' AND cntr_value >= 100
              )

BEGIN

INSERT DB_MON_MEMORY_GRANT_REPORT
SELECT getdate() AS [DateTime]
       ,G.granted_memory_kb
       ,R.session_id
       ,R.database_id
       ,S.login_name
       ,T.TEXT
       ,R.start_time
       ,R.STATUS
       ,R.command
       ,R.wait_time
       ,R.cpu_time
       ,R.reads
       ,R.writes
       ,R.logical_reads
FROM sys.dm_exec_requests R
INNER LOOP JOIN sys.dm_exec_sessions S ON (R.session_id = S.session_id)
CROSS APPLY sys.dm_exec_sql_text(R.sql_handle) AS T
INNER LOOP JOIN sys.dm_exec_query_memory_grants G ON (R.session_id = G.session_id) 
WHERE R.session_id > 50
       AND R.session_id <> @@SPID
       AND R.cpu_time > 100 
ORDER BY G.granted_memory_kb DESC
OPTION (MAXDOP 1)
END

GO
