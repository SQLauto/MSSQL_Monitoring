--============================================
-- ��Ƽ�� ���̺� Ȯ�� ���ν���
--============================================
EXEC up_DBA_partition_list    -- ��Ƽ�� �� ���̺� ��� Ȯ�� ����

DECLARE @object_name sysname
EXEC up_DBA_helptable_partition @object_name  -- ���̺� �ϳ��� �� ����


-- ��ü ��Ƽ�ǵ� ���̺��� ���� ���� DBA ������ ���̽��� ����
USE DBA
GO

EXEC up_DBA_select_partition_table_info