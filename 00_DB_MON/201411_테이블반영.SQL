
exec sp_rename 'DB_MON_QUERY_PLAN_V2', 'DB_MON_QUERY_PLAN_V3'
exec sp_rename 'DB_MON_QUERY_PLAN_V3.PK_DB_MON_QUERY_PLAN_V3', 'PK_DB_MON_QUERY_PLAN_V3'

go


/*

alter table Db_Mon_Query_Stats_Total_V3 drop column  sql_handle
alter table switch_DB_MON_query_stats_total_v3 drop column  sql_handle
alter table DB_MON_query_stats_v3   drop column  sql_handle
alter table switch_DB_MON_query_stats_v3 drop column  sql_handle


alter table Db_Mon_Query_Stats_Total_V3 add sql_handle varbinary(64)
alter table switch_DB_MON_query_stats_total_v3 add sql_handle varbinary(64)
alter table DB_MON_query_stats_v3 add sql_handle varbinary(64)
alter table switch_DB_MON_query_stats_v3 add sql_handle varbinary(64)

*/		

ALTER TABLE DB_MON_QUERY_STATS_DAILY_V2 
	alter column  object_id int null
ALTER TABLE DB_MON_QUERY_STATS_DAILY_V2  alter column object_name varchar(255) null
go

ALTER TABLE SWITCH_DB_MON_QUERY_STATS_DAILY_V2 
	alter column  object_id int null
ALTER TABLE SWITCH_DB_MON_QUERY_STATS_DAILY_V2 
	alter column  object_name varchar(255) null
go


ALTER TABLE DB_MON_QUERY_STATS_DAILY_V2 
	ADD  writes_day bigint ,writes_cnt bigint
go


ALTER TABLE switch_DB_MON_QUERY_STATS_DAILY_V2 
	ADD  writes_day bigint ,writes_cnt bigint
go
	

ALTER TABLE DB_MON_QUERY_STATS_DAILY_V2 ALTER COLUMN OBJECT_ID INT NULL
ALTER TABLE DB_MON_QUERY_STATS_DAILY_V2 ALTER COLUMN db_id smallint NULL
ALTER TABLE SWITCH_DB_MON_QUERY_STATS_DAILY_V2 ALTER COLUMN OBJECT_ID INT NULL
ALTER TABLE SWITCH_DB_MON_QUERY_STATS_DAILY_V2 ALTER COLUMN db_id smallint NULL

ALTER TABLE DB_MON_PROCEDURE_STATS ADD plan_handle VARBINARY(64)
ALTER TABLE SWITCH_DB_MON_PROCEDURE_STATS ADD plan_handle VARBINARY(64)
go


drop table WORK_QUERY_STATS_GAP
go

DECLARE @BASE DATETIME
SET @BASE = '2014-11-01'
DECLARE @PF_TIME1 DATETIME
DECLARE @PF_TIME2 DATETIME
DECLARE @PF_TIME3 DATETIME

SET @pf_time1 = convert(datetime, convert(char(10), dateadd(DD, 10, @base), 121), 121)
SET @pf_time2 = convert(datetime, convert(char(10), dateadd(DD, 20, @base), 121), 121)
SET @pf_time3 = convert(datetime, convert(char(10), dateadd(DD, 30, @base), 121), 121)

CREATE PARTITION FUNCTION PF__DB_MON_QUERY_STATS_TOTAL_CPU_REG_DATE (datetime)  
AS RANGE RIGHT FOR VALUES (@pf_time1,@pf_time2,@pf_time3)
CREATE PARTITION SCHEME PS__DB_MON_QUERY_STATS_TOTAL_CPU_REG_DATE
AS PARTITION PF__DB_MON_QUERY_STATS_TOTAL_CPU_REG_DATE ALL TO ([PRIMARY])
go


CREATE TABLE DB_MON_QUERY_STATS_TOTAL_CPU 
(	REG_DATE DATETIME NOT NULL, 
	CPU_TOTAL BIGINT 
)
ALTER TABLE DB_MON_QUERY_STATS_TOTAL_CPU ADD CONSTRAINT PK__DB_MON_QUERY_STATS_TOTAL_CPU PRIMARY KEY CLUSTERED ( REG_DATE) ON PS__DB_MON_QUERY_STATS_TOTAL_CPU_REG_DATE (REG_DATE)


CREATE TABLE SWITCH_DB_MON_QUERY_STATS_TOTAL_CPU 
(	REG_DATE DATETIME NOT NULL, 
	CPU_TOTAL BIGINT 
)
ALTER TABLE SWITCH_DB_MON_QUERY_STATS_TOTAL_CPU ADD CONSTRAINT PK__SWITCH_DB_MON_QUERY_STATS_TOTAL_CPU PRIMARY KEY CLUSTERED ( REG_DATE) 
GO

--DROP PARTITION SCHEME PS__DB_MON_QUERY_STATS_V3_REG_DATE
--DROP PARTITION FUNCTION PF__DB_MON_QUERY_STATS_V3_REG_DATE
go

drop table  DB_MON_QUERY_STATS_V3
drop PARTITION SCHEME PS__DB_MON_QUERY_STATS_V3__REG_DATE 
drop PARTITION FUNCTION PF__DB_MON_QUERY_STATS_V3__REG_DATE
go


DECLARE @BASE DATETIME
SET @BASE = '2014-10-28'
DECLARE @PF_TIME1 DATETIME
DECLARE @PF_TIME2 DATETIME
DECLARE @PF_TIME3 DATETIME
DECLARE @PF_TIME4 DATETIME
DECLARE @PF_TIME5 DATETIME
DECLARE @PF_TIME6 DATETIME
DECLARE @PF_TIME7 DATETIME
DECLARE @PF_TIME8 DATETIME
DECLARE @PF_TIME9 DATETIME
DECLARE @PF_TIME10 DATETIME
DECLARE @PF_TIME11 DATETIME

SET @pf_time1 = convert(datetime, convert(char(10), dateadd(DD, 1, @base), 121), 121)
SET @pf_time2 = convert(datetime, convert(char(10), dateadd(DD, 2, @base), 121), 121)
SET @pf_time3 = convert(datetime, convert(char(10), dateadd(DD, 3, @base), 121), 121)
SET @pf_time4 = convert(datetime, convert(char(10), dateadd(DD, 4, @base), 121), 121)
SET @pf_time5 = convert(datetime, convert(char(10), dateadd(DD, 5, @base), 121), 121)
SET @pf_time6 = convert(datetime, convert(char(10), dateadd(DD, 6, @base), 121), 121)
SET @pf_time7 = convert(datetime, convert(char(10), dateadd(DD, 7, @base), 121), 121)
SET @pf_time8 = convert(datetime, convert(char(10), dateadd(DD, 8, @base), 121), 121)
SET @pf_time9 = convert(datetime, convert(char(10), dateadd(DD, 9, @base), 121), 121)
SET @pf_time10 = convert(datetime, convert(char(10), dateadd(DD, 10, @base), 121), 121)
SET @pf_time11 = convert(datetime, convert(char(10), dateadd(DD, 11, @base), 121), 121)

CREATE PARTITION FUNCTION PF__DB_MON_QUERY_STATS_V3__REG_DATE (datetime)  
AS RANGE RIGHT FOR VALUES (@pf_time1,@pf_time2,@pf_time3,@pf_time4,@pf_time5,@pf_time6,@pf_time7,@pf_time8,@pf_time9,@pf_time10,@pf_time11)
CREATE PARTITION SCHEME PS__DB_MON_QUERY_STATS_V3__REG_DATE
AS PARTITION PF__DB_MON_QUERY_STATS_V3__REG_DATE ALL TO ([PRIMARY])



CREATE TABLE DB_MON_QUERY_STATS_V3
( 
reg_date datetime    NOT NULL   , 
from_date datetime    NOT NULL   , 
type char(1) 		null, 
db_name varchar (32)   NULL   , 
object_name varchar (255)   NULL   , 
db_id smallint    NULL   , 
object_id int    NULL   , 
statement_start int    NOT NULL   , 
statement_end int    NOT NULL   , 
set_options int    NULL   , 
create_date datetime    NULL   , 
cnt_min bigint    NULL   , 
cpu_rate numeric (6, 2)  NULL   , 
cpu_min bigint    NULL   , 
reads_min bigint    NULL   , 
writes_min bigint    NULL   , 
duration_min bigint    NULL   , 
cpu_cnt bigint    NULL   , 
reads_cnt bigint    NULL   , 
writes_cnt bigint    NULL   , 
duration_cnt bigint    NULL   , 
term bigint    NULL   , 
sql_handle varbinary(64) null,
plan_handle varbinary(64)    NOT NULL   , 
cnt_total bigint    NULL   , 
cpu_total bigint    NULL   , 
reads_total bigint    NULL   , 
writes_total bigint    NULL  ,
duration_total bigint    NULL   , 
query_text varchar (max)   NULL    
)  ON [PS__DB_MON_QUERY_STATS_V3__REG_DATE]( REG_DATE)
GO
CREATE clustered INDEX CIDX_REG_DATE_PLAN_HANDLE ON DB_MON_QUERY_STATS_V3 ([reg_date] ASC, [plan_handle] ASC  ) with(data_compression = page)
 ON [PS__DB_MON_QUERY_STATS_V3__REG_DATE]  (REG_DATE)
GO

drop table SWITCH_DB_MON_QUERY_STATS_V3
go

CREATE TABLE SWITCH_DB_MON_QUERY_STATS_V3
( 
reg_date datetime    NOT NULL   , 
from_date datetime    NOT NULL   , 
type char(1) 		null, 
db_name varchar (32)   NULL   , 
object_name varchar (255)   NULL   , 
db_id smallint    NULL   , 
object_id int    NULL   , 
statement_start int    NOT NULL   , 
statement_end int    NOT NULL   , 
set_options int    NULL   , 
create_date datetime    NULL   , 
cnt_min bigint    NULL   , 
cpu_rate numeric (6, 2)  NULL   , 
cpu_min bigint    NULL   , 
reads_min bigint    NULL   , 
writes_min bigint    NULL   , 
duration_min bigint    NULL   , 
cpu_cnt bigint    NULL   , 
reads_cnt bigint    NULL   , 
writes_cnt bigint    NULL   , 
duration_cnt bigint    NULL   , 
term bigint    NULL   , 
sql_handle varbinary(64) null,
plan_handle varbinary(64)   NOT NULL   , 
cnt_total bigint    NULL   , 
cpu_total bigint    NULL   , 
reads_total bigint    NULL   , 
writes_total bigint    NULL  ,
duration_total bigint    NULL   , 
query_text varchar (max)   NULL    
)  
GO
CREATE clustered INDEX CIDX_REG_DATE_PLAN_HANDLE ON SWITCH_DB_MON_QUERY_STATS_V3 
([reg_date] ASC, [plan_handle] ASC  )  with(data_compression = page)
GO


drop table DB_MON_QUERY_STATS_TOTAL_V3
drop partition SCHEME PS__DB_MON_QUERY_STATS_TOTAL_V3__REG_DATE
drop partition function PF__DB_MON_QUERY_STATS_TOTAL_V3__REG_DATE
go

DECLARE @BASE DATETIME
SET @BASE = '2014-10-28'
DECLARE @PF_TIME1 DATETIME
DECLARE @PF_TIME2 DATETIME
DECLARE @PF_TIME3 DATETIME

SET @pf_time1 = convert(datetime, convert(char(10), dateadd(DD, 1, @base), 121), 121)
SET @pf_time2 = convert(datetime, convert(char(10), dateadd(DD, 2, @base), 121), 121)
SET @pf_time3 = convert(datetime, convert(char(10), dateadd(DD, 3, @base), 121), 121)

CREATE PARTITION FUNCTION PF__DB_MON_QUERY_STATS_TOTAL_V3__REG_DATE (datetime)  
AS RANGE RIGHT FOR VALUES (@pf_time1,@pf_time2,@pf_time3)
CREATE PARTITION SCHEME PS__DB_MON_QUERY_STATS_TOTAL_V3__REG_DATE
AS PARTITION PF__DB_MON_QUERY_STATS_TOTAL_V3__REG_DATE ALL TO ([PRIMARY])


CREATE TABLE DB_MON_QUERY_STATS_TOTAL_V3
( 
reg_date datetime    NOT NULL  , 
type	char(1)  null, 
plan_handle varbinary(64)    NOT NULL   , 
statement_start int    NOT NULL   , 
statement_end int    NOT NULL   , 
db_id smallint    NULL   , 
object_id int    NULL   , 
object_name varchar (255)   NULL   , 
set_options int    NULL   , 
create_date datetime    NOT NULL   , 
cnt bigint    NULL   , 
cpu bigint    NULL   , 
writes bigint    NULL   , 
reads bigint    NULL   , 
duration bigint    NULL   , 
query_text nvarchar (max)   NULL ,
sql_handle varbinary(64) null
)  ON [PS__DB_MON_QUERY_STATS_TOTAL_V3__REG_DATE] (REG_DATE)
GO
CREATE clustered INDEX CIDX_REG_DATE__PLAN_HANDLE ON DB_MON_QUERY_STATS_TOTAL_V3
 ([reg_date] ASC, [plan_handle] ASC , [statement_start] ASC , [statement_end] ASC  )  with(data_compression = page)
 ON [PS__DB_MON_QUERY_STATS_TOTAL_V3__REG_DATE]  (REG_DATE)
GO

drop table SWITCH_DB_MON_QUERY_STATS_TOTAL_V3
CREATE TABLE SWITCH_DB_MON_QUERY_STATS_TOTAL_V3
( 
reg_date datetime    NOT NULL  , 
type	char(1)  null, 
plan_handle varbinary(64)   NOT NULL   , 
statement_start int    NOT NULL   , 
statement_end int    NOT NULL   , 
db_id smallint    NULL   , 
object_id int    NULL   , 
object_name varchar (255)   NULL   , 
set_options int    NULL   , 
create_date datetime    NOT NULL   , 
cnt bigint    NULL   , 
cpu bigint    NULL   , 
writes bigint    NULL   , 
reads bigint    NULL   , 
duration bigint    NULL   , 
query_text nvarchar (max)   NULL ,
sql_handle varbinary(64) null
) 
GO
CREATE clustered INDEX CIDX_REG_DATE__PLAN_HANDLE ON SWITCH_DB_MON_QUERY_STATS_TOTAL_V3
 ([reg_date] ASC, [plan_handle] ASC , [statement_start] ASC , [statement_end] ASC  ) 
 with(data_compression = page)
GO


drop table DB_MON_PROCEDURE_STATS_TOTAL
drop PARTITION SCHEME PS__DB_MON_PROCEDURE_STATS_TOTAL__REG_DATE
drop PARTITION FUNCTION PF__DB_MON_PROCEDURE_STATS_TOTAL__REG_DATE
go
DECLARE @BASE DATETIME
SET @BASE = '2014-10-28'
DECLARE @PF_TIME1 DATETIME
DECLARE @PF_TIME2 DATETIME
DECLARE @PF_TIME3 DATETIME

SET @pf_time1 = convert(datetime, convert(char(10), dateadd(DD, 1, @base), 121), 121)
SET @pf_time2 = convert(datetime, convert(char(10), dateadd(DD, 2, @base), 121), 121)
SET @pf_time3 = convert(datetime, convert(char(10), dateadd(DD, 3, @base), 121), 121)


