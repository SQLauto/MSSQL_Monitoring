/*************************************************************************  
* 프로시저명  : dbo.up_DBA_get_syscache_stats_list_date
* 작성정보    : 2007-11-06 안지원
* 관련페이지  :  
* 내용        : 수집된 일자 확인
* 수정정보    : 
* 실행문      : EXEC dbo.up_DBA_get_sp_change_recent_list_date '2007-10-30'
**************************************************************************/
CREATE PROC dbo.up_DBA_get_syscache_stats_list_date
AS
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    SELECT DISTINCT convert(char(10), reg_dt, 121) as date_list
    FROM dbo. SYSCACHE_EXEC_STATS with (nolock)
    WHERE reg_dt <> ''
    ORDER BY date_list DESC

    SET NOCOUNT OFF


