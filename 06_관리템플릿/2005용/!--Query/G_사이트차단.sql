---======================================
-- �α��� ��ȣ ����, ����Ʈ ���ܽ� ���
-- =======================================
--1. 2005��
use master
GO

ALTER LOGIN goodsdaq WITH PASSWORD ='sql3951'
ALTER LOGIN dev WITH PASSWORD ='dev3951'
ALTER LOGIN backend WITH PASSWORD ='admin3951'

ALTER LOGIN goodsdaq WITH PASSWORD ='sql3950'
ALTER LOGIN dev WITH PASSWORD ='dev3950'
ALTER LOGIN backend WITH PASSWORD ='admin3950'

GO

--2.  2000��
use master
GO
--�̿��� ������ ���� ���� ����
sp_password 'sql3950', 'sql3951', 'goodsdaq'
go
sp_password 'dev3950', 'dev3951', 'dev'
go
sp_password 'admin3950', 'admin3951', 'backend'
go

--�۾� �Ϸ� �� �̿��� ���� �������� �����ֱ�
sp_password 'sql3951', 'sql3950', 'goodsdaq'
go
sp_password 'dev3951', 'dev3950', 'dev'
go
sp_password 'admin3951', 'admin3950', 'backend'
go
