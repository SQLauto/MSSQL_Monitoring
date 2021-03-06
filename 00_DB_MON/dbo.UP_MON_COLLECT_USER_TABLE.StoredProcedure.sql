USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[UP_MON_COLLECT_USER_TABLE]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[UP_MON_COLLECT_USER_TABLE]  
AS  
  
set nocount on  
  
create table #table_list (  
 hobt_id    bigint primary key,  
 partition_id  bigint,  
 object_id   int,  
 index_id   int,  
 partition_number int  
)  
  
declare @db_id int  
declare @hobt_id bigint, @partition_id bigint, @object_id int, @index_id int, @partition_number int  
declare @max int, @seq int  
declare @script nvarchar(1000)  
  
set @db_id = 0  
  
while 1 = 1  
begin  
  
 select top 1 @db_id = database_id 
-- select * 
from sys.databases with (nolock) 
 where database_id > @db_id and state = 0 and user_access = 0 and name !='gmktlink'
 order by database_id  
   
 if @@rowcount = 0 break  
  
 set @script = 'select hobt_id, partition_id, object_id, index_id, partition_number   
     from ' + db_name(@db_id) + '.sys.partitions  with (nolock) order by hobt_id'  
  
 insert #table_list (hobt_id, partition_id, object_id, index_id, partition_number)  
 exec (@script)  
  
 set @hobt_id = 0  
  
 while 1 = 1  
 begin  
  
  select top 1 @hobt_id = hobt_id from #table_list where hobt_id > @hobt_id order by hobt_id  
    
  if @@rowcount = 0 break  
  
  select @partition_id = partition_id,  
      @object_id = object_id,  
      @index_id = index_id,  
      @partition_number = partition_number  
  from #table_list  
  where hobt_id = @hobt_id  
  
  if exists (select top 1 * from DB_MON_USER_TABLE  with (nolock) where db_id = @db_id and hobt_id = @hobt_id)  
  begin  
   if exists (select top 1 * from DB_MON_USER_TABLE (nolock)  
        where db_id = @db_id and hobt_id = @hobt_id   
       and (partition_id <> @partition_id or object_id <> @object_id or index_id <> @index_id or partition_number <> @partition_number))  
    update DB_MON_USER_TABLE   
       set partition_id = @partition_id,   
        object_id = @object_id,   
        index_id = @index_id,   
        partition_number = @partition_number,  
        upd_date = getdate()  
     where db_id = @db_id and hobt_id = @hobt_id  
  
  end  
  else  
   insert DB_MON_USER_TABLE (db_id, hobt_id, partition_id, object_id, index_id, partition_number, reg_date, upd_date)  
   values (@db_id, @hobt_id, @partition_id, @object_id, @index_id, @partition_number, getdate(), getdate())  
  
 end  
   
 -- 삭제된 테이블 or index 에 대한 정보 지우기  
 delete s  
 from DB_MON_USER_TABLE as s  
 where s.db_id = @db_id  
  and s.hobt_id not in (select hobt_id from #table_list where hobt_id = s.hobt_id)  
   
 truncate table #table_list  
  
end  
  
drop table #table_list;  
  


GO
