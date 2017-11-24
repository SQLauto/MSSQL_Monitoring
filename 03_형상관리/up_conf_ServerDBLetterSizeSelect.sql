use admin
go

/*************************************************************************  
* 프로시저명  : dbo.up_conf_ServerDBLetterSizeSelect
* 작성정보    : 2010-09-30 by 디스크별 DB Size
* 관련페이지  : 
* 내용        : 
* 수정정보    : exec up_conf_ServerDBLetterSizeSelect 12, 'Q'
**************************************************************************/
ALTER PROCEDURE dbo.up_conf_ServerDBLetterSizeSelect
    @server_id      int,
    @letter         char(1) = NULL,
    @base_date      datetime = NULL
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @days int

/* BODY */
IF @base_date IS  NULL
   SELECT @base_date = MAX(reg_dt ) from DATABASE_FILE_LIST  with (nolock)
   WHERE server_id = @server_id 
    
ELSE
BEGIN
   SELECT @base_date = MAX(reg_dt ) from DATABASE_FILE_LIST  with (nolock)
   WHERE server_id = @server_id and reg_dt <= @base_date
END

SELECT @days = DATEDIFF(d, DATEADD(m, -1, @base_date), DATEADD(d, 1, @base_date))

CREATE TABLE #DiskDBSize
( letter char(1),  avg_day_usage numeric(10,2), avg_day_size numeric(10,2)  )
    

INSERT #DiskDBSize
select  upper(left(a.file_full_name ,1)) as letter
       , SUM(a.usage -  b.usage)  / @days as avg_day_usage
        ,SUM(a.size-b.size) / @days as avg_day_size
from DATABASE_FILE_LIST  as a  with (nolock)
    join DATABASE_FILE_LIST as b with (nolock) on a.server_id = b.server_id and a.db_id = b.db_id and a.file_id = b.file_id
         and  a.reg_dt = dateadd(dd, 1, b.reg_dt)
where a.server_id = @server_id  and b.server_id = @server_id
    and a.reg_dt >= DATEADD(m, -1, @base_date) and a.reg_dt < DATEADD(d, 1, @base_date)
    and b.reg_dt >= DATEADD(m, -1, @base_date) and b.reg_dt < DATEADD(d, 1, @base_date)
and upper(left(a.file_full_name ,1))  = case when @letter is null then upper(left(a.file_full_name ,1)) else @letter end
group by upper(left(a.file_full_name ,1)) 




SELECT  dbo.get_svrnm(f.server_id) as server_name,f.reg_dt, 
        f.DB_ID, d.db_name, 
        f.filegroup,f.file_id,f.name, UPPER(left(f.file_full_name, 1)) as letter, h.avg_day_usage, h.avg_day_size,
        ('..' + RIGHT(f.file_full_name, 20)) as  file_full_name,
        f.size,usage, (f.size-f.usage) as free, f.growth,f.max_size
FROM DATABASE_FILE_LIST  as f with (nolock)
    join DATABASE_LIST as d with (nolock) on f.server_id = d.server_id  and f.db_id = d.db_id
    join #DiskDBSize as h  on h.letter = left(f.file_full_name, 1)
WHERE f.server_id = @server_id  and d.server_id = @server_id
    and f.reg_dt = @base_date and d.reg_dt = @base_date
    and upper(left(a.file_full_name ,1))  = case when @letter is null then upper(left(a.file_full_name ,1)) else @letter end
ORDER by left(f.file_full_name, 1), f.db_id, f.size desc, f.file_id


drop table #DiskDBSize

RETURN
