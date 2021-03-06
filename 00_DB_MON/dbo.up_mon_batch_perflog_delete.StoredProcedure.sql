USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_batch_perflog_delete]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*************************************************************************  
* 프로시저명  : dbo.up_mon_batch_perflog_delete
* 작성정보    : 2010-04-09 by choi bo ra
* 관련페이지  : 
* 내용        : 수집된 성능 counter 파일 삭제
* 수정정보    : exec up_mon_batch_perflog_delete 9, 'D:\MS_Perflogs', 'GMKT2008_Perflog_'
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_batch_perflog_delete] 
		@period						int 
	 ,@file_dir					nvarchar(30)
	 ,@file_name_prifx	nvarchar(30)
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @del_day datetime
declare @del_yyyymmdd nvarchar(8)
declare @del_file 		nvarchar(100)

/* BODY */
set @del_day = dateadd(dd, -@period, getdate())
set @del_yyyymmdd = convert(nvarchar(8), @del_day, 112)

set @file_dir = @file_dir + '\'

set @del_file = 'DEL ' + @file_dir + @file_name_prifx + @del_yyyymmdd + '*.csv'
select @del_file

exec master.dbo.xp_cmdshell  @del_file

			
RETURN

GO
