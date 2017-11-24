--암호화 테스트용 DB생성
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

--공개키 생성 
--공개키 생성시 사용되는 마스터키는 SQL 설치시 master db에 생성된 공개키를 이용해 암호화 됨
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'dkfausdkseho~'
--MASTER KEY는 수정되지 않는다. MASTER KEY 를 DROP할 경우 기존에 MASTER KEY를 이용해 암호화 된 데이터는 유실되게 된다

--확인
SELECT *
  FROM sys.symmetric_keys with (nolock)

/*
데이터베이스 마스터 키가 있으면 이를 사용하여 암호화 요구에 따라 세 가지 유형의 키를 만들 수 있습니다. 

1. 비대칭 키는 공개 키 및 개인 키 쌍을 사용한 공개 키 암호화에 사용
2. 대칭 키는 동일한 키를 암호화 및 암호화 해독에 모두 사용하는 공유 암호에 사용
3. 인증서는 근본적으로 공개 키를 위한 래퍼입니다.

참고사항 1)비대칭 키로 암호화/암호 해독을 수행하면 대칭 키로 암호화/암호 해독을 수행하는 것보다 비용이 훨씬 많이 듭니다. 
           테이블의 사용자 데이터와 같이 큰 데이터 집합으로 작업할 경우에는 비대칭 키를 사용하지 않는 것이 좋습니다.
         2)비대칭 키는 대칭 키 및 데이터를 암호화할 수 있으며 대칭 키는 다른 대칭 키 및 데이터를 암호화할 수 있습니다
         3)인증서는 대칭 키 및 데이터를 암호화할 수 있습니다.
         4)비대칭 키를 사용하여 수행하는 일반적인 유형의 암호화를 종종 공개 키 암호화라고 합니다
         5)비대칭 키는 512, 1,024 또는 2,048비트 키 크기의 RSA 알고리즘을 사용합니다(비트수가 커질수록 견고한 암호화가 적용됨)
*/

--파일을 이용한 MASTER KEY 백업
BACKUP SERVICE MASTER KEY TO FILE = 'C:\keys\service_master_key'
ENCRYPTION BY PASSWORD = 'qlalfqjsgh!'

--파일을 이용한 MASTER KEY 복원
--RESTORE SERVICE MASTER KEY FROM FILE = 'C:\keys\service_master_key'
--DECRYPTION BY PASSWORD = 'qlalfqjsgh' FORCE

--마스터키로부터  비대칭 키 만들기 
CREATE ASYMMETRIC KEY EncAsyncKeyForPwd 
 WITH ALGORITHM = RSA_1024
go 

--확인
SELECT *
  FROM sys.asymmetric_keys with (nolock)


--데이터 암호화에 사용되는 대칭 키 만들기 
CREATE SYMMETRIC KEY EncSymKeyPwd 
 WITH ALGORITHM = DES 
 ENCRYPTION BY ASYMMETRIC KEY EncAsyncKeyForPwd
go 

--확인
SELECT *
  FROM sys.symmetric_keys with (nolock)

--대칭 키 열기 
OPEN SYMMETRIC KEY EncSymKeyPwd DECRYPTION BY ASYMMETRIC KEY EncAsyncKeyForPwd 



--대칭 키의 GUID 를 열고 데이터를 입력 
declare @guid uniqueidentifier
set @guid = (select key_guid from sys.symmetric_keys where name = 'EncSymKeyPwd') 


insert into dbo.dataSecure (data_secure, data_encryption) values ('GMAKRET DB는 장애가 있어요.', encryptbykey(@guid, 'GMAKRET DB는 장애가 있어요.')) 
go 


--암호화된 데이터 보기 
SELECT seq_no, data_secure, data_encryption 
  FROM dbo.dataSecure with (nolock)


--복호화 테스트 
SELECT seq_no, data_secure, cast(decryptbykey(data_encryption) as varchar(100)) 
  FROM dbo.dataSecure WITH (NOLOCK)



--테스트 KEY 개체 삭제 
DROP SYMMETRIC KEY EncSymKeyPwd
DROP ASYMMETRIC KEY EncAsyncKeyForPwd 
go 


