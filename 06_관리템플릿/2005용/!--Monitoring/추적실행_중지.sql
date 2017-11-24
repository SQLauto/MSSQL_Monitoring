-- =============================
--  ���� ����/���� ���
-- =============================
use master
GO

-- ���ν��� �̿� ���� ����, ����
DECLARE @file_name NVARCHAR(200)
DECLARE @end_time DATETIME

SET @end_time = DATEADD(mi,20, GETDATE())
SET @file_name = 'D:\Data\TRACE\trace_' + convert(char(8), getdate(), 112) + right('00' + convert(varchar, datepart(hh, getdate())), 2) +  right('00' + convert(varchar, datepart(mi, getdate())), 2)

EXEC sp_start_trace @file_name, 'SEARCHDB_Trace', 0, 1024, null, null, null, 11

-- ����
EXEC sp_stop_trace 0, 'SEARCHDB_Trace'

-- ���� ���� ��ȯ
select * from fn_trace_getinfo (0)

 

-- �������� ����/����
exec sp_trace_setstatus @traceid = , @status = 

--0: ������ ������ ����
--1: ������ ��ô ����
--2: ������ ���� �ݰ� ���� ����