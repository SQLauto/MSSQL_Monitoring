
/*IF EXISTS (SELECT name 
              FROM   sysobjects 
              WHERE  name = N'up_DBA_backup_dbmon_update_backup_detail' 
              AND              type = 'P')
    DROP PROCEDURE  procedure_name
*/
/*************************************************************************  
* ���ν�����  : dbo.up_DBA_backup_dbmon_update_backup_detail
* �ۼ�����    : 2007-12-28
* ����������  : �� �� ��   
* ����        :
* ��������    : exec dbo.up_DBA_backup_dbmon_update_backup_detail 
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_backup_dbmon_update_backup_detail	
		@intSeqNo			int					--��ȣ 
	,	@strFactor			nvarchar(max)		--����
	,	@strResult			nvarchar(max)		--��ġ ���� 
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

UPDATE dbo.backup_detail 
SET factor = @strFactor
and result = @strResult



IF @@ERROR <> 0 RETURN
RETURN

