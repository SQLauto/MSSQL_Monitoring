USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_query_plan_change_object]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* 프로시저명  : dbo.up_mon_query_plan_change_object
* 작성정보    : 2011-08-06 by choi bo ra
* 관련페이지  : 
* 내용        : plan이 변경된 전 plan 상세 조회
* 수정정보    :exec dbmon.dbo.up_mon_query_plan_change_object 'up_gmkt_daemon_sms_order_delete',20,26,251
,0x05000b0072fd5e5f4061987e3e0000000000000000000000
**************************************************************************/
CREATE PROC [dbo].[up_mon_query_plan_change_object]
@object_name varchar(255),
@line_start int,
@line_end int,
@set_option int,
@plan_handle varbinary(64)
as

SET NOCOUNT ON

declare @now_date datetime, @rowcount int
set @rowcount = 2


SET @now_date = GETDATE()

SELECT @now_date=MAX(reg_date) from DB_MON_QUERY_STATS_V2 (nolock)
WHERE reg_date <= @now_date

--SELECT @object_name as [object_name], @now_date as base_date,dateadd(mi,-61,@now_date) as to_date

-- 현재 상태
select 
 '현재' as type,
 getdate() as reg_date,  
 db_name(qt.dbid) as db_name,   
 object_name(qt.objectid, qt.dbid) as object_name,
 qs.creation_time,  
 f.line_start, f.line_end,
 (select convert(int, value) from sys.dm_exec_plan_attributes(qs.plan_handle) where attribute = 'set_options') as set_options,   
 qs.cnt,  
 qs.cpu,  
 qs.writes,  
 qs.reads,  
 qs.duration, 
 convert(xml, qt.query_plan ) as query_plan 
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
	and plan_handle = @plan_handle

) qs
cross apply sys.dm_exec_text_query_plan   ( plan_handle, statement_start, statement_end) as qt  
outer apply dbo.fn_getobjectline(qs.plan_handle, qs.statement_start, qs.statement_end) f 
where 
	f.line_start = @line_start 
	and f.line_end  = @line_end
	and dbid <> 32767


--수집된 내역
SELECT  TOP (@rowcount) 
 '변경 전' as type
,s.reg_date as reg_date
,s.db_name as [db_name]
,s.object_name
,s.create_date  
,p.line_start
,p.line_end
,s.set_options
,cnt_min  as cnt_min   
,(cpu_min /1000) as cpu_min
,(duration_min/1000) as duration_min    
,reads_min, cpu_cnt as cpu_cnt
,reads_cnt as reads_cnt
,duration_cnt as duration_cnt
,p.query_plan
FROM DBMON.dbo.DB_MON_QUERY_STATS_V2 s WITH (NOLOCK)
	left join  dbo.db_mon_query_plan_v2 p (nolock)      
	on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start 
		and s.statement_end = p.statement_end 
		and s.create_date = p.create_date
		and p.line_start= @line_start and p.line_end = @line_end and s.set_options = @set_option
WHERE s.reg_date >= dateadd(mi,-61,@now_date) and s.reg_date <= @now_date
	and s.object_name= @object_name 
	
order by s.reg_date desc , s.create_date desc
GO
