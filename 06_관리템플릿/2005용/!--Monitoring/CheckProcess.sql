--=================================
-- 모니터링에서 lock 확인
--=================================

USE DBA
GO

-- 2000 방식
exec dba.dbo.up_DBA_CheckProcessStatus2  @exec_mode = 1
--exec dba.dbo.up_DBA_CheckProcessStatus  @exec_mode = 1

exec sp_who4

-- 블로킹 유발, 대기리스트 및 현재 실행중인 구문
exec tiger.dbo.up_DBA_show_blockinfo