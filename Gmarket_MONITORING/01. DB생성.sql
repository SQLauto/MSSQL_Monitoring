create database MONITORING
on
(
	name = 'Monitor_Data'
,	filename = 'E:\MSSQL\DATA\Monitor.mdf'
,	size = 5GB
,	filegrowth = 100MB
),
FILEGROUP Customer_Index_FG1
(
	name = 'Monitor_Index1'
,	filename = 'F:\MSSQL\DATA\Monitor_Index_FG1.ndf'
,	size = 1GB
,	filegrowth = 100MB
)
log on 
(
	name = 'Monitor_Log'
,	filename = 'F:\MSSQL\LOG\Monitor_log.ldf'
,	size = 1GB
, 	filegrowth = 100MB
)

ALTER DATABASE MONITORING ADD FILEGROUP Monitor_Data_FG1
GO
ALTER DATABASE MONITORING ADD FILE (NAME ='Monitor_Data1', FILENAME='F:\MSSQL\DATA\Monitor_Data1.ndf' , SIZE=5GB , FILEGROWTH=100MB) TO FILEGROUP Monitor_Data_FG1
GO
ALTER DATABASE MONITORING MODIFY FILEGROUP Monitor_Data_FG1 DEFAULT
GO
