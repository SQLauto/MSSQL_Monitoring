ALTER PROC dbo.up_dba_replication_sql_error_log
	@site  char(1) = 'G'
AS

BEGIN
SET NOCOUNT ON 

	create table #tmp_errorlog
	(
		seqno int identity(1,1) not null
	,	logdate datetime
	,	processinfo  varchar(100)
	,	text varchar(max)
	)
	declare @sql varchar(max)
	set @sql = 'xp_readerrorlog'

	insert into #tmp_errorlog (logdate , processinfo , text)
	exec(@sql)

	declare @sdt datetime 
	declare @edt datetime

	set @edt = getdate()
	set @sdt = dateadd(hh , -1 , @edt)

	--  PM 시간 제외
	IF @site = 'G'
	BEGIN
		IF DATEPART(DD, GETDATE()) = 6 and DATEPART(HH, GETDATE()) >= 4 AND DATEPART(HH,GETDATE()) < 7
		RETURN
	END
	ELSE IF @site ='I'
	BEGIN
		IF DATEPART(DD, GETDATE()) = 3 and DATEPART(HH, GETDATE()) >= 4 AND DATEPART(HH,GETDATE()) < 7
		RETURN
	END

	------------------------------------------------
	-- replication 에러만 추출함.
	------------------------------------------------
	declare @sample varchar(100)
	declare @len_sample int  , @cnt int 

	set @sample = 'Replication-복제 배포 하위 시스템:'
	set @len_sample = len(@sample)

	-- 1차가공
	select  logdate
		, substring(fail_agent, charindex(':', fail_agent) +1 , len(fail_agent) ) as msg
		into #tmp
	from 
	(select  logdate, substring(text , charindex(@sample , text) + @len_sample 
			, len(text) - charindex(@sample ,text ) + @len_sample) as fail_agent 
	from #tmp_errorlog with(nolock)
	where ( logdate >= @sdt and  logdate < @edt )
		and Left(text , 11) = 'Replication'
	) as a
	
	
	--2차 가공	
	select identity(int, 1,1) as seqno, convert(nvarchar(13),logdate, 121) as logdate
		, substring ( msg, charindex('-', msg) +1,   len(msg) - charindex('.', msg)) as msg
		, count(*) as failcnt
	into #tmp_last
	from #tmp
	group by convert(nvarchar(13),logdate, 121)
		, substring ( msg, charindex('-', msg) +1,   len(msg) - charindex('.', msg)  )
	
	-- 형식 : 2011-04-20 10	TIGER-REPLITIGER_ETC-GCONTENTSDB-108	18
	
	set @cnt = @@rowcount
	
	declare @i int, @msg varchar(80)
	set @i = 1
	
	-- 문자발송
	If @cnt > 0 
	begin
		
		while (@i <= @cnt)
		begin
		
			select  @msg = '[' + @site + ' 복제]' + logdate +  '시 ' + msg + ' Fail,Cnt :' + convert(varchar(10), failcnt)
			from #tmp_last with (nolock)
		    where seqno = @i
		    
			IF @site = 'G'
            BEGIN
                exec CUSTINFODB.SMS_ADMIN.DBO.UP_DBA_SEND_SHORT_MSG 'DBA' ,@msg    
            END
            ELSE IF @site = 'A'
            BEGIN
                declare @sms varchar(200)
                set @sms = 'sqlcmd -S epdb2 -E -Q"exec smsdb.dbo.up_dba_send_short_msg ''DBA'',''' + @msg + '''"'
    			exec xp_cmdshell  @sms
                
            END
		    
		    set @i = @i + 1
		end 

	end

	drop table #tmp_last
	drop table #tmp
	drop table #tmp_errorlog
END
