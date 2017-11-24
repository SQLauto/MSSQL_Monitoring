SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_dba_backup_update_backup_master' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_dba_backup_update_backup_master
*/

/*************************************************************************  
* ���ν�����  : dbo.up_dba_backup_update_backup_master 
* �ۼ�����    : 2007-12-20 by choi bo ra
* ����������  :  
* ����        : backup_master ��ȸ, GDM01�� ����
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_backup_update_backup_master
    @server_name		    NVARCHAR(128) ,
	@database_name	        NVARCHAR(128) ,
    @backup_flag		    TINYINT		  ,
	@backup_type	        TINYINT		  ,
	@san_flag	            TINYINT		  ,
	@backup_cycle           TINYINT       ,
	@backup_day             TINYINT          
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @reg_dt     DATETIME
SET @reg_dt = GETDATE()

/* BODY */
UPDATE dbo.BACKUP_MASTER
    SET backup_flag = @backup_flag,
        backup_type = @backup_type,
        san_flag = @san_flag,
        backup_cycle = @backup_cycle,
        backup_day = @backup_day,
        chg_date = @reg_dt
WHERE server_name= @server_name AND database_name = @database_name

IF @@ERROR <> 0 RETURN


RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO