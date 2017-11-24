
/*************************************************************************  
* 프로시저명  : dbo.up_dba_monitoring_sysprocess 
* 작성정보    : 2010-02-08 by choi bo ra
* 관련페이지  :  
* 내용        : sysprocess 수집
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_monitoring_sysprocess
    @type       int = 0
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @object_query nvarchar(100) 
DECLARE @get_date  datetime

/* BODY */
set @get_date = getdate()

IF @type =  0 
BEGIN


    CREATE TABLE #monitoring_sysprocess
    (
        reg_dt          datetime,
        lastwaittype    nchar(64),
        dbname          nchar(100),
        spid            smallint,
        blocked         smallint,
        cpu             int,
        physical_io     bigint,
        waittype        binary(2),
        waittime        int,
        waitresource    nchar(600),
        status          nchar(60),
        objectid        int,
        objectname      nchar(512),
        cmd             nchar(32),
        query_text      varchar(4000),
        hostname        nchar(256),
        program_name    nchar(256),
        login_time      datetime,
        last_batch      datetime,
        sql_handle      binary(20),
        stmt_start      int,
        stmt_end        int
    )
    
    
    
    declare
        @lastwaittype    nchar(64),
        @dbname          nchar(100),
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
        @stmt_start      int,
        @stmt_end        int,
        @query_text      varchar(4000),
        @objectid        int,
        @objectname      nchar(512),
        @dbid            int,
        @status          nchar(60),
        @day             int,
        @hour            int,
        @minute          int
    
    set @day  = datepart (day, getdate()) % 10         
    set @hour = datepart(hour, getdate())              
    set @minute = datepart(minute, getdate())  
        
     
    declare sys_process_cur cursor for          
    select 
            lastwaittype, dbid,db_name(dbid) as dbname, spid, blocked, 
            cpu,physical_io, status,
            waittype,waittime, waitresource,
            cmd, CONVERT(VARCHAR(25),hostname) as hostname, program_name,
            login_time,last_batch
            ,sql_handle
            ,stmt_start,stmt_end
    from master..sysprocesses 
    where spid > 50 --and lastwaittype <> 'WAITFOR' and waittype > 0x0000 -- 모두 다 잡아야 한다.
    order by dbid, spid, cpu desc, blocked desc
    
    open sys_process_cur
    fetch next from  sys_process_cur 
    into @lastwaittype,@dbid,@dbname,@spid,@blocked,@cpu,@physical_io,@status,@waittype,@waittime,@waitresource,
        @cmd,@hostname,@program_name,@login_time,@last_batch,@sql_handle,@stmt_start,@stmt_end
    
    while @@fetch_status = 0  
    begin 
        insert into #monitoring_sysprocess
            (reg_dt,lastwaittype, dbname,spid,blocked,cpu,physical_io,status, waittype,waittime,waitresource,
             cmd, hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end)
        select  
                @get_date,lastwaittype, db_name(dbid) as dbname, spid, blocked, 
                cpu,physical_io, status,
                waittype,waittime, waitresource,
                cmd, CONVERT(VARCHAR(25),hostname) as hostname, program_name,
                login_time,last_batch,sql_handle,stmt_start,stmt_end
        from master..sysprocesses 
        where spid = @spid
        --> 50 and lastwaittype <> 'WAITFOR' and waittype > 0x0000
        order by dbid, spid, cpu desc, blocked desc
    
    
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
        update   #monitoring_sysprocess 
        set objectid = @objectid, query_text = @query_text, objectname=@objectname
        where spid = @spid
    
        fetch next from  sys_process_cur 
         into @lastwaittype,@dbid,@dbname,@spid,@blocked,@cpu,@physical_io,@status,@waittype,@waittime,@waitresource,
            @cmd,@hostname,@program_name,@login_time,@last_batch,@sql_handle,@stmt_start,@stmt_end
    end
    
    close sys_process_cur            
    deallocate sys_process_cur  
    
    
    IF @day = 0
    BEGIN
    
      insert into MONITOR_SYSPROCESS_0
            (reg_dt,lastwaittype, dbname,spid,blocked, cpu, objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd,query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end)
      select reg_dt,lastwaittype, dbname,spid,blocked,cpu,objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd, query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end
      from #monitoring_sysprocess
    END
    ELSE IF @day = 1
    BEGIN
    
      insert into MONITOR_SYSPROCESS_1
           (reg_dt,lastwaittype, dbname,spid,blocked, cpu, objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd,query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end)
      select reg_dt,lastwaittype, dbname,spid,blocked,cpu,objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd, query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end
      from #monitoring_sysprocess
    END
    ELSE IF @day = 2
    BEGIN
    
      insert into MONITOR_SYSPROCESS_2
           (reg_dt,lastwaittype, dbname,spid,blocked, cpu, objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd,query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end)
      select reg_dt,lastwaittype, dbname,spid,blocked,cpu,objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd, query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end
      from #monitoring_sysprocess
    END
    
    ELSE IF @day = 3
    BEGIN
    
      insert into MONITOR_SYSPROCESS_3
              (reg_dt,lastwaittype, dbname,spid,blocked, cpu, objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd,query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end)
      select reg_dt,lastwaittype, dbname,spid,blocked,cpu,objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd, query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end
      from #monitoring_sysprocess
    END
    
    ELSE IF @day = 4
    BEGIN
    
      insert into MONITOR_SYSPROCESS_4
           (reg_dt,lastwaittype, dbname,spid,blocked, cpu, objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd,query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end)
      select reg_dt,lastwaittype, dbname,spid,blocked,cpu,objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd, query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end
      from #monitoring_sysprocess
    END
    
    ELSE IF @day = 5
    BEGIN
    
      insert into MONITOR_SYSPROCESS_5
            (reg_dt,lastwaittype, dbname,spid,blocked, cpu, objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd,query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end)
      select reg_dt,lastwaittype, dbname,spid,blocked,cpu,objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd, query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end
      from #monitoring_sysprocess
    END
    
    ELSE IF @day = 6
    BEGIN
    
      insert into MONITOR_SYSPROCESS_6
           (reg_dt,lastwaittype, dbname,spid,blocked, cpu, objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd,query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end)
      select reg_dt,lastwaittype, dbname,spid,blocked,cpu,objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd, query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end
      from #monitoring_sysprocess
    END
    
    ELSE IF @day = 7
    BEGIN
    
      insert into MONITOR_SYSPROCESS_7
        (reg_dt,lastwaittype, dbname,spid,blocked, cpu, objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd,query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end)
      select reg_dt,lastwaittype, dbname,spid,blocked,cpu,objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd, query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end
      from #monitoring_sysprocess
    END
    
    ELSE IF @day = 8
    BEGIN
    
      insert into MONITOR_SYSPROCESS_8
             (reg_dt,lastwaittype, dbname,spid,blocked, cpu, objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd,query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end)
      select reg_dt,lastwaittype, dbname,spid,blocked,cpu,objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd, query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end
        from #monitoring_sysprocess
    END
    
    ELSE IF @day = 9
    BEGIN
    
      insert into MONITOR_SYSPROCESS_9
       (reg_dt,lastwaittype, dbname,spid,blocked, cpu, objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd,query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end)
      select reg_dt,lastwaittype, dbname,spid,blocked,cpu,objectname,physical_io,status, waittype,waittime,waitresource,
             objectid,cmd, query_text,hostname,program_name,login_time,last_batch,sql_handle, stmt_start,stmt_end
      from #monitoring_sysprocess
    END
    
    if @hour = 7 and (@minute = 20  or @minute = 21)                  
    begin                   
      if @day = 0 truncate table dbo.MONITOR_SYSPROCESS_1             
      if @day = 1 truncate table dbo.MONITOR_SYSPROCESS_2                  
      if @day = 2 truncate table dbo.MONITOR_SYSPROCESS_3                  
      if @day = 3 truncate table dbo.MONITOR_SYSPROCESS_4                  
      if @day = 4 truncate table dbo.MONITOR_SYSPROCESS_5                  
      if @day = 5 truncate table dbo.MONITOR_SYSPROCESS_6                  
      if @day = 6 truncate table dbo.MONITOR_SYSPROCESS_7                  
      if @day = 7 truncate table dbo.MONITOR_SYSPROCESS_8                  
      if @day = 8 truncate table dbo.MONITOR_SYSPROCESS_9                  
      if @day = 9 truncate table dbo.MONITOR_SYSPROCESS_0             
    end    
    
    drop table #monitoring_sysprocess       
END
ELSE IF @type = 1
BEGIN
    
    select 
            lastwaittype, dbid,db_name(dbid) as dbname, spid, blocked, kpid,
            cpu,physical_io, status,
            waittype,waittime, waitresource,
            cmd, CONVERT(VARCHAR(25),hostname) as hostname, program_name,
            'DBCC INPUTBUFFER(' + CAST(SPID AS VARCHAR(5)) + ')'as inputuffer,
            login_time,last_batch
            ,sql_handle
            ,stmt_start,stmt_end
            ,'SELECT * FROM ::fn_get_sql(' as str1 , sql_handle , ')' as str2
    from master..sysprocesses 
    where spid > 50   --and lastwaittype <> 'WAITFOR' and waittype > 0x0000
    order by  cpu desc, kpid desc
END



