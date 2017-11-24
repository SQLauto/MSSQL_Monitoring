CREATE proc dbo.up_DBA_show_blockinfo
as 
begin
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
		

select req.session_id as session_id
,req.blocking_session_id as blocking_session_id 
into #temp_blocking
from sys.dm_exec_requests req with(nolock)
where req.session_id > 50
--and req.blocking_session_id > 0
--order by req.cpu_time desc


select 0 as session_id ,0 as blocking_session_id ,'' as str_kill, '--' as db_name , 'blocking 유발자' as obj_name ,'----------------'  as cur_statement

union all

select req.session_id  , req.blocking_session_id
, case when req.blocking_session_id > 0 then 'KILL ' + convert(varchar(10) , req.blocking_session_id)  else '---' end as str_kill
,db.name  as db_name 
,case when t1.objectid is null  then t1.text
 else
	'[' + usr.name + '.' + obj.name +']'
 end as obj_name 
,( SELECT TOP 1 SUBSTRING(t1.text,  statement_start_offset / 2, ( (CASE WHEN statement_end_offset = -1 THEN (LEN(CONVERT(nvarchar(max),t1.text)) * 2) ELSE statement_end_offset END)  - statement_start_offset) / 2)  )  AS cur_statement
from sys.dm_exec_requests req with(nolock) 
cross apply sys.dm_exec_sql_text (req.sql_handle) as t1
inner join master..sysdatabases db with(nolock) on t1.dbid = db.dbid
inner join sysobjects obj with(nolock) on t1.objectid = obj.id
inner join sysusers usr with(nolock) on usr.uid = obj.uid
where req.session_id in (select distinct blocking_session_id from #temp_blocking with(nolock) )

union all

select 0 as session_id ,0 as blocking_session_id ,'' as str_kill, '--' as db_name , 'blocking 대기자' as obj_name ,'----------------'  as cur_statement

union all

select req.session_id  , req.blocking_session_id
, case when req.blocking_session_id > 0 then 'KILL ' + convert(varchar(10) , req.blocking_session_id)  else '---' end as str_kill
,db.name  as db_name 
,case when t1.objectid is null  then t1.text
 else
	'[' + usr.name + '.' + obj.name +']'
 end as obj_name 
,( SELECT TOP 1 SUBSTRING(t1.text,  statement_start_offset / 2, ( (CASE WHEN statement_end_offset = -1 THEN (LEN(CONVERT(nvarchar(max),t1.text)) * 2) ELSE statement_end_offset END)  - statement_start_offset) / 2)  )  AS cur_statement
from sys.dm_exec_requests req with(nolock) 
cross apply sys.dm_exec_sql_text (req.sql_handle) as t1
inner join master..sysdatabases db with(nolock) on t1.dbid = db.dbid
inner join sysobjects obj with(nolock) on t1.objectid = obj.id
inner join sysusers usr with(nolock) on usr.uid = obj.uid
where req.session_id in (select session_id from #temp_blocking with(nolock) where blocking_session_id > 0 )

set NOCOUNT OFF
end