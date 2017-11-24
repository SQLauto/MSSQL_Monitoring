/*************************************************************************          
* 프로시저명  : DBO.UP_DBA_TRANSINFO_SELECT
* 작성정보    : 2014-06-02 BY JUNYONG
* 관련페이지  : UP_DBA_TRANSINFO_SELECT     
* 내용        : SERVER별 RETENTION 정보 수집     
* 수정정보    :   [UP_DBA_TRANSINFO_SELECT] 1    
			  2014-09-25 by choi bo ra 컬럼에 맞게 수정
**************************************************************************/        
ALTER PROCEDURE [UP_DBA_TRANSINFO_SELECT]
    @SERVER_ID          INT
AS        
/* COMMON DECLARE */        
SET NOCOUNT ON        
SET FMTONLY OFF        
             
  
        
SELECT @SERVER_ID AS SERVER_ID,
		DB_NAME,
		TABLE_NAME,
		CASE WHEN TO_DB_NAME IS NULL  OR TO_DB_NAME = '' THEN NULL  ELSE @SERVER_ID END AS TO_SERVER_ID,
		CASE WHEN TO_DB_NAME IS NULL OR TO_DB_NAME  ='' THEN NULL  ELSE TO_DB_NAME END AS TO_DB_NAME,
		CASE WHEN TO_TABLE_NAME IS NULL OR TO_TABLE_NAME  ='' THEN NULL  ELSE TO_TABLE_NAME END AS TO_TABLE_NAME,
		'Y' AS USE_YN,  --- 로컬 이관 정책의 경우 모두 사용
		TRANS_TYPE AS WORK_TYPE,
		'D' AS PERIOD_TYPE,  -- 로컬 이관정책은 모두 일 처리
		TERM AS PERIOD, 
		STR_COLUMN AS TRANS_COLUMN , 
		STR_WHERE AS TRANS_WHERE_STR, 
		'N' AS PARTITION_YN, 
		'N' AS SSIS_YN, 
		CONVERT(NVARCHAR(500), COMMENT ) AS JOB_NAME, 
		convert(nvarchar(100), MANUAL_SP) AS SP_NAME, 
		convert(nvarchar(500),COMMENT) AS COMMENT, 
		UPD_DATE AS REG_DT, 
		UPD_DATE AS CHG_DT, 
		'DB_JOB' AS REG_ID, 
		'DB_JOB' AS CHG_ID,
		 0 AS P_TRANS_SEQ_NO,
		'Y' AS LOCAL_JOB_YN	
FROM  DBO.TRANS_BASIC_MASTER (NOLOCK)
ORDER BY DB_NAME, TABLE_NAME
                               
            
           
RETURN 
