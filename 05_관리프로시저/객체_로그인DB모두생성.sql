/**********************************************************************************  
 *** 프로시져명 : up_dba_login_script_multi     
 *** 목      적 : 해당 유저의 Login 스크립트 추출  
 *** 작  성  자 : 이성표  
 *** 작  성  일 : 2009-11-25  
 *** parameter   
   @loginname : login 명  
   @database : 권한을 주고자 하는 database  
   @role : 해당 db 에 주고자 하는 권한 (r : 읽기, w : 쓰기, o : owner)  
   @version  : 출력 스크립트의 SQL 버젼 별 유형 (2000, 2005, 2008)     
 *** 예제   
 exec [up_dba_login_script_multi] 'ceusee'  
 exec [up_dba_login_script_multi] @loginname = 'ceusee', @def_database = 'event', @role = 'rw', @version = 2005  
**********************************************************************************/  
ALTER PROCEDURE [dbo].[up_dba_login_script_multi]
     @loginname sysname = NULL,
	 @role varchar(10) = NULL, -- 'rwo'  
	 @version int = 2005,  
	 @def_database sysname = NULL,
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
 PRINT '    EXEC up_dba_login_script_multi @loginname = ''ceusee'', @def_database = ''event'', @role = ''rw'', @version = 2005'  
 PRINT '    EXEC up_dba_login_script_multi @loginname = ''ceusee'''
 RETURN  
END  
  
DECLARE @password varchar(256)  
DECLARE @sid varchar(85)  
DECLARE @script varchar(4000) 
DECLARE @loginname1 sysname
DECLARE @user_count int, @i int
DECLARE @dbname     varchar(50)

SET @user_count = 0
SET @i = 1
  
IF @loginname IS NOT NULL  
BEGIN
  
    select @password = master.dbo.fnc_hexa2decimal(CONVERT(varbinary(256), password)), @sid = master.dbo.fnc_hexa2decimal(sid)   
    from master.dbo.syslogins where name = @loginname  
    
    IF @sid IS NULL  
    BEGIN
    	DECLARE @msg varchar(100)
    	SET @msg = @loginname + ' 은 존재하지 않은 Login 입니다.'
    	RAISERROR(@msg, 16, 1)  
    	return
    END
END
 
select  identity(int,1,1) as seqno 
	 ,master.dbo.fnc_hexa2decimal(CONVERT(varbinary(256), password)) as password
	 , master.dbo.fnc_hexa2decimal(sid)  as sid 
	 , name as loginname
into #tmp_user
from master..syslogins where name like @loginname + '%'

SET @user_count = @@ROWCOUNT


