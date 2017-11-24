use master
go

/*************************************************************************  
* 프로시저명  : dbo.sp_mon_execute
* 작성정보    : 2010-02-11 by 최보라
* 관련페이지  :  
* 내용        : sysprocess조회 2000용
* 수정정보    :
*************************************************************************/
ALTER PROCEDURE dbo.sp_mon_execute
     @iswaitfor      tinyint = 0
    
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

-- sysprocess 		
	create table #tmp_top_process
	(
		seq_no int not null identity(1,1)
	,	spid int 
	,	blocked int
	, kpid    int
	,	lastwaittype varchar(100)
	,	open_tran int
	, objectid    int
	, query_text   varchar(4000)
	,	cmd varchar(100)
	,	dbid int 
	, dbname varchar(100)
	,	cpu numeric(38,0)
	,	physical_io numeric(38,0)
	,	status varchar(100)
	,	waitresource varchar(100)
	,   [hostname] [nchar](256) NULL
	,   [program_name] [nchar](256) NULL
	,   [login_time] [datetime] NULL
	,   [last_batch] [datetime] NULL
    ,   [sql_handle] [binary](20) NULL
    ,   [stmt_start] [int] NULL
    ,   [stmt_end] [int] NULL
	,	str_kill varchar(20)
	)

	-- dbcc inputbuffer
--	create table #inputbuffer
--	(
--		eventtype nvarchar(30)
--	,	parameters int
--	,	eventinfo nvarchar(4000)
--	)
--	

insert into #tmp_top_process
			(
				spid 
			,	blocked
			,   kpid
			,	lastwaittype
			,	open_tran
			,	cmd
			,	dbid
			,   dbname
			,	cpu
			,	physical_io
			,	status
			,	waitresource
			,   hostname
			,   program_name
			,   login_time
			,   last_batch
			,   sql_handle
			,   stmt_start
			,   stmt_end
			,	str_kill
			)
		select 
			 spid as spid
			,blocked as blocked
			,kpid   
			,lastwaittype
			,open_tran
			,cmd
			,dbid
            ,db_name(dbid) as dbname
			,cpu
			,physical_io
			,status
			,waitresource
			, convert(varchar(25),hostname) as hostname
			,   program_name
			,   login_time
			,   last_batch
			,   sql_handle
			,   stmt_start
			,   stmt_end
			,case blocked 
					when null then ''
					else 'KILL ' + convert(varchar(10) , blocked)
			  end  as str_kill
		from master..sysprocesses with(nolock)
		where  
    	    spid > 50  and spid != @@spid
            and ((@iswaitfor = 1 and lastwaittype = lastwaittype) or (lastwaittype <> 'WAITFOR' and lastwaittype > 0x0000))
        order by kpid desc ,cpu desc, blocked desc
        
        ---------------------------------------------------------------------
		-- 조건에 맞는 process 없을시 바로 종료
		---------------------------------------------------------------------
		
		if @@rowcount <=0 return 

       
        declare @limit_seq int ,@start_seq int , @end_seq int , @process_size int
      
        
        set @process_size = 1
        
        select @limit_seq= count(*) from #tmp_top_process with(nolock)
        
        set @start_seq = 1
		set @end_seq = @start_seq + @process_size
        
        while (1=1)
	    begin

             declare @sql_handle      binary(20), @stmt_start      int,  @stmt_end        int, @dbid int
             declare @spid  int, @blocked int , @object_query nvarchar(200), @objectname nchar(512) , @objectid int,
                @query_text varchar(400)
            
	          
            select @spid = spid , @blocked = blocked , @dbid = dbid,
                   @sql_handle = sql_handle, @stmt_start = stmt_start, @stmt_end =stmt_end
			from #tmp_top_process with(nolock)
			where seq_no = @start_seq
			
		 
		
		  --객체 찾기	
	     if exists (select * from ::fn_get_sql(@sql_handle)) 
         begin      
             select  @objectid = objectid,
                    @query_text =substring(text, (@stmt_start+2)/2, case @stmt_end when -1 then (datalength(text)) 
                                    else (@stmt_end-@stmt_start +2)/2 end ) 
             from ::fn_get_sql(@sql_handle)  
             

             SET @object_query = N'SELECT  @name=  name FROM ' + db_name(@dbid) 
                                    + '.dbo.sysobjects with (nolock) where id = ' 
                             + CONVERT(nvarchar, @objectid)  
                                    
            exec sp_executesql @object_query, N'@name nchar(512) OUTPUT', @name=@objectname output        
    
        end
        


        
        --------------------------------------------------------------------
        -- 상태 update
        --------------------------------------------------------------------
        update   #tmp_top_process 
            set objectid = @objectid
            ,query_text = case when @objectname is null then @query_text else @objectname end
        where spid = @spid
        
        if @end_seq > @limit_seq break;
					
		set @start_seq = @end_seq
		set @end_seq= @start_seq + @process_size

      
    end
    
    ----------------------------------------------------------------------------
    -- 출력
    ----------------------------------------------------------------------------

    select  spid, blocked, kpid, lastwaittype, cpu, status, dbname, objectid, query_text, 
            --datediff(mi, login_time, isnull(last_batch, getdate())) as diff_min, 
            dbid, physical_io, cmd, hostname, login_time,last_batch, waitresource,program_name,
            str_kill,sql_handle, stmt_start,stmt_end            
    from #tmp_top_process
    order by kpid desc ,cpu desc, blocked desc
    
 
 drop table #tmp_top_process

RETURN
