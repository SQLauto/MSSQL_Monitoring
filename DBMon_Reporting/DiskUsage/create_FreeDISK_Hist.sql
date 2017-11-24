USE [DBA]
GO
/****** 개체:  Table [dbo].[FreeDISK_Hist]    스크립트 날짜: 01/15/2008 13:59:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[FreeDISK_Hist](
	[seqno] [int] IDENTITY(1,1) NOT NULL,
	[server_nm] [sysname] NULL,
	[Drive] [char](1) NOT NULL,
	[FreeMB] [int] NOT NULL,
	[log_time] [smalldatetime] NOT NULL DEFAULT getdate(),
PRIMARY KEY CLUSTERED 
(
	[seqno] ASC
)ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF