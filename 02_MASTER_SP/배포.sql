use dba
go
set nocount on

CREATE TABLE dbo.DBA_MON (
  seq_no    int           NOT NULL IDENTITY(1, 1)
, sp_name   sysname       NOT NULL 
, parameter nvarchar(300) NULL     
, sp_desc   nvarchar(300) NULL     
, reg_id    nvarchar(10)  NULL     
, sp_type   tinyint       NULL     
, class     nvarchar(20)  NOT NULL 
, priority  tinyint       NULL     
)

CREATE CLUSTERED INDEX CIDX_class__priority ON dbo.dba_mon (class, priority)

ALTER TABLE dbo.dba_mon ADD CONSTRAINT PK_dba_mon PRIMARY KEY NONCLUSTERED (seq_no)
go
SET IDENTITY_INSERT dba_mon ON
INSERT dba_mon (seq_no, sp_name, parameter, sp_desc, reg_id, sp_type, class, priority)  VALUES (3, 'sp_mon_blocking', NULL, '블로킹 정보, is_blocker = 1 블로킹 유발', 'ceusee', 1, 'connection', 1)
INSERT dba_mon (seq_no, sp_name, parameter, sp_desc, reg_id, sp_type, class, priority)  VALUES (10, 'dbcc opentran', '', '활성트랜잭션', 'ceusee', 0, 'connection', 1)
INSERT dba_mon (seq_no, sp_name, parameter, sp_desc, reg_id, sp_type, class, priority)  VALUES (4, 'sp_mon_top_cpu', '@row_count=15, @delay_time=''00:00:02''', '기간동안 CPU높은 쿼리', 'ceusee', 1, 'cpu', 1)
INSERT dba_mon (seq_no, sp_name, parameter, sp_desc, reg_id, sp_type, class, priority)  VALUES (1, 'sp_mon_execute', '@iswaitfor=0, @plan=0', '현재 실행 중인 쿼리 (sys.dm_exec_requests) ', 'ceusee', 1, 'cpu', 1)
INSERT dba_mon (seq_no, sp_name, parameter, sp_desc, reg_id, sp_type, class, priority)  VALUES (2, 'sp_mon_con_byhost', NULL, 'host별 connection', 'seolee', 1, 'cpu', 1)
INSERT dba_mon (seq_no, sp_name, parameter, sp_desc, reg_id, sp_type, class, priority)  VALUES (11, 'dbcc sqlperf(''logspace'')', '', 'Log Space Used', 'ceusee', 0, 'db', 3)
INSERT dba_mon (seq_no, sp_name, parameter, sp_desc, reg_id, sp_type, class, priority)  VALUES (12, 'dbcc loginfo', '', 'Log VLF', 'ceusee', 0, 'db', 3)
INSERT dba_mon (seq_no, sp_name, parameter, sp_desc, reg_id, sp_type, class, priority)  VALUES (13, 'sp_mon_change_procedure', '@duration=60', '기간 동안 변경된 프로시져 리스트', 'seolee', 1, 'etc', 3)
INSERT dba_mon (seq_no, sp_name, parameter, sp_desc, reg_id, sp_type, class, priority)  VALUES (6, 'sp_mon_logjob', '@durtion=60', '오래 실행중인 JOB 내역', 'ceusee', 1, 'job', 2)
INSERT dba_mon (seq_no, sp_name, parameter, sp_desc, reg_id, sp_type, class, priority)  VALUES (5, 'sp_mon_tempuse', '@type=0', 'tempdb 사용 쿼리', 'seolee', 1, 'memory', 2)
INSERT dba_mon (seq_no, sp_name, parameter, sp_desc, reg_id, sp_type, class, priority)  VALUES (7, 'sp_mon_replication_perf', '', '복제-배포자 성능', 'seolee', 1, 'service', 2)
INSERT dba_mon (seq_no, sp_name, parameter, sp_desc, reg_id, sp_type, class, priority)  VALUES (8, 'sp_mon_replication_status', '', '복제-배포자 상태', 'ceusee', 1, 'service', 2)
INSERT dba_mon (seq_no, sp_name, parameter, sp_desc, reg_id, sp_type, class, priority)  VALUES (9, 'sp_mon_mirroring_status', '', '미러링-연결 상태', 'ceusee', 1, 'service', 2)
SET IDENTITY_INSERT dba_mon OFF
go

