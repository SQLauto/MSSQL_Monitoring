USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_os_schedulers]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*************************************************************************  
* 프로시저명  : dbo.up_mon_collect_os_schedulers
* 작성정보    : 2010-05-04 by choi bo ra os_schedulers 수집
* 관련페이지  : 
* 내용        : 
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_collect_os_schedulers] 
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
/* USER DECLARE */
declare @reg_date datetime
/* BODY */
set @reg_date = getdate()
exec UP_SWITCH_PARTITION  @table_name = 'DB_MON_OS_SCHEDULERS',@column_name = 'reg_date'

INSERT INTO DB_MON_OS_SCHEDULERS
(reg_date
,scheduler_id
,parent_node_id
,scheduler_address
,cpu_id
,status
,is_online
,is_idle
,preemptive_switches_count
,context_switches_count
,idle_switches_count
,current_tasks_count
,runnable_tasks_count
,current_workers_count
,active_workers_count
,work_queue_count
,pending_disk_io_count
,load_factor
,yield_count
,last_timer_activity
,failed_to_create_worker
,active_worker_address
,memory_object_address
,task_memory_object_address  )
select
 @reg_date
 ,scheduler_id
,parent_node_id
,scheduler_address
,cpu_id
,status
,is_online
,is_idle
,preemptive_switches_count
,context_switches_count
,idle_switches_count
,current_tasks_count
,runnable_tasks_count
,current_workers_count
,active_workers_count
,work_queue_count
,pending_disk_io_count
,load_factor
,yield_count
,last_timer_activity
,failed_to_create_worker
,active_worker_address
,memory_object_address
,task_memory_object_address
from  sys.dm_os_schedulers  with (nolock)          
where scheduler_id < 255



RETURN

GO
