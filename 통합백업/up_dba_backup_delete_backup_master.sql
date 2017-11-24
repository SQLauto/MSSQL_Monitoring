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
* ���ν�����  : dbo.up_dba_backup_delete_backup_master 
* �ۼ�����    : 2007-12-20 by choi bo ra
* ����������  :  
* ����        : backup_master ����, GDM01�� ����
* ��������    :
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