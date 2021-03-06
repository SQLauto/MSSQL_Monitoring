USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[UP_MON_COLLECT_QUERY_PLAN_V2_OBJECT]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UP_MON_COLLECT_QUERY_PLAN_V2_OBJECT]
	@OBJECT_NAME SYSNAME             
AS              
set nocount on              
              
declare @reg_date datetime              
declare @seq int, @max int              
declare @plan_handle varbinary(64), @statement_start int, @statement_end int, @create_date datetime        
declare @db_id smallint              
              
declare @plan_info table (              
 seq int identity(1, 1) primary key,              
 plan_handle varbinary(64),              
 statement_start int,              
 statement_end int,              
 create_date datetime,        
 db_id smallint         
)        
              
select @reg_date = max(reg_date) from DB_MON_QUERY_STATS_V2 (nolock)              
              
if exists (select top 1 * from DB_MON_QUERY_PLAN_V2 (nolock) where reg_date = @reg_date and object_name=@OBJECT_NAME)              
begin              
 print '이미 해당 시간의 plan 정보가 저장되었습니다!'              
 return              
end              
              
insert @plan_info (plan_handle, statement_start, statement_end, create_date, db_id)              
select plan_handle, statement_start, statement_end, create_date, db_id         
from DB_MON_QUERY_STATS_V2 with (nolock)     
where reg_date = @reg_date  AND	object_name = @object_name           
--and  cpu_rate > 0.5             
              
select @seq = 1, @max = @@rowcount              
              
while @seq <= @max              
begin              
              
 select @plan_handle = plan_handle,              
     @statement_start = statement_start,              
     @statement_end = statement_end,              
     @create_date = create_date,        
     @db_id = db_id              
 from @plan_info              
 where seq = @seq              
               
 set @seq = @seq + 1              
         
 if @db_id < 5 continue        
               
 if not exists (              
  select top 1 * from DB_MON_QUERY_PLAN_V2 (nolock)               
  where plan_handle = @plan_handle and statement_start = @statement_start and statement_end = @statement_end and create_date = @create_date)              
 begin              
        
  begin try      
  insert DB_MON_QUERY_PLAN_V2               
   (plan_handle, statement_start, statement_end, create_date, set_options, db_name,       
   object_name, query_plan, reg_date, upd_date, line_start, line_end)              
  select               
      @plan_handle,              
      @statement_start,              
      @statement_end,              
      @create_date,              
      0,              
      db_name(dbid) as db_name,               
      object_name(objectid, dbid) as object_name,              
      query_plan,             
      @reg_date,        
      @reg_date,      
      f.line_start, f.line_end              
  from sys.dm_exec_text_query_plan(@plan_handle, @statement_start, @statement_end)      
 outer apply dbo.fn_getobjectline(@plan_handle, @statement_start, @statement_end) f          
  where dbid >= 5            
  end try      
  begin catch  -- xml 이 너무 길어지면(depth 가 128 이상이면 저장 못함)      
   insert DB_MON_QUERY_PLAN_V2               
    (plan_handle, statement_start, statement_end, create_date, set_options, db_name,       
  object_name, query_plan, reg_date, upd_date, line_start, line_end)              
   select @plan_handle, @statement_start, @statement_end, @create_date, 0,       
    db_name(dbid) as db_name,      
    object_name(objectid, dbid) as object_name,      
    null,      
    @reg_date,      
    @reg_date,      
    f.line_start, f.line_end      
   from sys.dm_exec_text_query_plan(@plan_handle, @statement_start, @statement_end)            
    outer apply dbo.fn_getobjectline(@plan_handle, @statement_start, @statement_end) f          
  end catch      
              
 end              
 else         
 begin 
 update DB_MON_QUERY_PLAN_V2        
 set upd_date = @reg_date        
 where plan_handle = @plan_handle and statement_start = @statement_start and statement_end = @statement_end and create_date = @create_date        
 end        
            
end 
GO
