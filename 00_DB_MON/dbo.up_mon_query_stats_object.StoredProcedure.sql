CREATE PROCEDURE [dbo].[up_mon_query_stats_object]
 @object_name sysname = null,
 @date datetime = null,  
 @rowcount int = 5  
AS  
SET NOCOUNT ON  

declare @basedate datetime
declare @max int, @seq int
declare @statement_start int, @statement_end int, @set_options int

declare @object table (
	seq int identity(1, 1) primary key,
	statement_start int,
	statement_end int,
	set_options int
)

if @object_name is null
begin
	print '@object_name   !!!'
	return
end

if @date is null set @date =  getdate()  

select @basedate = max(reg_date) from db_mon_query_stats_v3 (nolock)   where reg_date <= @date

insert @object (statement_start, statement_end, set_options)
select statement_start, statement_end, set_options
from db_mon_query_stats_v3 (nolock) 
where object_name = @object_name and reg_date = @basedate
order by statement_start

select @max = @@rowcount, @seq = 1

while @seq <= @max
begin
  
   select @statement_start = statement_start, @statement_end = statement_end, @set_options = set_options
   from @object
   where seq = @seq
   
   set @seq = @seq + 1
  
	select top (@rowcount)  
	s.db_name,  
	s.object_name,  
	s.reg_date as to_date,   
	s.type,
	s.term, 
	s.set_options,  
	p.line_start,  
	p.line_end,  
	s.cnt_min,  
	s.cpu_rate,  
	s.cpu_min,  
	s.reads_min,  
	s.writes_min,  
	s.duration_min,  
	s.cpu_cnt,  
	s.reads_cnt,  
	s.writes_cnt, 
	s.duration_cnt,  
	s.plan_handle,
	s.statement_start,
	s.statement_end,
	s.create_date,   	
	s.query_text,
	p.query_plan
	from dbo.db_mon_query_stats_v3 s (nolock)   
	left join  dbo.db_mon_query_plan_v3 p (nolock)  
	  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
--	outer apply dbo.fn_getobjectline(s.plan_handle, s.statement_start, s.statement_end) f  
	where s.reg_date <= @date and s.object_name = @object_name
	  and s.statement_start = @statement_start and s.statement_end = @statement_end and s.set_options = @set_options
	order by s.reg_date desc

end
