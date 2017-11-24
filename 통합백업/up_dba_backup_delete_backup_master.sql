SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_dba_backup_delete_backup_master' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_dba_backup_delete_backup_master
*/

/*************************************************************************  
* 프로시저명  : dbo.up_dba_backup_delete_backup_master 
* 작성정보    : 2007-12-20 by choi bo ra
* 관련페이지  :  
* 내용        : backup_master 삭제, GDM01에 생성
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_backup_delete_backup_master
    @server_name		    NVARCHAR(128) ,
	@database_name	        NVARCHAR(128) 
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
DELETE dbo.BACKUP_MASTER
WHERE server_name= @server_name AND database_name = @database_name

IF @@ERROR <> 0 RETURN


RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO