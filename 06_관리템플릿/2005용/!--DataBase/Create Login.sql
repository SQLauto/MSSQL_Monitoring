-- ===========================
-- Create Login
-- ===========================

-- 1. 순수 계정 생성
CREATE LOGIN <userName, sysname, userName> WITH PASSWORD ='<password, nvarchar,password>',
		DEFAULT_DATABASE = <dbname, sysname, dbname>,
		CHECK_POLICY = ON | OFF,
		CHECK_EXPIRATION = ON | OFF,		-- 암호 만료 정책 적용
		SID = [SID 값];
GO

-- 1-1 윈도우 도메인 계저에서 로그인 만들기
CREATE LOGIN [ADVWORKS\fogisu] FROM WINDOWS;
GO


--2. 로그인 수정
ALTER LOGIN <userName, sysname, userName> 
		WITH PASSWORD ='<password, nvarchar,password>',
		DEFAULT_DATABASE = <dbname, sysname, dbname>,
GO

-- 2-1 활성화 /비활성화
ALTER LOGIN <userName, sysname, userName>  ENABLE;
GO

--3. 로그인 삭제
DROP LOGIN <userName, sysname, userName>;
GO


-- 4. 로그인 계정이 잘 되었는지 확인
USER <dbname, sysname, dbname>
GO

EXEC sp_change_user_login 'REPORT'
GO

EXEC sp_change_user_login 'Update_One',  'Mary', NULL
GO