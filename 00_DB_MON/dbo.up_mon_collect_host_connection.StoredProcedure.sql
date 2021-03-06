USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_host_connection]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
CREATE PROCEDURE [dbo].[up_mon_collect_host_connection]  
 @min_count int = 10  
AS  
SET NOCOUNT ON  
  
exec up_switch_partition @table_name = 'DB_MON_HOST_CONNECTION', @column_name = 'REG_DATE'     
  
declare @reg_date datetime  
  
select @reg_date = max(reg_date) from db_mon_sysprocess (nolock)   
  
-- 이미 중복된 LOG 가 있으면 저장 안함  
if exists (select top 1 * from db_mon_host_connection (nolock) where reg_date >= @reg_date)  
begin  
 raiserror ('이미 저장된 로그가 있습니다!!', 16, 1)  
 return  
end  
  
insert db_mon_host_connection (reg_date, host_name, connection_count)
select @reg_date as reg_date, 'TOTAL', count(*) as connection_count
from db_mon_sysprocess with (nolock)
where session_id > 50 and reg_date = @reg_date  
  
insert db_mon_host_connection (reg_date, host_name, connection_count)  
select @reg_date as reg_date,   
 dbo.fnc_removenum(host_name) as host_name,   
 count(*) as connection_count  
FROM db_mon_sysprocess with (nolock)            
where session_id > 50 and reg_date = @reg_date            
group by dbo.fnc_removenum(host_name)  
having count(*) >= @min_count            
order by count(*) desc  
GO
