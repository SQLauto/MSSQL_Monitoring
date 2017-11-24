USE [DBA]
GO
/****** 개체:  Table [dbo].[OPERATORS]    스크립트 날짜: 01/06/2010 18:11:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[OPERATORS](
	[operator_no] [int] NOT NULL,
	[operator_id] [varchar](10) NOT NULL,
	[operator_name] [nvarchar](40) NOT NULL,
	[team_code] [tinyint] NULL,
	[hp_no] [varchar](15) NULL,
	[email] [varchar](100) NULL,
	[reg_dt] [datetime] NULL,
	[chg_dt] [datetime] NULL,
	[nation_code] [char](2) NOT NULL,
	[alert_code] [tinyint] NULL,
 CONSTRAINT [PK__OPERATORS__OPERATOR_NO_NATION_CODE] PRIMARY KEY CLUSTERED 
(
	[operator_no] ASC,
	[nation_code] ASC
) ON [JOBMNG_DATA_FG1]
) ON [JOBMNG_DATA_FG1]
GO
SET ANSI_PADDING OFF
GO
