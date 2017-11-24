/*----------------------------------------------------
    Date    : 2007-11-06
    Note    : Job 싱크 부분 로직 변경에 따른 테이블 생성
    No.     :
*----------------------------------------------------*/

CREATE TABLE [dbo].[JobHistory] (
	[job_hist_id] [int] NOT NULL ,
	[job_id] [varchar] (40)  NOT NULL ,
	[step_id] [int] NOT NULL ,
	[message] [varchar] (7900)  NULL ,
	[run_status] [tinyint] NOT NULL ,
	[run_date] [int] NOT NULL ,
	[run_time] [int] NOT NULL ,
	[run_duration] [int] NOT NULL ,
	SMS_CK  CHAR(1) NOT NULL,
	EMS_CK  CHAR(1) NOT NULL,
	SMSFlag tinyint DEFAULT (1) not null,
	EMSFlag tinyint DEFAULT (1) not null,
	[reg_dt] [smalldatetime] DEFAULT(getdate()) NOT NULL
) ON [PRIMARY]
GO



CREATE TABLE [dbo].[JobSteps] (
	[job_id] [varchar] (40)  NOT NULL ,
	[step_id] [int] NOT NULL ,
	[mgr_no] [int]  DEFAULT(1) NOT NULL ,
	[step_name] sysname  NOT NULL ,
	[subsystem] [nvarchar] (40)  NOT NULL ,
	--[command] [nvarchar] (3200)  NULL ,
	[command] [nvarchar] (max)  NULL ,
	[database_name] [sysname]   NULL ,
	[stat] [char] (2) DEFAULT('S2') NOT NULL ,
	[reg_dt] [smalldatetime] DEFAULT(getdate())NOT NULL ,
	[chg_dt] [smalldatetime] DEFAULT(getdate())NOT NULL 
) ON [PRIMARY]
GO



CREATE TABLE [dbo].[Jobs] (
	[job_id] [varchar] (40)  NOT NULL ,
	[job_name] [varchar] (100)  NOT NULL ,
	[enabled] [tinyint] NOT NULL ,
	job_type    tinyint NOT NULL CONSTRAINT DF__JOBS__JOB_TYPE  DEFAULT 1,  --1: job, 2:db 3:backup, 4:로직, 5: 하드웨어
	[last_run_outcome] [int] NOT NULL CONSTRAINT DF__JOBS__LAST_RUN_OUTCOME DEFAULT(5) ,
	[last_run_duration] [int] NOT NULL CONSTRAINT DF__JOBS__LAST_RUN_DURATION DEFAULT(0) ,
	[date_created] [datetime] NULL ,
	[date_modified] [datetime] NULL ,
	[reg_dt] [smalldatetime] NOT NULL  CONSTRAINT DF__JOBS__REG_DT DEFAULT(GETDATE())  ,
	[chg_dt] [smalldatetime] NOT NULL  CONSTRAINT DF__JOBS__CHG_DT DEFAULT(GETDATE()),
	[stat] [char] (2) NOT NULL CONSTRAINT DF__JOBS__STAT DEFAULT('S2') ,
	[job_hist_ck] [char] (1)  NOT NULL CONSTRAINT DF__JOBS__JOB_HIST_CK DEFAULT('Y') ,
	[SMS_ck] [char] (1)   NOT NULL CONSTRAINT DF__JOBS__SMS_ck DEFAULT('N') ,
	[EMS_ck] [char] (1)  NOT NULL CONSTRAINT DF__JOBS__EMS_ck DEFAULT('N'),
	[mgr_no] [int]  NOT NULL CONSTRAINT DF__JOBS__MGER_NO DEFAULT(2504), --김태환
	[monitoring_yn] [char] (1) NULL  CONSTRAINT DF__JOBS__MONITORING_YN DEFAULT('Y'),
	[kill_yn] [char] (1) NULL CONSTRAINT DF__JOBS__KILL_YN DEFAULT('N'),
	kill_duration   int  null CONSTRAINT DF__JOBS__KILL_DURATION DEFAULT 60,
	job_id_char varchar(100) NULL
) ON [PRIMARY]
GO



