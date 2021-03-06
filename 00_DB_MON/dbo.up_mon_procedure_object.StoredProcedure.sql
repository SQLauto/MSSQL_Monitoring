/*************************************************************************    
* 프로시저명  : dbo.[up_mon_procedure_object]  
* 작성정보    : 2014-10-29 by choi bo ra
* 관련페이지  :   
* 내용        : 프로시저 정보 
* 수정정보    : [up_mon_procedure_object] 
**************************************************************************/  
CREATE PROCEDURE [dbo].[up_mon_procedure_object]
 @object_name sysname = null,
 @date datetime = null,  
 @rowcount int = 10  
AS  
SET NOCOUNT ON  

declare @basedate datetime, @query_basedate datetime
declare @max int, @seq int
declare @statement_start int, @statement_end int, @set_options int



if @object_name is null
begin
	print '@object_name 이 입력되어야 합니다!!!'
	return
end

if @date is null set @date =  getdate()  

select @basedate = max(reg_date) from DB_MON_PROCEDURE_STATS (nolock)  wehre reg_date <= @date

-- 프로시저 내역
select top ( @rowcount)  reg_date,  from_date, to_date,term, db_name, object_name, cached_time, cpu_rate
	, cnt_min,cpu_min, reads_min, writes_min,duration_min
	, cpu_cnt, reads_cnt, writes_cnt, duration_cnt
	--, CONVERT(XML, P.query_plan) AS query_plan
	, sql_handle,plan_handle
from DBMON.DBO.DB_MON_PROCEDURE_STATS AS S WITH(NOLOCK) 
--	cross apply sys.dm_exec_query_plan  (s.plan_handle) as p
where s.reg_date <= @basedate
 and s.object_name = @object_name
order by s.reg_date desc

