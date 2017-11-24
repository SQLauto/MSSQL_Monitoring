/**************************************************************************************************************  
SP    명 : master.dbo.sp_who3
작성정보: 2004-12-13 양은선
관련페이지 :
내용	    : 정원혁 강사님 교육받고...
지난 2초간 가장 CPU를 많이사용한 프로세스를 보여준다.
===============================================================================
				수정정보 
===============================================================================
2006-4-12 박노철 inputbuffer 도 함께 나오도록 수정
**************************************************************************************************************/ 
CREATE proc sp_who4
,@bactive	bit	= 1
as

SET NOCOUNT ON
SET LOCK_TIMEOUT 10000
SET ANSI_WARNINGS OFF

create table #cpu_usage
(
	seq int identity primary key
,	cpu int
,	spid int
,	kpid int
,	inputbuffer varchar(3000)
)

create table #inputbuffer
(
	seq int identity primary key
,	eventtype char(50)
,	parameters int
,	eventinfo varchar(5000)
)

declare @rowcount int
	,	@iid int

set @rowcount = 0
set @iid = 0

insert #cpu_usage (cpu, spid, kpid)
select cpu ,spid, kpid from master..sysprocesses 
where spid > 50

select @rowcount = @@rowcount , @iid = scope_identity()

while(@rowcount > 0) begin
	declare @buf_str varchar(40)
	select @buf_str  = 'dbcc inputbuffer(' + cast(spid as varchar) + ')' from #cpu_usage with(nolock) where seq = @iid

	insert into #inputbuffer (EventType, Parameters, EventInfo)
	exec(@buf_str)

	if(@@rowcount > 0) begin	
		declare @inputbuf varchar(3000)
		select top 1 @inputbuf = substring(eventinfo,1,3000) from #inputbuffer order by seq desc
		update #cpu_usage set inputbuffer = @inputbuf where seq=@iid 
	end

	set @iid = @iid - 1
	set @rowcount = @rowcount - 1	
end	


PRINT 'waiting for 2 seconds...'
WAITFOR DELAY '0:00:02'

IF @bactive = 0 
	SELECT TOP 15 u.inputbuffer AS inputBufferStr, p.spid, p.cpu - u.cpu AS 'CPU변화', p.cpu, p.physical_io, CAST (p.hostname AS VARCHAR(20)) AS hostname
		, p.last_batch, p.program_name,p.loginame 
	FROM master..sysprocesses p JOIN #cpu_usage u ON p.spid = u.spid and p.kpid = u.kpid
	ORDER BY CPU변화 DESC, p.cpu DESC 
ELSE
	SELECT TOP 15 u.inputbuffer  AS inputBufferStr, p.spid, p.cpu - u.cpu AS 'CPU변화', p.cpu, p.physical_io, CAST (p.hostname AS VARCHAR(20)) AS hostname
		, p.last_batch, p.program_name,p.loginame 
	FROM master..sysprocesses p JOIN #cpu_usage u ON p.spid = u.spid and p.kpid = u.kpid
	WHERE p.cpu - u.cpu > 0 
	ORDER BY CPU변화 DESC, p.cpu DESC 
