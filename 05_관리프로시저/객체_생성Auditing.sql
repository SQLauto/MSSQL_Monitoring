/**************************************************************
	권한 생성
*************************************************************/
USE MASTER
GO
GRANT VIEW SERVER STATE TO dba_ssis

CREATE LOGIN dba_ssis WITH PASSWORD ='dba_3950'
		,CHECK_POLICY = OFF
		,CHECK_EXPIRATION = OFF		-- 암호 만료 정책 적용
		,SID = 0xF2944E5C4D6680498ABFCF74CFA36C4D
;

USE DBMON
GO

CREATE USER dba_ssis FOR LOGIN dba_ssis
EXEC SP_ADDROLEMEMBER 'DB_DATAWRITER', 'dba_ssis'
go

/**************************************************************
	권한 생성 끝
*************************************************************/


use dbmon
go

DROP PARTITION SCHEME PS__DB_MON_CREATE_OBJECTS__INS_DATE 
DROP PARTITION FUNCTION PF__DB_MON_CREATE_OBJECTS__INS_DATE
go

declare @pf_time1 datetime
declare @pf_time2 datetime
declare @pf_time3 datetime
 
set @pf_time1 = convert(datetime, convert(char(10), '2012-01-01', 121), 121)
set @pf_time2 = convert(datetime, convert(char(10), '2013-01-01', 121), 121)
set @pf_time3 = convert(datetime, convert(char(10),  '2014-01-01', 121), 121)
  
CREATE PARTITION FUNCTION PF__DB_MON_CREATE_OBJECTS__INS_DATE (datetime)  
AS RANGE RIGHT FOR VALUES (@pf_time1, @pf_time2, @pf_time3)
go
  
CREATE PARTITION SCHEME PS__DB_MON_CREATE_OBJECTS__INS_DATE  
AS PARTITION PF__DB_MON_CREATE_OBJECTS__INS_DATE ALL TO ([PRIMARY])  
go

DROP TABLE DB_MON_CREATE_OBJECTS
go

CREATE TABLE dbo.DB_MON_CREATE_OBJECTS
(
	seq_no    int  identity  not null,
    event_type    nvarchar(100),
    object_type   nvarchar(100),
    server_name   nvarchar(255),
    database_name nvarchar(255),
    schema_name   nvarchar(255),
    object_name   nvarchar(255),
    host_name     varchar(64),
    ipaddress     varchar(32),
    program_name  nvarchar(255),
    login_name    nvarchar(255),
    event_ddl     nvarchar(max),
    event_xml     xml,
	ins_date  datetime default getdate() not null
);
--GO

ALTER TABLE DB_MON_CREATE_OBJECTS ADD constraint PK__INS_DATE__ID  PRIMARY KEY CLUSTERED( INS_DATE,SEQ_NO)
 WITH ( DATA_COMPRESSION = PAGE) ON PS__DB_MON_CREATE_OBJECTS__INS_DATE (INS_DATE)

EXEC UP_DBA_HELPTABLE_PARTITION 'DB_MON_CREATE_OBJECTS'
GO

CREATE TABLE dbo.SWITCH_DB_MON_CREATE_OBJECTS
(
	seq_no    int   not null,
    event_type    nvarchar(100),
    object_type   nvarchar(100),
    server_name   nvarchar(255),
    database_name nvarchar(255),
    schema_name   nvarchar(255),
    object_name   nvarchar(255),
    host_name     varchar(64),
    ipaddress     varchar(32),
    program_name  nvarchar(255),
    login_name    nvarchar(255),
    event_ddl     nvarchar(max),
    event_xml     xml,
	ins_date  datetime default getdate() not null
);
GO


ALTER TABLE SWITCH_DB_MON_CREATE_OBJECTS ADD constraint PK__SWITCH_DB_MON_CREATE_OBJECTS  
PRIMARY KEY CLUSTERED( INS_DATE,SEQ_NO)
 WITH ( DATA_COMPRESSION = PAGE) 

USE MASTER
go

/********************************************************************************
	트리거 
*********************************************************************************/

DROP TRIGGER UP_MON_CREATE_OBJECTS ON ALL SERVER
GO

CREATE TRIGGER UP_MON_CREATE_OBJECTS
ON ALL SERVER
WITH EXECUTE AS 'DBA_SSIS'
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
 
    DECLARE 
        @ip VARCHAR(32) =
        (
            SELECT client_net_address
                FROM sys.dm_exec_connections
                WHERE session_id = @@SPID
        );

    INSERT DBMON.DBO.DB_MON_CREATE_OBJECTS
    (
		 event_type
		,object_type
		,server_name
		,database_name
		,schema_name
		,object_name
		,host_name
		,ipaddress
		,program_name
		,login_name
		,event_ddl
		,event_xml
    )
    SELECT
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]',   'NVARCHAR(100)') event_type, 
        @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]',  'NVARCHAR(100)') object_type, 
        @EventData.value('(/EVENT_INSTANCE/ServerName)[1]',  'NVARCHAR(255)') schema_name,
        @EventData.value('(/EVENT_INSTANCE/DatabaseName)[1]','NVARCHAR(255)') database_name,
        @EventData.value('(/EVENT_INSTANCE/SchemaName)[1]',  'NVARCHAR(255)') schema_name, 
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]',  'NVARCHAR(255)') object_name,
        HOST_NAME() host_name,
        @ip IPAddress,
        PROGRAM_NAME() program_name,
		@EventData.value('(/EVENT_INSTANCE/LoginName)[1]',  'NVARCHAR(255)') object_name,
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'NVARCHAR(MAX)') event_ddl,
        @EventData event_xml;
END
go



select * from DBMON.DBO.DB_MON_CREATE_OBJECTS order by seq_no desc
go

create table test ( i int)
drop table test