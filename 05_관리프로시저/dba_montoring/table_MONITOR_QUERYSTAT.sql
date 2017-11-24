--drop table MONITOR_QUERYSTAT
--drop table MONITOR_QUERYSTAT_TERM
--
--drop table MONITOR_QUERYSTAT_SWITCH
--drop table MONITOR_QUERYSTAT_TERM_SWITCH

--drop partition function pf__monitor_querystat__reg_dt
--drop partition SCHEME ps__monitor_querystat__reg_dt
--
--drop partition SCHEME PS__MONITOR_QUERYSTAT_TERM_REG_DT
--drop partition function PF__MONITOR_QUERYSTAT_TERM_REG_DT

CREATE PARTITION FUNCTION PF__MONITOR_QUERYSTAT__REG_DT(DATETIME)
AS RANGE RIGHT
FOR VALUES (
    '2010-02-25 00:00',
    '2010-02-26 00:00',
    '2010-02-27 00:00',
    '2010-02-28 00:00',
    '2010-03-01 00:00',
    '2010-03-02 00:00',
    '2010-03-03 00:00',
    '2010-03-04 00:00',
    '2010-03-05 00:00',
    '2010-03-06 00:00',
    '2010-03-07 00:00'
)
GO


--1-2 파티션 스키마 생성
CREATE PARTITION SCHEME  PS__MONITOR_QUERYSTAT__REG_DT
AS PARTITION PF__MONITOR_QUERYSTAT__REG_DT
TO
(
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY]

)
GO


CREATE PARTITION FUNCTION PF__MONITOR_QUERYSTAT_TERM__REG_DT(DATETIME)
AS RANGE RIGHT
FOR VALUES (
    '2010-02-25 00:00',
    '2010-02-26 00:00',
    '2010-02-27 00:00',
    '2010-02-28 00:00',
    '2010-03-01 00:00',
    '2010-03-02 00:00',
    '2010-03-03 00:00',
    '2010-03-04 00:00',
    '2010-03-05 00:00',
    '2010-03-06 00:00',
    '2010-03-07 00:00'
)
GO


--1-2 파티션 스키마 생성
CREATE PARTITION SCHEME  PS__MONITOR_QUERYSTAT_TERM__REG_DT
AS PARTITION PF__MONITOR_QUERYSTAT_TERM__REG_DT
TO
(
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY],
    [PRIMARY]

)
GO


