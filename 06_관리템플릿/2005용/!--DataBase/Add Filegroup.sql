-- ======================================
-- db 파일 그룹 추가
-- ======================================
-- 1. 파일 그룹을 추가
ALTER DATABASE <DBName,sysname,userDB>
    ADD FILEGROUP <FilegorupName, nvarchar, userFilegroup>
GO

--2.데이터 파일을 추가
ALTER DATABASE <DBName,sysname,userDB> 
	ADD FILE (
		Name = <fileName, nvarchar, userFile>,
		FILENAME '<dir, nvarchar, userdir>',
		SIZE = , 
		MAXSIZE = , 
		FILEGROWTH = ) TO FILEGROUP '<FilegorupName, nvarchar, userFilegroup>'
GO

-- ==================================
-- db 파일 그룹 수정
-- ==================================
-- 1. 파일 그룹명 변경
ALTER DATABASE <DBName, sysname, userDB> MODIFY FILEGROUP <FileGroupName, nvarchar, userFileGroup> 
	NAME = <NewFileGroup, nvarchar, NewFileGroup>
GO
-- 해당 파일 그룹에 객체들이 존재하지 않아야 함



-- ==================================
-- db 파일 수정
-- ==================================
-- 1. 파일 사이즈 변경
ALTER DATABASE <DBName,sysname,userDB>
	MODIFY FILE (
		Name = <fileName, nvarchar, userFile>,
		FILENAME '<dir, nvarchar, userdir>',
		SIZE = , 
		MAXSIZE = , 
		FILEGROWTH = ) TO FILEGROUP '<FilegorupName, nvarchar, userFilegroup>'
GO




-- =================================
-- 파일 그룹/파일 삭제
-- ==================================
-- 1.그룹 삭제
ALTER DATABASE <DBName, sysname, userDB>
	REMOVE FILEGROUP <FileGroupName, nvarchar, userFileGroup> 
GO

-- 2.파일 삭제
ALTER DATABASE <DBName, sysname, userDB>
	REMOVE FILE <fileName, nvarchar, userFile>
GO



-- ===============================
-- 기본 파일 그룹 설정
-- ===============================
ALTER DATABASE <DBName, sysname, userDB>
MODIFY FILEGROUP <FileGroupName, nvarchar, userFileGroup> DEFAULT;
GO

