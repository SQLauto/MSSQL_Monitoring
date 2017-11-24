CREATE TABLE all_tables
( 
seqno int   IDENTITY (1 , 1)  NOT NULL   , 
table_name sysname    NOT NULL   , 
use_yn char (1)   NULL  CONSTRAINT DF__ALL_TABLES__USE_YN DEFAULT ('N')  , 
index_size_level smallint    NULL  CONSTRAINT DF__ALL_TABLES__INDEX_SIZE_LEVEL DEFAULT (0) 
)  ON [PRIMARY]
GO


/**************************************************************************************************************    
    SP    명 :  dbo.up_DBA_update_statistics  
    작성정보: 2007-04-17 김태환  
    내용     : update_statistics를 자동으로 수행  
**************************************************************************************************************/   
CREATE PROCEDURE   dbo.up_DBA_update_statistics  
AS  
  
SET NOCOUNT ON   
SET ARITHABORT ON   
SET CONCAT_NULL_YIELDS_NULL ON   
SET QUOTED_IDENTIFIER ON   
SET ANSI_NULLS ON   
SET ANSI_PADDING ON   
SET ANSI_WARNINGS ON   
SET NUMERIC_ROUNDABORT OFF   
  
if exists(select * from search.information_schema.tables a with (nolock)   
   left join dba.dbo.all_tables b with (nolock) on a.table_name = b.table_name   
 where a.table_type = 'base table' and a.table_schema = 'dbo'  
 and b.table_name is null  
) begin  
 insert into dba.dbo.all_tables(table_name)  
 select a.table_name from search.information_schema.tables a with (nolock)   
    left join dba.dbo.all_tables b with (nolock) on a.table_name = b.table_name   
 where a.table_type = 'base table' and a.table_schema = 'dbo'  
 and b.table_name is null  
 order by a.table_name  
end  
  
if exists( select * from dba.dbo.all_tables a with (nolock)   
   left join search.information_schema.tables b with (nolock) on a.table_name = b.table_name   
      and b.table_type = 'base table' and b.table_schema = 'dbo'  
 where b.table_name is null   
) begin  
 delete a  
  from dba.dbo.all_tables a with (nolock)   
   left join search.information_schema.tables b with (nolock) on a.table_name = b.table_name   
      and b.table_type = 'base table' and b.table_schema = 'dbo'  
 where b.table_name is null   
end  
  
  
declare @seqno   int  
, @max_seqno int  
  
declare @sql  varchar(100)  
  
set @seqno = 1  
select @max_seqno = max(seqno) from dba.dbo.all_tables with (nolock)  
  
while (@seqno <= @max_seqno)  
begin  
 if exists(select seqno from  dba.dbo.all_tables with (nolock) where seqno = @seqno)  
 begin  
  select @sql = table_name from dba.dbo.all_tables with (nolock) where seqno = @seqno  
  set @sql = 'UPDATE STATISTICS ' +'search.dbo.' +@sql  
    
  exec(@sql)  
 end  
  
 set @seqno = @seqno + 1  
 if @seqno > @max_seqno break;  
end  
  
  
  
  
  
  
  