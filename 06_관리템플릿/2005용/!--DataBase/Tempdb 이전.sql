--=====================================
-- tempdb 이전에만 사용가능함
--=====================================
USE tempdb
go

EXEC sp_helpfile
go

USE master
go

--ALTER DATABASE tempdb SET SINGLE_USER WITH ROLLBACK AFTER 30

-- 1. 데이터 파일 이관
ALTER DATABASE tempdb
MODIFY FILE (
	NAME = tempdev,
	FILENAME = '디렉토리',
    SIZE = ,
    MAXSIZE = ,
    FILEGROWTH = 0MB
)
go

-- 2. 로그 파일 이관
ALTER DATABASE tempdb
MODIFY FILE (
	NAME = templog,
	FILENAME = '디렉토리',
    SIZE = ,
    MAXSIZE = ,
    FILEGROWTH = 0MB
)
go

-- 3.sql 재 시작
-- 4. 확인
USE tempdb
go
EXEC sp_helpfile
go

-- 5. 기존 파일 삭제