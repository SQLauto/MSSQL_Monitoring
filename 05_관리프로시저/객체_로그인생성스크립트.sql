/**********************************************************************************  
 *** 프로시져명 : up_dba_login_script  
 *** 목      적 : 해당 유저의 Login 스크립트 추출  
 *** 작  성  자 : 이성표  
 *** 작  성  일 : 2009-11-25  
 *** parameter   
   @loginname : login 명  
   @database : 권한을 주고자 하는 database  
   @role : 해당 db 에 주고자 하는 권한 (r : 읽기, w : 쓰기, o : owner)  
   @version  : 출력 스크립트의 SQL 버젼 별 유형 (2000, 2005, 2008)     
 *** 예제   
 exec up_dba_login_script 'ceusee'  
 exec up_dba_login_script @loginname = 'ceusee', @database = 'event', @role = 'rw', @version = 2005  
**********************************************************************************/  
ALTER PROCEDURE [dbo].[up_dba_login_script]   
     @loginname sysname = NULL,  
	 @database sysname = NULL,  
	 @role varchar(3) = NULL, -- 'rwo'  
	 @version int = 2005,  
	 @option char(1) = NULL  
AS  
SET NOCOUNT ON  
BEGIN  
  
IF @option = 'H'  
BEGIN  
 PRINT '-- PROC NAME : up_dba_login_script'  
 PRINT '-- PARAMETER'  
 PRINT '    @loginname : login name'  
 PRINT '    @database : default database'  
 PRINT '    @role : r 읽기, w 쓰기, o DBOWNER, 순차적으로 붙여서 사용'  
 PRINT '    @version'  
 PRINT '      2000 : MSSQL2000 형태(exec sp_addlogin)'  
 PRINT '      2005 : MSSQL2005 형태(CREATE LOGIN, DEFAULT)'  
 PRINT '      2008 : MSSQL2008 형태(현재는 2005 와 동일)'  
 PRINT '-- EXAMPLE'  
 PRINT '    EXEC sp_script_login_create @loginname = ''ceusee'', @database = ''event'', @role = ''rw'', @version = 2005'  
 PRINT '    EXEC sp_script_login_create ''login 명'''  
 RETURN  
END  
  
DECLARE @password varchar(256)  
DECLARE @sid varchar(85)  
DECLARE @script varchar(4000)  
  
IF @loginname IS NULL  
 RAISERROR('@loginname 에 정확한 값을 입력하여 주세요', 16, 1)  
  
select @password = master.dbo.fnc_hexa2decimal(CONVERT(varbinary(256), password)), @sid = master.dbo.fnc_hexa2decimal(sid)   
from master.dbo.syslogins where name = @loginname  

IF @sid IS NULL  
BEGIN
	DECLARE @msg varchar(100)
	SET @msg = @loginname + ' 은 존재하지 않은 Login 입니다.'
	RAISERROR(@msg, 16, 1)  
	return
END
 
  
IF @version = 2000  
BEGIN  
 SET @script = 'DECLARE @pwd sysname, @ssid varbinary(85)' + CHAR(13) + CHAR(10)  
 SET @script = @script + 'SET @pwd = CONVERT(varbinary(256), ' + @password + ')' + CHAR(13) + CHAR(10)  
 SET @script = @script + 'SET @sid = CONVERT(varbinary(16), ' + @sid + ')' + CHAR(13) + CHAR(10)  
 SET @script = @script + 'EXEC master.dbo.sp_addlogin ''' + @loginname + ''', @pwd, ''master'', @encryptopt = ''skip_encryption'', @sid = @sid' + CHAR(13) + CHAR(10)  
END  
ELSE IF @version = 2005 OR @version = 2008  
BEGIN  
 SET @script = 'CREATE LOGIN ' + @loginname + CHAR(13) + CHAR(10)  
 SET @script = @script + 'WITH PASSWORD = ' + @password + ' HASHED  MUST_CHANGE' + CHAR(13) + CHAR(10)  
 SET @script = @script + '     SID = ' + @sid + ',' + CHAR(13) + CHAR(10)  
 IF @database IS NOT NULL  
 SET @script = @script + '     DEFAULT_DATABASE = ' + @database + ',' + CHAR(13) + CHAR(10)  
 SET @script = @script + '     CHECK_EXPIRATION = OFF,' + CHAR(13) + CHAR(10)  
 SET @script = @script + '     CHECK_POLICY = OFF' + CHAR(13) + CHAR(10)  
END  
ELSE   
 RAISERROR('@version 값이 적합한 값이 아닙니다.', 16, 1)  
  
IF @database IS NOT NULL  
BEGIN  
  
 SET @script = @script + CHAR(13) + CHAR(10)
 SET @script = @script + 'USE ' + @database + CHAR(13) + CHAR(10)
 SET @script = @script + 'GO' +  CHAR(13) + CHAR(10)  
  
 SET @script = @script + 'IF EXISTS (SELECT * FROM ' + @database + '.dbo.sysusers WHERE name = ''' + @loginname + ''')' + CHAR(13) + CHAR(10)  
 SET @script = @script + 'BEGIN' + CHAR(13) + CHAR(10)  
 SET @script = @script + '    EXEC ' + @database + '.dbo.sp_change_users_login update_one, ' + @loginname + ', ' + @loginname + CHAR(13) + CHAR(10)  
 
 IF @role like '%r%'  
  SET @script = @script + '    EXEC ' + @database + '.dbo.sp_addrolemember ''db_datareader'', ''' + @loginname + '''' + CHAR(13) + CHAR(10)  
 
 IF @role like '%w%'  
  SET @script = @script + '    EXEC ' + @database + '.dbo.sp_addrolemember ''db_datawriter'', ''' + @loginname + '''' + CHAR(13) + CHAR(10)  
 
 IF @role like '%o%'  
  SET @script = @script + '    EXEC ' + @database + '.dbo.sp_addrolemember ''db_owner'', ''' + @loginname + '''' + CHAR(13) + CHAR(10)   
 SET @script = @script + 'END' + CHAR(13) + CHAR(10)  
 SET @script = @script + 'ELSE' + CHAR(13) + CHAR(10)  
 SET @script = @script + 'BEGIN' + CHAR(13) + CHAR(10)  
 
 SET @script =  @script + '    CREATE USER ' + @loginname  + ' FOR LOGIN ' + @loginname  + CHAR(13) + CHAR(10) 
 
 IF @role like '%r%'  
  SET @script = @script + '    EXEC ' + @database + '.dbo.sp_addrolemember ''db_datareader'', ''' + @loginname + '''' + CHAR(13) + CHAR(10)  
 
 IF @role like '%w%'  
  SET @script = @script + '    EXEC ' + @database + '.dbo.sp_addrolemember ''db_datawriter'', ''' + @loginname + '''' + CHAR(13) + CHAR(10)  
 
 IF @role like '%o%'  
  SET @script = @script + '    EXEC ' + @database + '.dbo.sp_addrolemember ''db_owner'', ''' + @loginname + '''' + CHAR(13) + CHAR(10)  
 SET @script = @script + 'END'  
END  
  
SET @script = @script + CHAR(13) + CHAR(10)  
  
PRINT @script  
  
END  