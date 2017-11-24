-- ======================================================================
-- 데이터베이스 파일 축소
-- 데이터베이스 옵션에 AutoShrink 을 true로 설정하면 자동으로 축되된다. 
-- ======================================================================
DBCC SHRINKDATABASE(test, 10)
GO

-- 특정데이터베이스 파일 줄이기
USE testdb
DBCC SHRINKDATABASE(test_dat, 10)
GO

-- 2.가상 로그 파일 축소
/* 트랜젝션 로그 파일이 여러번 자동 증가할 경우 가상 파일로 조각화 되고 성능에 
좋지 않은 영향을 미친다. 25개 이상일 경우 로그 파일 제거, 로그파일 적절한 크기로 변경
*/
USE test
GO
DBCC LOGINFO

-- 2-1. 트랜젝련 로그 파일 백업 혹은 삭제
BACKUP LOG test TO DISK = '<dir,nvarchar,userDir>'
GO

BACKUP LOG test WITH NO_LOG
GO

-- 2-2 트랜젝션 로그 파일의 크기를 작은 크기로 축소.
EXEC sp_helpfile
GO

DBCC SHRINKFILE(test_log, TRUNCATEONLY)
GO

--2-3 로그파일을 변경
ALTER DATABASE test MODIFIY FILE (
    NAME  = ,
    SIZE )
GO
