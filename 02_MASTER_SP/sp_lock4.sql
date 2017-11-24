CREATE PROCEDURE sp_lock4 AS
set nocount on

DECLARE @tSpids table(spid int PRIMARY KEY CLUSTERED,count int)
DECLARE @iSpid int,@iCount int

insert into @tSpids (spid,count)
select convert (smallint, req_spid) As spid,
count(*) as count

from master.dbo.syslockinfo,
master.dbo.spt_values v,
master.dbo.spt_values x,
master.dbo.spt_values u

where master.dbo.syslockinfo.rsc_type = v.number
and v.type = 'LR'
and master.dbo.syslockinfo.req_status = x.number
and x.type = 'LS'
and master.dbo.syslockinfo.req_mode + 1 = u.number
and u.type = 'L'
group by converT(smallint,req_spid),'dbcc inputbuffer(' + cast(req_spid as varchar(4)) + ')'
having count(*)>10
order by count(*) desc

DECLARE cLoop cursor for 
select spid,count from @tSpids

OPEN cLoop

FETCH NEXT FROM cLoop INTO @iSpid,@iCount
WHILE @@FETCH_STATUS=0
BEGIN
select 'spid ' + cast(@iSpid as varchar(4)) + ' has ' + cast(@iCount as varchar(5)) + ' locks.'
exec ('dbcc inputbuffer (' + @ispid + ')')
FETCH NEXT FROM cLoop INTO @iSpid,@iCount
END

CLOSE cLoop
DEALLOCATE cLoop 

return (0) -- sp_lock
GO
