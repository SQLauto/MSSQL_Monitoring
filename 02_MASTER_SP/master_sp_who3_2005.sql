
/*
sp_who3(SQL2005)
작성일 : 2007-08-06 
작성자 : 윤태진
파라미터 : 
지난 2초간 가장 CPU를 많이사용한 프로세스를 보여준다.
*/

CREATE proc sp_who3
@res_count  int = 15
,@delay_time datetime  = '00:00:02'
as
begin
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
		SET LOCK_TIMEOUT 10000
	
	  ----------------------------------------------------------------
	  -- insert sys.dm_exec_requests into temp table !
	  ----------------------------------------------------------------
		select 
		session_id
		,sql_handle
		,cpu_time
		,(writes + reads) as physical_io into #tmp_requests 
		from sys.dm_exec_requests with(nolock) 
		
		----------------------------------------------------------------
	  -- delay with parameter
	  ----------------------------------------------------------------
		WAITFOR DELAY @delay_time
		
		
		----------------------------------------------------------------
	  -- find 
	  ----------------------------------------------------------------
		
		select
		t1.text as sql_string
		,raw.session_id
		,raw.cpu_gap as 'cpu변화'
		,raw.cpu_time
		,raw.physical_io
		,raw.host_name
		,raw.start_time
		,raw.program_name
		,raw.login_name
		from (
			----------------------------------------------------------------
	  	-- compare with temptable (calc cpu_time) or physical_io
	  	----------------------------------------------------------------
			select top(@res_count) 
			req1.sql_handle
			,req1.session_id
			,(req1.cpu_time - req2.cpu_time) as 'cpu_gap'
			, req1.cpu_time
			,(req1.reads + req1.writes) as 'physical_io'
			,session.host_name
			,req1.start_time
			,session.program_name
			,session.login_name 
			from sys.dm_exec_requests req1 with(nolock)
			inner join sys.dm_exec_sessions session with(nolock) on req1.session_id = session.session_id
			inner join #tmp_requests req2 with(nolock) on ( req1.session_id = req2.session_id and  req1.sql_handle = req2.sql_handle)
			where req1.session_id > 64
			order by 'cpu_gap' desc , req1.cpu_time desc 
		) raw 
		cross apply sys.dm_exec_sql_text(raw.sql_handle) as t1
		
		
		SET NOCOUNT OFF
end		 

