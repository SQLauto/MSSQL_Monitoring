create proc dbo.up_DBA_CheckThreads
--@check_enum int  = 0 -- 0: cpu 1 : io  2: memusage
@check_mode varchar(10) ='cpu'
as
begin
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
		
		---------------------------------------------------------------------
		-- parameter check
		---------------------------------------------------------------------
		if @check_mode != 'io' and @check_mode !='cpu' and @check_mode != 'mem' 
		begin
				return
		end
		
		---------------------------------------------------------------------
		-- 작업에 필요한 임시 테이블 생성! 
		---------------------------------------------------------------------
		
		create table #sqlperf_threads
		(
			spid int 
			,threadid int 
			,status varchar(50)
			,loginname varchar(50)
			,io numeric(10,0)
			,cpu numeric(10,0)
			,memusage int
		)

		-- show
		create table #sqlperf_res
		(
			seqno int not null identity(1,1)
			,spid int 
			,threadid int 
			,status varchar(50)
			,loginname varchar(50)
			,io numeric(10,0)
			,cpu numeric(10,0)
			,memusage int
			,str_cmd varchar(500)
		)
		
		-- dbcc inputbuffer
		create table #inputbuffer
		(
			seq int identity primary key
		,	eventtype char(100)
		,	parameters int
		,	eventinfo char(500)
		)
		
		---------------------------------------------------------------------
		-- dbcc sqlperf(threads) 실행
		---------------------------------------------------------------------
		
		insert into #sqlperf_threads(spid , threadid , status , loginname , io , cpu , memusage)
		exec('dbcc sqlperf(threads)')
		
		---------------------------------------------------------------------
		-- 조건에 맞는 process 없을시 바로 종료
		---------------------------------------------------------------------
		
			if @@rowcount <=0 return 
			
		
		---------------------------------------------------------------------
		-- 요청에 맞는 data filtering 
		---------------------------------------------------------------------
		
		create clustered index cidx__spid on #sqlperf_threads(spid)
		if @check_mode = 'cpu' 
		begin
					create index idx__cpu on #sqlperf_threads(cpu)
					
					insert #sqlperf_res(spid , threadid , status , loginname , io , cpu , memusage)
					select top 50 *
					from #sqlperf_threads with(nolock)
					where spid > 50
					order by cpu desc
		end
		
		if @check_mode = 'io'
		begin
					create index idx__io on #sqlperf_threads(io)
					
					insert #sqlperf_res(spid , threadid , status , loginname , io , cpu , memusage)
					select top 50 *
					from #sqlperf_threads with(nolock)
					where spid > 50
					order by io desc
		end
		
		if @check_mode = 'mem'
		begin
					create index idx__memusage on #sqlperf_threads(memusage)
					
					insert #sqlperf_res(spid , threadid , status , loginname , io , cpu , memusage)
					select top 50 *
					from #sqlperf_threads with(nolock)
					where spid > 50
					order by memusage desc
		end
		
		
		
		
		---------------------------------------------------------------------
		-- dbcc inputbuffer로 실행되는 script capture
		---------------------------------------------------------------------

		declare @limit_seq int ,@start_seq int , @end_seq int , @process_size int
		
		set @process_size = 1
		
		select @limit_seq= count(*) from #sqlperf_res with(nolock)
		
		set @start_seq = 1
		set @end_seq = @start_seq + @process_size
		
		while (1=1)
		begin
		
			--print 'start=' + convert(varchar(10) , @start_seq) + ',end=' + convert(varchar(10) , @end_seq) + ',limit=' + convert(varchar(10) , @limit_seq)	
			
			declare @dbcc_input varchar(300) , @dbcc_output varchar(500)
			declare @spid int
			
			
			---------------------------------------------------------------------
			-- dbcc inputbuffer(spid) 수행!
			---------------------------------------------------------------------

			select @spid = spid -- , @src_blocked = blocked 
			from #sqlperf_res with(nolock)
			where seqno = @start_seq
			
			set @dbcc_input = 'dbcc inputbuffer(' + convert(varchar(10) , @spid ) + ')'
			
			insert into #inputbuffer (EventType, Parameters, EventInfo)
			exec(@dbcc_input)
			
			
			if @@rowcount > 0
			begin
					select top 1 @dbcc_output = EventInfo 
					from #inputbuffer with(nolock)
					order by seq desc
			end
			
			---------------------------------------------------------------------
			-- update process temp table 
			---------------------------------------------------------------------
					
			update #sqlperf_res
			set str_cmd = @dbcc_output
			where seqno = @start_seq
			
			if @end_seq > @limit_seq break;
			
			set @start_seq = @end_seq
			set @end_seq= @start_seq + @process_size
		end
		
		---------------------------------------------------------------------
		-- 결과출력
		---------------------------------------------------------------------
		select *
		from #sqlperf_res with(nolock)			
		
		SET NOCOUNT OFF
end		

