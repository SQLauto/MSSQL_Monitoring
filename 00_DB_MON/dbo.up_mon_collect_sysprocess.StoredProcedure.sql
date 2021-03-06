USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_sysprocess]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************    
* 프로시저명  : dbo.up_mon_collect_sysprocess  
* 작성정보    : 2010-04-05 by choi bo ra  
* 관련페이지  :   
* 내용        :  sysprocess 수집  
* 수정정보    : 2015-01-15 by choi bo ra
**************************************************************************/  
CREATE PROCEDURE [dbo].[up_mon_collect_sysprocess]   
AS  
/* COMMON DECLARE */  
SET NOCOUNT ON  
SET QUERY_GOVERNOR_COST_LIMIT 0  
/* USER DECLARE */  
DECLARE @get_date datetime  
  
  
  
/* BODY */  
  
exec UP_SWITCH_PARTITION @table_name = 'DB_MON_SYSPROCESS',@column_name = 'reg_date'  
  
  
SET @get_date = GETDATE()  
  
INSERT INTO DB_MON_SYSPROCESS   
 ( reg_date  
    ,session_id  
    ,blocking_session_id  
    ,host_process_id  
    ,status  
    ,cpu_time  
    ,db_name  
    ,schema_name  
    ,object_name  
    ,query_text  
    ,wait_type  
    ,wait_time  
    ,last_wait_type  
    ,login_name  
    ,host_name  
    ,program_name  
    ,wait_resource  
    ,open_transaction_count  
    ,last_batch  
    ,login_time  
    ,total_elapsed_time  
    ,reads  
    ,writes  
    ,logical_reads  
    ,physical_io  
    ,scheduler_id  
    ,ecid)  
  
SELECT top 20000 @get_date as reg_date  
    ,sp.spid as session_id  
    ,sp.blocked as blocking_session_id  
    ,sp.kpid as host_process_id   
    ,sp.status  
    ,sp.cpu as cpu_time  
    ,db_name(qt.dbid) as db_name  
    ,object_schema_name(qt.objectid, qt.dbid) as schema_name  
    ,object_name(qt.objectid, qt.dbid)  as object_name  
  ,CASE WHEN   sp.stmt_end = -1 and ( (sp.stmt_start /2 )  > DATALENGTH (qt.text) )  THEN
          convert(varchar(4000),  substring(isnull(qt.text, '')   , 1, ( ( DATALENGTH (qt.text) - 1 )/2 ) + 1 ) )  
        WHEN    sp.stmt_start not in (0,-1) then  
			 convert(varchar(4000), substring(isnull(qt.text, '') , 
			 (sp.stmt_start / 2) + 1 , (( case when sp.stmt_end = -1 then DATALENGTH (qt.text) else sp.stmt_end end   - sp.stmt_start ) /2 ) + 1) )  
     END  as query_text    
    ,dr.wait_type  
    ,sp.waittime as wait_time  
    ,sp.lastwaittype as last_wait_type  
    ,sp.loginame as login_name  
    ,sp.hostname as host_name  
    ,sp.program_name as program_name  
    ,sp.waitresource as wait_resource  
    ,sp.open_tran as open_transaction_count  
    ,sp.last_batch  
    ,sp.login_time   
    ,dr.total_elapsed_time  
    ,dr.reads  
    ,dr.writes  
    ,dr.logical_reads  
    ,sp.physical_io   
    ,dr.scheduler_id  
    --,sp.ecid  
    ,(select count(*) from sys.sysprocesses with(nolock) where spid = sp.spid and ecid > 0 ) as ecid  
FROM  
 sys.sysprocesses as  sp with (nolock)              
 left join sys.dm_exec_requests  as dr  with (nolock) on dr.session_id = sp.spid    
 left join sys.dm_exec_sessions as ses with (nolock) on dr.session_id = ses.session_id            
 outer apply sys.dm_exec_sql_text(sp.sql_handle) as qt              
WHERE sp.spid > 50   and sp.spid != @@spid and sp.ecid = 0  
ORDER BY cpu_time desc  
  
RETURN  
  
go