use master
go
if object_id('sp_mon_execute') is not null drop procedure sp_mon_execute
go
if object_id('sp_mon_con_byhost') is not null drop procedure sp_mon_con_byhost
go
if object_id('sp_mon_blocking') is not null drop procedure sp_mon_blocking
go
if object_id('sp_mon_top_cpu') is not null drop procedure sp_mon_top_cpu
go
if object_id('sp_mon_tempuse') is not null drop procedure sp_mon_tempuse
go
if object_id('sp_mon_logjob') is not null drop procedure sp_mon_logjob
go
if object_id('sp_mon_replication_perf') is not null drop procedure sp_mon_replication_perf
go
if object_id('sp_mon_replication_status') is not null drop procedure sp_mon_replication_status
go
if object_id('sp_mon_mirroring_status') is not null drop procedure sp_mon_mirroring_status
go
if object_id('sp_mon_change_procedure') is not null drop procedure sp_mon_change_procedure
go
/*************************************************************************  
* 프로시저명  : dbo.sp_mon_execute
* 작성정보    : 2010-02-11 by 최보라
* 관련페이지  :  
* 내용        : sysprocess조회
* 수정정보    :
*************************************************************************/
CREATE PROCEDURE dbo.sp_mon_execute
     @iswaitfor      tinyint = 0
     ,@plan          tinyint = 0
    
AS

SET NOCOUNT ON

if @plan is null
    set @plan = 0

    
if @plan = 0
begin
   select 
                r.session_id as [sid]
    			,r.blocking_session_id [blocked]
    			,r.status
    			,r.cpu_time [cpu]
    			,datediff(ss, r.start_time, getdate()) as [duration]
    			,db_name(qt.dbid) db_name
    			,object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [object_name]
    			,isnull(substring(qt.text,r.statement_start_offset / 2 + 1,                          
					(case when r.statement_end_offset = -1                               
				     then len(convert(nvarchar(max), qt.text)) * 2                               
					else r.statement_end_offset end - r.statement_start_offset) / 2), '')
    			as query_text
                ,r.last_wait_type
                ,s.login_name
    			,s.host_name
    			--,case when s.program_name like 'SQLAgent - TSQL JobStep%' then j.name else s.program_name end program_name 
                ,s.program_name
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
                ,r.percent_complete as '%'  
    			,r.plan_handle
    		from sys.dm_exec_requests r
    		    inner join sys.dm_exec_sessions s on r.session_id = s.session_id
                cross apply sys.dm_exec_sql_text(sql_handle) as qt
--    		    left outer join msdb.dbo.sysjobs j
--    			    on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
--    												substring(left(j.job_id,8),5,2) +
--    												substring(left(j.job_id,8),3,2) +
--    												substring(left(j.job_id,8),1,2))
    		   
    		where s.IS_USER_PROCESS = 1 
                and  ((@iswaitfor = 1 and wait_type  = wait_type) or  (wait_type <> 'WAITFOR'))
    		order by r.cpu_time DESC
		
end		
if @plan = 1 -- Paln 쿼리.
begin
    
    
    
        select 
                r.session_id as [sid]
    			,r.blocking_session_id [blocked]
    			,r.status
    			,r.cpu_time [cpu]
    			,datediff(ss, r.start_time, getdate()) as [duration]
    			,db_name(qt.dbid) db_name
    			,object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [object_name]
    			,isnull(substring(qt.text,r.statement_start_offset / 2 + 1,                          
					(case when r.statement_end_offset = -1                               
				     then len(convert(nvarchar(max), qt.text)) * 2                               
					else r.statement_end_offset end - r.statement_start_offset) / 2), '')
    			as query_text
                ,r.last_wait_type
                ,s.login_name
    			,s.host_name
    			--,case when s.program_name like 'SQLAgent - TSQL JobStep%' then j.name else s.program_name end program_name 
                ,s.program_name
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
                ,r.percent_complete as '%'     			
    			,r.plan_handle
    		    ,pt.query_plan
    		from sys.dm_exec_requests r
    		    inner join sys.dm_exec_sessions s on r.session_id = s.session_id
                 cross apply sys.dm_exec_sql_text(sql_handle) as qt
                 cross apply sys.dm_exec_query_plan(r.plan_handle) as pt
--    		    left outer join msdb.dbo.sysjobs j
--    			    on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
--    												substring(left(j.job_id,8),5,2) +
--    												substring(left(j.job_id,8),3,2) +
--    												substring(left(j.job_id,8),1,2))
    		   
    		where s.IS_USER_PROCESS = 1 
                and  ((@iswaitfor = 1 and wait_type  = wait_type) or  (wait_type <> 'WAITFOR'))
    		order by r.cpu_time DESC
