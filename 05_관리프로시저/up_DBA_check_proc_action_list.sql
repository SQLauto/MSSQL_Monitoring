/*************************************************************************  
* 프로시저명  : dbo.up_DBA_check_proc_action_list 
* 작성정보    : 2007-10-01 김태환
* 관련페이지  :  
* 내용        : 특정 object에 대한 sp별 Action 확인
1. DSCONTR을 사용하는 전체 sp목록

EXEC dbo.up_DBA_check_proc_action_list @obj_nm = 'DSCONTR', @update_flag = 0

2. DSCONTR을 갱신하는 sp목록

EXEC dbo.up_DBA_check_proc_action_list @obj_nm = 'DSCONTR', @update_flag = 1


* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_check_proc_action_list
    @obj_nm         sysname,         -- object name
    @update_flag    tinyint = 0      -- update 여부

AS
    set nocount on
    set transaction isolation level read uncommitted

    declare     @objId      int

    select @objId = id from sys.sysobjects with (nolock) where xtype = 'U' and name = @obj_nm

    IF @update_flag = 1
    BEGIN
        select distinct 
                'name' = (s.name + '.' + o.name),
	            type = substring(v.name, 5, 16),
                case d.selall when 1 then '사용'
                              else '미사용' end as 'SELECT * 사용 여부',
                case d.resultobj when 1 then 'UPDATED'
                                 else 'NOTHING' end as 'UPDATABLE',
                case d.readobj when 1 then 'SELETED'
                               else 'NOTHING' end as 'SELETABLE'
          from sys.objects as o with (nolock)
          inner join master.dbo.spt_values as v with (nolock) on o.type = substring(v.name,1,2) collate database_default and v.type = 'O9T'
          inner join sysdepends as d with (nolock) on o.object_id = d.id
          inner join sys.schemas as s with (nolock) on o.schema_id = s.schema_id
          where d.depid = @objId
	        and deptype < 2
            and d.resultobj = @update_flag
    END
    ELSE
    BEGIN
        select distinct 
                'name' = (s.name + '.' + o.name),
	            type = substring(v.name, 5, 16),
                case d.selall when 1 then '사용'
                              else '미사용' end as 'SELECT * 사용 여부',
                case d.resultobj when 1 then 'UPDATED'
                                 else 'NOTHING' end as 'UPDATABLE',
                case d.readobj when 1 then 'SELETED'
                               else 'NOTHING' end as 'SELETABLE'
          from sys.objects as o with (nolock)
          inner join master.dbo.spt_values as v with (nolock) on o.type = substring(v.name,1,2) collate database_default and v.type = 'O9T'
          inner join sysdepends as d with (nolock) on o.object_id = d.id
          inner join sys.schemas as s with (nolock) on o.schema_id = s.schema_id
          where d.depid = @objId
	        and deptype < 2
    END
    set nocount off