-- 테이블 
CREATE TABLE MONITOR_BLOCKER
(
    seq_no          int identity(1,1),
    reg_dt          datetime,
    lastwaittype    nchar(64),
    dbname          nchar(512),
    spid            smallint,
    blocked         smallint,
    cpu             int,
    physical_io     bigint,
    waittype        binary(2),
    waittime        int,
    waitresource    nchar(600),
    status          nchar(60),
    objectid        int,
    objectid_bk     int,
    eventinfo       nvarchar(256),
    eventinfo_bk    nvarchar(256),
    hostname        nchar(256),
    program_name    nchar(256),
    login_time      datetime,
    last_batch      datetime,
    sql_handle      binary(20),
    stmt_start      int,
    stmt_end        int
) ON [PRIMARY]
;

ALTER TABLE MONITOR_BLOCKER ADD CONSTRAINT PK__MONITOR_BLOCKER__SEQ_NO  
    PRIMARY  KEY NONCLUSTERED (seq_no)
;

CREATE CLUSTERED INDEX CIDX__MONITOR_SYSPROCESS_0__REG_DT ON MONITOR_BLOCKER (REG_DT)
;






SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_monitoring_blocker 
* 작성정보    : 2010-02-08 by choi bo ra
* 관련페이지  :  
* 내용        :
* 수정정보    :
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_monitoring_blocker
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @eventinfo nvarchar(255)
declare @get_date datetime
declare
        @lastwaittype    nchar(64),
        @dbname          nchar(512),
        @spid            smallint,
        @blocked         smallint,
        @cpu             int,
        @physical_io     bigint,
        @waittype        binary(20),
        @waittime        int,
        @waitresource    nchar(600),
        @cmd             nchar(32),
        @hostname        nchar(256),
        @program_name    nchar(256),
        @login_time      datetime,
        @last_batch      datetime,
        @sql_handle      binary(20),
        @sql_handle_bk   binary(20),
        @stmt_start      int,
        @stmt_end        int,
        @stmt_start_bk      int,
        @stmt_end_bk       int,
        @query_text      varchar(255),
        @query_text_bk      varchar(255),
        @objectid        int,
        @objectid_bk     int,
        @objectname      nchar(512),
        @objectname_bk   nchar(512),
        @dbid            int,
        @dbid_bk         int,
        @status          nchar(60),
        @day             int,
        @hour            int,
        @minute          int,
        @cnt           int,
        @str           nvarchar(1000)
    

/* BODY */
set @hour = datepart(hour, getdate())              
set @minute = datepart(minute, getdate())  
set @cnt = 0

 select   @cnt = count(*)
from master.dbo.sysprocesses  with (nolock)
where blocked > 0   and spid <> blocked
    and lastwaittype <> 'WAITFOR' and waittype > 0 
    and spid > 50  --and blocked = 0


if @cnt > 0
BEGIN


    CREATE TABLE #monitoring_blocker
        (
            reg_dt          datetime,
            lastwaittype    nchar(64),
            dbname          nchar(512),
            spid            smallint,
            blocked         smallint,
            cpu             int,
            physical_io     bigint,
            waittype        binary(2),
            waittime        int,
            waitresource    nchar(600),
            status          nchar(60),
            objectid        int,
            objectid_bk     int,
            eventinfo       nvarchar(256),
            eventinfo_bk    nvarchar(256),
            objectname      nchar(512),
            objectname_bk      nchar(512),
            --query_text      varchar(2000),
            hostname        nchar(256),
            program_name    nchar(256),
            login_time      datetime,
            last_batch      datetime,
            sql_handle      binary(20),
            stmt_start      int,
            stmt_end        int
      )
                     

	   set @get_date = getdate()
	   
     declare sys_process_cur cursor for       
     select   lastwaittype, dbid,db_name(dbid) as dbname, spid, blocked, 
                cpu,physical_io, status,
                waittype,waittime, waitresource,
                cmd, CONVERT(VARCHAR(25),hostname) as hostname, program_name,
                login_time,last_batch
                ,sql_handle
                ,stmt_start,stmt_end
    from master.dbo.sysprocesses  with (nolock)
    where  blocked > 0  and spid <> blocked -- blocked되어있지만 자기꺼 아닌것.
        and lastwaittype <> 'WAITFOR' and waittype > 0 
        and spid > 50  --and blocked = 0
    
    open sys_process_cur
        fetch next from  sys_process_cur 
        into @lastwaittype,@dbid,@dbname,@spid,@blocked,@cpu,@physical_io,@status,@waittype,@waittime,@waitresource,
            @cmd,@hostname,@program_name,@login_time,@last_batch,@sql_handle,@stmt_start,@stmt_end


    while @@fetch_status = 0  
    begin 

        
           if (@@fetch_status <> -2)
            begin
