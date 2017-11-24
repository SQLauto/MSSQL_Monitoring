SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_dba_backup_insert_backup_master' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_dba_backup_insert_backup_master
*/

/*************************************************************************  
* ���ν�����  : dbo.up_dba_backup_insert_backup_master 
* �ۼ�����    : 2007-12-20 by choi bo ra
* ����������  : 
* ����        : SQL �� DB ����ϴ� ����
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_backup_insert_backup_master
    @server_name		    NVARCHAR(128) ,
	@database_name	        NVARCHAR(128) ,
	@backup_flag		    TINYINT		  ,--1: DB + LOG, --2:DB, --3:LOG       
	@backup_type	        TINYINT		  ,--1: ONLINE BACKUP, --2: FILE BACKUP 
	@san_flag	            TINYINT		  ,--1: SAN ���, -2: ��Ʈ��ũ ���	    
	@backup_cycle           TINYINT       ,--1: ��, 2: ��, 3 : ��               
	@backup_day             TINYINT        -- cycle�� ���� �Է�                 
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @reg_dt     DATETIME
SET @reg_dt = GETDATE()

/* BODY */
INSERT INTO dbo.BACKUP_MASTER
    (server_name, database_name, backup_flag, backup_type, san_flag, backup_cycle, backup_day, reg_date, chg_date)
VALUES(@server_name, @database_name, @backup_flag, @backup_type, @san_flag, @backup_cycle, @backup_day, @reg_dt, @reg_dt)

IF @@ERROR <> 0 RETURN

RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO