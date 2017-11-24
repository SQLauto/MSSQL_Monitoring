DECLARE @pf_time1	datetime,
		@pf_time2	datetime,
		@pf_time3	datetime,
		@pf_time4	datetime,
		@pf_time5	datetime,
		@pf_time6	datetime

		
SET @pf_time1 = CONVERT(datetime, CONVERT(char(10), GETDATE() + 30, 121), 121)
SET @pf_time2 = CONVERT(datetime, CONVERT(char(10), GETDATE() + 60, 121), 121)
SET @pf_time3 = CONVERT(datetime, CONVERT(char(10), GETDATE() + 90, 121), 121)
SET @pf_time4 = CONVERT(datetime, CONVERT(char(10), GETDATE() + 120, 121), 121)
SET @pf_time5 = CONVERT(datetime, CONVERT(char(10), GETDATE() + 150, 121), 121)
SET @pf_time6 = CONVERT(datetime, CONVERT(char(10), GETDATE() + 180, 121), 121)


CREATE PARTITION FUNCTION PF_MON_TABLE_SPACEUSED_TERM (datetime)
AS RANGE RIGHT FOR VALUES (@pf_time1, @pf_time2, @pf_time3, @pf_time4, @pf_time5, @pf_time6)
GO

-- 파티션 스키마 생성
CREATE PARTITION SCHEME PS_MON_TABLE_SPACEUSED_TERM
AS PARTITION PF_MON_TABLE_SPACEUSED_TERM
ALL TO ([PRIMARY])
GO


CREATE TABLE dbo.DB_MON_TABLE_SPACEUSED_TERM (
  now				datetime NOT NULL
, dbname			sysname  NOT NULL 
, objectname		sysname  NOT NULL 
, rows				bigint   NOT NULL 
, reserved			bigint   NOT NULL 
, row_change		bigint	 NOT NULL
, reserved_change	bigint	 NOT NULL
, row_change_day	bigint	 NOT NULL
, reserved_change_day bigint NOT NULL
, term_min			bigint	 NOT NULL
) ON PS_MON_TABLE_SPACEUSED_TERM (now)
GO

ALTER TABLE dbo.DB_MON_TABLE_SPACEUSED_TERM ADD 
	CONSTRAINT PK_DB_MON_TABLE_SPACEUSED_TERM PRIMARY KEY CLUSTERED (now, dbname, objectname) ON PS_MON_TABLE_SPACEUSED_TERM (now)
GO	

CREATE TABLE dbo.DB_MON_TABLE_SPACEUSED_TERM_TEMP (
  now				datetime NOT NULL
, dbname			sysname  NOT NULL 
, objectname		sysname  NOT NULL 
, rows				bigint   NOT NULL 
, reserved			bigint   NOT NULL 
, row_change		bigint	 NOT NULL
, reserved_change	bigint	 NOT NULL
, row_change_day	bigint	 NOT NULL
, reserved_change_day bigint NOT NULL
, term_min			bigint	 NOT NULL
) ON [PRIMARY]
GO

ALTER TABLE dbo.DB_MON_TABLE_SPACEUSED_TERM_TEMP ADD 
	CONSTRAINT PK_DB_MON_TABLE_SPACEUSED_TERM_TEMP PRIMARY KEY CLUSTERED (now, dbname, objectname) ON [PRIMARY]
GO	


/* ROLLBACK 
DROP TABLE DB_MON_TABLE_SPACEUSED_TERM_TEMP
GO

DROP TABLE DB_MON_TABLE_SPACEUSED_TERM
GO

DROP PARTITION SCHEME PS_MON_TABLE_SPACEUSED_TERM
GO

DROP PARTITION FUNCTION PF_MON_TABLE_SPACEUSED_TERM
GO
*/