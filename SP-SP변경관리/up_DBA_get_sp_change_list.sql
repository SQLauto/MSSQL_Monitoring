/*************************************************************************  
* 프로시저명  : dbo.up_DBA_get_sp_change_list
* 작성정보    : 2007-10-30 김태환
* 관련페이지  :  
* 내용        : 당일 등록/변경 된 SP목록 확인
* 수정정보    : 2009-05 최보라 테이블에 이력 남기지 않고 조회만 처리
* 실행문      : EXEC dbo.up_DBA_get_sp_change_list '2007-10-30'
**************************************************************************/
CREATE PROC dbo.up_DBA_get_sp_change_list
    --@toDay          char(10)            -- 조회 날짜
AS
    set nocount on
    set transaction isolation level read uncommitted

    declare     @stDate     datetime
    declare     @edDate     datetime

    --조회 날짜
    set @stDate = convert(char(10), @toDay, 121) + ' 00:00:00.000'
    set @edDate = convert(char(10), @toDay, 121) + ' 23:59:59.999'

--    INSERT INTO dbo.object_change_hist
--    (
--        sp_nm
--    ,   obj_id
--    ,   schem_id
--    ,   create_dt
--    ,   modify_dt
--    )
    SELECT 
            SCHEMA_NAME(schema_id) + '.' + name as sp_nm
        ,   object_id
        ,   create_date
        ,   modify_date
      FROM tiger.sys.objects with (nolock)
     WHERE ((create_date >= @stDate AND create_date <= @edDate)
        OR (modify_date >= @stDate AND modify_date <= @edDate))
       AND type = 'P'
     ORDER BY create_date ASC, modify_date ASC

    set nocount off