CREATE PARTITION FUNCTION PF__DB_MON_PROCEDURE_STATS_TOTAL__REG_DATE (datetime)  
AS RANGE RIGHT FOR VALUES (@pf_time1,@pf_time2,@pf_time3)
CREATE PARTITION SCHEME PS__DB_MON_PROCEDURE_STATS_TOTAL__REG_DATE
AS PARTITION PF__DB_MON_PROCEDURE_STATS_TOTAL__REG_DATE ALL TO ([PRIMARY])
go

DROP INDEX DB_MON_PROCEDURE_STATS_TOTAL.CIDX_DB_MON_PROCEDURE_STATS_TOTAL__reg_date
go


CREATE TABLE DB_MON_PROCEDURE_STATS_TOTAL
( 
reg_date datetime    NOT NULL   , 
db_id int    NOT NULL   , 
object_id int    NOT NULL   , 
sql_handle varbinary(64)    NULL   , 
plan_handle varbinary(64)    NULL   , 
cached_time datetime    NULL   , 
execution_count bigint    NULL   , 
worker_time bigint    NULL   , 
physical_reads bigint    NULL   , 
logical_reads bigint    NULL   , 
logical_writes bigint    NULL   , 
elapsed_time bigint    NULL  
)  ON [PS__DB_MON_PROCEDURE_STATS_TOTAL__REG_DATE] ( REG_DATE)
GO
CREATE clustered INDEX CIDX_DB_MON_PROCEDURE_STATS_TOTAL__REG_DATE ON DB_MON_PROCEDURE_STATS_TOTAL ([reg_date] ASC )  with(data_compression = page) 
ON [PS__DB_MON_PROCEDURE_STATS_TOTAL__REG_DATE] 
(REG_DATE)
GO

drop index SWITCH_DB_MON_PROCEDURE_STATS_TOTAL.CIDX_SWITCH_DB_MON_PROCEDURE_STATS_TOTAL__reg_date
go

drop table SWITCH_DB_MON_PROCEDURE_STATS_TOTAL
go
CREATE TABLE SWITCH_DB_MON_PROCEDURE_STATS_TOTAL
( 
reg_date datetime    NOT NULL   , 
db_id int    NOT NULL   , 
object_id int    NOT NULL   , 
sql_handle varbinary(64)    NULL   , 
plan_handle varbinary(64)    NULL   , 
cached_time datetime    NULL   , 
execution_count bigint    NULL   , 
worker_time bigint    NULL   , 
physical_reads bigint    NULL   , 
logical_reads bigint    NULL   , 
logical_writes bigint    NULL   , 
elapsed_time bigint    NULL  
) 
GO
CREATE clustered INDEX CIDX_SWITCH_DB_MON_PROCEDURE_STATS_TOTAL__REG_DATE 
ON SWITCH_DB_MON_PROCEDURE_STATS_TOTAL ([reg_date] ASC )  with(data_compression = page)
GO



drop table DB_MON_PROCEDURE_STATS
drop PARTITION SCHEME PS__DB_MON_PROCEDURE_STATS__REG_DATE
drop PARTITION FUNCTION PF__DB_MON_PROCEDURE_STATS__REG_DATE
go

DECLARE @BASE DATETIME
SET @BASE = '2014-10-28'
DECLARE @PF_TIME1 DATETIME
DECLARE @PF_TIME2 DATETIME
DECLARE @PF_TIME3 DATETIME
DECLARE @PF_TIME4 DATETIME
DECLARE @PF_TIME5 DATETIME
DECLARE @PF_TIME6 DATETIME
DECLARE @PF_TIME7 DATETIME
DECLARE @PF_TIME8 DATETIME
DECLARE @PF_TIME9 DATETIME
DECLARE @PF_TIME10 DATETIME
DECLARE @PF_TIME11 DATETIME

