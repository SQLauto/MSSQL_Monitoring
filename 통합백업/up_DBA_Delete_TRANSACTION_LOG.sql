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
* 프로시저명  : dbo.up_DBA_Delete_TRANSACTION_LOG
* 작성정보    : 2007-12-05
* 관련페이지  : 안 지 원  
* 내용        : 트랜잭션 로그 날짜 지우기 
* 수정정보    :
* param정보   : 1) DB명 2) 디렉토리경로 3) 지울 날짜(몇일전 로그 지울것인지 입력받음)
* exec dbo.up_DBA_Delete_TRANSACTION_LOG 'gmarket_Config_db' , 'E:\BackupDB\gmarket_Config_db' , 1
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_Delete_TRANSACTION_LOG
 @db_name            SYSNAME,					--DB이름
 @file_dir       	 NVARCHAR(256) = NULL,  	--파일디렉토리 경로
 @delete_date 	     INT = 1,					--지울날짜 
 @RetCd			     INT   OUTPUT

    
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @getdate			 DATETIME       		--오늘날짜
DECLARE @backup_date		 NVARCHAR(12)   		--삭제될 날짜 	
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


