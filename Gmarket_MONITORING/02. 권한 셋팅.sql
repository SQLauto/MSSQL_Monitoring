USE MONITORING
GO
sp_grantdbaccess 'dev'
go
sp_addrolemember 'db_datareader', 'dev'
go
sp_addrolemember 'db_ddladmin', 'dev'
go
sp_addrolemember 'db_securityadmin' ,'dev'
go
sp_grantdbaccess 'backend'
go
sp_addrolemember 'db_datareader', 'backend'
go
sp_addrolemember 'db_datawriter', 'backend'
go
sp_grantdbaccess 'goodsdaq'
go
sp_addrolemember 'db_datareader', 'goodsdaq'
go
sp_addrolemember 'db_datareader', 'goodsdaq'
go
sp_addrolemember 'db_datawriter', 'goodsdaq'
go