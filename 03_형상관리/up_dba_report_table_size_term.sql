
/*************************************************************************  
* 프로시저명  : dbo.up_dba_report_table_size_term
* 작성정보    : 2010-03-26 by choi bo ra
* 관련페이지  : 
* 내용        : 테이블 사이즈 report
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_report_table_size_term 
	@server_id		int,
	@instance_id  int,
	@db_id				int  = 0, 
	@from_dt			date,
	@base_dt				date
	
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

DECLARE @get_from_dt    date
DECLARE @get_to_dt      date
DECLARE @get_base_from_dt date
DECLARE @get_base_to_dt		date

/* BODY */
IF @from_dt is null 
BEGIN
    SET @get_from_dt = convert(datetime,convert(nvarchar(10), getdate() , 121) )
    SET @get_to_dt = convert(datetime,convert(nvarchar(10), dateadd(dd,1,getdate()), 121) )
    
END
ELSE
BEGIN
	SET @get_from_dt = convert(datetime,convert(nvarchar(10), @from_dt , 121) )
  SET @get_to_dt = convert(datetime,convert(nvarchar(10), dateadd(dd,1,@from_dt), 121) )
   
END


set @get_base_from_dt  = @base_dt
set @get_base_to_dt  = convert(datetime, (convert(nvarchar(10), dateadd(d,1,@base_dt), 112)))


--select @get_from_dt,@get_to_dt



select t.reg_dt, t.db_id, db.db_name,t.table_id,
     t.schema_name, t.object_id, t.table_name,
     t.row_count,
     isnull(b.row_count,0) as row_count_base, 
     t.reserved, isnull(b.reserved,0) as reserved_base,
     t.data, isnull(b.data,0) as data_base, 
     t.index_size, isnull(b.index_size,0) as index_size_base,
     t.unused, isnull(b.unused,0) as unused_base,
     a.avg_row_day,
     a.avg_reserved_day
from VW_TABLE_BASE as t with (nolock)
    INNER JOIN 
        (
            select t.server_id, t.instance_id ,t.db_id ,t.object_id, t.table_id,
                SUM(t.row_count ) / datediff(d, dateadd(m, -1, @get_from_dt), @get_to_dt ) as avg_row_day, 
                SUM(t.reserved ) /datediff(d, dateadd(m, -1, @get_from_dt), @get_to_dt )  as avg_reserved_day
            from VW_TABLE_BASE as t with (nolock)
            where reg_dt >= dateadd(m, -1,@get_from_dt) and reg_dt <  @get_to_dt
            group by t.server_id, t.instance_id , t.db_id , t.object_id , t.table_id
         ) AS A on t.table_id = A.table_id
    left join (select * from VW_TABLE_BASE  with (nolock) 
            where reg_dt>=@get_base_from_dt and reg_dt < @get_base_to_dt) as b
        on t.table_id = b.table_id
    INNER JOIN 
    	(select distinct server_id, instance_id, db_id, db_name from database_list with(nolock) ) db
    	on t.server_id = db.server_id and t.instance_id = db.instance_id and t.db_id = db.db_id
where t.reg_dt >= @get_from_dt and t.reg_dt < @get_to_dt
		and t.server_id = @server_id and t.instance_id = @instance_id
		and ((@db_id = 0 and t.db_id = t.db_id) or (t.db_id = @db_id))
order by t.server_id, t.db_id,t.row_count desc

