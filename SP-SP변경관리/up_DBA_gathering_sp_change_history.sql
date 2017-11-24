/*************************************************************************  
* 프로시저명  : dbo.up_DBA_gathering_sp_change_history
* 작성정보    : 2007-10-30 김태환
* 관련페이지  :  
* 내용        : 당일 등록/변경 되는 sp 목록 수집
* 수정정보    : 2009-05 최보라 조회용 DB에서 실행되게 변경, 쿼리 변경
* 실행문      : EXEC dbo.up_DBA_gathering_sp_change_history
**************************************************************************/
CREATE PROC dbo.up_DBA_gathering_sp_change_history
AS
    set nocount on
    set transaction isolation level read uncommitted

    declare     @stDate     datetime
    declare     @edDate     datetime

    --전날 기준으로 변경된 sp만 추출
    set @stDate = convert(char(10), getdate(), 121) + ' 00:00:00.000'
    set @edDate = convert(char(10), getdate(), 121) + ' 23:59:59.999'

    INSERT INTO dbo.object_change_hist
    (
        sp_nm
    ,   obj_id
    ,   schem_id
    ,   create_dt
    ,   modify_dt
    )
    SELECT 
            name
        ,   object_id
        ,   schema_id
        ,   create_date
        ,   modify_date
      FROM tiger.sys.objects with (nolock)
     WHERE ((create_date >= @stDate AND create_date <= @edDate)
        OR (modify_date >= @stDate AND modify_date <= @edDate))
       AND type = 'P'
     ORDER BY create_date asc, modify_date asc

    set nocount off