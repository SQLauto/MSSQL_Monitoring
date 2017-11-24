--=======================
--Linked Server 설정
--======================

--1. OLEDB
EXEC sp_addlinkedserver 
    @server='AccountDB', 
    @srvproduct='',
    @provider='SQLOLEDB', 
    @datasrc='222.231.55.124,3950'
GO

EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = 'AccountDB',
    @useself = 'False',
    @locallogin = null,
    @rmtuser  = 'dba',
    @rmtpassword = 'okb0331'
GO


EXEC sp_serveroption 'AccountDB', 'rpc' , 'true'
GO

EXEC sp_serveroption 'AccountDB', 'rpc out', 'true'
GO

--2. SQLSERVER 형식
exec sp_addlinkedserver 'COWDB1', N'SQL Server'
exec sp_addlinkedsrvlogin 'COWDB1', 'false', null, 'sa', 'boss3950'
go