end
RETURN
;

go

CREATE PROCEDURE dbo.sp_mon_con_byhost
AS
SET NOCOUNT ON 
    select dbo.fnc_removenumeric(hostname) as hostname, count(*) as connection_count
    FROM sys.sysprocesses with (nolock)  
    where spid > 50
    group by dbo.fnc_removenumeric(hostname)  
    order by count(*) desc  
;
go

/*************************************************************************  
* 프로시저명  : dbo.sp_mon_blocking 
* 작성정보    : 2010-02-22 by 윤태진
* 관련페이지  :  
* 내용        :
* 수정정보    : 2010-02-22 by 최보라 수정
**************************************************************************/
CREATE PROCEDURE dbo.sp_mon_blocking
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

/* USER DECLARE */

/* BODY */
select req.session_id as session_id
    ,req.blocking_session_id as blocking_session_id 
    into #temp_blocking
from sys.dm_exec_requests req with(nolock)
where req.session_id > 50

IF exists(select top 1  * from #temp_blocking with(nolock) where blocking_session_id > 0 )
BEGIN
    select
         blocking.sid 
        ,blocking.blocked
        ,blocking.is_blocker
        ,blocking.cpu
        ,blocking.db_name
        ,blocking.object_name
        ,blocking.login_name
        ,blocking.host_name
        ,blocking.program_name
        ,blocking.query_text
        ,blocking.last_wait_type
        ,blocking.total_elapsed_time 
        ,blocking.status
        ,blocking.reads
        ,blocking.writes
        ,blocking.logical_reads
        ,blocking.scheduler_id
        ,blocking.wait_type
        ,blocking.wait_resource
        ,blocking.open_transaction_count

    from (
            select r.session_id  as sid 
            , r.blocking_session_id as blocked
            , 1 as is_blocker
            , r.status
    	    , r.cpu_time [cpu]
            , db_name(t1.dbid) as db_name 
            , object_schema_name(t1.objectid,t1.dbid) + '.' + object_name(t1.objectid,t1.dbid) [object_name]
            ,s.login_name
            ,s.host_name
            ,case when s.program_name like 'SQLAgent - TSQL JobStep%' then j.name else s.program_name end program_name 
            ,substring(t1.text,r.statement_start_offset/2 + 1,
            			(case when r.statement_end_offset = -1
            			then len(convert(nvarchar(max), t1.text)) * 2
            			else r.statement_end_offset end - r.statement_start_offset)/2)
            as query_text
            ,r.last_wait_type
            ,r.total_elapsed_time 
            ,r.reads
            ,r.writes
            ,r.logical_reads
            ,r.scheduler_id
            ,r.wait_type
            ,r.wait_resource
            ,r.open_transaction_count
            from sys.dm_exec_requests r with(nolock) 
            inner join sys.dm_exec_sessions s with(nolock) on r.session_id = s.session_id 
            left  join msdb.dbo.sysjobs j with(nolock) on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
            												substring(left(j.job_id,8),5,2) +
            												substring(left(j.job_id,8),3,2) +
            												substring(left(j.job_id,8),1,2))
            cross apply sys.dm_exec_sql_text (r.sql_handle) as t1
            where r.session_id in (select distinct blocking_session_id from #temp_blocking with(nolock) )
            
            union all 
            
            select r.session_id  as sid
            , r.blocking_session_id as blocked
            , 0 as is_blocker
            , r.status
    	    , r.cpu_time [cpu]
            , db_name(t1.dbid) as db_name 
            , object_schema_name(t1.objectid,t1.dbid) + '.' + object_name(t1.objectid,t1.dbid) [object_name]
            , s.login_name
            , s.host_name
            ,case when s.program_name like 'SQLAgent - TSQL JobStep%' then j.name else s.program_name end program_name 
            ,substring(t1.text,r.statement_start_offset/2,
            			(case when r.statement_end_offset = -1
            			then len(convert(nvarchar(max), t1.text)) * 2
            			else r.statement_end_offset end - r.statement_start_offset)/2)
                as query_text
            ,r.last_wait_type
            ,r.total_elapsed_time 
            ,r.reads
            ,r.writes
            ,r.logical_reads
            ,r.scheduler_id
            ,r.wait_type
            ,r.wait_resource
            ,r.open_transaction_count
            from sys.dm_exec_requests r with(nolock) 
            inner join sys.dm_exec_sessions s with(nolock) on r.session_id = s.session_id 
            left  join msdb.dbo.sysjobs j with(nolock) on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
            												substring(left(j.job_id,8),5,2) +
            												substring(left(j.job_id,8),3,2) +
            												substring(left(j.job_id,8),1,2))
            cross apply sys.dm_exec_sql_text (r.sql_handle) as t1
            where r.session_id in (select distinct session_id from #temp_blocking with(nolock) where blocking_session_id > 0 )
    )blocking

END

RETURN

go

/*************************************************************************  
* 프로시저명  : dbo.sp_mon_top_cpu 
* 작성정보    : 2010-02-22 by 최보라
* 관련페이지  :  
* 내용        : 2초간 CPU 높은 쿼리
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.sp_mon_top_cpu
     @row_count  int = 15
    ,@delay_time datetime  = '00:00:02'

AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
SET LOCK_TIMEOUT 10000

/* USER DECLARE */

/* BODY */
        -- insert sys.dm_exec_requests into temp table !
		select 
    		 session_id
    		,request_id 
    		,connection_id
    		,sql_handle
    		,cpu_time
    		,(writes + reads) as physical_io 
    	into #tmp_requests 
		from sys.dm_exec_requests with(nolock) 
		
	
	  -- delay with parameter

		WAITFOR DELAY @delay_time
		
		
		----------------------------------------------------------------
	  -- find 
	  ----------------------------------------------------------------
	    select top(@row_count) 
    			req.session_id as sid
                ,case when qt.objectid is null then
    			    isnull(substring(qt.text,req.statement_start_offset / 2 + 1,                          
					    (case when req.statement_end_offset = -1                               
				         then len(convert(nvarchar(max), qt.text)) * 2   
                         else req.statement_end_offset end - req.statement_start_offset) / 2), '')
                    else object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid)  end [object_name]
    			,(req.cpu_time - tmp.cpu_time) as cpu_gap
    			, req.cpu_time
    			,(req.reads + req.writes) as physical_io
    			,session.login_name 
    			,session.host_name
    			,req.start_time
    			,session.program_name
    		    ,req.sql_handle
		from sys.dm_exec_requests req with(nolock)
			inner join sys.dm_exec_sessions session with(nolock) on req.session_id = session.session_id
			inner join #tmp_requests tmp with(nolock) 
			    on ( req.session_id = tmp.session_id and  req.request_id = tmp.request_id)
			cross apply sys.dm_exec_sql_text(req.sql_handle) as qt
		where session.is_user_process = 1 
		    and session.host_name <> @@servername and object_name(qt.objectid,qt.dbid)  != 'sp_mon_top_cpu'
		order by (req.cpu_time - tmp.cpu_time) desc , req.cpu_time desc 


