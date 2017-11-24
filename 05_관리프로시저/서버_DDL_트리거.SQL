
USE DBMON
GO

ALTER TABLE DB_MON_CREATE_OBJECTS ADD session_id int null,  duration int null;

/*
CREATE TABLE DB_MON_CREATE_OBJECTS
( 
seq_no int   IDENTITY (1 , 1)  NOT NULL   , 
event_type nvarchar (100)   NULL   , 
object_type nvarchar (100)   NULL   , 
session_id  INT NULL, 
server_name nvarchar (255)   NULL   , 
database_name nvarchar (255)   NULL   , 
schema_name nvarchar (255)   NULL   , 
object_name nvarchar (255)   NULL   , 
host_name varchar (64)   NULL   , 
ipaddress varchar (32)   NULL   , 
program_name nvarchar (255)   NULL   , 
login_name nvarchar (255)   NULL   , 
event_ddl nvarchar (max)   NULL   , 
event_xml xml    NULL   , 
ins_date datetime    NOT NULL  CONSTRAINT DF__DB_MON_CREATE_OBJECTS__INS_DATE DEFAULT (getdate()) ,
duration int null, 
)  ON [PRIMARY]
GO
ALTER TABLE DB_MON_CREATE_OBJECTS ADD CONSTRAINT PK__INS_DATE__ID primary key clustered ([ins_date] ASC, [seq_no] ASC  ) ON [PRIMARY] 
GO
*/

USE [master]
GO
/****** Object:  DdlTrigger [UP_MON_CREATE_OBJECTS]    Script Date: 2017-06-29 오전 8:30:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER TRIGGER [UP_MON_CREATE_OBJECTS]
ON ALL SERVER
WITH EXECUTE AS 'dba_ssis'
FOR DDL_FUNCTION_EVENTS
	,DDL_PROCEDURE_EVENTS
	,DDL_SYNONYM_EVENTS
	,DDL_TABLE_EVENTS
	,DDL_VIEW_EVENTS
	,DDL_TRIGGER_EVENTS
	,RENAME 

AS
BEGIN
    SET NOCOUNT ON;
    DECLARE
        @EventData XML = EVENTDATA();
 
    DECLARE @ip VARCHAR(32) 
	DECLARE @session_id int
	DECLARE @duration int
	DECLARE @ins_date datetime 

        
    SELECT @ip = client_net_address FROM sys.dm_exec_connections  WHERE session_id = @@SPID
	SELECT @ins_date = start_time FROM sys.dm_exec_requests WHERE session_id =  @@SPID


    INSERT DBMON.DBO.DB_MON_CREATE_OBJECTS
    (
		 event_type
		,object_type
		,server_name
		,session_id 
		,database_name
		,schema_name
		,object_name
		,host_name
		,ipaddress
		,program_name
		,login_name
		,event_ddl
		,event_xml
		,ins_date
		,duration
    )
    SELECT
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]',   'NVARCHAR(100)') event_type, 
        @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]',  'NVARCHAR(100)') object_type,
        @EventData.value('(/EVENT_INSTANCE/ServerName)[1]',  'NVARCHAR(255)') server_name,
		@@SPID,
        @EventData.value('(/EVENT_INSTANCE/DatabaseName)[1]','NVARCHAR(255)') database_name,
        @EventData.value('(/EVENT_INSTANCE/SchemaName)[1]',  'NVARCHAR(255)') schema_name, 
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]',  'NVARCHAR(255)') object_name,
        HOST_NAME() host_name,
        @ip IPAddress,
        PROGRAM_NAME() program_name,
		@EventData.value('(/EVENT_INSTANCE/LoginName)[1]',  'NVARCHAR(255)') object_name,
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'NVARCHAR(MAX)') event_ddl,
        @EventData event_xml, 
		@ins_date, 
		datediff(ss, @ins_date, getdate())
END



GO

ENABLE TRIGGER [UP_MON_CREATE_OBJECTS] ON ALL SERVER
GO


-- 테스트

USE DBMON 
GO
CREATE TABLE BBBB  (I INT) ; 
DROP TABLE BBB ; 

SELECT * FROM DBMON.DBO.DB_MON_CREATE_OBJECTS
