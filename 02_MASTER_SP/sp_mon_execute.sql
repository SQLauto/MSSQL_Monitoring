use master
go

/*************************************************************************  
* 프로시저명  : dbo.sp_mon_execute
* 작성정보    : 2010-02-11 by 최보라
* 관련페이지  :  
* 내용        : sysprocess조회
* 수정정보    : 2013-10-18 BY 최보라, 조건 정리
*************************************************************************/
ALTER PROCEDURE [dbo].[sp_mon_execute]
      @iswaitfor     tinyint = 0
     ,@plan          tinyint = 0
    
AS

SET NOCOUNT ON

if @plan is null
    set @plan = 0

if @plan = 0
begin
   	select		convert(time(0), getdate()) as run_time,
                r.session_id as [sid]
    			,r.blocking_session_id [blocked]
    			,r.status
    			,r.cpu_time [cpu]
    			,datediff(ss, r.start_time, getdate()) as [duration]
    			,db_name(qt.dbid) db_name
    			,r.wait_type
				,r.logical_reads
				,convert(money,round(r.logical_reads/128.0,2))as logical_MB
    			,object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [object_name]
    			,isnull(substring(qt.text,r.statement_start_offset / 2 + 1,                          
					(case when r.statement_end_offset = -1                               
				     then len(convert(nvarchar(max), qt.text)) * 2                               
					else r.statement_end_offset end - r.statement_start_offset) / 2), '')
    			as query_text
    			,r.last_wait_type
				,s.login_name
    			,s.host_name
    			,case when s.program_name like 'SQLAgent - TSQL JobStep%' then 'SQLAgent - ' + isnull(j.name, '') 
    				 else s.program_name end program_name 
    			,qt.dbid
    			,qt.objectid
                ,r.total_elapsed_time  
    			,r.reads
    			,r.writes
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
				,r.percent_complete as '%'  
    			,r.plan_handle
    		from sys.dm_exec_requests r
    		    inner join sys.dm_exec_sessions s on r.session_id = s.session_id
            cross apply sys.dm_exec_sql_text(sql_handle) as qt
						left outer join msdb.dbo.sysjobs j
							on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
														substring(left(j.job_id,8),5,2) +
														substring(left(j.job_id,8),3,2) +
														substring(left(j.job_id,8),1,2))
    		where ((@iswaitfor = 0 and wait_type <> 'WAITFOR')
				or (@iswaitfor =  1 and ISNULL(wait_type, '') <> 'WAITFOR') 
				or (@iswaitfor = 2 and isnull(wait_type,'')  = isnull(wait_type, '')) )
              and  r.session_id != @@spid
    		order by r.cpu_time DESC
		
end		
if @plan = 1 -- Paln 쿼리.
begin
    
    
    
        select  convert(time(0), getdate()) as run_time,
                r.session_id as [sid]
    			,r.blocking_session_id [blocked]
    			,r.status
    			,r.cpu_time [cpu]
    			,datediff(ss, r.start_time, getdate()) as [duration]
    			,db_name(qt.dbid) db_name
				,r.wait_type
				,r.logical_reads
				,convert(money,round(r.logical_reads/128.0,2))as logical_MB
    			,object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [object_name]
    			,isnull(substring(qt.text,r.statement_start_offset / 2 + 1,                          
					(case when r.statement_end_offset = -1                               
				     then len(convert(nvarchar(max), qt.text)) * 2                               
					else r.statement_end_offset end - r.statement_start_offset) / 2), '')
    			as query_text
    			,r.last_wait_type
				,s.login_name
    			,s.host_name
    			,case when s.program_name like 'SQLAgent - TSQL JobStep%' then 'SQLAgent - ' + j.name else s.program_name end program_name 
					,s.program_name
    			,qt.dbid
    			,qt.objectid
				,r.total_elapsed_time  
    			,r.reads
    			,r.writes
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
                ,r.percent_complete as '%'     			
    			,r.plan_handle
    		    ,pt.query_plan
    		from sys.dm_exec_requests r
    		    inner join sys.dm_exec_sessions s on r.session_id = s.session_id
                 cross apply sys.dm_exec_sql_text(sql_handle) as qt
                 cross apply sys.dm_exec_query_plan(r.plan_handle) as pt
    		    left outer join msdb.dbo.sysjobs j
    			    on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
    												substring(left(j.job_id,8),5,2) +
    												substring(left(j.job_id,8),3,2) +
    												substring(left(j.job_id,8),1,2))
    		   
    		where ((@iswaitfor = 0 and wait_type <> 'WAITFOR')
				or (@iswaitfor =  1 and ISNULL(wait_type, '') <> 'WAITFOR') 
				or (@iswaitfor = 2 and isnull(wait_type,'')  = isnull(wait_type, '')) )
                  and  r.session_id != @@spid
    		order by r.cpu_time DESC
end
if @plan = 2  -- outer apply
begin
   select		convert(time(0), getdate()) as run_time,
				 r.session_id as [sid]
    			,r.blocking_session_id [blocked]
    			,r.status
    			,r.cpu_time [cpu]
    			,datediff(ss, r.start_time, getdate()) as [duration]
    			,db_name(qt.dbid) db_name
    			,r.wait_type
				,r.logical_reads
				,convert(money,round(r.logical_reads/128.0,2))as logical_MB
    			,object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [object_name]
    			,isnull(substring(qt.text,r.statement_start_offset / 2 + 1,                          
					(case when r.statement_end_offset = -1                               
				     then len(convert(nvarchar(max), qt.text)) * 2                               
					else r.statement_end_offset end - r.statement_start_offset) / 2), '')
    			as query_text
    			,r.last_wait_type
				,s.login_name
    			,s.host_name
    			,case when s.program_name like 'SQLAgent - TSQL JobStep%' then 'SQLAgent - ' + isnull(j.name, '') 
    				 else s.program_name end program_name 
    			,qt.dbid
    			,qt.objectid
                ,r.total_elapsed_time  
    			,r.reads
    			,r.writes
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
				,r.percent_complete as '%'  
    			,r.plan_handle
    		from sys.dm_exec_requests r
    		    inner join sys.dm_exec_sessions s on r.session_id = s.session_id
            outer apply sys.dm_exec_sql_text(sql_handle) as qt
						left outer join msdb.dbo.sysjobs j
							on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
														substring(left(j.job_id,8),5,2) +
														substring(left(j.job_id,8),3,2) +
														substring(left(j.job_id,8),1,2))
    		where ((@iswaitfor = 0 and wait_type <> 'WAITFOR')
				or (@iswaitfor =  1 and ISNULL(wait_type, '') <> 'WAITFOR') 
				or (@iswaitfor = 2 and isnull(wait_type,'')  = isnull(wait_type, '')) )
    		order by r.cpu_time DESC
		
end



