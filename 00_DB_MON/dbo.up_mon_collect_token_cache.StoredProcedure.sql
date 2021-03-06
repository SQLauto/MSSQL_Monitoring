USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_token_cache]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*************************************************************************  
* 프로시저명  : dbo.up_mon_collect_token_cache
* 작성정보    : 2010-04-15 by choi bo ra
* 관련페이지  : 
* 내용        : 
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_collect_token_cache] 
	 @threshHold				int
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @cache_size int 
declare @cache_size_MB int 
declare @state varchar(20)
/* BODY */
exec UP_SWITCH_PARTITION @table_name = 'DB_MON_TOKEN_CACHE',@column_name = 'reg_date'


SET @cache_size_MB = 0
SET @cache_size = 0


SELECT @cache_size = SUM(single_pages_kb + multi_pages_kb) 
 FROM sys.dm_os_memory_clerks  with (nolock)
 WHERE name = 'TokenAndPermUserStore'



set @cache_size_MB = @cache_size / 1024 


if @threshHold != 0 and @cache_size_MB >= @threshHold 
begin
	-- free cache !

	set @state = 'UNSTABLE/FREE CACHE'
	DBCC FREESYSTEMCACHE ('TokenAndPermUserStore')
end
else
begin
	set @state = 'STABLE'
end


insert into dbo.DB_MON_TOKEN_CACHE
(reg_date,token_cache_size, state) 
values(getdate(), @cache_size , @state)


RETURN

GO
