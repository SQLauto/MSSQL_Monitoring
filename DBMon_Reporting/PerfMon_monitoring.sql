USE [DBA]
GO
/****** 개체:  Table [dbo].[tbl_SMSAlertTime]    스크립트 날짜: 06/15/2009 17:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_SMSAlertTime](
	[seq] [int] IDENTITY(1,1) NOT NULL,
	[SMSDateTime] [datetime] NULL CONSTRAINT [DF_tbl_SMSAlertTime_SMSDateTime]  DEFAULT (getdate()),
	[Message] [nvarchar](2000) NULL,
	[Counter] [nvarchar](500) NULL,
	[Sent] [bit] NULL CONSTRAINT [DF_tbl_SMSAlertTime_Sent]  DEFAULT ((0)),
 CONSTRAINT [PK__tbl_SMSAlertTime__05E4990D] PRIMARY KEY NONCLUSTERED 
(
	[seq] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [CIDX_SMSAlertTime] ON [dbo].[tbl_SMSAlertTime] 
(
	[SMSDateTime] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** 개체:  Table [dbo].[tbl_AlertRecord]    스크립트 날짜: 06/15/2009 17:26:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbl_AlertRecord](
	[rec_dt] [datetime] NOT NULL,
	[session_id] [smallint] NOT NULL,
	[blocking_session_id] [smallint] NULL,
	[status] [nvarchar](30) NOT NULL,
	[cpu_time] [int] NOT NULL,
	[query_text] [nvarchar](max) NULL,
	[dbid] [smallint] NULL,
	[objectid] [int] NULL,
	[object_name] [nvarchar](128) NULL,
	[total_elapsed_time] [int] NOT NULL,
	[reads] [bigint] NOT NULL,
	[writes] [bigint] NOT NULL,
	[logical_reads] [bigint] NOT NULL,
	[scheduler_id] [int] NULL,
	[wait_type] [nvarchar](60) NULL,
	[last_wait_type] [nvarchar](60) NOT NULL,
	[wait_resource] [nvarchar](256) NOT NULL,
	[open_transaction_count] [int] NOT NULL,
	[row_count] [bigint] NOT NULL,
	[login_name] [nvarchar](128) NOT NULL,
	[host_name] [nvarchar](128) NULL,
	[program_name] [nvarchar](128) NULL,
	[last_request_start_time] [datetime] NULL,
	[plan_handle] [varbinary](64) NULL,
	[statement_start_offset] [int] NULL,
	[statement_end_offset] [int] NULL
)  ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [CIDX_ALERTRECORD] ON [dbo].[tbl_AlertRecord] 
(
	[rec_dt] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
