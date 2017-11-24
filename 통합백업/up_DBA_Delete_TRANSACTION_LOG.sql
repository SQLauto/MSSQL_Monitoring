SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
              FROM   sysobjects 
              WHERE  name = N'up_DBA_Delete_TRANSACTION_LOG' 
              AND              type = 'P')
    DROP PROCEDURE  procedure_name
*/

/*************************************************************************  
* ���ν�����  : dbo.up_DBA_Delete_TRANSACTION_LOG
* �ۼ�����    : 2007-12-05
* ����������  : �� �� ��  
* ����        : Ʈ����� �α� ��¥ ����� 
* ��������    :
* param����   : 1) DB�� 2) ���丮��� 3) ���� ��¥(������ �α� ��������� �Է¹���)
* exec dbo.up_DBA_Delete_TRANSACTION_LOG 'gmarket_Config_db' , 'E:\BackupDB\gmarket_Config_db' , 1
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_Delete_TRANSACTION_LOG
 @db_name            SYSNAME,					--DB�̸�
 @file_dir       	 NVARCHAR(256) = NULL,  	--���ϵ��丮 ���
 @delete_date 	     INT = 1,					--���ﳯ¥ 
 @RetCd			     INT   OUTPUT

    
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @getdate			 DATETIME       		--���ó�¥
DECLARE @backup_date		 NVARCHAR(12)   		--������ ��¥ 	
DECLARE @strSql				 NVARCHAR(300)	

SET @getdate = getdate()
SET @backup_date =  CONVERT(nvarchar(8),GETDATE(),112) - @delete_date
SET @file_dir = @file_dir + '\'
SET @RetCd = -1

/* BODY */
SET @db_name = UPPER(@db_name)
IF (DB_ID(@db_name) IS NULL) OR (DATABASEPROPERTYEX(@db_name,'Status')<>'ONLINE')
BEGIN                   				
	RAISERROR('Database %s is invalid or database status is not ONLINE',16,1,@db_name)
	SET @RetCd = 2
	RETURN		
END



BEGIN    
    SELECT @strSql = N'EXEC master..xp_cmdshell  ''DEL ' + + @file_dir  + @db_name +'_TLOG_' +@backup_date +'*.TRN'''

    EXEC sp_executesql @strSql
    
    SET @RetCd = @@ERROR
    IF @RetCd <> 0 RETURN
END


RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO


