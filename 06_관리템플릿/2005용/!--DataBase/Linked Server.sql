--=============================
--	��ũ�� ���� setting
--=============================

-- 1. OLEDB ���
-- ��ũ�� ���� ��� �ʿ��� ���
EXEC sp_addlinkedserver 
    @server='�̸�', 
    @srvproduct='',
    @provider='SQLOLEDB', 
    @datasrc='IPADDRERSS'
GO

EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = '�̸�',
    @useself = 'False',
    @locallogin = null,
    @rmtuser  = '����',
    @rmtpassword = '��ȣ'
GO


EXEC sp_serveroption '�̸�', 'rpc' , 'true'
GO

EXEC sp_serveroption '�̸�', 'rpc out', 'true'
GO


--2. SQLSERVER ���
--��Ī�� ����ؾ��Ѵ�.
exec sp_addlinkedserver '�̸�', N'SQL Server'
exec sp_addlinkedsrvlogin '�̸�', 'false', null, '����', '��ȣ'
go