
/*************************************************************************  
* 프로시저명  : dbo.up_dba_process_user_kill 
* 작성정보    : 2007-08-05
* 관련페이지  :  
* 내용        : 사용자 프로시저 Kill
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.sp_dba_process_user_kill
	@user_db_name		sysname,			    -- DataBase Name
	@logging_mode		smallint =1			-- 1:NO LOGGING, 2: LOGGING(LOGGING TABLE : KILLED_PROCESS_HISTORY)
AS
	/* COMMON DECLARE */
	set nocount on
	set transaction isolation level read uncommitted

	/* USER DECLARE */
	declare @iSessionListCnt	smallint	-- KILL 해야되는 process개수
	declare @iLoopCnt			int			-- Loop Counter
	declare @sSql				nvarchar(100)		-- KILL SQL 
	declare @iSessionId			int			-- session id

	create table #tblSessionList
	    (
		seq_no				int		not null identity(1,1)
	,	session_id			smallint		not null	-- session id
	)
    
	-- index 생성
	create index idx__seq_no on #tblSessionList (seq_no)
	create clustered index cidx__session_id on #tblSessionList (session_id)
    
	/* BODY */
	insert into #tblSessionList(session_id)
	SELECT distinct(spid)
	FROM master.dbo.sysprocesses WITH (NOLOCK)   
	  WHERE dbid = db_id(@user_db_name) AND spid > 50  
	
	/*select req.session_id
	from sys.dm_exec_requests as req with (nolock)
	inner join master..sysdatabases as cat with (nolock) on req.database_id = cat.dbid
	where req.session_id > 50
	  and UPPER(cat.name) = @user_db_name */
    
	set @iSessionListCnt = @@ROWCOUNT
    
	if @iSessionListCnt = 0
	begin
		return;
	end

	-- PROCESS KILL
	if (@logging_mode = 2)
	begin
		
		insert into dba.dbo.KILLED_PROCESS_HISTORY
		(
						session_id
		,               user_db_name
		,				start_time
		,				status
		,				command
		,				sql_text
		)
		select 
			req.session_id,
			DB_NAME(req.database_id) as user_db_name,
			req.start_time, 
			req.status, 
			req.command, 
			(select text from sys.dm_exec_sql_text(req.sql_handle)) as sql
		   from sys.dm_exec_requests as req with (nolock)
		   inner join #tblSessionList as ses with (nolock) on req.session_id = ses.session_id

	end

	--loop counter 초기화
	set @iLoopCnt = 1

	while (@iLoopCnt <= @iSessionListCnt)
	begin
		select @iSessionId = session_id from dbo.#tblSessionList with (nolock) where seq_no = @iLoopCnt

		SET @sSql = ' KILL ' + cast(@iSessionId as varchar)

		EXEC sp_executesql @sSql

		set @iLoopCnt = @iLoopCnt + 1

		if (@iLoopCnt > @iSessionListCnt)
		begin
			return;
		end
	end 
		
	drop table #tblSessionList

	set nocount off
GO


grant all on sp_dba_process_user_kill to public
GO