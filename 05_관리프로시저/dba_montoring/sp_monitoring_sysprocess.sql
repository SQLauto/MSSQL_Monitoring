USE [master]
GO
/****** 개체:  StoredProcedure [dbo].[sp_monitoring_sysproces]    스크립트 날짜: 02/04/2010 17:05:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*************************************************************************  
* 프로시저명  : dbo.sp_monitoring_sysprocess 
* 작성정보    : 2009-11-11
* 관련페이지  :  
* 내용        : sysprocess 수집 & 조회
* 수정정보    :
*************************************************************************/
CREATE PROCEDURE [dbo].[sp_monitoring_sysproces]
     @type            tinyint  = 0
    ,@duration_ms    int = 0
    ,@plan           tinyint = 0
    
AS

SET NOCOUNT ON

if @type is null 
    set @type = 0
    
if @duration_ms is null
    set @duration_ms = 0
    
if @plan is null
    set @plan = 0

if @type = 0
begin
    
    if @plan = 0
    begin
        select 
                r.session_id as [sid]
    			,r.blocking_session_id [blocked_id]
    			,r.status
    			,r.cpu_time [cpu_by_requests]
    			,s.cpu_time [cpu_by_session]
    			,r.wait_type
                ,r.last_wait_type
                --,tsk.wait_duration_ms
    			,db_name(qt.dbid) db_name
    			,object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [object_name]
    			,substring(qt.text,r.statement_start_offset/2,
    			(case when r.statement_end_offset = -1
    			then len(convert(nvarchar(max), qt.text)) * 2
    			else r.statement_end_offset end - r.statement_start_offset)/2)
    			as query_text
    			,r.percent_complete as '%'  
    			,qt.dbid
    			,qt.objectid
                ,r.total_elapsed_time  
    			,r.reads
    			,r.writes
    			,r.logical_reads
    			,r.scheduler_id
    			,CASE s.transaction_isolation_level 
                      WHEN 0 THEN 'Unspecified'
                      WHEN 1 THEN 'ReadUncomitted'
                      WHEN 2 THEN 'ReadCommitted'        
                      WHEN 3 THEN 'Repeatable'
                      WHEN 4 THEN 'Serializable'
                      WHEN 5 THEN 'Snapshot' END AS tx_level
    			,r.wait_resource
    			,r.open_transaction_count
    			,r.row_count
    			,s.login_name
    			,s.host_name
    			,case when s.program_name like 'SQLAgent - TSQL JobStep%' then j.name else s.program_name end program_name 
    			,r.plan_handle
    			,r.statement_start_offset
    			,r.statement_end_offset
    		from sys.dm_exec_requests r
    		    inner join sys.dm_exec_sessions s on r.session_id = s.session_id
    		    --inner join sys.dm_os_waiting_tasks tsk on tsk.session_id = r.session_id
    		    left outer join msdb.dbo.sysjobs j
    			    on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
    												substring(left(j.job_id,8),5,2) +
    												substring(left(j.job_id,8),3,2) +
    												substring(left(j.job_id,8),1,2))
    		    cross apply sys.dm_exec_sql_text(sql_handle) as qt
    		where r.session_id > 49 --and s.host_name <> @@servername
    		   -- and tsk.wait_duration_ms > @duration_ms
    		order by r.cpu_time DESC
    		
   end		
   if @plan = 1 -- Paln 쿼리.
   begin
            select 
                r.session_id as [sid]
    			,r.blocking_session_id [blocked_id]
    			,r.status
    			,r.cpu_time [cpu_by_requests]
    			,s.cpu_time [cpu_by_session]
    			,r.wait_type
                ,r.last_wait_type
                --,tsk.wait_duration_ms
    			,db_name(qt.dbid) db_name
    			,object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [object_name]
    			,substring(qt.text,r.statement_start_offset/2,
    			(case when r.statement_end_offset = -1
    			then len(convert(nvarchar(max), qt.text)) * 2
    			else r.statement_end_offset end - r.statement_start_offset)/2)
    			as query_text
    			,r.percent_complete as '%'  
    			,qt.dbid
    			,qt.objectid
                ,r.total_elapsed_time  
    			,r.reads
    			,r.writes
    			,r.logical_reads
    			,r.scheduler_id
    			,CASE s.transaction_isolation_level 
                      WHEN 0 THEN 'Unspecified'
                      WHEN 1 THEN 'ReadUncomitted'
                      WHEN 2 THEN 'ReadCommitted'        
                      WHEN 3 THEN 'Repeatable'
                      WHEN 4 THEN 'Serializable'
                      WHEN 5 THEN 'Snapshot' END AS tx_level
    			,r.wait_resource
    			,r.open_transaction_count
    			,r.row_count
    			,s.login_name
    			,s.host_name
    			,case when s.program_name like 'SQLAgent - TSQL JobStep%' then j.name else s.program_name end program_name 
    			,r.plan_handle
    			,r.statement_start_offset
    			,r.statement_end_offset
    			,pt.query_plan
    		from sys.dm_exec_requests r
    		    inner join sys.dm_exec_sessions s on r.session_id = s.session_id
    		   -- inner join sys.dm_os_waiting_tasks tsk on tsk.session_id = r.session_id
    		    left outer join msdb.dbo.sysjobs j
    			    on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
    												substring(left(j.job_id,8),5,2) +
    												substring(left(j.job_id,8),3,2) +
    												substring(left(j.job_id,8),1,2))
    		    cross apply sys.dm_exec_sql_text(sql_handle) as qt
    		    cross apply sys.dm_exec_query_plan(r.plan_handle) as pt
    		where r.session_id > 49 -- and s.host_name <> @@servername
    		    --and tsk.wait_duration_ms > @duration_ms
    		order by r.cpu_time DESC
   end
end
else if @type = 1 --table 저장
begin
    
            insert into MONITOR_SYSPROCESS
                (
                     
                    reg_dt  
                    ,session_id  
                    ,blocked_id  
                    ,status   
                    ,cpu_by_requests    
                    ,cpu_by_session 
                    ,wait_type    
                    ,last_wait_type 
                    ,wait_duration_ms
                    ,db_name 
                    ,object_name 
                    ,query_text 
                    ,db_id       
                    ,objectid   
                    ,total_elapsed_time  
                    ,reads      
                    ,writes     
                    ,logical_reads  
                    ,scheduler_id    
                    ,tx_level           
                    ,wait_resource 
                    ,open_tran_cnt   
                    ,row_count      
                    ,login_name   
                    ,host_name  
                    ,program_name 
                    ,plan_handle 
                    ,statement_start_offset 
                    ,statement_end_offset  )
            select  getdate() as reg_dt
                , r.session_id as [sid]
    			,r.blocking_session_id [blocked_id]
    			,r.status
    			,r.cpu_time [cpu_by_requests]
    			,s.cpu_time [cpu_by_session]
                ,tsk.wait_type
                ,r.last_wait_type
                ,tsk.wait_duration_ms
    			,db_name(qt.dbid) db_name
    			,object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [object_name]
    			,substring(qt.text,r.statement_start_offset/2,
    			(case when r.statement_end_offset = -1
    			then len(convert(nvarchar(max), qt.text)) * 2
    			else r.statement_end_offset end - r.statement_start_offset)/2)  as query_text
    			--,r.percent_complete as '%'  
    			,qt.dbid
    			,qt.objectid
                ,r.total_elapsed_time  
    			,r.reads
    			,r.writes
    			,r.logical_reads
    			,r.scheduler_id
    			,CASE s.transaction_isolation_level 
                      WHEN 0 THEN 'Unspecified'
                      WHEN 1 THEN 'ReadUncomitted'
                      WHEN 2 THEN 'ReadCommitted'        
                      WHEN 3 THEN 'Repeatable'
                      WHEN 4 THEN 'Serializable'
                      WHEN 5 THEN 'Snapshot' END AS tx_level
    			,r.wait_resource
    			,r.open_transaction_count
    			,r.row_count
    			,s.login_name
    			,s.host_name
    			,case when s.program_name like 'SQLAgent - TSQL JobStep%' then j.name else s.program_name end program_name 
    			,r.plan_handle
    			,r.statement_start_offset
    			,r.statement_end_offset
    		from sys.dm_exec_requests r
    		    inner join sys.dm_exec_sessions s on r.session_id = s.session_id
    		    inner join sys.dm_os_waiting_tasks tsk on tsk.session_id = r.session_id
    		    left outer join msdb.dbo.sysjobs j
    			    on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
    												substring(left(j.job_id,8),5,2) +
    												substring(left(j.job_id,8),3,2) +
    												substring(left(j.job_id,8),1,2))
    		    cross apply sys.dm_exec_sql_text(sql_handle) as qt
    		where r.session_id > 49 --and s.host_name <> @@servername
    		    --and tsk.wait_duration_ms > @duration_ms
    		order by r.cpu_time DESC
end
		
RETURN