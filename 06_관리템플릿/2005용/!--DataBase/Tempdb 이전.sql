--=====================================
-- tempdb �������� ��밡����
--=====================================
USE tempdb
go

EXEC sp_helpfile
go

USE master
go

--ALTER DATABASE tempdb SET SINGLE_USER WITH ROLLBACK AFTER 30

-- 1. ������ ���� �̰�
ALTER DATABASE tempdb
MODIFY FILE (
	NAME = tempdev,
	FILENAME = '���丮',
    SIZE = ,
    MAXSIZE = ,
    FILEGROWTH = 0MB
)
go

-- 2. �α� ���� �̰�
ALTER DATABASE tempdb
MODIFY FILE (
	NAME = templog,
	FILENAME = '���丮',
    SIZE = ,
    MAXSIZE = ,
    FILEGROWTH = 0MB
)
go

-- 3.sql �� ����
-- 4. Ȯ��
USE tempdb
go
EXEC sp_helpfile
go

-- 5. ���� ���� ����