USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_free_free_cache]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* 프로시저명  : dbo.up_mon_free_free_cache
* 작성정보    : 2010-04-15 by choi bo
* 관련페이지  : 
* 내용        : DBCC FREESYSTEMCACHE('SQL Plans')
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_free_free_cache] 
	@name				nvarchar(100)
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
	DBCC FREESYSTEMCACHE(@name)
	
RETURN
GO
