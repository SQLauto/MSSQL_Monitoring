

CREATE PARTITION FUNCTION PF__MONITOR_SYSPROCESS_REG_DT(DATETIME)
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
CREATE PARTITION SCHEME  PS__MONITOR_SYSPROCESS_REG_DT
AS PARTITION PF__MONITOR_SYSPROCESS_REG_DT
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



/****** 개체:  Table [dbo].[MONITOR_SYSPROCESS]    스크립트 날짜: 02/26/2010 20:00:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[MONITOR_SYSPROCESS](
	[reg_dt]    [datetime] NOT NULL,
	[sid]       [smallint] NOT NULL,
	[blocked] [smallint] NULL,
	[status]        [nvarchar](60) NULL,
	[cpu]           [int] NULL,
	[duration]      int null,
    [dbname]       [sysname] NULL,
	[objectname]   [sysname] NULL,
	[query_text] [text] NULL,
	[last_wait_type] [nvarchar](64) NULL,
	[login_name] [nvarchar](128) NULL,
	[host_name] [nvarchar](128) NULL,
	[program_name] [sysname] NULL,
	[dbid] [int] NULL,
	[objectid] [int] NULL,
	[total_elapsed_time] [int] NULL,
	[wait_type] [nvarchar](60) NULL,
	[reads] [bigint] NULL,
	[writes] [bigint] NULL,
	[logical_reads] [bigint] NULL,
	[scheduler_id] [int] NULL,
	[tx_level] [varchar](15) NULL,
	[wait_resource] [nvarchar](512) NULL,
	[open_tran_cnt] [int] NULL,
	[row_count] [bigint] NULL,	
	[plan_handle] [varbinary](64) NULL,
	[query_plan] xml,
 CONSTRAINT [PK__MONITOR_SYSPROCESS__RET_DT__SID] PRIMARY KEY CLUSTERED 
(
	[reg_dt], [sid]
) ON  PS__MONITOR_SYSPROCESS_REG_DT(REG_DT) 
) ON PS__MONITOR_SYSPROCESS_REG_DT(REG_DT) 

GO
SET ANSI_PADDING OFF
GO

--/****** 개체:  Index [CIDX__MONITOR_SYSPROCESS__REG_DT_CPU_BY_REQUESTS]    스크립트 날짜: 02/26/2010 20:00:42 ******/
--CREATE CLUSTERED INDEX [CIDX__MONITOR_SYSPROCESS__REG_DT_CPU_BY_REQUESTS] ON [dbo].[MONITOR_SYSPROCESS] 
--(
--	[reg_dt] ASC,
--	[cpu_by_requests] DESC
--)ON PS__MONITOR_SYSPROCESS_REG_DT(REG_DT)



/****** 개체:  Table [dbo].[MONITOR_SYSPROCESS_SWITCH]    스크립트 날짜: 02/26/2010 20:00:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[MONITOR_SYSPROCESS_SWITCH](
	[reg_dt] [datetime] NOT NULL,
	[sid] [smallint] NOT NULL,
	[blocked] [smallint] NULL,
	[status] [nvarchar](60) NULL,
	[cpu] [int] NULL,
	[duration] int null,
    [dbname] [sysname] NULL,
	[objectname] [sysname] NULL,
	[query_text] [text] NULL,
	[last_wait_type] [nvarchar](64) NULL,
	[login_name] [nvarchar](128) NULL,
	[host_name] [nvarchar](128) NULL,
	[program_name] [sysname] NULL,
	[dbid] [int] NULL,
	[objectid] [int] NULL,
	[total_elapsed_time] [int] NULL,
	[wait_type] [nvarchar](60) NULL,
	[reads] [bigint] NULL,
	[writes] [bigint] NULL,
	[logical_reads] [bigint] NULL,
	[scheduler_id] [int] NULL,
	[tx_level] [varchar](15) NULL,
	[wait_resource] [nvarchar](512) NULL,
	[open_tran_cnt] [int] NULL,
	[row_count] [bigint] NULL,	
	[plan_handle] [varbinary](64) NULL,
	[query_plan] xml,
 CONSTRAINT [PK__MONITOR_SYSPROCESS_SWITCH__REG_DT__SID] PRIMARY KEY CLUSTERED 
(
	[reg_dt], [sid]
) ON [PRIMARY]
) ON [PRIMARY] 

GO
SET ANSI_PADDING OFF
GO
