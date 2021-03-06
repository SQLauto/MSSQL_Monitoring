USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_dbmon_collect_sql_logins]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dbmon_collect_sql_logins
* 작성정보    : 2011-08-
* 관련페이지  : 
* 내용        : 
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[up_dbmon_collect_sql_logins]
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @reg_date datetime
SET @reg_date =  convert(datetime,convert(nvarchar(10), getdate() -1, 121))

/* BODY */

IF DATEPART ( hh, getdate()) != 0 AND DATEPART (mi, getdate()) != 5
return


exec up_switch_partition @table_name = 'DB_MON_SQL_LOGINS', @column_name = 'REG_DATE'


IF EXISTS (SELECT TOP 1 * FROM DB_MON_SQL_LOGINS (NOLOCK) WHERE REG_DATE = @reg_date)     
BEGIN    
 PRINT '이미 저장된 데이터가 있습니다. '    
 RETURN    
END    
  

insert into DB_MON_SQL_LOGINS ( reg_date, login_name, connetion)
select  @reg_date, login_name , COUNT(*)
from db_mon_sysprocess where reg_date >= @reg_date and reg_date < dateadd(dd, 1, @reg_date)
	and login_name != ''
group by login_name





RETURN

GO
