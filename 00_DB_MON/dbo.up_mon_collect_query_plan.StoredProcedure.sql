USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_query_plan]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
    
/* sql_handle 값의 비밀 : 아래와 같이 안 나올 경우에는 프로시져 수정이 필요    
declare @sql_handle varbinary(64)    
    
set @sql_handle = 0x0300050015002714B205AE00509D00000100000000000000    
    
select convert(int, substring(@sql_handle, 1, 1))  as object_type,  -- 3 일 경우 프로시져임    
 convert(int, substring(@sql_handle, 3, 1))  as dbid,    
 convert(int,     
  substring(@sql_handle, 8, 1) +     
  substring(@sql_handle, 7, 1) +     
  substring(@sql_handle, 6, 1) +     
  substring(@sql_handle, 5, 1))  as object_id        
*/        
CREATE PROCEDURE [dbo].[up_mon_collect_query_plan]        
AS        
        
set nocount on        
        
declare @seq int, @max int        
declare @sql_handle varbinary(64), @plan_handle varbinary(64), @creation_time datetime      
declare @old_creation_time datetime    
        
declare @query_list table (        
 seq int identity(1, 1) primary key,        
 sql_handle varbinary(64),        
 plan_handle varbinary(64),        
 creation_time datetime        
)    
        
insert @query_list (sql_handle, plan_handle, creation_time)        
select sql_handle, plan_handle, max(creation_time) as creation_time        
from sys.dm_exec_query_stats qu        
where sql_handle >= 0x030005 and sql_handle < 0x0300ff  -- 저장 프로시져 중에 system 쪽 제외 조건    
--where left(sql_handle, 1) = 0x03    -- 저장 프로시져 조건    
group by sql_handle, plan_handle        
        
select @seq = 1, @max = @@rowcount        
        
while @seq <= @max        
begin        
        
 select @sql_handle = sql_handle, @plan_handle = plan_handle, @creation_time = creation_time         
 from @query_list where seq = @seq        
        
 set @seq = @seq + 1    
     
 if exists (select * from DB_MON_QUERY_PLAN (nolock) where sql_handle = @sql_handle and plan_handle = @plan_handle and creation_time = @creation_time)        
  continue -- 동일한 결과 있으면 그냥 넘김        
 else if exists (select * from DB_MON_QUERY_PLAN (nolock) where sql_handle = @sql_handle and plan_handle = @plan_handle)        
 begin -- plan_handle 까진 있으나  creation_time 이 틀리면 Update        
          
  select @old_creation_time = max(creation_time) from DB_MON_QUERY_PLAN (nolock)         
  where sql_handle = @sql_handle and plan_handle = @plan_handle      
          
  update P        
  set creation_time = @creation_time,        
   db_id = qp.dbid,        
   object_id = qp.objectid,        
   db_name = db_name(qp.dbid),        
   object_name = object_name(qp.objectid, qp.dbid),        
   query_plan = qp.query_plan,        
   upd_date = getdate()        
  from DB_MON_QUERY_PLAN P        
   cross apply sys.dm_exec_query_plan(@plan_handle) qp        
  where P.sql_handle = @sql_handle and P.plan_handle = @plan_handle and P.creation_time = @old_creation_time           
         
 end        
 else        
 begin -- 없으면 insert        
         
  insert DB_MON_QUERY_PLAN (sql_handle, plan_handle, creation_time, db_id, object_id, db_name, object_name, query_plan, reg_date, upd_date)        
  select @sql_handle, @plan_handle, @creation_time,        
      dbid, objectid, db_name(dbid), object_name(objectid, dbid), query_plan,        
      getdate(), getdate()        
  from sys.dm_exec_query_plan(@plan_handle)    
         
 end        
        
end 
GO
