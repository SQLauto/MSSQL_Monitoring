--======================================
-- ����͸� �ϴ� SP ����
--======================================
USE TIGER
GO

-- blocking ����
exec dbo.up_dba_show_blockinfo

-- ���ŷ ���� ����Ʈ
exec sp_blocking_sessions


-- ���� ����ǰ� �ִ� sysprocess ����
exec dbo.up_dba_showsysprocess

--���� �������� SP ���
exec sp_current_execs


-- ��ü��/��ü�� counting
exec lion.dbo.up_dba_contrcount_deail

-- ü�� ���� �����α� ��ȸ 
exec sp_get_dscontr_error

-- ���� ��� ����
exec sp_track_waitstats

-- ���� ��� ������ data ��ȸ
exec sp_get_waitstats

