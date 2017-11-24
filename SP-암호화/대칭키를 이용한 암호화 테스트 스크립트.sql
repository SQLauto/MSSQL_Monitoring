--��ȣȭ �׽�Ʈ�� DB����
CREATE DATABASE ENCRYPTDB
ON
(
	name = 'ENCRYPTDB_Data'
,	filename = 'D:\MSSQL\DATA\ENCRYPTDB_Data.mdf'
,	size = 3MB
,	filegrowth = 1MB
)
log on 
(
	name = 'ENCRYPTDB_Log'
,	filename = 'D:\MSSQL\LOG\ENCRYPTDB_log.ldf'
,	size = 1MB
, 	filegrowth = 1MB
)
go 

use ENCRYPTDB
go 


create table dbo.dataSecure
(
    seq_no             int             not null identity(1,1)
,   data_secure        varchar(100)    null
,   data_encryption    varchar(100)    null
) 
go 

--����Ű ���� 
--����Ű ������ ���Ǵ� ������Ű�� SQL ��ġ�� master db�� ������ ����Ű�� �̿��� ��ȣȭ ��
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'dkfausdkseho~'
--MASTER KEY�� �������� �ʴ´�. MASTER KEY �� DROP�� ��� ������ MASTER KEY�� �̿��� ��ȣȭ �� �����ʹ� ���ǵǰ� �ȴ�

--Ȯ��
SELECT *
  FROM sys.symmetric_keys with (nolock)

/*
�����ͺ��̽� ������ Ű�� ������ �̸� ����Ͽ� ��ȣȭ �䱸�� ���� �� ���� ������ Ű�� ���� �� �ֽ��ϴ�. 

1. ���Ī Ű�� ���� Ű �� ���� Ű ���� ����� ���� Ű ��ȣȭ�� ���
2. ��Ī Ű�� ������ Ű�� ��ȣȭ �� ��ȣȭ �ص��� ��� ����ϴ� ���� ��ȣ�� ���
3. �������� �ٺ������� ���� Ű�� ���� �����Դϴ�.

������� 1)���Ī Ű�� ��ȣȭ/��ȣ �ص��� �����ϸ� ��Ī Ű�� ��ȣȭ/��ȣ �ص��� �����ϴ� �ͺ��� ����� �ξ� ���� ��ϴ�. 
           ���̺��� ����� �����Ϳ� ���� ū ������ �������� �۾��� ��쿡�� ���Ī Ű�� ������� �ʴ� ���� �����ϴ�.
         2)���Ī Ű�� ��Ī Ű �� �����͸� ��ȣȭ�� �� ������ ��Ī Ű�� �ٸ� ��Ī Ű �� �����͸� ��ȣȭ�� �� �ֽ��ϴ�
         3)�������� ��Ī Ű �� �����͸� ��ȣȭ�� �� �ֽ��ϴ�.
         4)���Ī Ű�� ����Ͽ� �����ϴ� �Ϲ����� ������ ��ȣȭ�� ���� ���� Ű ��ȣȭ��� �մϴ�
         5)���Ī Ű�� 512, 1,024 �Ǵ� 2,048��Ʈ Ű ũ���� RSA �˰����� ����մϴ�(��Ʈ���� Ŀ������ �߰��� ��ȣȭ�� �����)
*/

--������ �̿��� MASTER KEY ���
BACKUP SERVICE MASTER KEY TO FILE = 'C:\keys\service_master_key'
ENCRYPTION BY PASSWORD = 'qlalfqjsgh!'

--������ �̿��� MASTER KEY ����
--RESTORE SERVICE MASTER KEY FROM FILE = 'C:\keys\service_master_key'
--DECRYPTION BY PASSWORD = 'qlalfqjsgh' FORCE

--������Ű�κ���  ���Ī Ű ����� 
CREATE ASYMMETRIC KEY EncAsyncKeyForPwd 
 WITH ALGORITHM = RSA_1024
go 

--Ȯ��
SELECT *
  FROM sys.asymmetric_keys with (nolock)


--������ ��ȣȭ�� ���Ǵ� ��Ī Ű ����� 
CREATE SYMMETRIC KEY EncSymKeyPwd 
 WITH ALGORITHM = DES 
 ENCRYPTION BY ASYMMETRIC KEY EncAsyncKeyForPwd
go 

--Ȯ��
SELECT *
  FROM sys.symmetric_keys with (nolock)

--��Ī Ű ���� 
OPEN SYMMETRIC KEY EncSymKeyPwd DECRYPTION BY ASYMMETRIC KEY EncAsyncKeyForPwd 



--��Ī Ű�� GUID �� ���� �����͸� �Է� 
declare @guid uniqueidentifier
set @guid = (select key_guid from sys.symmetric_keys where name = 'EncSymKeyPwd') 


insert into dbo.dataSecure (data_secure, data_encryption) values ('GMAKRET DB�� ��ְ� �־��.', encryptbykey(@guid, 'GMAKRET DB�� ��ְ� �־��.')) 
go 


--��ȣȭ�� ������ ���� 
SELECT seq_no, data_secure, data_encryption 
  FROM dbo.dataSecure with (nolock)


--��ȣȭ �׽�Ʈ 
SELECT seq_no, data_secure, cast(decryptbykey(data_encryption) as varchar(100)) 
  FROM dbo.dataSecure WITH (NOLOCK)



--�׽�Ʈ KEY ��ü ���� 
DROP SYMMETRIC KEY EncSymKeyPwd
DROP ASYMMETRIC KEY EncAsyncKeyForPwd 
go 


