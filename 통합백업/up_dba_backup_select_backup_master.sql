SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_dba_backup_select_backup_master' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_dba_backup_select_backup_master
*/

/*************************************************************************  
* 프로시저명  : dbo.up_dba_backup_select_backup_master 
* 작성정보    : 2007-12-20 by choi bo ra
* 관련페이지  :  
* 내용        : backup_master 조회, GDM01에 생성
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_backup_select_backup_master
     @server_name       NVARCHAR(128) = NULL
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
IF @server_name IS NULL OR @server_name = ''
BEGIN
    SELECT server_name, database_name, 
           (CASE WHEN backup_flag = 1 THEN 'DB+LOG'
                 WHEN backup_flag = 2 THEN 'DB'
                 WHEN backup_flag = 3 THEN 'LOG' END ) as backup_flag, 
            (CASE WHEN backup_type = 1 THEN 'ONLINE' ELSE 'FILE' END )as backup_type, 
            (CASE WHEN san_flag = 1 THEN 'SAN' ELSE 'NETWORK' END ) as san_flag, 
            (CASE WHEN backup_cycle = 1 THEN 'Daily' 
                  WHEN backup_cycle = 2 THEN 'Weekly'
                  WHEN backup_cycle = 3 THEN 'Monthly' END) as backup_cycle, backup_day
    FROM dbo.BACKUP_MASTER WITH (NOLOCK)
    ORDER BY server_name, database_name
    
    IF @@ERROR <> 0 RETURN
END
ELSE
BEGIN
    SELECT server_name, database_name, 
            (CASE WHEN backup_flag = 1 THEN 'DB+LOG'
                 WHEN backup_flag = 2 THEN 'DB'
                 WHEN backup_flag = 3 THEN 'LOG' END ) as backup_flag, 
            (CASE WHEN backup_type = 1 THEN 'ONLINE' ELSE 'FILE' END )as backup_type, 
            (CASE WHEN san_flag = 1 THEN 'SAN' ELSE 'NETWORK' END ) as san_flag, 
            (CASE WHEN backup_cycle = 1 THEN 'Daily' 
                  WHEN backup_cycle = 2 THEN 'Weekly'
                  WHEN backup_cycle = 3 THEN 'Monthly' END) as backup_cycle, backup_day
    FROM dbo.BACKUP_MASTER WITH (NOLOCK)
    WHERE server_name = @server_name
    ORDER BY server_name, database_name
    
    IF @@ERROR <> 0 RETURN
END

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO