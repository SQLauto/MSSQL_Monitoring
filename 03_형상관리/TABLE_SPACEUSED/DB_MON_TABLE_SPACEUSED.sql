DECLARE @pf_time1	datetime,
		@pf_time2	datetime,
		@pf_time3	datetime

		
SET @pf_time1 = CONVERT(datetime, CONVERT(char(10), GETDATE() + 10, 121), 121)
SET @pf_time2 = CONVERT(datetime, CONVERT(char(10), GETDATE() + 20, 121), 121)
SET @pf_time3 = CONVERT(datetime, CONVERT(char(10), GETDATE() + 30, 121), 121)

CREATE PARTITION FUNCTION PF_MON_TABLE_SPACEUSED (datetime)
AS RANGE RIGHT FOR VALUES (@pf_time1, @pf_time2, @pf_time3)
GO

-- 파티션 스키마 생성
CREATE PARTITION SCHEME PS_MON_TABLE_SPACEUSED
AS PARTITION PF_MON_TABLE_SPACEUSED
ALL TO ([PRIMARY])
GO


CREATE TABLE dbo.DB_MON_TABLE_SPACEUSED (
  now        datetime NOT NULL
, dbname	 sysname  NOT NULL 
, objectname sysname  NOT NULL 
, rows       bigint   NOT NULL 
, reserved   bigint   NOT NULL 
, data       bigint   NOT NULL 
, indexed    bigint   NOT NULL 
, unused     bigint   NOT NULL 
) ON PS_MON_TABLE_SPACEUSED (now)
GO

ALTER TABLE dbo.DB_MON_TABLE_SPACEUSED ADD 
	CONSTRAINT PK_DB_MON_TABLE_SPACEUSED PRIMARY KEY CLUSTERED (now, dbname, objectname) ON PS_MON_TABLE_SPACEUSED (now)
GO	

CREATE TABLE dbo.DB_MON_TABLE_SPACEUSED_TEMP (
  now        datetime NOT NULL
, dbname	 sysname  NOT NULL 
, objectname sysname  NOT NULL 
, rows       bigint   NOT NULL 
, reserved   bigint   NOT NULL 
, data       bigint   NOT NULL 
, indexed    bigint   NOT NULL 
, unused     bigint   NOT NULL 
) ON [PRIMARY]
GO

ALTER TABLE dbo.DB_MON_TABLE_SPACEUSED_TEMP ADD 
	CONSTRAINT PK_DB_MON_TABLE_SPACEUSED_TEMP PRIMARY KEY CLUSTERED (now, dbname, objectname) ON [PRIMARY]
GO	