/****** 개체:  Table [dbo].[OperatorSimple]    스크립트 날짜: 03/10/2008 14:57:35 ******/

CREATE TABLE [dbo].[OperatorSimple](
	[operatorNo] [int] NOT NULL,
	[operatorId] [varchar](10) NOT NULL,
	[sabun] [char](6) NULL,
	[operatorName] [nvarchar](20) NOT NULL,
	[temCode] [tinyint] NULL DEFAULT (0),
	[HPNo] [varchar](15) NULL DEFAULT (0),
	[EMail] [varchar](50) NULL,
	[jobFlag] [tinyint] NULL DEFAULT (0),
	[dbFlag] [tinyint] NULL DEFAULT (0),
	[backupFlag] [tinyint] NULL DEFAULT (0),
	[logicFlag] [tinyint] NULL DEFAULT (0),
	[HWFlag] [tinyint] NULL DEFAULT (0),
	[registerDate] [datetime] NOT NULL DEFAULT (getdate()),
	[changeDate] [datetime] NOT NULL DEFAULT (getdate()),
 CONSTRAINT [PK_OperatorSimple_operatorNo] PRIMARY KEY CLUSTERED 
(
	[operatorNo] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO



CREATE TABLE dbo.JOBS_OPERATOR
(
    seq_no					int IDENTITY(1,1)               not null, 
    job_id                varchar(40)       not null,
    operatorno            int               not null,
    reg_dt                datetime          not null constraint DF__JOBS_OPERATOR__REG_DT DEFAULT getdate()
)
GO

ALTER TABLE dbo.JOBS_OPERATOR ADD CONSTRAINT PK__JOBS_OPERATOR__seq_no  PRIMARY KEY NONCLUSTERED (seq_no) ON [PRIMARY]
GO

CREATE CLUSTERED INDEX CIDX__JOBS_OPERATOR__JOB_ID ON dbo.JOBS_OPERATOR (job_id) ON [PRIMARY]
GO




ALTER TABLE [dbo].[Jobs] WITH NOCHECK ADD 
	CONSTRAINT [pk_Jobs_job_id] PRIMARY KEY  CLUSTERED 
	(
		[job_id]
	)  ON [PRIMARY] 
GO

CREATE NONCLUSTERED INDEX IDX__monitoring_yn ON Jobs (monitoring_yn) ON [PRIMARY]
GO


ALTER TABLE [dbo].[JobSteps] WITH NOCHECK ADD 
	CONSTRAINT [PK_JobSteps_job_id_step_id] PRIMARY KEY  CLUSTERED 
	(
		[job_id],
		[step_id]
	)  ON [PRIMARY] 
GO


ALTER TABLE [dbo].[JobHistory] ADD 
	
	CONSTRAINT [PK_JobHistory_job_hist_id] PRIMARY KEY  NONCLUSTERED 
	(
		[job_hist_id]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
GO

CREATE  CLUSTERED INDEX IDX_C_JobHistory_job_id
    ON dbo.JobHistory(job_id)WITH FILLFACTOR = 90 ON [PRIMARY]
 GO 
 
 CREATE  INDEX IDX__JOBHISTORY_REG_DT
    ON dbo.JobHistory(reg_dt)WITH FILLFACTOR = 90 ON [PRIMARY]
 GO 
 
 
 

/****** 개체:  Table [dbo].[EMSSendMaster]    스크립트 날짜: 03/19/2008 16:40:21 ******/

CREATE TABLE [dbo].[EMSSendMaster](
	[seqNo] [int] IDENTITY(1,1) NOT NULL,
	[jobHistId] [int] NOT NULL,
	[jobId] [varchar](40) NOT NULL,
	[jobName] [varchar](100) NOT NULL,
	[jobStepId] [int] NOT NULL,
	[operatorName] [nvarchar](20) NOT NULL,
	[EMail] [varchar](50) NOT NULL,
	[sendFlag] [tinyint] NOT NULL DEFAULT (1),
	[runStatus] [tinyint] NOT NULL,
	[runDate] [int] NOT NULL,
	[runTime] [int] NOT NULL,
	[message] [varchar](4000) NULL,
	[registerDate] [datetime] NOT NULL DEFAULT (getdate()),
	[changeDate] [datetime] NOT NULL DEFAULT (getdate()),
	[runduration] [int] NULL CONSTRAINT [DF__EMSSENDMASTER__RUNDURATION]  DEFAULT ((0)),
	[ems_send_nm] [varchar](20) NULL,
 CONSTRAINT [PK_EMSSendMaster_seqNo] PRIMARY KEY NONCLUSTERED 
(
	[seqNo] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE CLUSTERED INDEX [IDX_C_EMSSendMaster_jobHistId] ON [dbo].[EMSSendMaster] 
(
	[jobHistId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** 개체:  Table [dbo].[SMSSendMaster]    스크립트 날짜: 03/19/2008 16:40:29 ******/
CREATE TABLE [dbo].[SMSSendMaster](
	[seqNo] [int] IDENTITY(1,1) NOT NULL,
	[jobHistId] [int] NOT NULL,
	[jobId] [varchar](40) NOT NULL,
	[jobName] [varchar](100) NOT NULL,
	[jobStepId] [int] NOT NULL,
	[operatorName] [nvarchar](20) NOT NULL,
	[HPNo] [varchar](50) NOT NULL,
	[sendFlag] [tinyint] NOT NULL DEFAULT (1),
	[runStatus] [tinyint] NOT NULL,
	[registerDate] [datetime] NOT NULL DEFAULT (getdate()),
	[changeDate] [datetime] NOT NULL DEFAULT (getdate()),
	[sms_send_nm] [varchar](20) NULL,
 CONSTRAINT [PK_SMSSendMaster_seqNo] PRIMARY KEY NONCLUSTERED 
(
	[seqNo] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


CREATE CLUSTERED INDEX [IDX_C_SMSSendMaster_jobHistId] ON [dbo].[SMSSendMaster] 
(
	[jobHistId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO




USE [DBA]
GO
/****** 개체:  Table [dbo].[LONG_RUN_JOB_HISTORY]    스크립트 날짜: 06/13/2008 11:26:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LONG_RUN_JOB_HISTORY]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[LONG_RUN_JOB_HISTORY](
	[SEQ_NO] [int] IDENTITY(1,1) NOT NULL,
	[JOB_ID] [uniqueidentifier] NULL,
	[DURATION] [int] NULL CONSTRAINT [DF__LONG_RUN_JOB_HISTORY__DURATION]  DEFAULT (0),
	[REG_DT] [datetime] NULL CONSTRAINT [DF__LONG_RUN_JOB_HISTORY__REG_DT]  DEFAULT (getdate()),
 CONSTRAINT [pk_LONG_RUN_JOB_HISTORY] PRIMARY KEY NONCLUSTERED 
(
	[SEQ_NO] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LONG_RUN_JOB_HISTORY]') AND name = N'CIDX_JOB_ID')
CREATE CLUSTERED INDEX [CIDX_JOB_ID] ON [dbo].[LONG_RUN_JOB_HISTORY] 
(
	[JOB_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LONG_RUN_JOB_HISTORY]') AND name = N'nidx__reg_dt')
CREATE NONCLUSTERED INDEX [nidx__reg_dt] ON [dbo].[LONG_RUN_JOB_HISTORY] 
(
	[REG_DT] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

--====================================
-- 임시 테이블 2008/07/01 생성
--====================================
CREATE TABLE DBA_OPERATOR_TEMP
  (
    OID     INT     NOT NULL,
    HPNO    VARCHAR(15) NULL,
    EMAIL   varchar(50) NULL,
    JOBFLAG TINYINT NULL,
    DBFLAG  TINYINT NULL,
    LOGICFLAG TINYINT NULL,
    BACKUPFLAG TINYINT NULL,
    HWFLAG     TINYINT NULL,
    TEMCODE     TINYINT NULL,
    CHG_DT      DATETIME NULL
  )
  
