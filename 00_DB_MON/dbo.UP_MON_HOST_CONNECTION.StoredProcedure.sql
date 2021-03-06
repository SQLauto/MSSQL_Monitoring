USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[UP_MON_HOST_CONNECTION]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[UP_MON_HOST_CONNECTION]    
 @duration int = 30,    
 @reg_date datetime = NULL    
AS              
BEGIN              
SET NOCOUNT ON              
              
declare @host table (              
 seq int identity(1,1) primary key,              
 host_name varchar(128)              
)              
              
declare @cnt_host int, @seq int              
declare @str_host nvarchar(2000), @str_host2 nvarchar(2000)              
declare @query nvarchar(4000)    
declare @from_date datetime, @to_date datetime    
    
select @to_date = max(reg_date), @from_date = min(reg_date) from DB_MON_HOST_CONNECTION with (nolock)     
where reg_date <= ISNULL(@reg_date, GETDATE()) and reg_date >= DATEADD(minute, (-1) * @duration, ISNULL(@reg_date, GETDATE()))     
  
if @to_date IS NULL or @from_date IS NULL  
begin  
 print 'DB_MON_HOST_CONNECTION 테이블에 해당하는 기간의 데이터가 없습니다!!!'  
 return  
end  
   
    
insert @host (host_name)               
select host_name    
FROM DB_MON_HOST_CONNECTION with (nolock)              
where reg_date >= @from_date and reg_date <= @to_date 
group by host_name
order by sum(connection_count) desc    
              
set @cnt_host = @@ROWCOUNT    

              
set @seq = 1              
set @str_host = ''              
set @str_host2 = ''        
    
while @seq <= @cnt_host              
begin              
        
 if (select host_name from @host where seq = @seq) = '' 
 begin
	set @seq = @seq + 1
	continue
 end     
     
 select @str_host = @str_host + '[' + host_name + '], ' from @host where seq = @seq              
         
 select @str_host2 = @str_host2 + 'ISNULL(CONVERT(VARCHAR, [' + host_name + ']), ''0~9'') AS [' + host_name + '], ' from @host where seq = @seq              
              
 set @seq = @seq + 1  
               
end              
  
set @str_host = @str_host + '[ETC]'  
set @str_host2 = @str_host2 + 'ISNULL([ETC], 0) AS [ETC]'  
    
set @query = N'     
 select reg_date, ' + @str_host2 + '    
 from (    
  select reg_date, host_name, connection_count    
  from db_mon_host_connection with (nolock)    
  where reg_date >= @from_date and reg_date <= @to_date    
  union all    
  select reg_date, ''ETC'' as host_name,   
 sum(case when host_name = ''TOTAL'' then connection_count else (-1) * connection_count end) as connection_count    
  from db_mon_host_connection with (nolock)    
  where reg_date >= @from_date and reg_date <= @to_date    
  group by reg_date      
 ) source    
 PIVOT (sum(connection_count) for host_name in (' + @str_host + ')) as pvt    
 order by reg_date desc'    

exec sp_executesql @query, N'@from_date datetime, @to_date datetime', @from_date = @from_date, @to_date = @to_date              
              
END 



GO
