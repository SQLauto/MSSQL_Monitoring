
--DROP TABLE dbo.KILLED_PROCESS_HISTORY

CREATE TABLE dbo.KILLED_PROCESS_HISTORY
(
	seq_no			int		        NOT NULL IDENTITY(1,1)
,	session_id		smallint		NULL
,   user_db_name    sysname         NULL
,	start_time		datetime		NULL
,	status			nvarchar(60)	NULL
,	command		    nvarchar(32)	NULL
,	sql_text		varchar(8000)	NULL
,	reg_dt			datetime		NULL DEFAULT(getdate())
	
) ON [PRIMARY]
GO

ALTER TABLE  dbo.KILLED_PROCESS_HISTORY ADD CONSTRAINT PK__KILLED_PROCESS_HISTORY__seq_no
	 PRIMARY KEY NONCLUSTERED 
    (seq_no) ON [PRIMARY]
GO


if exists (select 1
            from  sysindexes
           where  id    = object_id('dbo.KILLED_PROCESS_HISTORY')
            and   name  = 'CIDX__KILLED_PROCESS_HISTORY__USER_DB_NAME'
            and   indid > 0
            and   indid < 255)
   drop index dbo.LOGSHIPPING_RESTORE_LIST.IDX_IDX__LOGISHIPPING_RESTORE_LIST__RESTORE_FLAG
go

CREATE CLUSTERED INDEX CIDX__KILLED_PROCESS_HISTORY__USER_DB_NAME ON dbo.KILLED_PROCESS_HISTORY 
    (user_db_name) ON [PRIMARY]
GO
