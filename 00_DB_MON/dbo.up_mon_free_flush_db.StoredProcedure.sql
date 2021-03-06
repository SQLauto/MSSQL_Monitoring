USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_free_flush_db]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*************************************************************************  
* 프로시저명  : dbo.up_mon_free_flush_db
* 작성정보    : 2010-04-15 by choi bo
* 관련페이지  : 
* 내용        : BCC FLUSHPROCINDB(@dbid)
* 수정정보    :
**************************************************************************/
CREATe PROCEDURE [dbo].[up_mon_free_flush_db] 
	@database_name		sysname
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
DECLARE @StringVariable NVARCHAR(50), @dbid int
SET @StringVariable = N'%s IS NOT ONLINE';
set @dbid = 0
select @dbid = dbid from sys.sysdatabases 
where name = @database_name  and DATABASEPROPERTYEX(name,'status')='ONLINE'

if @dbid = 0 
begin
	raiserror ( @StringVariable, 16,1, @database_name)
end
else
	DBCC FLUSHPROCINDB(@dbid)
	
RETURN

GO
