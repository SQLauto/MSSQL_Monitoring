--==========================================================
--      2009-02-23 by 최보라

-- 내용 : GMKTSQL2008 권한 재 설정 스크립트
--          db_op  : read, write, showplan 가능
--          db_manager : read 가능, 모니터링 sp 권한 추가
-- ==========================================================

-- 기존 db_namager 삭제


/*
-- TIGER
up_DBA_ShowSysProcess
up_DBA_ShowSysProcessByOption
up_DBA_show_blockinfo
-- LION
up_DBA_contrCount_Detail
*/

-- cowdb에서 삭제
use master
go

SET NOCOUNT ON 
DECLARE @name sysname, @sql nvarchar(max)

DECLARE cur_dbname CURSOR FOR
    select name from sys.databases where database_id != 4 and state = 0 order by name

OPEN cur_dbname
FETCH NEXT FROM cur_dbname
INTO @name 

WHILE @@FETCH_STATUS = 0
BEGIN
    

    SET @sql = 'USE ' + @name + ';' + char(13) 
           + 'IF exists(select name from sys.sysusers where name = ''db_manager'')' + char(13)
           + 'BEGIN' + char(13)
           + 'DROP SCHEMA [db_manager];' + char(13)
           + 'DROP USER [db_manager]; END'

    print @sql
    exec sp_executesql @sql 

    FETCH NEXT FROM cur_dbname 
    INTO @name

END
CLOSE cur_dbname
DEALLOCATE cur_dbname

Drop Login db_manager
go

-- ==============================
-- 생성
-- ==============================
use master
go

CREATE LOGIN db_op WITH PASSWORD ='Op301^',
	       DEFAULT_DATABASE = tiger,
	       CHECK_POLICY = OFF,
	       CHECK_EXPIRATION = OFF
go

CREATE LOGIN db_manager WITH PASSWORD ='Ma301^',
	       DEFAULT_DATABASE = tiger,
	       CHECK_POLICY = OFF,
	       CHECK_EXPIRATION = OFF
go

/*
exec sp_grantdbaccess 'db_manager', 'db_manager';
exec sp_addrolemember 'db_datawriter', 'db_manager';
exec sp_addrolemember 'db_datareader', 'db_manager';
grant SHOWPLAN to db_manager;
grant VIEW DEFINITION to db_manager;

exec sp_grantdbaccess 'db_op', 'db_op';
exec sp_addrolemember 'db_datareader', 'db_op';
*/


use master
go

SET NOCOUNT ON 
DECLARE @name sysname, @sql nvarchar(max)

DECLARE cur_dbname CURSOR FOR
    select name from sys.databases where database_id > 4 and state = 0 order by name

OPEN cur_dbname
FETCH NEXT FROM cur_dbname
INTO @name 

WHILE @@FETCH_STATUS = 0
BEGIN
    
    
    SET @sql = 'USE ' + @name + ';' + char(13) 
           + 'IF not exists(select name from sys.sysusers where name = ''db_manager'')' + char(13)
           + 'BEGIN' + char(13)
           + 'exec sp_grantdbaccess ''db_manager'', ''db_manager'';' + char(13)
           + 'exec sp_addrolemember ''db_datawriter'', ''db_manager'';' + char(13)
           + 'exec sp_addrolemember ''db_datareader'', ''db_manager'';' + char(13)
           + 'exec sp_addrolemember ''db_securityadmin'', ''db_manager'';' + char(13)
           + 'grant SHOWPLAN to db_manager;' + char(13)
           + 'grant execute to db_manager;' + char(13)
           + 'grant VIEW DEFINITION to db_manager; END'

    print @sql
    exec sp_executesql @sql 
    

    SET @sql = 'USE ' + @name + ';' + char(13) 
       + 'IF not exists(select name from sys.sysusers where name = ''db_op'')' + char(13)
       + 'BEGIN' + char(13)
       + 'exec sp_grantdbaccess ''db_op'', ''db_op'';' + char(13)
       + 'exec sp_addrolemember ''db_datareader'', ''db_op'';' + char(13)
       + 'END'
 


    print @sql
    exec sp_executesql @sql 

    FETCH NEXT FROM cur_dbname 
    INTO @name

END
CLOSE cur_dbname
DEALLOCATE cur_dbname

grant VIEW SERVER STATE  to db_manager

use dba
go

grant VIEW DEFINITION to db_op;

use tiger
go

GRANT EXECUTE ON OBJECT::up_DBA_ShowSysProcess   to db_op                                 
GRANT EXECUTE ON OBJECT::up_DBA_ShowSysProcessByOption     to db_op                       
GRANT EXECUTE ON OBJECT::up_DBA_show_blockinfo to db_op   
go

use lion
go                                       
          
GRANT EXECUTE ON OBJECT::up_DBA_contrCount_Detail to db_op                                                     
                                     