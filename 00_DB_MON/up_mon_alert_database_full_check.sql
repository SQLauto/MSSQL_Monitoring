
CREATE PROC dbo.up_mon_alert_database_full_check
	@site  char(1) = 'G'
AS

BEGIN
SET NOCOUNT ON 

	create table #tmp_errorlog
	(
		seqno int identity(1,1) not null
	,	logdate datetime
	,	processinfo  varchar(100)
	,	text varchar(4000)
	)
	
	declare @sql varchar(max)
	declare @sdt datetime 
	declare @edt datetime
	declare @database_name sysname

	set @edt = getdate()  
	set @sdt = dateadd(mi , -2 , @edt)

	

	set @sql = 'xp_readerrorlog 0, 1, null, null, ''' + convert(nvarchar(19),@sdt, 121 ) + ''', ''' + convert(nvarchar(19),@edt, 121 ) + ''''
	--exec xp_readerrorlog 0, 1, null, null,  @from_date, @to_date, 'desc'
	print @sql

	insert into #tmp_errorlog (logdate , processinfo , text)
	exec(@sql)

	if @@rowcount > 0 
	begin

		------------------------------------------------
		-- tempdb full  에러만 추출함.
		------------------------------------------------
		declare @sample varchar(100)
		declare @len_sample int  , @cnt int 
		--in database 'tempdb' because the 'PRIMARY' filegroup is full.

		set @sample = 'filegroup is full'

	

		declare @logdate nvarchar(16),@msg varchar(80)
		DECLARE @SMS VARCHAR(200)

		select top 1  @logdate = convert(nvarchar(16), logdate, 121) ,
					@database_name =upper(replace(substring(text, charindex('in database', text) + 12
						, ( charindex('because', text)  -  charindex('in database', text) ) -12 )
						, '''', '') )
		from #tmp_errorlog
		where text like '%'+ @sample + '%'
			AND  ( logdate >= @sdt and  logdate < @edt )
		order by logdate desc

		set @cnt = @@rowcount



		IF @CNT > 0 
		BEGIN

				SET @MSG = '[' + @@SERVERNAME + '] ' + @logdate +' - ' + @database_name + ' DATA FULL '

				IF @SITE = 'G'
				BEGIN
              
					SET @SMS = 'SQLCMD -S GCONTENTSDB,3950 -E -Q"EXEC SMS_ADMIN.DBO.UP_DBA_SEND_SHORT_MSG ''DBA'',''' + @msg + '''"'
					EXEC XP_CMDSHELL  @SMS
				END
				ELSE IF @SITE = 'A'
				BEGIN
          
					SET @SMS = 'SQLCMD -S EPDB2 -E -Q"EXEC SMSDB.DBO.UP_DBA_SEND_SHORT_MSG ''DBA'',''' + @MSG + '''"'
    				EXEC XP_CMDSHELL  @SMS
                
				END


		END
 END
END


