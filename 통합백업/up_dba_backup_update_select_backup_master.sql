/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_dba_backup_update_select_backup_master' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_dba_backup_update_select_backup_master
*/

/*************************************************************************  
* ���ν�����  : dbo.up_dba_backup_update_select_backup_master 
* �ۼ�����    : 2008-01-28 by ������
* ����������  :  
* ����        : backup_master ������ BACKUP_MASTER�� ��ȸ, GDM01�� ����
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_backup_update_select_backup_master
    @server_name		    NVARCHAR(128) ,
	@database_name	        NVARCHAR(128) 
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @reg_dt     DATETIME
SET @reg_dt = GETDATE()

/* BODY */
SELECT 
		seq_no
	,	server_name
	,	database_name
	,	backup_flag
	,	backup_type
	,	san_flag
	,	backup_cycle
	,	backup_day
	,	reg_date
	,	chg_date	
FROM dbo.BACKUP_MASTER  
WHERE server_name= @server_name AND database_name = @database_name

IF @@ERROR <> 0 RETURN


RETURN

