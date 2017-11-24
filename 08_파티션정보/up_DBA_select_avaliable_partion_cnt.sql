/*************************************************************************  
* 프로시저명  : dbo.up_DBA_select_avaliable_partion_cnt
* 작성정보    : 2008-01-02 김태환
* 관련페이지  :  
* 내용        : DB별 파티션별 여유 파티션 개수
* 수정정보    : 
**************************************************************************/
CREATE PROC dbo.up_DBA_select_avaliable_partion_cnt
AS
    set nocount on
    set transaction isolation level read uncommitted

    SELECT db_name, name, count(*)
      FROM dbo.PARTITION_TABLE_INFO WITH (NOLOCK)
     WHERE rows = 0
       AND range is not null
     GROUP BY db_name, name
     ORDER BY db_name, name

    set nocount off
