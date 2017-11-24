SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

use dbadmin
go

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_drop_all_sqllogin
* 작성정보    : 2011-09-01 by choi bo ra
* 관련페이지  : 
* 내용        : 로그인 계정 모두 삭제
* 수정정보    :
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_drop_all_sqllogin 
    @sql_login      sysname
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @script nvarchar(4000)
DECLARE @loginname  sysname
DECLARE @username   sysname
DECLARE @schemaname sysname 
DECLARE @dbname		sysname
DECLARE @ParmDefinition nvarchar(300)

DECLARE @errnum int
DECLARE @errmessage nvarchar(2048)
SET @script =''

/* BODY */

-- 로그인 계정이 있는지 확인. 
IF NOT EXISTS ( SELECT  *  FROM SYS.SQL_LOGINS WITH (NOLOCK)  WHERE name = @sql_login)
BEGIN
	RAISERROR ( N'%s는 존재하지 않은 Login 입니다. User 삭제 진행합니다.', 10, 1, @sql_login)

END



 DECLARE dbname_cursor CURSOR FOR   
        SELECT name  
        from master..sysdatabases with (nolock)       
        where name not in   
            ('northwind', 'pubs', 'LiteSpeedCentral', 'LiteSpeedLocal', 'credit2', 'tempdb')  
        and DATABASEPROPERTYEX(name,'status')='ONLINE'
        and DATABASEPROPERTYEX(name,'Updateability') = 'READ_WRITE'    
        and dbid > 4 
    
OPEN dbname_cursor         
FETCH next FROM dbname_cursor into @dbname
  WHILE @@FETCH_STATUS = 0  
  BEGIN  
    
        SET @script = @script + 'USE ' + @dbname + CHAR(13) + CHAR(10)
 
        
        SET @script = @script + 'SELECT @loginname=slog.name, @username=duser.name, @schemaname=sch.name '+ char(10)
                              + 'FROM SYS.SQL_LOGINS AS SLOG WITH (NOLOCK) '+ char(10)
                	          + 'INNER JOIN SYS.DATABASE_PRINCIPALS AS DUSER WITH(NOLOCK)  '+ char(10)
                		      +     'ON SLOG.SID = DUSER.SID '+ char(10)
                	          + 'LEFT JOIN SYS.SCHEMAS AS SCH WITH(NOLOCK) '+ char(10)
                		      +     'ON SCH.PRINCIPAL_ID = DUSER.PRINCIPAL_ID '+ char(10)
                              + 'WHERE  DUSER.TYPE_DESC =''SQL_USER'' '+ char(10)
                              + ' AND slog.name = ''' + @sql_login + ''''
        
        SET @ParmDefinition = N'@loginname sysname output, @username sysname output, @schemaname sysname output' 
        
        --print @script
        -- 계정 정보 select
        BEGIN TRY                         
            exec sp_executesql @script, @ParmDefinition, @loginname =@loginname output , @username =@username output, 
                                    @schemaname  = @schemaname output
        END TRY
        BEGIN CATCH
            
            SET @errnum = ERROR_NUMBER()
            SET @errmessage = ERROR_MESSAGE()
            
            RAISERROR ( N'로그인 계정 조회 ERROR :%d, message:%s', 16, 1, @errnum, @errmessage)
            RETURN
            
    
        END CATCH
        
        --DB별 User 삭제 작업 Start
        SET @script = ''
  
  
        IF @schemaname is not null
        BEGIN
			SET @script = @script + 'DROP SCHEMA ' + @schemaname + char(10)
        END
        
        IF @username is not null
        BEGIN
			SET @script = @script + 'DROP USER ' + @username + char(10)
		END
  

        
        BEGIN TRY
			IF @script != ''
			BEGIN
				SET @script =  'USE ' + @dbname + CHAR(13) + CHAR(10) + @script
				
				exec sp_executesql @script
				
			   print @dbname + ' 삭제 완료'
			END
        END TRY
        BEGIN CATCH
            
            SET @errnum = ERROR_NUMBER()
            SET @errmessage = ERROR_MESSAGE()
            
            RAISERROR ( N'%s User Drop 에러 ERROR :%d, message:%s', 16, 1, @loginname,@errnum, @errmessage)
            RETURN
    
        END CATCH
       
       SET @script = ''    
       FETCH NEXT FROM dbname_cursor INTO @dbname
        
  
  END
         
  CLOSE dbname_cursor  
  DEALLOCATE dbname_cursor   

IF EXISTS ( SELECT  *  FROM SYS.SQL_LOGINS WITH (NOLOCK)  WHERE name = @sql_login)
BEGIN
	  -- 로그인 삭제
	SET @script = ''
	SET @script = 'DROP LOGIN ' + @sql_login
	  
	BEGIN TRY
		exec sp_executesql @script
	END TRY
	BEGIN CATCH
	    
		SET @errnum = ERROR_NUMBER()
		SET @errmessage = ERROR_MESSAGE()
	    
		RAISERROR ( N'%s Login Drop 에러 ERROR :%d, message:%s', 16, 1, @loginname,@errnum, @errmessage)
		RETURN
	    

	END CATCH

END
   
RETURN



SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