SET @pf_time1 = convert(datetime, convert(char(10), dateadd(DD, 1, @base), 121), 121)
SET @pf_time2 = convert(datetime, convert(char(10), dateadd(DD, 2, @base), 121), 121)
SET @pf_time3 = convert(datetime, convert(char(10), dateadd(DD, 3, @base), 121), 121)
SET @pf_time4 = convert(datetime, convert(char(10), dateadd(DD, 4, @base), 121), 121)
SET @pf_time5 = convert(datetime, convert(char(10), dateadd(DD, 5, @base), 121), 121)
SET @pf_time6 = convert(datetime, convert(char(10), dateadd(DD, 6, @base), 121), 121)
SET @pf_time7 = convert(datetime, convert(char(10), dateadd(DD, 7, @base), 121), 121)
SET @pf_time8 = convert(datetime, convert(char(10), dateadd(DD, 8, @base), 121), 121)
SET @pf_time9 = convert(datetime, convert(char(10), dateadd(DD, 9, @base), 121), 121)
SET @pf_time10 = convert(datetime, convert(char(10), dateadd(DD, 10, @base), 121), 121)
SET @pf_time11 = convert(datetime, convert(char(10), dateadd(DD, 11, @base), 121), 121)

CREATE PARTITION FUNCTION PF__DB_MON_PROCEDURE_STATS__REG_DATE (datetime)  
AS RANGE RIGHT FOR VALUES (@pf_time1,@pf_time2,@pf_time3,@pf_time4,@pf_time5,@pf_time6,@pf_time7,@pf_time8,@pf_time9,@pf_time10,@pf_time11)
CREATE PARTITION SCHEME PS__DB_MON_PROCEDURE_STATS__REG_DATE
AS PARTITION PF__DB_MON_PROCEDURE_STATS__REG_DATE ALL TO ([PRIMARY])
go

DROP INDEX DB_MON_PROCEDURE_STATS.CIDX_DB_MON_PROCEDURE_STATS__REG_DATE
go


CREATE TABLE DB_MON_PROCEDURE_STATS
( 
reg_date datetime    NOT NULL   , 
db_id smallint    NULL   , 
object_id int    NULL   , 
db_name sysname    NULL   , 
object_name sysname    NULL   , 
cached_time datetime    NOT NULL   , 
from_date datetime    NULL   , 
to_date datetime    NULL   , 
cnt_min bigint    NOT NULL   , 
cpu_rate float    NOT NULL   , 
cpu_min bigint    NOT NULL   , 
reads_min bigint    NOT NULL   ,
writes_min bigint		NOT NULL,  
duration_min bigint    NOT NULL   , 
cpu_cnt bigint    NOT NULL   , 
reads_cnt bigint    NOT NULL   , 
writes_cnt bigint 	not null,
duration_cnt bigint    NOT NULL   , 
sql_handle varbinary(64)    NOT NULL   , 
plan_handle varbinary(64)  NOT NULL,
term bigint    NOT NULL  
)  ON [PS__DB_MON_PROCEDURE_STATS__REG_DATE] (REG_DATE)
GO
CREATE clustered INDEX CIDX_DB_MON_PROCEDURE_STATS__reg_date ON DB_MON_PROCEDURE_STATS ([reg_date] ASC ) ON [PS__DB_MON_PROCEDURE_STATS__REG_DATE]  (REG_DATE)
GO


drop table SWITCH_DB_MON_PROCEDURE_STATS
go
CREATE TABLE SWITCH_DB_MON_PROCEDURE_STATS
( 
reg_date datetime    NOT NULL   , 
db_id smallint    NULL   , 
object_id int    NULL   , 
db_name sysname    NULL   , 
object_name sysname    NULL   , 
cached_time datetime    NOT NULL   , 
from_date datetime    NULL   , 
to_date datetime    NULL   , 
cnt_min bigint    NOT NULL   , 
cpu_rate float    NOT NULL   , 
cpu_min bigint    NOT NULL   , 
reads_min bigint    NOT NULL   , 
writes_min bigint		NOT NULL, 
duration_min bigint    NOT NULL   , 
cpu_cnt bigint    NOT NULL   , 
reads_cnt bigint    NOT NULL   , 
writes_cnt bigint 	not null,
duration_cnt bigint    NOT NULL   , 
sql_handle varbinary(64)    NOT NULL   , 
plan_handle varbinary(64)  NOT NULL,
term bigint    NOT NULL  
) 
GO
CREATE clustered INDEX CIDX_DB_MON_PROCEDURE_STATS__reg_date ON SWITCH_DB_MON_PROCEDURE_STATS ([reg_date] ASC )
GO

