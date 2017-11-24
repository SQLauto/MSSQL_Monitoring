
--������ �α��λ��� GMARKETSEO
CREATE LOGIN [GMARKETSEO\DBA] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[�ѱ���];
CREATE LOGIN [GMARKETSEO\DB_MANAGER] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[�ѱ���];
CREATE LOGIN [GMARKETSEO\DB_OP] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[�ѱ���];
CREATE LOGIN [GMARKETSEO\DEV] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[�ѱ���];

--������ �α��λ��� GMARKETINT
CREATE LOGIN [GMARKETINT\DBA] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[�ѱ���];
CREATE LOGIN [GMARKETINT\DB_MANAGER] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[�ѱ���];
CREATE LOGIN [GMARKETINT\DB_OP] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[�ѱ���];
CREATE LOGIN [GMARKETINT\DEV] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[�ѱ���];

--������ �α��λ��� GMARKETSEONH
CREATE LOGIN [GMARKETNH\DBA] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[�ѱ���];
CREATE LOGIN [GMARKETNH\DB_MANAGER] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[�ѱ���];
CREATE LOGIN [GMARKETNH\DB_OP] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[�ѱ���];
CREATE LOGIN [GMARKETNH\DEV] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[�ѱ���];


/******* ���� �� ***********/
--���Ѻο� ex)GMARKETNH\DB_MANAGER���� execute, showplan, view definition ���� �ο�
use [master]
GO
GRANT VIEW SERVER STATE TO [GMARKETNH\DB_MANAGER]

-- [GMARKET*/DBA] sysadmin ������ �ο�
EXEC sys.sp_addsrvrolemember @loginame = N'GMARKETSEO\DBA', @rolename = N'sysadmin'
GO


--������ Ȯ��
--EXEC sp_helpsrvrolemember
GO


-- User������ DB�� �ο� ex) GMARKETSEO\DEV

USE [����� DB] -- master�ؾ���. 
/****** ���� , OP ���� master�� ���� ���� ���ƾ��� **********/
GO

CREATE USER [GMARKETSEO\DB_MANAGER] FOR LOGIN [GMARKETSEO\DB_MANAGER]
GO
EXEC sp_addrolemember N'db_datareader', N'GMARKETSEO\DB_MANAGER'
EXEC sp_addrolemember N'db_datawriter', N'GMARKETSEO\DB_MANAGER'
if db_name() != master
begin
        EXEC sp_addrolemember N'db_ddladmin', N'GMARKETNH\DB_MANAGER' -- master���� ddl admin ���� ����
end
GO


GRANT VIEW DEFINITION TO [GMARKETNH\DB_MANAGER]
GRANT SHOWPLAN TO [GMARKETNH\DB_MANAGER]
GO

if db_name() != master
begin
    CREATE USER [GMARKETSEO\DB_OP] FOR LOGIN [GMARKETSEO\DB_OP]
    GO
    EXEC sp_addrolemember N'db_datareader', N'GMARKETSEO\DB_OP'
    
    
    CREATE USER [GMARKETSEO\DEV] FOR LOGIN [GMARKETSEO\DEV]
    GO
    EXEC sp_addrolemember N'db_datareader', N'GMARKETSEO\DEV'
    EXEC sp_addrolemember N'db_ddladmin', N'GMARKETSEO\DEV'
    EXEC sp_addrolemember N'db_securityadmin', N'GMARKETSEO\DEV'
end

