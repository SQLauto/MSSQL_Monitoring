/*
특정 Database 로그 truncate
작성일 : 2007-07-03 
작성자 : 윤태진
파라미터 : 
@dbnm varchar(20) : target database name
@limit ratio int (*default 90) : limit used ratio
----------------------------------------------
  2007-07-09  윤태진 : truncate 로그 쓰기 추가!  
  2007-08-22  윤태진 : 관리자 SMS 쏘기 추가(DBA)
  2008-11-12  윤태진 : 사용자 db 확대 적용 테스트 
*/

ALTER proc dbo.up_DBA_TruncateTransactionLog
@dbnm varchar(20)      --target database name
,@limit_ratio int = 90 --limit used ratio
as
begin

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
	
	--------------------------------------------------------------------
	-- tempdb 일때만 동작해야 함!!!!!
	---------------------------------------------------------------------
	--if @dbnm <> 'tempdb' Or @dbnm = '' 		return 
	if @dbnm = '' return 
		
	--------------------------------------------------------------------
	-- 각 db 별 log 사용량 조회
	---------------------------------------------------------------------
	declare @dbcc  varchar(100)
	declare @sms_msg varchar(80)

	set @sms_msg = @dbnm + '의 로그 가 ' +  convert(varchar(10) , @limit_ratio) + '%를 넘고 있습니다.'

	declare @db_ratio int
	create table #tmp_dbcc
	(
		seqno int not null identity(1,1)
		,dbnm varchar(20)
		,log_size numeric(20,8)
		,used_ratio numeric(20,8)
		,status int
	)
		
	set @dbcc = 'DBCC SQLPERF(LOGSPACE)'
		
	insert into #tmp_dbcc (dbnm, log_size, used_ratio , status)
	exec(@dbcc)
	
	--------------------------------------------------------------------
	-- 결과 없을시 바로 종료
	---------------------------------------------------------------------
	if @@rowcount <= 0 return 
	
	--------------------------------------------------------------------
	-- target db 사용량 비교
	---------------------------------------------------------------------
	set @db_ratio = 0
	
	select @db_ratio = convert(int , used_ratio)  
	from #tmp_dbcc 
	where dbnm = @dbnm
	
	--------------------------------------------------------------------
	-- transaction log backup
	---------------------------------------------------------------------
	if @db_ratio >= @limit_ratio
	begin
		declare @sql varchar(500)
		set @sql = 'backup log '  + @dbnm + ' with TRUNCATE_ONLY'
		
		exec( @sql ) 
		
		--'backup log tempdb with no_log 
	--------------------------------------------------------------------
	-- 2007-08-22 윤태진
	-- sms 보내기(DBA팀)
	---------------------------------------------------------------------
		exec dbo.up_DBA_send_sms 1 , '01190214129' , @sms_msg
		--exec dbo.up_DBA_send_sms 1,  '0177162542' , @sms_msg
		exec dbo.up_DBA_send_sms 1,  '01064551104' , @sms_msg
		exec dbo.up_DBA_send_sms 1,  '01075247744' , @sms_msg
		
	--------------------------------------------------------------------
	-- 2007-07-09 윤태진
	-- write truncate log !!!!!
	---------------------------------------------------------------------
		insert into dba.dbo.txlog_truncate_history(db_nm , db_ratio , limit_ratio ,reg_dt ) values(@dbnm ,@db_ratio ,  @limit_ratio , getdate())
	end	
SET NOCOUNT OFF	
end

