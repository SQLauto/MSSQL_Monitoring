
/*************************************************************************  
* 프로시저명  : dbo.up_dba_report_table_size_hist
* 작성정보    : 2010-03-26 by choi bo ra
* 관련페이지  : 
* 내용        : table_size history 정보
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_report_table_size_hist
	@server_id		int,
	@instance_id  int,
	@db_id				int  , 
	@object_id	  int = 0
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @get_from_dt    datetime
DECLARE @get_to_dt      datetime

/* BODY */
SET @get_from_dt = convert(datetime,convert(nvarchar(10), dateadd(m, -1,getdate()) , 121) )
SET @get_to_dt = convert(datetime,convert(nvarchar(10), getdate() + 1, 121) )

if @object_id = 0 
begin
    select reg_dt, sum(row_count) as tot_row_count, sum(reserved) as tot_reserved
    from dbo.VW_TABLE_BASE with (nolock)
    where server_id = @server_id and instance_id = @instance_id 
        and ((@db_id = 0 and db_id = db_id ) or (db_id = @db_id))
        and reg_dt >= @get_from_dt and reg_dt < @get_to_dt
    group by reg_dt
    
 
end
else
begin
    select reg_dt, row_count as tot_row_count, reserved as tot_reserved
    from dbo.VW_TABLE_BASE with (nolock)
    where server_id = @server_id and instance_id = @instance_id 
        and ((@db_id = 0 and db_id = db_id ) or (db_id = @db_id))
        and reg_dt >= @get_from_dt and reg_dt < @get_to_dt
        and object_id = @object_id
end

RETURN


