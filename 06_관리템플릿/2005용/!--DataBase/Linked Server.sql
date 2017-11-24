--=============================
--	링크드 서버 setting
--=============================

-- 1. OLEDB 사용
-- 링크드 서버 등록 필요한 경우
EXEC sp_addlinkedserver 
    @server='이름', 
    @srvproduct='',
    @provider='SQLOLEDB', 
    @datasrc='IPADDRERSS'
GO

EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = '이름',
    @useself = 'False',
    @locallogin = null,
    @rmtuser  = '계정',
    @rmtpassword = '암호'
GO


EXEC sp_serveroption '이름', 'rpc' , 'true'
GO

EXEC sp_serveroption '이름', 'rpc out', 'true'
GO


--2. SQLSERVER 사용
--별칭을 등록해야한다.
exec sp_addlinkedserver '이름', N'SQL Server'
exec sp_addlinkedsrvlogin '이름', 'false', null, '계정', '암호'
go