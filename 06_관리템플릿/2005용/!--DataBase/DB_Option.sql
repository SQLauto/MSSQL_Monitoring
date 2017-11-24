--==================================================
-- DB 옵션 변경
-- 옵션종료
-- offline  true : offline
-- single user
--==================================================
USE master
GO

-- sp_dboption 으로 설정하고자 할때
-- 설정
EXEC sp_dboption '<dbname, sysname, dbname>', 'read only', 'TRUE'; -- 읽기전용으로 설정
-- 옵션 해제
EXEC sp_dboption '<dbname, sysname, dbname>', 'read only', 'FALSE';


-- ALTER DATABASE (SET Option)
/*
	update option : { READ_ONLY | READ_WRITE }
	db_user_access_option : { SINGLE_USER | RESTRICTED_USER | MULTI_USER }
	db_stat_option : { ONLINE | OFFLINE | EMERGENCY }
	recovery_option : RECOVERY { FULL | BULK_LOGGED | SIMPLE } 
					  | TORN_PAGE_DETECTION { ON | OFF }
					  | PAGE_VERIFY { CHECKSUM | TORN_PAGE_DETECTION | NONE }
*/

ALTER DATABASE '<dbname, sysname, dbname>' SET OFFLINE ON