--                set @str = 'dbcc inputbuffer ('+convert(varchar,@spid)+')'
--                insert #sp_who_temp
--                exec (@str)
                
                
              select  @objectid = objectid,
                @query_text =convert(nvarchar(256), (substring(text, (@stmt_start+2)/2, case @stmt_end when -1 then (datalength(text)) 
                                else (@stmt_end-@stmt_start +2)/2 end ) ) )
               from ::fn_get_sql(@sql_handle)
             
              SET @str = N'SELECT  @name=  name FROM ' + db_name(@dbid) 
                                    + '.dbo.sysobjects with (nolock) where id = ' 
                                    + CONVERT(nvarchar, @objectid)  
                                    
              exec sp_executesql @str, N'@name nchar(512) OUTPUT', @name=@objectname output  
              
                
                
--                set @str = 'dbcc inputbuffer ('+convert(varchar,@blocked)+')'
--                insert #sp_who_temp_blocked
--                exec (@str)
            
                
           end 
           
           -- blocking 정보
           select @sql_handle_bk = sql_handle , @stmt_end_bk = stmt_end, @stmt_start_bk = @stmt_start,
                   @dbid_bk = dbid
           from master.dbo.sysprocesses with (nolock) where spid = @blocked
           
            select  @objectid_bk = objectid,
                		@query_text_bk =convert(nvarchar(256),(substring(text, (@stmt_start+2)/2, case @stmt_end when -1 then (datalength(text)) 
                                else (@stmt_end-@stmt_start +2)/2 end )))
           from ::fn_get_sql(@sql_handle_bk)
             
           SET @str = N'SELECT  @name=  name FROM ' + db_name(@dbid) 
                                    + '.dbo.sysobjects with (nolock) where id = ' 
                                    + CONVERT(nvarchar, @objectid)  
                                    
          exec sp_executesql @str, N'@name nchar(512) OUTPUT', @name=@objectname_bk output  


               
          insert into #monitoring_blocker
            (reg_dt,lastwaittype, dbname,spid,blocked,cpu,physical_io,status, waittype,waittime,waitresource,
             objectid, eventinfo, objectid_bk, eventinfo_bk,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end)
          select @get_date, @lastwaittype, @dbname, @spid, @blocked, @cpu, @physical_io, @status, 
                @waittype, @waittime, @waitresource, @objectid, 
                case when @objectname is null then @query_text  else @objectname_bk end,
                @objectid_bk, case when @objectname_bk is null then @query_text_bk else @objectname_bk end,
                --(select eventinfo from #sp_who_temp) as eventinfo, 
               -- (select eventinfo from #sp_who_temp_blocked) as eventinfo_bk, 
                @hostname, @program_name, @login_time, @last_batch,@sql_handle,@stmt_start, @stmt_end         
        
 
            
            update   #monitoring_blocker  
            set objectid_bk = @objectid_bk, 
                eventinfo_bk = case when @objectname_bk is null then @query_text_bk else @objectname end 
            where spid = @spid
            
          
        fetch next from  sys_process_cur 
             into @lastwaittype,@dbid,@dbname,@spid,@blocked,@cpu,@physical_io,@status,@waittype,@waittime,@waitresource,
                @cmd,@hostname,@program_name,@login_time,@last_batch,@sql_handle,@stmt_start,@stmt_end
     end
        
    close sys_process_cur            
    deallocate sys_process_cur   

     insert into MONITOR_BLOCKER
            (reg_dt,lastwaittype, dbname,spid,blocked,cpu,physical_io,status, waittype,waittime,waitresource,
             objectid, eventinfo,eventinfo_bk,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end,
             objectid_bk)
      select reg_dt,lastwaittype, dbname,spid,blocked,cpu,physical_io,status, waittype,waittime,waitresource,
             objectid, eventinfo,eventinfo_bk,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end,
             objectid_bk
      from #monitoring_blocker    
          
    drop table #monitoring_blocker   
        
          
end     

   set rowcount 100
   if @hour = 4 and (@minute = 00  or @minute = 40)
   begin
        while (1 =1)
        begin
            DELETE MONITOR_BLOCKER WHERE reg_dt < CONVERT(nvarchar(10), getdate() -10, 121)
            if @@rowcount < 100 BREAK;
        end
        
   end

   set rowcount 0
RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO