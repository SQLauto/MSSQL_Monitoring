---======================================
-- 로그인 암호 변경, 사이트 차단시 사용
-- =======================================
--1. 2005용
use master
GO

ALTER LOGIN goodsdaq WITH PASSWORD ='sql3951'
ALTER LOGIN dev WITH PASSWORD ='dev3951'
ALTER LOGIN backend WITH PASSWORD ='admin3951'

ALTER LOGIN goodsdaq WITH PASSWORD ='sql3950'
ALTER LOGIN dev WITH PASSWORD ='dev3950'
ALTER LOGIN backend WITH PASSWORD ='admin3950'

GO

--2.  2000용
use master
GO
--이용자 계정을 통한 접속 차단
sp_password 'sql3950', 'sql3951', 'goodsdaq'
go
sp_password 'dev3950', 'dev3951', 'dev'
go
sp_password 'admin3950', 'admin3951', 'backend'
go

--작업 완료 후 이용자 계정 정상으로 돌려주기
sp_password 'sql3951', 'sql3950', 'goodsdaq'
go
sp_password 'dev3951', 'dev3950', 'dev'
go
sp_password 'admin3951', 'admin3950', 'backend'
go
