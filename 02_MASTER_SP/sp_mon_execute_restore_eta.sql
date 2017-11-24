create table DB_MON_RESTORE_DB
(
	SEQNO INT  IDENTITY(1,1) NOT NULL ,
	REG_DATE DATE NOT NULL, 
	DB_NAME SYSNAME NOT NULL,
	START_RESTORE_DATE DATETIME, 
	END_RESTOER_DATE DATETIME, 
	START_ROLLFORWARD_DATE DATETIME, 
	END_ROLLFORWARD_DATE DATETIME, 
	PERCENT_COMPLETE VARCHAR(20), 
	CONSTRAINT  PK__DB_MON_RESTORE_DB__SEQ   PRIMARY  KEY NONCLUSTERED ( SEQNO) WITH(DATA_COMPRESSION = PAGE)
)
CREATE CLUSTERED INDEX CIDX_DB_MON_RESTORE_DB__REG_DATE__DB_NAME ON DB_MON_RESTORE_DB ( REG_DATE, DB_NAME) WITH(DATA_COMPRESSION = PAGE) 

6:40 : The database 'ESMPLUSDB' is marked RESTORING and is in a state that does not allow recovery to be run.

9:30
9:30 Restore is complete on database 'ESMPLUSDB'.  The database is now available.


/*************************************************************************  
* 프로시저명  : dbo.sp_mon_execute
* 작성정보    : 2010-02-11 by 최보라
* 관련페이지  :  
* 내용        : sysprocess조회
* 수정정보    : 2013-10-18 BY 최보라, 조건 정리
*************************************************************************/
CREATE PROCEDURE [dbo].[sp_mon_execute_backup_st]

    
AS

SET NOCOUNT ON

DECLARE @row_count int

  select		convert(time(0), getdate()) as run_time,
				d.name, 
                r.session_id as [sid]
				,CONVERT(NUMERIC(6, 2), [r].[percent_complete]) AS [PERCENT Complete]
				,[r].[command]
				,CONVERT(VARCHAR(20), DATEADD(ms, [r].[estimated_completion_time],GETDATE()), 20) AS [ETA COMPLETION TIME]
	INTO #TMP_BACKUP
    from sys.dm_exec_requests r
    	inner join sys.dm_exec_sessions s on r.session_id = s.session_id
				
		left outer join msdb.dbo.sysjobs j
					on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
												substring(left(j.job_id,8),5,2) +
												substring(left(j.job_id,8),3,2) +
											substring(left(j.job_id,8),1,2))
		inner join sys.databases  as d on   d.name =   substring (j.name, charindex(d.name, j.name) , len(d.name))
    where  [r].[percent_complete] > 0
		and d.state_desc ='RESTORING'

	
	set @row_count = @@rowcount
	
	 insert into dbmon.dbo.DB_MON_RESTORE_DB 
	 (reg_date, db_name, START_RESTORE_DATE, END_RESTOER_DATE, PERCENT_COMPLETE )
	 select getdate(), t.name, getdate(), [ETA COMPLETION TIME], [PERCENT Complete]
	 from #TMP_BACKUP as t
		left join dbmon.dbo.DB_MON_RESTORE_DB as m on m.db_name = t.name  and m.reg_date = convert(date,getdate())
	 where m.db_name is null 


	 update dbmon.dbo.DB_MON_RESTORE_DB
	 set END_RESTOER_DATE = case when t.[PERCENT Complete] !=100 then  t.[ETA COMPLETION TIME] else m.END_RESTOER_DATE end
		,PERCENT_COMPLETE = t.[PERCENT Complete]
		,START_ROLLFORWARD_DATE = case when t.[PERCENT Complete] = 100  and m.START_ROLLFORWARD_DATE is null   then getdate() else m.START_ROLLFORWARD_DATE end
	 from #TMP_BACKUP as t
		join dbmon.dbo.DB_MON_RESTORE_DB as m on m.db_name = t.name  and m.reg_date = convert(date,getdate())

	if @row_count = 0
	begin
		-- sp_readerrorlog check
		declare @start_dt varchar(10), @end_dt varchar(10)
		select @start_dt= convert(varchar(10), getdate(), 112), @end_dt =  convert(varchar(10), dateadd(dd,1,getdate()), 112)

		create table #tmp_errorlog 
		( logdate datetime,  processinfo varchar(100), msg varchar(max) )

		insert into #tmp_errorlog
		exec xp_readerrorlog 1,1, N'Restore is complete on database', null, @start_dt, @end_dt

		 update dbmon.dbo.DB_MON_RESTORE_DB	
			set END_ROLLFORWARD_DATE =  t.logdate
		 from #tmp_errorlog as t
			join dbmon.dbo.DB_MON_RESTORE_DB as m on m.db_name = substring(t.msg, charindex( m.db_name, t.msg), len(m.db_name) )
				and m.reg_date = convert(date,getdate())

	end

	select * from dbmon.dbo.DB_MON_RESTORE_DB	




