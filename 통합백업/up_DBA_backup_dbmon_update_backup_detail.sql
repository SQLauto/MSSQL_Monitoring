
/*IF EXISTS (SELECT name 
              FROM   sysobjects 
              WHERE  name = N'up_DBA_backup_dbmon_update_backup_detail' 
              AND              type = 'P')
    DROP PROCEDURE  procedure_name
*/
/*************************************************************************  
* 프로시저명  : dbo.up_DBA_backup_dbmon_update_backup_detail
* 작성정보    : 2007-12-28
* 관련페이지  : 안 지 원   
* 내용        :
* 수정정보    : exec dbo.up_DBA_backup_dbmon_update_backup_detail 
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_backup_dbmon_update_backup_detail	
		@intSeqNo			int					--번호 
	,	@strFactor			nvarchar(max)		--원인
	,	@strResult			nvarchar(max)		--조치 사항 
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

UPDATE dbo.backup_detail 
SET factor = @strFactor
and result = @strResult



IF @@ERROR <> 0 RETURN
RETURN