DROP TABLE  #tmp_requests 
RETURN

go

/*************************************************************************  
* 프로시저명  : dbo.sp_mon_tempuse 
* 작성정보    : 2010-02-19 by choi bo ra
* 관련페이지  :  
* 내용        :
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.sp_mon_tempuse
    @type       int = 0
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */

IF @type = 0
BEGIN
    select  
         u.session_id,    
        s.host_name,    
        s.login_name,  
        s.status,  
        s.program_name, 
        sum(u.user_objects_alloc_page_count+u.internal_objects_alloc_page_count)*8 tempdb_space_alloc_kB,    
        sum(u.user_objects_dealloc_page_count+u.internal_objects_dealloc_page_count)*8 tempdb_space_dealloc_kB,   
        sum(u.user_objects_alloc_page_count+u.internal_objects_alloc_page_count -u.user_objects_dealloc_page_count - u.internal_objects_dealloc_page_count)*8 remaining_tempdb_space_alloc_kB    
    from sys.dm_db_session_space_usage as u   
        join sys.dm_exec_sessions as s on s.session_id = u.session_id   
    where u.database_id = 2    
    group by u.session_id, s.host_name,  s.status, s.login_name, s.program_name   
    order by 6 desc  
END
ELSE IF @type = 1
BEGIN
    select  
        u.session_id, 
        s.host_name,    
        s.login_name,  
        s.status,  
        object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [object_name],
        s.program_name, 
        sum(u.user_objects_alloc_page_count+u.internal_objects_alloc_page_count)*8 tempdb_space_alloc_kB,    
        sum(u.user_objects_dealloc_page_count+u.internal_objects_dealloc_page_count)*8 tempdb_space_dealloc_kB,   
        sum(u.user_objects_alloc_page_count+u.internal_objects_alloc_page_count -u.user_objects_dealloc_page_count - u.internal_objects_dealloc_page_count)*8 remaining_tempdb_space_alloc_kB    
    from sys.dm_db_session_space_usage as u   
        join sys.dm_exec_sessions as s on s.session_id = u.session_id   
        left join sys.dm_exec_requests r on s.session_id = r.session_id
        outer  apply sys.dm_exec_sql_text(sql_handle) as qt
    where u.database_id = 2  and u.session_id > 50 --and r.wait_type <> 'WAITFOR'
    group by u.session_id, s.host_name,  s.status, s.login_name, s.program_name 
        ,  object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid)
    order by  7 desc  

END


RETURN

go

/*************************************************************************  
* 프로시저명  : dbo.sp_mon_logjob
* 작성정보    : 2010-02-22 by 최보라
* 관련페이지  :  
* 내용        : 1시간 이상  경과한 job 목록
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.sp_mon_logjob
    @durtion        int = 60
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
select 'KILL ' + cast(s.session_id as varchar) as 'kill', 
               s.session_id,
	           j.name as job_name, 
	           cast(datediff(mi, s.login_time, getdate()) as varchar)+ '분' as duration
	           , s.login_time
	           , s.host_name
 	           , s.client_interface_name
	from sys.dm_exec_sessions as s with (nolock)
        inner join msdb.dbo.sysjobs j with (nolock)
        on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
									    substring(left(j.job_id,8),5,2) +
									    substring(left(j.job_id,8),3,2) +
									    substring(left(j.job_id,8),1,2))
where s.session_id > 50  and datediff(mi, s.login_time, getdate()) >= @durtion
order by datediff(mi, s.login_time, getdate()) desc

RETURN

go

/*************************************************************************  
* 프로시저명  : dbo.sp_mon_replication_perf 
* 작성정보    : 2010-02-19 by 이성표
* 관련페이지  :  
* 내용        :
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.sp_mon_replication_perf
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT instance_name, 
  SUM(CASE counter_name WHEN 'Dist:Delivery Latency' THEN cntr_value ELSE 0 END) AS delivery_Latency,
  SUM(CASE counter_name WHEN 'Dist:Delivered Cmds/sec' THEN cntr_value ELSE 0 END) AS delivery_cmds,
  SUM(CASE counter_name WHEN 'Dist:Delivered Trans/sec' THEN cntr_value ELSE 0 END) AS delivery_trans  
  FROM sys.dm_os_performance_counters with (nolock)
WHERE (object_name like '%Replication Dist.%')
GROUP BY instance_name

RETURN

go
/*************************************************************************                
* 프로시저명  : dbo.sp_mon_replication_status               
* 작성정보    : 2009-06-15  인성환                
* 관련페이지  :                
* 내용        : 복제 에이전트 기록    
* 수정정보    : 2009-12-07 최보라 agent_id 추가             
**************************************************************************/      
  CREATE PROCEDURE sp_mon_replication_status  
AS  
set nocount on  
declare @v_agentid_table table (  
 i int identity(1,1) primary key,  
 agent_id int);  
  
declare @v_repl_hist table(
 agent_id   int,  
 agent_name nvarchar(100) primary key,  
 runstatus nvarchar(10),  
 [time]  datetime,  
 delivery_latency int,  
 comments nvarchar(4000),  
 duration int,  
 delivery_rate float,  
 delivered_transactions int,  
 delivered_commands int,  
 average_commands int,  
 error_id int,  
 current_delivery_rate float,  
 current_delivery_latency int,  
 total_delivered_commands int);  
  
declare @vloop int  
set @vloop = 1  
insert into @v_agentid_table (agent_id)  
select  
 agent.id agent_id  
from msdb.dbo.sysjobs job with (nolock)  
inner join Distribution.dbo.MSdistribution_agents agent with (nolock)  
 on job.name = agent.name  
  
while (@vloop <= (select max(i) from @v_agentid_table))  
begin  
insert into @v_repl_hist  
select top 1  
     temp.agent_id,
     agent.name,  
     case hist.runstatus when 1 then '시작'  
          when 2 then '성공'  
          when 3 then '진행중'  
          when 4 then '유휴상태'  
          when 5 then '다시시도'  
          when 6 then '실패' end runstatus,  
     'time' = sys.fn_replformatdatetime(time),  
     hist.delivery_latency,  
     hist.comments,  
     hist.duration,  
     hist.delivery_rate,  
     hist.delivered_transactions,  
     hist.delivered_commands,  
     hist.average_commands,  
     hist.error_id,  
     hist.current_delivery_rate,  
     hist.current_delivery_latency,  
     hist.total_delivered_commands  
