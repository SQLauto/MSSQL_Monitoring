--=================================
-- ����͸����� lock Ȯ��
--=================================

USE DBA
GO

-- 2000 ���
exec dba.dbo.up_DBA_CheckProcessStatus2  @exec_mode = 1
--exec dba.dbo.up_DBA_CheckProcessStatus  @exec_mode = 1

exec sp_who4

-- ���ŷ ����, ��⸮��Ʈ �� ���� �������� ����
exec tiger.dbo.up_DBA_show_blockinfo