while (@i  <= @user_count)
begin
    
    select  @password = password, @sid =sid, @loginname1 = loginname
	from #tmp_user where seqno = @i
	
	
    IF @version = 2000  
    BEGIN  
     SET @script = 'DECLARE @pwd sysname, @ssid varbinary(85)' + CHAR(13) + CHAR(10)  
     SET @script = @script + 'SET @pwd = CONVERT(varbinary(256), ' + @password + ')' + CHAR(13) + CHAR(10)  
     SET @script = @script + 'SET @sid = CONVERT(varbinary(16), ' + @sid + ')' + CHAR(13) + CHAR(10)  
     SET @script = @script + 'EXEC master.dbo.sp_addlogin ''' + @loginname1 + ''', @pwd, ''master'', @encryptopt = ''skip_encryption'', @sid = @sid' + CHAR(13) + CHAR(10)  
    END  
    ELSE IF @version = 2005 OR @version = 2008  
    BEGIN  
     SET @script = 'CREATE LOGIN ' + @loginname1 + CHAR(13) + CHAR(10)  
     SET @script = @script + 'WITH PASSWORD = ' + @password + ' HASHED ' + CHAR(13) + CHAR(10)  
     SET @script = @script + '     SID = ' + @sid + ',' + CHAR(13) + CHAR(10)  
     
     IF  @def_database IS NOT NULL  
     SET @script = @script + '     DEFAULT_DATABASE = ' + @def_database + ',' + CHAR(13) + CHAR(10)  
     SET @script = @script + '     CHECK_EXPIRATION = OFF,' + CHAR(13) + CHAR(10)  
     SET @script = @script + '     CHECK_POLICY = OFF' + CHAR(13) + CHAR(10)  
    END  
    ELSE   
     RAISERROR('@version 값이 적합한 값이 아닙니다.', 16, 1)
     
     DECLARE dbname_cursor CURSOR FOR   
        SELECT name  
        from master..sysdatabases with (nolock)       
        where name not in   
            ('northwind', 'pubs', 'LiteSpeedCentral', 'LiteSpeedLocal', 'credit2', 'tempdb')  
        and DATABASEPROPERTYEX(name,'status')='ONLINE' 
        and dbid > 4 
    
    OPEN dbname_cursor         
    FETCH next FROM dbname_cursor into @dbname    
      
    WHILE @@FETCH_STATUS = 0  
    BEGIN  
        
        SET @script = @script + CHAR(13) + CHAR(10)
        SET @script = @script + 'USE ' + @dbname + CHAR(13) + CHAR(10)
        SET @script = @script + 'GO' +  CHAR(13) + CHAR(10)
        
        SET @script = @script + 'IF EXISTS (SELECT * FROM ' + @dbname + '.dbo.sysusers WHERE name = ''' + @loginname1 + ''')' + CHAR(13) + CHAR(10)  
		SET @script = @script + 'BEGIN' + CHAR(13) + CHAR(10)  
        SET @script = @script + '    EXEC ' + @dbname + '.dbo.sp_change_users_login update_one, ' + @loginname1 + ', ' + @loginname + CHAR(13) + CHAR(10)  
        
        IF @role like '%r%'  
          SET @script = @script + '    EXEC ' + @dbname + '.dbo.sp_addrolemember ''db_datareader'', ''' + @loginname1 + '''' + CHAR(13) + CHAR(10)  
        IF @role like '%w%'  
          SET @script = @script + '    EXEC ' + @dbname + '.dbo.sp_addrolemember ''db_datawriter'', ''' + @loginname1 + '''' + CHAR(13) + CHAR(10)  
        IF @role like '%o%'  
          SET @script = @script + '    EXEC ' + @dbname + '.dbo.sp_addrolemember ''db_owner'', ''' + @loginname1 + '''' + CHAR(13) + CHAR(10)   
        SET @script = @script + 'END' + CHAR(13) + CHAR(10)  
        SET @script = @script + 'ELSE' + CHAR(13) + CHAR(10)  
        SET @script = @script + 'BEGIN' + CHAR(13) + CHAR(10) 
        
        SET @script =  @script + '    CREATE USER ' + @loginname1  + ' FOR LOGIN ' + @loginname1  + CHAR(13) + CHAR(10) 
        IF @role like '%r%'  
          SET @script = @script + '    EXEC ' + @dbname + '.dbo.sp_addrolemember ''db_datareader'', ''' + @loginname1 + '''' + CHAR(13) + CHAR(10)  
        IF @role like '%w%'  
          SET @script = @script + '    EXEC ' + @dbname + '.dbo.sp_addrolemember ''db_datawriter'', ''' + @loginname1 + '''' + CHAR(13) + CHAR(10)  
        IF @role like '%o%'  
          SET @script = @script + '    EXEC ' + @dbname + '.dbo.sp_addrolemember ''db_owner'', ''' + @loginname1 + '''' + CHAR(13) + CHAR(10)  
        
        SET @script = @script + 'END'  
 
 
        print @script
        
        set @script = ''    
          
       FETCH NEXT FROM dbname_cursor INTO @dbname  
     END  
      
    CLOSE dbname_cursor  
    DEALLOCATE dbname_cursor

   SET @i = @i + 1  
	END
END