SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_grant_database 
* 작성정보    : 2008-12-03  by 최보라
* 관련페이지  :  
* 내용        : 데이터베이스별로 권한을 모두 줌
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_grant_database
     @login_id      sysname ,
     @rolename      sysname ,
     @issystem      char(1) = 'F'
    

     
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* User Declare */
DECLARE @db_name	sysname
DECLARE @strsql		nvarchar(200)
DECLARE @row_count	tinyint

SET @row_count = 0

/* Body */
IF @issystem = 'F'
BEGIN
	DECLARE Grant_Cursor CURSOR FOR
		SELECT Name From Sys.Sysdatabases 
		WHERE Dbid > 4 And Name <> 'litespeedlocal'  -- 시스템 DB 제외
		        AND CONVERT(sysname,DatabasePropertyEx(name,'Status')) NOT IN ( 'OFFLINE')
		ORDER BY dbid
	FOR READ ONLY 
END
ELSE IF @issystem = 'T'
BEGIN
	DECLARE Grant_Cursor CURSOR FOR
		SELECT Name From Sys.Sysdatabases 
		WHERE Name NOT IN ( 'litespeedlocal', 'model')  -- 시스템 DB 포함
		        AND CONVERT(sysname,DatabasePropertyEx(name,'Status')) NOT IN ( 'OFFLINE')
		ORDER BY dbid
	FOR READ ONLY 
END


-- 커서 오픈
OPEN Grant_Cursor;

FETCH NEXT FROM  Grant_Cursor
INTO @db_name

WHILE @@FETCH_STATUS = 0
BEGIN

	SET @strsql =
		'select  @count= count(*)  from ' + @db_name + '.sys.database_principals where name = ''' + @login_id + ''''
	EXEC sp_executesql @strsql, N'@count tinyint output', @count = @row_count OUTPUT

	IF @row_count = 0 
	BEGIN
    
		SET @strsql = 'exec ' + @db_name + '.dbo.sp_grantdbaccess ''' + @login_id + '''' + ',''' + @login_id + ''''
		EXEC sp_executesql @strsql
	END
		
		
        SET @strsql = 'exec ' + @db_name + '.dbo.sp_addrolemember ''' + @rolename + '''' + ',''' + @login_id + ''''
        EXEC sp_executesql @strsql
   
    
    FETCH NEXT FROM Grant_Cursor INTO @db_name
        
END

CLOSE Grant_Cursor
DEALLOCATE Grant_Cursor

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO