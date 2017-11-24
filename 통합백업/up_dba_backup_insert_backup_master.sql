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
* 프로시저명  : dbo.up_dba_backup_insert_backup_master 
* 작성정보    : 2007-12-20 by choi bo ra
* 관련페이지  : 
* 내용        : SQL 별 DB 백업하는 정보
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_backup_insert_backup_master
    @server_name		    NVARCHAR(128) ,
	@database_name	        NVARCHAR(128) ,
	@backup_flag		    TINYINT		  ,--1: DB + LOG, --2:DB, --3:LOG       
	@backup_type	        TINYINT		  ,--1: ONLINE BACKUP, --2: FILE BACKUP 
	@san_flag	            TINYINT		  ,--1: SAN 백업, -2: 네트워크 백업	    
	@backup_cycle           TINYINT       ,--1: 일, 2: 주, 3 : 월               
	@backup_day             TINYINT        -- cycle에 따른 입력                 
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