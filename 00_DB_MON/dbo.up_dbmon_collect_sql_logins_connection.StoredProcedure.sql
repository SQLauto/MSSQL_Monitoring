USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_dbmon_collect_sql_logins_connection]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* 프로시저명  : dbo.up_dbmon_collect_sql_logins_connection
* 작성정보    : 2013-02-06
* 관련페이지  : 
* 내용       : DCM 현황파악을 위해 login/program_name/hostname 수집
* 수정정보    : 
**************************************************************************/
CREATE PROCEDURE [dbo].[up_dbmon_collect_sql_logins_connection]
	@server_id int
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @reg_date datetime
SET @reg_date =  convert(datetime,convert(nvarchar(10), getdate() -1, 121))

/* BODY */


select @server_id  server_id, @reg_date reg_date, login_name, host_name,program_name , COUNT(*) connection
from db_mon_sysprocess with(nolock) where reg_date >= @reg_date and reg_date < dateadd(dd, 1, @reg_date)
	and login_name != ''
	and host_name != @@servername	
	and NOT (login_name like   'pd1_%'  
    OR login_name like 'od1_%'  
    OR login_name like 'ad1_%'  
    OR login_name like 'dw_%'  
    OR login_name like 'da_%'  
	OR login_name like 'dba_%'  
    OR login_name like 'ed1_%'
	OR login_name like 'sl_%') 
	OR login_name = 'dba_ssis'
group by login_name, host_name,program_name

RETURN
GO
