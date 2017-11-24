
/*************************************************************************  
* 프로시저명  : dbo.up_dba_table_size_info_term 
* 작성정보    : 2010-03-24 by choi bo ra
* 관련페이지  :  
* 내용        : 테이블 사이즈 증가량 summary
* 수정정보    :
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_table_size_info_term

AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @from_dt datetime, @to_dt datetime
declare @from_dt_w datetime, @to_dt_w datetime
declare @from_dt_m datetime, @to_dt_m datetime
declare @from_dt_d datetime, @to_dt_d datetime
set @from_dt  = convert(datetime, (convert(nvarchar(10), getdate(), 112)))
set @to_dt  = convert(datetime, (convert(nvarchar(10), getdate()+1, 112)))
set @from_dt_d  = convert(datetime, (convert(nvarchar(10), getdate()-1, 112)))
set @to_dt_d  = convert(datetime, (convert(nvarchar(10), getdate(), 112)))
set @from_dt_w  = convert(datetime, (convert(nvarchar(10), dateadd(week, -1,getdate()), 112)))
set @to_dt_w  = convert(datetime, (convert(nvarchar(10), dateadd(week, -1,getdate()+1), 112)))

/* BODY */

--select @from_dt, @to_dt, @from_dt_w, @to_dt_w, @from_dt_d, @to_dt_d

DELETE TABLE_SIZE_INFO_TERM WHERE reg_dt >= @from_dt and reg_dt < @to_dt


insert into dbo.TABLE_SIZE_INFO_TERM
(  reg_dt, seq, schema_name, object_id, table_name,
   row_count, row_count_day, row_count_week, row_count_m,
   reserved, reserved_day, reserved_week, reserved_m,
   data, data_day, data_week, data_m,
   index_size, index_size_day, index_size_week, index_size_m,
   unused, unused_day, unused_week, unused_m, 
   avg_row_day, avg_reserved_day)

select t.reg_dt,  t.seq,
     t.schema_name, t.object_id, t.table_name,
     t.row_count, isnull(d.row_count,0) as row_count_day, isnull(w.row_count,0) as row_count_week, isnull(m.row_count,0) as row_count_mon,
     t.reserved, isnull(d.reserved,0) as reserved_day, isnull(w.reserved,0) as reserved_week, isnull(m.reserved,0) as reserved_mon,
     t.data, isnull(d.data,0) as data_day, isnull(w.data,0) as data_week, isnull(m.data,0) as data_mon,
     t.index_size, isnull(d.index_size,0) as index_size_d,isnull(w.index_size,0) as index_size_week,isnull(m.index_size,0) as index_size_mon,
     t.unused, isnull(d.unused,0) as unused_d,isnull(w.unused,0) as unused_w,isnull(m.unused,0) as unused_m,
     case when (w.row_count != 0) then (t.row_count - isnull(w.row_count,0)) / 7 else 0  end as avg_row_day,
     case when (w.reserved !=0) then (t.reserved - isnull(w.reserved,0)) /7  else 0  end as avg_reserved_day
from table_size_info as t with (nolock)
    left join (select * from table_size_info  with (nolock) 
            where reg_dt>=@from_dt_d and reg_dt < @to_dt_d) as d
        on t.seq = d.seq and t.object_id = d.object_id 
            and t.schema_name = d.schema_name
            and t.object_id = d.object_id
    left join (select * from table_size_info  with (nolock) 
            where reg_dt>=@from_dt_w and reg_dt < @to_dt_w) as w
      on t.seq = d.seq and t.object_id = d.object_id 
            and t.schema_name = d.schema_name
            and t.object_id = d.object_id
    left join (select * from table_size_info  with (nolock) 
            where reg_dt>=@from_dt_m and reg_dt < @to_dt_m) as m
        on t.seq = d.seq and t.object_id = d.object_id 
            and t.schema_name = d.schema_name
            and t.object_id = d.object_id
where t.reg_dt >= @from_dt and t.reg_dt < @to_dt
order by t.seq, t.row_count desc


RETURN