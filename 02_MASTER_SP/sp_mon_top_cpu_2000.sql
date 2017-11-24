use master
go

/*************************************************************************  
* 프로시저명  : dbo.sp_mon_top_cpu 
* 작성정보    : 2010-02-22 by 최보라
* 관련페이지  :  
* 내용        : 2초간 CPU 높은 쿼리
* 수정정보    :
**************************************************************************/
ALTER PROCEDURE dbo.sp_mon_top_cpu
    @delay_time datetime  = '00:00:02'
AS
BEGIN
/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
SET LOCK_TIMEOUT 10000

/* USER DECLARE */
DECLARE @rowcount int
	,	@seq int, @spid int
DECLARE @sql_handle  binary(20)          
DECLARE @stmt_start  int,  @stmt_end  int          
DECLARE @dbid   int          
DECLARE @objectid  int        
DECLARE @eventinfo2  varchar(4000)          
DECLARE @object_query varchar(100)  
	
create table #tmp_requests
(
	seq int identity primary key
,	session_id int
,	cpu_time int
,	host_process_id int
--,   sql_handle binary(20)
--,	stmt_start int       
--,   stmt_end  int    
)


create table #requests
(
	seq int identity primary key
,	session_id int
,	db_name  nvarchar(128)
,	object_name nvarchar(128)
,	status  nvarchar(30)
,	wait_time bigint
,	last_wait_type nvarchar(32)
,	wait_type binary(2)
,	cpu_time int
,	host_process_id int
,	login_name nvarchar(128)
,	host_name nvarchar(20)
,   program_name nvarchar(128)
,   physical_io int
,   last_batch datetime
,   sql_handle binary(20)
,	stmt_start int       
,   stmt_end  int    
)


CREATE TABLE  #sp_who_object          
(          
 seqno  smallint primary key,          
 spid  smallint,           
 dbname  varchar(30),          
 objectname varchar(128)          
)  


DECLARE @sp_who_event TABLE     
(seqno smallint primary key,    
 spid smallint,    
 dbid smallint,    
 objectid int,    
 eventinfo2 varchar(4000)    
)    

-- insert sys.dm_exec_requests into temp table !
insert #tmp_requests (session_id, cpu_time, host_process_id )--, sql_handle,stmt_start, stmt_end )
select spid, cpu, kpid --, sql_handle, stmt_start, stmt_end
from master..sysprocesses  with (nolock)
where spid > 50  

-- delay with parameter
WAITFOR DELAY @delay_time


INSERT #requests ( session_id,host_process_id, cpu_time, status, wait_time, last_wait_type, wait_type,
	login_name, physical_io, host_name, last_batch, program_name, sql_handle, stmt_start,stmt_end)
SELECT 
       p.spid
      ,p.kpid
      ,p.cpu 
      ,p.status
      ,p.waittime 
      ,p.lastwaittype 
      ,p.waittype 
      ,p.loginame 
      ,p.physical_io
      ,CAST (p.hostname AS NVARCHAR(20)) 
      ,p.last_batch
      ,p.program_name
      ,sql_handle
      ,stmt_start
      ,stmt_end
FROM master..sysprocesses p  where ecid = 0  and kpid > 0

select @rowcount = @@rowcount ,  @seq = 1  

while(@rowcount >= @seq) 
begin
    
    SELECT @spid = session_id, @sql_handle = sql_handle, @stmt_start = stmt_start, @stmt_end = stmt_end 
    FROM #requests     
    WHERE seq = @seq    

     IF @@ROWCOUNT > 0    
     BEGIN    

         INSERT @sp_who_event (seqno, spid, dbid, objectid,  eventinfo2)    
         SELECT @seq, @spid, dbid, objectid, replace(substring(replace(convert(varchar(4000), text), ' ', '~')
               , (@stmt_start + 2) / 2, case @stmt_end when -1 then (datalength(text)) else (@stmt_end - @stmt_start + 2) / 2 end), '~', ' ')      
         FROM ::fn_get_sql(@sql_handle)    
        
     END    
    	
	 SET @seq = @seq + 1  
end


SET @seq = 1    
    
-- db_id 와 object_id 로 부터 object_name 을 얻음    
WHILE @seq <= @rowcount   
BEGIN    
    
 SELECT @dbid = dbid, @objectid = objectid 
 FROM @sp_who_event 
 WHERE seqno = @seq 
 AND dbid IS NOT NULL    
    
 IF @@ROWCOUNT > 0    
 BEGIN    
    
  SET @object_query = 'SELECT ' + CONVERT(nvarchar, @seq) + ', ''' 
                    + db_name(@dbid) + ''', name FROM ' + db_name(@dbid) 
                    + '.dbo.sysobjects with (nolock) where id = ' + CONVERT(nvarchar, @objectid)          
    
  INSERT #sp_who_object(seqno, dbname, objectname)    
  EXEC (@object_query)    
    
 END    
    
 SET @seq = @seq + 1    
    
END    	
	


SELECT top 100
       u.session_id
      ,o.dbname as db_name, o.objectname as object_name
      ,(p.cpu_time - u.cpu_time) as cpu_gap
      ,p.cpu_time
      ,p.status
      ,p.wait_time
      ,p.last_wait_type
      ,p. wait_type
      ,p.login_name
      ,p.physical_io
      ,p.host_name
      ,p.last_batch
      ,p.program_name
FROM #requests p 
     JOIN #tmp_requests u ON p.session_id = u.session_id and p.host_process_id = u.host_process_id
    LEFT JOIN @sp_who_event e on p.seq = e.seqno
    LEFT JOIN #sp_who_object o with (nolock) on p.seq = o.seqno 
ORDER BY cpu_gap DESC, p.cpu_time DESC 



drop table #tmp_requests
drop table #requests
drop table #sp_who_object
END

