-- ======================================================================
-- �����ͺ��̽� ���� ���
-- �����ͺ��̽� �ɼǿ� AutoShrink �� true�� �����ϸ� �ڵ����� ��ǵȴ�. 
-- ======================================================================
DBCC SHRINKDATABASE(test, 10)
GO

-- Ư�������ͺ��̽� ���� ���̱�
USE testdb
DBCC SHRINKDATABASE(test_dat, 10)
GO

-- 2.���� �α� ���� ���
/* Ʈ������ �α� ������ ������ �ڵ� ������ ��� ���� ���Ϸ� ����ȭ �ǰ� ���ɿ� 
���� ���� ������ ��ģ��. 25�� �̻��� ��� �α� ���� ����, �α����� ������ ũ��� ����
*/
USE test
GO
DBCC LOGINFO

-- 2-1. Ʈ������ �α� ���� ��� Ȥ�� ����
BACKUP LOG test TO DISK = '<dir,nvarchar,userDir>'
GO

BACKUP LOG test WITH NO_LOG
GO

-- 2-2 Ʈ������ �α� ������ ũ�⸦ ���� ũ��� ���.
EXEC sp_helpfile
GO

DBCC SHRINKFILE(test_log, TRUNCATEONLY)
GO

--2-3 �α������� ����
ALTER DATABASE test MODIFIY FILE (
    NAME  = ,
    SIZE )
GO
