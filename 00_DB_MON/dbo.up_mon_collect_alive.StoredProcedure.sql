USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_alive]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*************************************************************************  
* 프로시저명  : dbo.up_mon_collect_alive
* 작성정보    : 2010-04-08 by choi bo ra
* 관련페이지  : 
* 내용        : DB 서버가 살아있는지 check
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_collect_alive] 
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
exec UP_SWITCH_PARTITION  @table_name = 'DB_MON_ALIVE',@column_name = 'reg_date'

INSERT INTO dbo.DB_MON_ALIVE
(reg_date, alive)
VALUES (getdate(), 1)



RETURN


GO
