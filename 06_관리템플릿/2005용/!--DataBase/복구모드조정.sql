--======================
--DB ������� ����
--=====================
-- GMARKET PM �۾��� ���. 
--�۾� ��
--1. ������� ����
ALTER DATABASE TIGER SET RECOVERY BULK_LOGGED
go 
ALTER DATABASE CUSTOMER SET RECOVERY BULK_LOGGED
go 
ALTER DATABASE EVENT SET RECOVERY BULK_LOGGED
go 
ALTER DATABASE SETTLE SET RECOVERY BULK_LOGGED
go 

--Ȯ��
SELECT DATABASEPROPERTYEX('TIGER','RECOVERY')
SELECT DATABASEPROPERTYEX('CUSTOMER','RECOVERY')
SELECT DATABASEPROPERTYEX('EVENT','RECOVERY')
SELECT DATABASEPROPERTYEX('SETTLE','RECOVERY')

--3. maxdop ����
exec sp_configure 'show advanced option', 1
go 
reconfigure with override
go 

exec sp_configure 'max degree of parallelism', 8
go 
reconfigure with override
go 

-- �۾� ����


---------------------------------------------------
--�۾� ��
---------------------------------------------------
ALTER DATABASE TIGER SET RECOVERY FULL
go 
ALTER DATABASE CUSTOMER SET RECOVERY FULL
go 
ALTER DATABASE EVENT SET RECOVERY FULL
go 
ALTER DATABASE SETTLE SET RECOVERY FULL
go 

--Ȯ��
SELECT DATABASEPROPERTYEX('TIGER','RECOVERY')
SELECT DATABASEPROPERTYEX('CUSTOMER','RECOVERY')
SELECT DATABASEPROPERTYEX('EVENT','RECOVERY')
SELECT DATABASEPROPERTYEX('SETTLE','RECOVERY')


exec sp_configure 'show advanced option', 1
go 
reconfigure with override
go 

exec sp_configure 'max degree of parallelism', 2
go 
reconfigure with override
go 




------------------------------------------------------------------------------------------------------------------------------------

