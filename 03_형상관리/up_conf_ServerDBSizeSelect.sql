use admin
go

/*************************************************************************  
* 프로시저명  : dbo.up_conf_ServerDBSizeSelect
* 작성정보    : 2010-09-30 by 서버의 Disk 추이
* 관련페이지  : 
* 내용        : 
* 수정정보    :
**************************************************************************/
ALTER PROCEDURE dbo.up_conf_ServerDBSizeSelect
    @server_id      int,
    @db_name        sysname = NULL, 
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


CREATE TABLE #DATABASE_Size
( db_id int, file_id int,  avg_day_usage numeric(10,2), avg_day_size numeric(10,2),autogrowth_cnt int  )

INSERT INTO #DATABASE_Size
select  a.DB_ID,a.file_id       
       , sum(a.usage - b.usage) / datediff(dd,DATEADD(m, -1, @base_date), @base_date) as avg_day_usage
       , sum(a.size  - b.size ) /datediff(dd,DATEADD(m, -1, @base_date), @base_date)  as avg_day_size
       , case when sum(a.size  - b.size ) != 0 then sum(a.size  - b.size ) / max(a.growth) else 0 end as autogrowth_cnt
from DATABASE_FILE_LIST  as a  with (nolock)
    join DATABASE_FILE_LIST as b with (nolock) on a.server_id = b.server_id and a.db_id = b.db_id and a.file_id = b.file_id
         and  a.reg_dt = dateadd(dd, 1, b.reg_dt)
where a.server_id = @server_id
    and a.reg_dt >= DATEADD(m, -1, @base_date) and a.reg_dt < DATEADD(d, 1, @base_date)
group by a.db_id, a.name, a.file_id

    

SELECT  dbo.get_svrnm(f.server_id) as server_name,f.reg_dt, f.DB_ID, d.db_name, d.status,
        case when d.is_auto_shrink_on  = 1 then 'true' else  'false' end as '자동축소',
        case when d.is_auto_update_stats_on  = 1 then 'true' else  'false' end as '통계갱신',
        f.filegroup,f.file_id,f.name, left(f.file_full_name, 1) as letter, f.file_full_name,
        f.size,usage, (f.size-f.usage) as free, f.growth,f.max_size,
        h.avg_day_usage, h.avg_day_size, h.autogrowth_cnt
FROM DATABASE_FILE_LIST  as f with (nolock)
    join DATABASE_LIST as d with (nolock) on f.server_id = d.server_id  and f.db_id = d.db_id
    join #DATABASE_Size as h  on h.db_id = d.db_id  and h.file_id = f.file_id     
WHERE f.server_id = @server_id  and d.db_name =case when @db_name is null then d.db_name else  @db_name end
    and f.reg_dt = @base_date and d.reg_dt = @base_date
ORDER by f.db_id, f.filegroup, f.file_id

drop table #DATABASE_Size

RETURN
