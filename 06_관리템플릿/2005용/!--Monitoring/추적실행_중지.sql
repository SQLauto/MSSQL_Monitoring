-- =============================
--  추적 실행/중지 방법
-- =============================
use master
GO

-- 프로시저 이용 추적 실행, 중지
DECLARE @file_name NVARCHAR(200)
DECLARE @end_time DATETIME

SET @end_time = DATEADD(mi,20, GETDATE())
SET @file_name = 'D:\Data\TRACE\trace_' + convert(char(8), getdate(), 112) + right('00' + convert(varchar, datepart(hh, getdate())), 2) +  right('00' + convert(varchar, datepart(mi, getdate())), 2)

EXEC sp_start_trace @file_name, 'SEARCHDB_Trace', 0, 1024, null, null, null, 11

-- 중지
EXEC sp_stop_trace 0, 'SEARCHDB_Trace'

-- 추적 정보 반환
select * from fn_trace_getinfo (0)

 

-- 추적상태 수정/중지
exec sp_trace_setstatus @traceid = , @status = 

--0: 지정한 추적을 중지
--1: 지정한 추척 시작
--2: 지정한 추적 닫고 정의 삭제