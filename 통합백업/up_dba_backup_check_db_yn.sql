/*IF EXISTS (SELECT name 
              FROM   sysobjects 
              WHERE  name = N'up_dba_backup_check_db_yn' 
              AND              type = 'P')
    DROP PROCEDURE  procedure_name
*/

/*************************************************************************  
* 프로시저명  : dbo.up_dba_backup_check_db_yn
* 작성정보    : 2007-12-18
* 관련페이지  : 안 지 원   
* 내용        :
* 수정정보    :
--BACKUP_MASTER는 기본정보를 담는다.
--BACKUP_MASTER에 내용이 있는데 BACKUP_DETAIL에 데이터가 없으면 백업 실패 
--SSIS로 보라대리님이 오전 9시에 데이터를 BACKUP_DETAIL에 넣는다
--오전 9시 이후, 9시 30분~ 10시 30분사이에 BACKUP_DETAIL의 등록된 시간(reg_dt)와 가장최근한 백업시간을 조건으로 넣는다.
--이때 데이터가 없으면, 백업 실패
--데이터가 있으면 백업성공
exec dbo.up_dba_backup_check_db_yn '2007-12-14'
--수정사항 1) 날짜입력받기 2) 분으로 고치기
2007-12-28 by choi bo ra, 조인이 필요 없어서 수정
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_backup_check_db_yn
	@todayDate		datetime     
AS
/* COMMON DECLARE */
SET NOCOUNT ON
/* USER DECLARE */
DECLARE @nextdayDate DATETIME
SET @nextdayDate  = DATEADD(dd, 1, @todayDate)

/* BODY */
--DB
SELECT 
       'DOC NAME' AS doc_name
	 , bm.server_name as server_name
	 , bm.database_name	 as db_name 
	 , (CASE bm.backup_flag WHEN 1 THEN 'DB + LOG '
							WHEN 2 THEN 'DB' 
							WHEN 3 THEN 'LOG' 
							ELSE 'TYPE ERROR' END) as backup_type 	
	 , (CASE bm.backup_cycle WHEN 1 THEN 'DAILY'
							 WHEN 2 THEN 'WEEKLY'
							 WHEN 3 THEN 'MONTHLY'
							 ELSE 'CYCLE CASE ERROR' END ) as backup_cycle
	 , bd.name 
	 , bd.backup_diffday  		 
	 , bd.type
	 , (CASE bm.backup_cycle WHEN 1 THEN (CASE WHEN bd.backup_diffday <= bm.backup_day THEN '성공' ELSE '실패' END) 
							 WHEN 2 THEN (CASE WHEN bd.backup_diffday <= bm.backup_day * 7 THEN '성공' ELSE '실패' END) 
							 WHEN 3 THEN (CASE WHEN bd.backup_diffday <= bm.backup_day * 30 THEN '성공' ELSE '실패' END)
							 ELSE 'ERROR' END) as success_flag							
	 , bd.backup_start_date 	 
	 , (DATEDIFF(mi, bd.backup_start_date, bd.backup_finish_date)) as backupTime
	 , bd.physical_device_name
	 , bd.backup_size as [size]
	 ,  bd.reg_dt
FROM backup_master AS bm WITH (NOLOCK)
        INNER JOIN backup_detail AS bd WITH (NOLOCK) ON bm.server_name = bd.server_name AND bm.database_name = bd.database_name 
        
WHERE bd.type = 'FULL BACKUP' AND reg_dt > @todayDate and reg_dt < @nextdayDate  
ORDER BY bm.server_name, bm.database_name, bm.seq_no

IF @@ERROR <> 0 RETURN

RETURN



