/*IF EXISTS (SELECT name 
              FROM   sysobjects 
              WHERE  name = N'up_DBA_backup_dbmon_check_db_yn' 
              AND              type = 'P')
    DROP PROCEDURE  procedure_name
*/

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_backup_dbmon_check_db_yn
* 작성정보    : 2007-12-29
* 관련페이지  : 안 지 원   
* 내용        : 웹페이지에서 사용하는 프로시저 
* 수정정보    : exec dbo.up_DBA_backup_dbmon_check_db_yn '2007-12-25','2007-12-30', 'FULL BACKUP', 'ACCOUNTDB', ''
**************************************************************************/
CREATE PROCEDURE [dbo].[up_DBA_backup_dbmon_check_db_yn]
		@fromDayDate		datetime			--시작날짜입력
	,	@todayDate			datetime			--끝 날짜입력
	,	@strType			nvarchar(20)		--FULL BACKUP/LOG BACKUP
	,	@strSvrNm			nvarchar(30)		--서버명
	,	@strDbNm			nvarchar(30)		--DB명 
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @nextdayDate DATETIME
SET @nextdayDate  = DATEADD(dd, 1, @fromDayDate)

/*
조회 끝날짜를 입력 안받았다면 다음날로 세팅
*/
IF @todayDate = @fromDayDate
BEGIN
   SET @todayDate = @nextdayDate
END 

SELECT 
		bd.reg_dt		
	,	bm.server_name as server_name
	,	bm.database_name    as db_name 	
	,	(CASE bm.backup_flag WHEN 1 THEN 'DB + LOG '
						 WHEN 2 THEN 'DB' 
						 WHEN 3 THEN 'LOG' 
		ELSE 'TYPE ERROR' END) as backup_type         
	,   (CASE bm.backup_cycle WHEN 1 THEN 'DAILY'
						  WHEN 2 THEN 'WEEKLY'
						  WHEN 3 THEN 'MONTHLY'
		ELSE 'CYCLE CASE ERROR' END ) as backup_cycle
	,	ISNULL(bd.backup_diffday, -1) as backup_diffday          
	,	(CASE bd.type WHEN 'FULL BACKUP' THEN 'FULL'
					  WHEN 'LOG BACKUP'  THEN 'LOG'
		ELSE '기타'	END) as type	
	,	( CASE bd.type WHEN 'LOG BACKUP' THEN  CASE WHEN bd.backup_diffday  <= 6 THEN '성공' ELSE '실패' END
	                   WHEN 'FULL BACKUP' THEN 
	                            CASE bm.backup_cycle WHEN 1 THEN (CASE WHEN bd.backup_diffday <= bm.backup_day THEN '성공' ELSE '실패' END) 
            					WHEN 2 THEN (CASE WHEN bd.backup_diffday <= bm.backup_day * 7 THEN '성공' ELSE '실패' END) 
            					WHEN 3 THEN (CASE WHEN bd.backup_diffday <= bm.backup_day * 30 THEN '성공' ELSE '실패' END)
		                        ELSE 'ERROR' END
		  END ) as success_flag                                                  
	,	ISNULL(bd.backup_start_date, 0) as backup_start_date
	,	ISNULL((DATEDIFF(mi, bd.backup_start_date, bd.backup_finish_date)),-1) as backupTime
	,   ISNULL(bd.backup_size, '0 MB') as [size]
	,	bd.seq_no  
	,	(CASE bm.backup_type WHEN 1 THEN 'Online 백업'
							 WHEN 2 THEN 'File 백업'
		 ELSE '기타' END ) as backup_type
FROM backup_master AS bm WITH (NOLOCK)
INNER JOIN backup_detail AS bd WITH (NOLOCK) ON bm.server_name = bd.server_name AND bm.database_name = bd.database_name 
WHERE reg_dt >= @fromDayDate and reg_dt < @todayDate
AND (( @strType ='' AND bd.type = bd.type) OR bd.type = @strType)
AND (( @strSvrNm ='' AND bm.server_name = bm.server_name) OR bm.server_name = @strSvrNm)
AND (( @strDbNm ='' AND bm.database_name = bm.database_name) OR bm.database_name = @strDbNm)
ORDER BY bd.reg_dt , bm.server_name, bm.database_name, bm.seq_no

IF @@ERROR <> 0 RETURN
RETURN