from msdb.dbo.sysjobs job with (nolock)  
    inner join Distribution.dbo.MSdistribution_agents agent with (nolock)  
     on job.name = agent.name  
    inner join Distribution.dbo.MSdistribution_history hist with (nolock)  
     on agent.id = hist.agent_id  
    inner join @v_agentid_table temp  
     on agent.id = temp.agent_id  
where temp.i = @vloop  
order by hist.timestamp desc, hist.delivery_latency desc
 set @vloop = @vloop + 1  
end;  
  
select @@servername as distribute_server_name , * from @v_repl_hist  
order by delivery_latency desc 

go

/*************************************************************************  
* 프로시저명  : dbo.sp_mon_mirroring_status
* 작성정보    : 2010-02-22
* 관련페이지  :  
* 내용        : 미러링 연결 상태
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.sp_mon_mirroring_status

AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT 
      DB_NAME(database_id) AS 'DatabaseName' 
       , database_id                                               -- 데이터베이스ID 
       , mirroring_guid                                            -- 미러링파트너관계의ID
       , CASE mirroring_state                                      -- 미러링세션의상태
             WHEN 0 THEN '일시중지됨'
             WHEN 1 THEN '연결끊김'
             WHEN 2 THEN '동기화중'
             WHEN 3 THEN '장애조치(Failover) 보류중'
             WHEN 4 THEN '동기화됨'
             WHEN null THEN '데이터베이스가온라인이아님'    
         END AS mirroring_state   
    , mirroring_role_desc    
       , CASE mirroring_safety_level                                     -- 미러링세션의상태
             WHEN 0 THEN '알수없는상태'
             WHEN 1 THEN 'Off[비동기]'
             WHEN 2 THEN 'Full[동기]'          
             WHEN null THEN '데이터베이스가온라인이아님'    
         END AS mirroring_safety_level       
    , mirroring_safety_sequence --트랜잭션보안수준변경내용에대한시퀀스번호를업데이트합니다.
    , mirroring_role_sequence --장애조치또는강제서비스로인해미러링파트너가주서버및미러서버역할을전환한횟수입니다. 
    , mirroring_partner_instance
    , mirroring_witness_name
    --, mirroring_witness_state_desc
       ,CASE mirroring_witness_state                                     -- 미러링세션의상태
             WHEN 0 THEN '알수없음'
             WHEN 1 THEN '연결됨'
             WHEN 2 THEN '연결끊김'             
             WHEN null THEN '미러링모니터가존재하지않거나데이터베이스가온라인이아님'       
         END AS mirroring_witness_state    
    , mirroring_failover_lsn --장애조치후에두파트너는mirroring_failover_lsn을새미러서버가새미러데이터베이스와새주데이터베이스와의동기화를시작하는조정지점
FROM sys.database_mirroring  as dm WITH(NOLOCK)
WHERE mirroring_guid IS NOT NULL;

RETURN

go

CREATE procedure sp_mon_change_procedure
	@duration int = 60
as

set nocount on

declare @seq int, @max int
declare @dbname sysname
declare @script nvarchar(1024)

declare @db_list table (
	seq int IDENTITY(1, 1) PRIMARY KEY,
	dbname	sysname
)

declare @proc_list table (
	seq int IDENTITY(1, 1) PRIMARY KEY,
	dbname	sysname,
	objectname sysname,
	type	char(6),
	create_date datetime,
	modify_date	datetime
)

insert @db_list (dbname)
select name from sys.databases where name NOT IN ('master', 'tempdb', 'model', 'msdb')

select @seq = 1, @max = @@rowcount

while @seq <= @max
begin

	select @dbname = dbname from @db_list where seq = @seq

	set @script = 'select ''' + @dbname + ''' as dbname, name, case when create_date = modify_date then ''CREATE'' else ''MODIFY'' end, create_date, modify_date from ' + @dbname + '.sys.procedures where create_date > dateadd(minute, (-1) * ' + convert(varchar, @duration) + ', getdate()) and modify_date > dateadd(minute, (-1) * ' + convert(varchar, @duration) + ', getdate())'

	insert @proc_list (dbname, objectname, type, create_date, modify_date)
	exec (@script)

	set @seq = @seq + 1

end

if exists (select * from @proc_list) 
	select * from @proc_list
else
	print '1시간 이내에 생성, 수정된 프로시져가 존재하지 않습니다!!'
go
