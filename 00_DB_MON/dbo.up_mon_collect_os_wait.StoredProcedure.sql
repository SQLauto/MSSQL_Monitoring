USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_os_wait]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*************************************************************************  
* 프로시저명  : dbo.up_mon_collect_os_wait
* 작성정보    : 2010-04-07 by choi bo ra
* 관련페이지  : 
* 내용        :  sys.dm_os_wait_stats 누적값 수집후 clear
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_collect_os_wait] 
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @reg_date datetime

/* BODY */
exec UP_SWITCH_PARTITION @table_name = 'DB_MON_OS_WAIT',@column_name = 'reg_date'
set @reg_date = getdate()

INSERT INTO DB_MON_OS_WAIT 
(
	reg_date
	,wait_type
	,waiting_tasks_count
	,average_wait_time_ms
	,total_wait_time_ms
	,wait_time_proportion
	,total_wait_ex_signal_time_ms
	,max_wait_time_ms
	,total_signal_wait_time_ms )

SELECT
    @reg_date as reg_date,
   ws.wait_type,
   ws.waiting_tasks_count,
   CASE WHEN ws.waiting_tasks_count = 0 THEN 0 ELSE ws.wait_time_ms / ws.waiting_tasks_count END as average_wait_time_ms,  
   ws.wait_time_ms as total_wait_time_ms,  
   CONVERT(DECIMAL(12,2), ws.wait_time_ms * 100.0 / SUM(ws.wait_time_ms) OVER()) as wait_time_proportion,  
   ws.wait_time_ms - signal_wait_time_ms as total_wait_ex_signal_time_ms,
   ws.max_wait_time_ms,
   ws.signal_wait_time_ms as total_signal_wait_time_ms
FROM	sys.dm_os_wait_stats as ws with (nolock)
WHERE
   -- Restrict results to requests that have actually occured.
   ws.waiting_tasks_count > 0
ORDER BY waiting_tasks_count desc

if @@error <> 0 RETURN


-- 초기화
DBCC SQLPERF ('sys.dm_os_wait_stats', CLEAR)

RETURN

GO