/****** 개체:  Table [dbo].[MONITOR_QUERYSTAT]    스크립트 날짜: 02/26/2010 20:00:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[MONITOR_QUERYSTAT](
    seq_no                  int identity(1,1) not null
	,reg_dt                 datetime not null 
    ,dbid                   smallint  null
    ,objectid               int    null   
    ,dbname                 nvarchar(100)  null 
    ,objectname             sysname  null
    ,create_date            datetime 
    ,distinct_cnt           bigint      
    ,cnt                    bigint      
    ,execution_count        bigint   
    ,total_worker_time      bigint   
    ,total_physical_reads   bigint   
    ,total_logical_writes   bigint   
    ,total_logical_reads    bigint   
    ,total_clr_time         bigint   
    ,total_elapsed_time     bigint   
    ,sql_handle             varbinary(64)
 CONSTRAINT [PK__MONITOR_SYSPROCESS__RET_DT_SEQ_NO] PRIMARY KEY NONCLUSTERED 
(   
	[reg_dt], seq_no
) ON  PS__MONITOR_QUERYSTAT__REG_DT(REG_DT) 
) ON PS__MONITOR_QUERYSTAT__REG_DT(REG_DT) 
    
GO  
SET ANSI_PADDING OFF
GO  
    
CREATE CLUSTERED INDEX  CIDX__MONITOR_QUERYSTAT__REG_DT ON MONITOR_QUERYSTAT
    ( reg_dt, objectname, dbname) ON PS__MONITOR_QUERYSTAT__REG_DT(REG_DT)
GO



CREATE TABLE dbo.MONITOR_QUERYSTAT_TERM (
     seq_no     int identity(1,1) not null
    , reg_dt	    datetime not null
    ,dbname	    nvarchar(100) null
    ,objectname	sysname null
    ,from_date	datetime
    ,to_date	datetime
    ,create_date	datetime
    ,cnt_min	int
    ,worker_time_min	bigint
    ,logical_reads_min	bigint
    ,elapsed_time_min	bigint
    ,worker_time_cnt	bigint
    ,logical_reads_cnt	bigint
    ,elapsed_time_cnt	bigint
    ,term	int
    , 
CONSTRAINT [PK__MONITOR_QUERYSTAT_TERM__REG_DT__SEQ_NO] PRIMARY KEY NONCLUSTERED 
(   
	[reg_dt], [seq_no]
) ON  PS__MONITOR_QUERYSTAT_TERM__REG_DT(REG_DT) 
) ON PS__MONITOR_QUERYSTAT_TERM__REG_DT(REG_DT)
GO

CREATE CLUSTERED INDEX  CIDX__MONITOR_QUERYSTAT_TERM__REG_DT ON MONITOR_QUERYSTAT_TERM
    ( reg_dt, objectname, dbname) ON PS__MONITOR_QUERYSTAT_TERM__REG_DT(REG_DT)
GO


/****** 개체:  Table [dbo].[MONITOR_SYSPROCESS_SWITCH]    스크립트 날짜: 02/26/2010 20:00:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[MONITOR_QUERYSTAT_SWITCH](
     seq_no     int identity(1,1) not null
	, reg_dt                 datetime  not null
    ,dbid                   smallint  null
    ,objectid               int      null
    ,dbname                 nvarchar(100) null 
    ,objectname             sysname  null  
    ,create_date            datetime 
    ,distinct_cnt           bigint      
    ,cnt                    bigint      
    ,execution_count        bigint   
    ,total_worker_time      bigint   
    ,total_physical_reads   bigint   
    ,total_logical_writes   bigint   
    ,total_logical_reads    bigint   
    ,total_clr_time         bigint   
    ,total_elapsed_time     bigint   
    ,sql_handle             varbinary(64)
 CONSTRAINT [PK__MONITOR_QUERYSTAT_SWITCH__REG_DT__SEQ_NO] PRIMARY KEY NONCLUSTERED 
(
	[reg_dt], seq_no
) ON [PRIMARY]
) ON [PRIMARY] 

GO

CREATE CLUSTERED INDEX  CIDX__MONITOR_QUERYSTAT_SWITCH__REG_DT ON MONITOR_QUERYSTAT_SWITCH
    ( reg_dt, objectname, dbname) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO


CREATE TABLE dbo.MONITOR_QUERYSTAT_TERM_SWITCH (
     seq_no     int identity(1,1) not null
     ,reg_dt	    datetime  not null
    ,dbname	    nvarchar(100) null
    ,objectname	sysname null
    ,from_date	datetime
    ,to_date	datetime
    ,create_date	datetime
    ,cnt_min	int
    ,worker_time_min	bigint
    ,logical_reads_min	bigint
    ,elapsed_time_min	bigint
    ,worker_time_cnt	bigint
    ,logical_reads_cnt	bigint
    ,elapsed_time_cnt	bigint
    ,term	int
    , 
CONSTRAINT [PK__MONITOR_QUERYSTAT_TERM_SWITCH__REG_DT__SEQ_NO] PRIMARY KEY NONCLUSTERED 
(   
	[reg_dt], seq_no
) ON  [PRIMARY]
) ON [PRIMARY]
GO

CREATE CLUSTERED INDEX  CIDX__MONITOR_QUERYSTAT_TERM_SWITCH__REG_DT ON MONITOR_QUERYSTAT_TERM_SWITCH
    ( reg_dt, objectname, dbname) ON [PRIMARY]
GO


SET ANSI_PADDING OFF
GO  