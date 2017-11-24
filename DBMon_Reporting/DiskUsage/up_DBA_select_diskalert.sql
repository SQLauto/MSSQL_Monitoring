/*************************************************************************  
* 프로시저명  : dbo.up_DBA_select_diskalert 
* 작성정보    : 2008-01-14 by 안지원
* 관련페이지  : 오늘 수집된 디스크 정보 중 가장 최신 정보 SELECT  
* 내용        :
* 수정정보    : 2008-01-17 by choi bo ra , 최신 버전을 가져오게 하기
**************************************************************************/
CREATE  PROCEDURE dbo.up_DBA_select_diskalert   
   
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT 
		--seqno	,	
		server_nm
	,	Drive
	,	FreeMb
	,   log_time
FROM freedisk_hist WITH (NOLOCK)
WHERE log_time >= (SELECT MAX(log_time) FROM freedisk_hist with (nolock))
    --AND server_nm in ('ACCOUNTDB1' , 'ADMINDB1', 'ADMINDB2') and Drive not in ('E', 'F', 'G','H', 'I')

RETURN


