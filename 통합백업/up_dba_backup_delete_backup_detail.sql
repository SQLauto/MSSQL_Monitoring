SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_dba_backup_delete_backup_detail' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_dba_backup_delete_backup_detail
*/

/*************************************************************************  
* ���ν�����  : dbo.up_dba_backup_delete_backup_detail 
* �ۼ�����    : 2007-12-21 by choi bo ra
* ����������  :  
* ����        : ���� ��¥�� ������ ������ �ִ��� Ȯ��
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_backup_delete_backup_detail
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @from_dt DATETIME
DECLARE @to_dt DATETIME
SET @from_dt = CONVERT(DATETIME, (CONVERT(NVARCHAR(10), GETDATE(), 120) + ' 00:00:00'))
SET @to_dt = CONVERT(DATETIME, (CONVERT(NVARCHAR(10),DATEADD(dd, 1, GETDATE()),120)) + ' 00:00:00')

/* BODY */
DELETE BACKUP_DETAIL WHERE reg_dt >= @from_dt AND reg_dt < @to_dt
IF @@ERROR <> 0  RETURN

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO