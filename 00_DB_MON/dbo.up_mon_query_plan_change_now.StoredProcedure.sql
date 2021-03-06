/*************************************************************************  
* 프로시저명  : dbo.up_mon_query_plan_change_now
* 작성정보    : 2011-08-06 by choi bo ra
* 관련페이지  : 
* 내용       : plan이 변경된 전 plan 상세 조회
* 수정정보    : exec up_mon_query_plan_change_now 
**************************************************************************/
CREATE PROC dbo.up_mon_query_plan_change_now
	@type  char(10) = 'CPU', -- CPU/I/O/CNT
	@duration int = 5
AS

SELECT   
 db_name(dbid) as db_name,   
 object_name(objectid, dbid) as object_name,
 qs.creation_time,  
 f.line_start, f.line_end,
 (select convert(int, value) from sys.dm_exec_plan_attributes(qs.plan_handle) where attribute = 'set_options') as set_options,   
 qs.cnt,  
 qs.cpu,  
 qs.writes,  
 qs.reads,  
 qs.duration, 
 convert(xml,qt.query_plan) query_plan , 
 qs.statement_start,   
 qs.statement_end,  
 qs.plan_handle
 INTO #tmp_db_mon_query_plan_change_now 
from (   
 select   
    plan_handle   
  , statement_start_offset as statement_start  
  , statement_end_offset as statement_end  
  , creation_time  
  , execution_count as cnt  
  , total_worker_time as cpu  
  , total_logical_writes as writes  
  , total_logical_reads as reads  
  , total_elapsed_time as duration
 from sys.dm_exec_query_stats  
 where convert(varbinary, left(sql_handle, 1)) = 0x03  
    and substring(sql_handle, 3, 1) <> 0xFF			-- system 디비 제거
	and creation_time >= dateadd(mi,-1* @duration, getdate())
) qs    
cross apply sys.dm_exec_text_query_plan   ( qs.plan_handle, qs.statement_start, qs.statement_end) as qt
outer apply dbo.fn_getobjectline(qs.plan_handle, qs.statement_start, qs.statement_end) f 
where qt.dbid > 4



if @type = 'CPU'
begin
	select db_name, object_name, creation_time, line_start, line_end,
		cnt, cpu, writes, reads, duration, query_plan, 
		'exec dbmon.dbo.up_mon_query_plan_change_object ''' + object_name + ''','
			+ convert(nvarchar(5), line_start) + ',' +  convert(nvarchar(5), line_end) + ','
				+ convert(nvarchar(5), set_options) + char(10) + ',' 
			+ dbo.fn_hexadecimal(plan_handle) as info, 
	      statement_start, statement_end, plan_handle
	from  #tmp_db_mon_query_plan_change_now order by cpu desc
end

else if @type = 'I/O'
begin
	select db_name, object_name, creation_time, line_start, line_end,
		cnt, cpu, writes, reads, duration, query_plan, 
		'exec dbmon.dbo.up_mon_query_plan_change_object ''' + object_name + ''','
			+ convert(nvarchar(5), line_start) + ',' +  convert(nvarchar(5), line_end) + ','
				+ convert(nvarchar(5), set_options) + char(10) + ',' 
			+ dbo.fn_hexadecimal(plan_handle) as info, 
	      statement_start, statement_end, plan_handle
	from  #tmp_db_mon_query_plan_change_now order by reads desc
end

else if @type = 'CNT'
begin
	select db_name, object_name, creation_time, line_start, f.line_end,
		cnt, cpu, writes, reads, duration, query_plan, 
		'exec dbmon.dbo.up_mon_query_plan_change_object ''' + object_name + ''','
			+ convert(nvarchar(5), line_start) + ',' +  convert(nvarchar(5), line_end) + ','
			+ convert(nvarchar(5), set_options) + char(10) + ',' 
			+ dbo.fn_hexadecimal(plan_handle) as info,  
	      statement_start, statement_end, plan_handle
	from  #tmp_db_mon_query_plan_change_now order by cnt desc
end