/*
alter table DB_MON_PROCEDURE_STATS add writes_min bigint, writes_cnt bigint
alter table switch_DB_MON_PROCEDURE_STATS add writes_min bigint, writes_cnt bigint
go
        
alter table DB_MON_PROCEDURE_STATS_HOUR add writes_min bigint, writes_cnt bigint
alter table switch_DB_MON_PROCEDURE_STATS_HOUR add writes_min bigint, writes_cnt bigint
go
*/
drop table DB_MON_PROCEDURE_STATS_HOUR
drop  PARTITION SCHEME PS__DB_MON_PROCEDURE_STATS_HOUR__REG_DATE
drop PARTITION FUNCTION PF__DB_MON_PROCEDURE_STATS_HOUR__REG_DATE 
go

DECLARE @BASE DATETIME
SET @BASE = '2014-10-28'
DECLARE @PF_TIME1 DATETIME
DECLARE @PF_TIME2 DATETIME
DECLARE @PF_TIME3 DATETIME
DECLARE @PF_TIME4 DATETIME
DECLARE @PF_TIME5 DATETIME
DECLARE @PF_TIME6 DATETIME
DECLARE @PF_TIME7 DATETIME
DECLARE @PF_TIME8 DATETIME
DECLARE @PF_TIME9 DATETIME
DECLARE @PF_TIME10 DATETIME
DECLARE @PF_TIME11 DATETIME

SET @pf_time1 = convert(datetime, convert(char(10), dateadd(DD, 1, @base), 121), 121)
SET @pf_time2 = convert(datetime, convert(char(10), dateadd(DD, 2, @base), 121), 121)
SET @pf_time3 = convert(datetime, convert(char(10), dateadd(DD, 3, @base), 121), 121)
SET @pf_time4 = convert(datetime, convert(char(10), dateadd(DD, 4, @base), 121), 121)
SET @pf_time5 = convert(datetime, convert(char(10), dateadd(DD, 5, @base), 121), 121)
SET @pf_time6 = convert(datetime, convert(char(10), dateadd(DD, 6, @base), 121), 121)
SET @pf_time7 = convert(datetime, convert(char(10), dateadd(DD, 7, @base), 121), 121)
SET @pf_time8 = convert(datetime, convert(char(10), dateadd(DD, 8, @base), 121), 121)
SET @pf_time9 = convert(datetime, convert(char(10), dateadd(DD, 9, @base), 121), 121)
SET @pf_time10 = convert(datetime, convert(char(10), dateadd(DD, 10, @base), 121), 121)
SET @pf_time11 = convert(datetime, convert(char(10), dateadd(DD, 11, @base), 121), 121)

CREATE PARTITION FUNCTION PF__DB_MON_PROCEDURE_STATS_HOUR__REG_DATE (datetime)  
AS RANGE RIGHT FOR VALUES (@pf_time1,@pf_time2,@pf_time3,@pf_time4,@pf_time5,@pf_time6,@pf_time7,@pf_time8,@pf_time9,@pf_time10,@pf_time11)
CREATE PARTITION SCHEME PS__DB_MON_PROCEDURE_STATS_HOUR__REG_DATE
AS PARTITION PF__DB_MON_PROCEDURE_STATS_HOUR__REG_DATE ALL TO ([PRIMARY])
go



