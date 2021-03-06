USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_dbmon_collect_tempdb_usage]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[up_dbmon_collect_tempdb_usage]
AS

SET NOCOUNT ON

INSERT INTO DBMON.DBO.DB_MON_TEMPDB_USAGE(
reg_date,
session_id,
host_name,
login_name,
status,
program_name,
tempdb_space_alloc_kB,
tempdb_space_dealloc_kB,
remaining_tempdb_space_alloc_kB)

select  top 30
getdate() as reg_date,
u.session_id,    
s.host_name,    
s.login_name,  
s.status,  
s.program_name, 
sum(u.user_objects_alloc_page_count+u.internal_objects_alloc_page_count)*8 tempdb_space_alloc_kB,    
sum(u.user_objects_dealloc_page_count+u.internal_objects_dealloc_page_count)*8 tempdb_space_dealloc_kB,   
sum(u.user_objects_alloc_page_count+u.internal_objects_alloc_page_count -u.user_objects_dealloc_page_count - u.internal_objects_dealloc_page_count)*8 remaining_tempdb_space_alloc_kB    
from sys.dm_db_session_space_usage as u   
join sys.dm_exec_sessions as s on s.session_id = u.session_id   
where u.database_id = 2    
group by u.session_id, s.host_name,  s.status, s.login_name, s.program_name   
order by 6 desc  

--10일경과 삭제
DELETE 
FROM DBMON.DBO.DB_MON_TEMPDB_USAGE
WHERE REG_DATE < DATEADD(DAY, -10, GETDATE())
GO
