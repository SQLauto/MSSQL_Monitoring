

CREATE PARTITION FUNCTION PF__MONITOR_BLOCKER_REG_DT(DATETIME)
AS RANGE RIGHT
FOR VALUES (
    '2010-02-25',
    '2010-02-26',
    '2010-02-27',
    '2010-02-28',
    '2010-03-01',
    '2010-03-02',
    '2010-03-03',
    '2010-03-04',
    '2010-03-05',
    '2010-03-06',
    '2010-03-07'
)
GO


--1-2 파티션 스키마 생성
CREATE PARTITION SCHEME  PS__MONITOR_BLOCKER_REG_DT
AS PARTITION PF__MONITOR_BLOCKER_REG_DT
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
CREATE TABLE [dbo].[MONITOR_BLOCKER](
	[reg_dt]        [datetime] NOT NULL,
	[sid]           [smallint] NOT NULL,
	[blocked]       [smallint] NULL,
	[status]        [nvarchar](60) NULL,
	[bk_cpu]           [int] NULL,
	[bk_dbname]     nvarchar(100)  null,
	[bk_objectid]   int null,
	[bk_objectname] text,
	[cpu]           [int] NULL,
	[dbname]     nvarchar(100)  null,
	[objectid]   int null,
	[objectname] text,
	[login_name] [nvarchar](128) NULL,
	[host_name] [nvarchar](128) NULL,
	[program_name] [sysname] NULL,
	[last_wait_type] [nvarchar](64) NULL,
	[total_elapsed_time] [int] NULL,
	[wait_type] [nvarchar](60) NULL,
	[reads] [bigint] NULL,
	[writes] [bigint] NULL,
	[logical_reads] [bigint] NULL,
	[wait_resource] [nvarchar](512) NULL,
	[tran_count] [int] NULL,
 CONSTRAINT [PK__MONITOR_BLOCKER__RET_DT__SID] PRIMARY KEY CLUSTERED 
(
	[reg_dt], [sid]
) ON  PS__MONITOR_BLOCKER_REG_DT(REG_DT) 
) ON PS__MONITOR_BLOCKER_REG_DT(REG_DT) 

GO
SET ANSI_PADDING OFF
GO

--/****** 개체:  Index [CIDX__MONITOR_SYSPROCESS__REG_DT_CPU_BY_REQUESTS]    스크립트 날짜: 02/26/2010 20:00:42 ******/
--CREATE CLUSTERED INDEX [CIDX__MONITOR_SYSPROCESS__REG_DT_CPU_BY_REQUESTS] ON [dbo].[MONITOR_SYSPROCESS] 
--(
--	[reg_dt] ASC,
--	[cpu_by_requests] DESC
--)ON PS__MONITOR_SYSPROCESS_REG_DT(REG_DT)



/****** 개체:  Table [dbo].[MONITOR_BLOCKER_SWITCH]    스크립트 날짜: 02/26/2010 20:00:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[MONITOR_BLOCKER_SWITCH](
	[reg_dt]        [datetime] NOT NULL,
	[sid]           [smallint] NOT NULL,
	[blocked]       [smallint] NULL,
	[status]        [nvarchar](60) NULL,
	[bk_cpu]           [int] NULL,
	[bk_dbname]     nvarchar(100)  null,
	[bk_objectid]   int null,
	[bk_objectname] text,
	[cpu]           [int] NULL,
	[dbname]     nvarchar(100)  null,
	[objectid]   int null,
	[objectname] text,
	[login_name] [nvarchar](128) NULL,
	[host_name] [nvarchar](128) NULL,
	[program_name] [sysname] NULL,
	[last_wait_type] [nvarchar](64) NULL,
	[total_elapsed_time] [int] NULL,
	[wait_type] [nvarchar](60) NULL,
	[reads] [bigint] NULL,
	[writes] [bigint] NULL,
	[logical_reads] [bigint] NULL,
	[wait_resource] [nvarchar](512) NULL,
	[tran_count] [int] NULL,
 CONSTRAINT [PK__MONITOR_BLOCKER_SWITCH__RET_DT__SID] PRIMARY KEY CLUSTERED 
(
	[reg_dt], [sid]
) ON  [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
