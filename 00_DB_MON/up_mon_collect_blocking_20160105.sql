ALTER PROCEDURE [dbo].[up_mon_collect_blocking]        
AS                                          
SET NOCOUNT ON                                          
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED                                          
                      
exec up_switch_partition @table_name = 'DB_MON_BLOCKING', @column_name = 'REG_DATE'  

declare @count  int
set @count  = 0

select @count = count(*)
from sys.sysprocesses with (nolock) where ecid =0 and kpid > 0 and blocked  != 0
               
if @count = 0 return

     
        
declare @reg_date datetime        
set @reg_date = getdate()        
        
declare @processes table (        
 session_id int,        
 blocking_session_id int,        
 login_name sysname,        
 host_name sysname,        
 program_name nvarchar(256),        
 last_wait_type nvarchar(120),        
 status nvarchar(32),        
 wait_resource nvarchar(512),        
 open_transaction_count int,        
 sql_handle varbinary(64),        
 stmt_start int,        
 stmt_end int,      
 ecid int ,
 wait_duration_ms bigint
        
)        
        
insert @processes (        
 session_id, blocking_session_id,        
 login_name, host_name, program_name, last_wait_type, status, wait_resource, open_transaction_count,         
 sql_handle, stmt_start, stmt_end, ecid ,wait_duration_ms   
)         
select         
 spid as session_id,        
 blocked as blocking_session_id,        
 loginame as login_name,        
 hostname as host_name,        
 program_name as program_name,        
 lastwaittype as last_wait_type,        
 status,        
 waitresource as wait_resource,        
 open_tran as open_transaction_count,        
 sql_handle as sql_handle,        
 stmt_start,        
 stmt_end,      
 ecid,   
 waittime  
from sys.sysprocesses b with (nolock)        
where ecid = 0

BEGIN TRY
;        
         
with cte_block (session_id, blocking_session_id, header_session_id, tree_session_id)        
AS (        
 select session_id, blocking_session_id, session_id,        
     convert(varchar(64), right('0000' + convert(varchar(64), session_id), 4)) as tree_session_id        
 from @processes  p        
 where blocking_session_id = 0 and session_id > 50        
   and exists (select top 1 * from @processes where blocking_session_id > 0 and blocking_session_id = p.session_id)        
 union all        
 select p.session_id, p.blocking_session_id, cte.header_session_id,         
     convert(varchar(64), convert(varchar(64), cte.tree_session_id) 
     	+  convert(varchar(64), right('0000' + convert(varchar(64), p.session_id), 4))) as tree_session_id        
 from @processes p        
  join cte_block cte on p.blocking_session_id = cte.session_id        
 where p.blocking_session_id <> 0 and p.session_id <> p.blocking_session_id        
)        
        
        
insert DB_MON_BLOCKING (                                  
 reg_date, header_session_id, session_id, blocking_session_id,                            
 db_name, object_name,                              
 resource_db_name, resource_object_name, --resource_index_id,                
 login_name, host_name, program_name, query_text,                                  
 last_wait_type, status,                        
 wait_type, wait_resource, wait_duration_ms,                        
 open_transaction_count, resource_address, resource_description,                            
 --resource_db_id, resource_hobt_id,
 tree_session_id                            
 )        
select top 1000         
 @reg_date,        
 cte.header_session_id,        
 p.session_id,        
 p.blocking_session_id,        
 DB_NAME(qt.dbid),        
 OBJECT_NAME(qt.objectid, qt.dbid),        
 isnull(db_name(qt.dbid), ''),         
 isnull(object_name(qt.objectid, qt.dbid), ''),         
-- isnull(ut.index_id, ''),          
 p.login_name,        
 p.host_name,      
 case when p.program_name like 'SQLAgent - TSQL JobStep%' then 'SQLAgent - ' + isnull(job.name, '') else p.program_name end,  
    left(isnull(substring(qt.text,p.stmt_start / 2 + 1,                                                            
     (case when p.stmt_end = -1                                                                 
         then len(convert(nvarchar(max), qt.text)) * 2                                
     else p.stmt_end end - p.stmt_start) / 2), ''), 512),           
 p.last_wait_type,        
 p.status,        
 task.wait_type,        
 p.wait_resource,  
 p.wait_duration_ms,
 --task.wait_duration_ms,        
 --req.wait_time as wait_duration_ms
 p.open_transaction_count,        
 task.resource_address,        
 task.resource_description,        
-- fnc.db_id,         
-- fnc.hobt_id,        
cte.tree_session_id        
from @processes p        
 join cte_block cte on p.session_id = cte.session_id        
    outer apply sys.dm_exec_sql_text (p.sql_handle) qt        
    left join sys.dm_exec_requests req with (nolock) on p.session_id = req.session_id           
    left join sys.dm_os_waiting_tasks  as task on req.task_address = task.waiting_task_address and p.blocking_session_id <> 0  
    left join msdb.dbo.sysjobs as job   
  on p.program_name like 'SQLAgent - TSQL JobStep%' and substring(p.program_name, 30, 34) = dbo.fnc_hexa2decimal(job.job_id)   
-- outer apply dbo.fnc_getresourcehobt(task.resource_description) as fnc                     
-- left join DB_MON_USER_TABLE as ut (nolock) on fnc.db_id = ut.db_id and fnc.hobt_id = ut.hobt_id               
option (MAXRECURSION 3)
END TRY
BEGIN CATCH
	PRINT 'MAX RECURSION OF 3 HAS BEEN EXCEEDED'
END CATCH
go

--fnc_getresourcehobt

--select top 10 * , 
-- fnc.db_id,         
-- fnc.hobt_id      
    
--from DB_MON_BLOCKING as blo with(nolock)
--	outer apply dbo.fnc_getresourcehobt(blo.resource_description) as fnc 
--	left join DB_MON_USER_TABLE as ut (nolock) on fnc.db_id = ut.db_id and fnc.hobt_id = ut.hobt_id 
-- order by blo.reg_date desc


