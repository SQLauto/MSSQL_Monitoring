--======================================
-- 모니터링 하는 SP 모음
--======================================
USE TIGER
GO

-- blocking 유발
exec dbo.up_dba_show_blockinfo

-- 블로킹 유발 리스트
exec sp_blocking_sessions


-- 현재 실행되고 있는 sysprocess 정보
exec dbo.up_dba_showsysprocess

--현재 수행중인 SP 목록
exec sp_current_execs


-- 선체결/후체결 counting
exec lion.dbo.up_dba_contrcount_deail

-- 체결 엔진 에러로그 조회 
exec sp_get_dscontr_error

-- 현재 대기 수집
exec sp_track_waitstats

-- 현재 대기 수집된 data 조회
exec sp_get_waitstats

