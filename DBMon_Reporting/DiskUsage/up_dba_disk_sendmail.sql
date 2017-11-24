/*************************************************************************  
* 프로시저명  : dbo.up_dba_disk_sendmail 
* 작성정보    : 2008-01-17
* 관련페이지  : 안지원
* 내용        : 서버별 남은 디스크 용량 받기 
* 수정정보    : exec dbo.up_dba_disk_sendmail 
                2009-04-20 by choi bo ra 레포팅 서비스에서 받을 수 있게 수정
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_disk_sendmail   
    @svr_nm     sysname 
AS
/* COMMON DECLARE */
SET NOCOUNT ON
/* USER DECLARE */




/* 오늘 날짜 입력 */
SELECT SVR_NM, DISK_NM, (FREE_SPACE / 1024) FREE_SPACE
FROM dbo.TB_CHK_DISK WITH(NOLOCK) WHERE 
     ((@SVR_NM  is null AND SVR_NM = SVR_NM ) OR (SVR_NM = @SVR_NM))
    AND  reg_dt = (SELECT MAX(reg_dt) FROM TB_CHK_DISK with(nolock) 
                        WHERE ((@SVR_NM  is null AND SVR_NM = SVR_NM ) OR (SVR_NM = @SVR_NM))) 
ORDER BY SVR_NM, DISK_NM


RETURN
