/*************************************************************************  
* 프로시저명  : dbo.up_dba_disk_select_info 
* 작성정보    : 2008-01-21
* 관련페이지  : 안지원  
* 내용        :
* 수정정보    : 
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_disk_select_info 
    @svr_nm     sysname   
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @fromdate datetime
DECLARE @todate datetime
SET @todate = CONVERT(char(10), DATEADD(day, 1, GETDATE()), 121)
SET @fromdate = DATEADD(day,-7, @todate)

/* BODY */

SELECT 
	SEQ_NO,
	tb.SVR_NM,
	tb.DISK_NM,
	convert(numeric(15,2), (convert(int,FREE_SPACE) /1024.00)) FREE_SPACE,
    convert(int,( 1- (convert(numeric(15,2),tb.FREE_SPACE) / sl.CAPACITY )) * 100) as USE_RATE,
	convert(char(10),tb.REG_DT, 120) as REG_DT
FROM dbo.TB_CHK_DISK AS tb WITH(NOLOCK)  
    JOIN SQL_SERVER_LIST AS sd WITH(NOLOCK) ON tb.svr_nm = sd.server_name
    JOIN SERVER_DISK AS sl WITH(NOLOCK) ON sd.svr_id = sl.svr_id  and tb.disk_nm = sl.DRV_LETTER
WHERE tb.REG_DT > @fromdate
    AND tb.REG_DT <= @todate
    AND ((@SVR_NM  is null AND tb.SVR_NM = SVR_NM ) OR (tb.SVR_NM = @SVR_NM))
ORDER BY tb.REG_DT ASC, tb.DISK_NM ASC
RETURN
