USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_os_wait]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*************************************************************************  
* 프로시저명  : dbo.up_mon_os_wait
* 작성정보    : 2010-05-11 by choi bo ra
* 관련페이지  : os_wait 조회
* 내용        : 
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_os_wait] 
	 @to_date datetime
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

declare @pre_date datetime
declare @reg_date datetime
/* BODY */



select @reg_date =max(reg_date) from DB_MON_OS_WAIT with (nolock)  where reg_date <= @to_date
select @pre_date = max(reg_date) from DB_MON_OS_WAIT with (nolock) where reg_date < @reg_date

--select @reg_date, @pre_date


select ba.reg_date, pre.reg_date as pre_date
	,ba.wait_type, ba.waiting_tasks_count, (ba.waiting_tasks_count - pre.waiting_tasks_count) as diff_waiting_tasks_count
	,ba.wait_time_proportion
	,ba.average_wait_time_ms, (ba.average_wait_time_ms - pre.average_wait_time_ms) as diff_average_wait_time_ms
	,ba.total_wait_time_ms, (ba.total_wait_time_ms- pre.total_wait_time_ms) as diff_total_wait_time_ms
	,ba.total_wait_ex_signal_time_ms, pre.total_wait_ex_signal_time_ms
	,ba.max_wait_time_ms, pre.max_wait_time_ms
	,ba.total_signal_wait_time_ms, pre.total_signal_wait_time_ms
from DB_MON_OS_WAIT  as ba with (nolock)
	LEFT JOIN   DB_MON_OS_WAIT  as pre with (nolock) on ba.wait_type = pre.wait_type
		and pre.reg_date = @pre_date
where ba.reg_date = @reg_date 
order by ba.wait_time_proportion desc,ba.waiting_tasks_count desc

RETURN

GO
