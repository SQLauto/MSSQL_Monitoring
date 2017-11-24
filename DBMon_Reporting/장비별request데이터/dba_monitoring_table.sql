sp_helpfile

select top 10 * from sql_server_list



/****** 개체:  Table [dbo].[tbl_LargeWaitTasks]    스크립트날짜: 01/05/2010 16:25:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_LargeWaitTasks](
       [svr_id] tinyint not null, 
       [rec_dt] [datetime] NULL,
       [session_id] [smallint] NULL,
       [exec_context_id] [int] NULL,
       [wait_type] [nvarchar](60) NULL,
       [wait_duration_ms] [bigint] NULL,
       [blocking_session_id] [smallint] NULL,
       [query_text] [nvarchar](max) NULL,
       [objectid] [int] NULL,
       [dbid] [smallint] NULL,
       [db_name] [nvarchar](128) NULL,
       [object_name] [nvarchar](257) NULL   
) ON [PRIMARY]
GO

CREATE CLUSTERED INDEX CIDX__TBL_LARGEWAITTASKS ON [dbo].[tbl_LargeWaitTasks] 
(
       svr_id  ASC,
       [rec_dt] asc,
       [session_id] ASC
) ON  [PRIMARY]
GO

/****** 개체:  Table [dbo].[tbl_AlertRecord]    스크립트날짜: 01/05/2010 16:25:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbl_AlertRecord](
       [svr_id] tinyint NOT NULL,
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
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [CIDX_ALERTRECORD] ON [dbo].[tbl_AlertRecord] 
(
       [svr_id] ASC,
       [rec_dt] ASC,
       [session_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


/****** 개체:  Table [dbo].[tbl_BlockingRecord]    스크립트날짜: 01/05/2010 16:25:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_BlockingRecord](
       [svr_id] tinyint     NOT NULL,
       [session_id] [smallint] NOT NULL,
       [blocking_session_id] [smallint] NULL,
       [is_blocker] [int] NOT NULL,
       [db_name] [nvarchar](128) NULL,
       [object_name] [nvarchar](257) NULL,
       [program_name] [nvarchar](128) NULL,
       [query_text] [nvarchar](max) NULL,
       [total_elapsed_time] [int] NOT NULL,
       [reads] [bigint] NOT NULL,
       [writes] [bigint] NOT NULL,
       [logical_reads] [bigint] NOT NULL,
       [scheduler_id] [int] NULL,
       [wait_type] [nvarchar](60) NULL,
       [wait_resource] [nvarchar](256) NOT NULL,
       [open_transaction_count] [int] NOT NULL,
       [login_name] [nvarchar](128) NOT NULL,
       [host_name] [nvarchar](128) NULL,
       [rec_dt] [datetime] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [cidx__rec_dt] ON [dbo].[tbl_BlockingRecord] 
(
    [svr_id] ASC,   
    [rec_dt] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

