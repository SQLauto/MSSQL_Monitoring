
/************************************************************************  
* 프로시저명  : dbo.up_DBA_get_Logshipping_list 
* 작성정보    : 2007-08-24 김태환
* 관련페이지  :  
* 내용        : 로그쉬핑리스트 조회
* 수정정보    : 
* 실행        : exec dbo.up_DBA_get_Logshipping_list @user_db_name = 'TIGER', @reg_dt = '2007-08-27'
**************************************************************************/
--DROP PROCEDURE dbo.up_DBA_get_Logshipping_list

CREATE PROCEDURE dbo.up_DBA_get_Logshipping_list
    @user_db_name       varchar(20)='TIGER'     -- User DB명
,   @reg_dt             char(10)                -- 등록일자
AS
    set nocount on
    set transaction isolation level read uncommitted

    declare @start_dt   datetime    -- 시작일자
    declare @end_dt     datetime    -- 종료일자

    set @start_dt = @reg_dt + ' 00:00:00.000'
    set @end_dt = @reg_dt + ' 23:59:59.999'

    select
            seq_no
    ,       case backup_no when 0 then 'LiteSpeed'
                           when 1 then 'Native'
            end as backup_no
    ,       log_file
    ,       case copy_flag when 0 then ''
                              else '완료' end
    ,       copy_end_time
--    ,       restore_type
    ,       case restore_flag when 0 then ''
                              else '완료' end
    ,       restore_start_time
    ,       restore_end_time
    ,       restore_duration
    ,       case delete_flag when 0 then ''
                              else '완료' end
    ,       delete_time
    ,       error_code
    ,       reg_dt 
    from logshipping_restore_list with (nolock)
    where user_db_name = @user_db_name
      and reg_dt >= @start_dt
      and reg_dt <= @end_dt
    order by reg_dt desc

    set nocount off