CREATE TABLE DB_MON_PROCEDURE_STATS_HOUR
( 
reg_date datetime    NOT NULL   , 
db_id smallint    NULL   , 
object_id int    NULL   , 
db_name sysname    NULL   , 
object_name sysname    NULL   , 
cached_time datetime    NOT NULL   , 
from_date datetime    NULL   , 
to_date datetime    NULL   , 
cnt_min bigint    NOT NULL   , 
cpu_rate float    NOT NULL   , 
cpu_min bigint    NOT NULL   , 
reads_min bigint    NOT NULL ,  
writes_min bigint    NULL   , 
duration_min bigint    NOT NULL   , 
cpu_cnt bigint    NOT NULL   , 
reads_cnt bigint    NOT NULL   , 
writes_cnt bigint    NULL  ,
duration_cnt bigint    NOT NULL   , 
sql_handle varbinary(64)    NOT NULL   , 
term bigint    NOT NULL   , 
)  ON [PS__DB_MON_PROCEDURE_STATS_HOUR__REG_DATE] ( reg_date)
GO
CREATE clustered INDEX CIDX_DB_MON_PROCEDURE_STATS_HOUR__reg_date ON DB_MON_PROCEDURE_STATS_HOUR ([reg_date] ASC ) ON [PS__DB_MON_PROCEDURE_STATS_HOUR__REG_DATE] 
 ( reg_date)
GO


drop table SWITCH_DB_MON_PROCEDURE_STATS_HOUR
go

CREATE TABLE SWITCH_DB_MON_PROCEDURE_STATS_HOUR
( 
reg_date datetime    NOT NULL   , 
db_id smallint    NULL   , 
object_id int    NULL   , 
db_name sysname    NULL   , 
object_name sysname    NULL   , 
cached_time datetime    NOT NULL   , 
from_date datetime    NULL   , 
to_date datetime    NULL   , 
cnt_min bigint    NOT NULL   , 
cpu_rate float    NOT NULL   , 
cpu_min bigint    NOT NULL   , 
reads_min bigint    NOT NULL ,  
writes_min bigint    NULL   , 
duration_min bigint    NOT NULL   , 
cpu_cnt bigint    NOT NULL   , 
reads_cnt bigint    NOT NULL   , 
writes_cnt bigint    NULL  ,
duration_cnt bigint    NOT NULL   , 
sql_handle varbinary(64)    NOT NULL   , 
term bigint    NOT NULL   , 
)  
GO
CREATE clustered INDEX CIDX_DB_MON_PROCEDURE_STATS_HOUR__reg_date ON SWITCH_DB_MON_PROCEDURE_STATS_HOUR ([reg_date] ASC ) 
GO






INSERT INTO Db_Mon_Query_Stats_V3
(reg_date
,from_date
,db_name
,object_name
,db_id
,object_id
,statement_start
,statement_end
,set_options
,create_date
,cnt_min
,cpu_rate
,cpu_min
,reads_min
,duration_min
,cpu_cnt
,reads_cnt
,duration_cnt
,term
,plan_handle
,cnt_total
,cpu_total
,reads_total
,duration_total
)
SELECT 
reg_date
,from_date
,db_name
,object_name
,db_id
,object_id
,statement_start
,statement_end
,set_options
,create_date
,cnt_min
,cpu_rate
,cpu_min
,reads_min
,duration_min
,cpu_cnt
,reads_cnt
,duration_cnt
,term
,plan_handle
,cnt_total
,cpu_total
,reads_total
,duration_total
FROM DB_MON_QUERY_STATS_V2
go





INSERT INTO DB_MON_QUERY_STATS_TOTAL_V3
(reg_date
,plan_handle
,statement_start
,statement_end
,db_id
,object_id
,set_options
,create_date
,cnt
,cpu
,writes
,reads
,duration
)

SELECT 
reg_date
,plan_handle
,statement_start
,statement_end
,db_id
,object_id
,set_options
,create_date
,cnt
,cpu
,writes
,reads
,duration
FROM DB_MON_QUERY_STATS_TOTAL_V2
go
