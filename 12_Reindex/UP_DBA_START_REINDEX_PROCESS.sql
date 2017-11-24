/*****************************************************************************************************************   
. 작 성 자: 전세환   
. 작 성 일: 2015-02-02   
. 유지보수: GmarketDBA팀 전세환   
. 기능구분: REINDEX 작업 Start
. 실행예제    
  - exec UP_DBA_START_REINDEX_PROCESS 
*****************************************************************************************************************   
변경내역:   
        수정일자        수정구분        수정자        수정내용   
==========================================================================   
       2015-02-02                    전세환        신규생성 
*****************************************************************************************************************/   
CREATE PROCEDURE dbo.UP_DBA_START_REINDEX_PROCESS

AS
BEGIN
	SET NOCOUNT ON
	
	
IF not exists( 
	SELECT top 1 sj.name
	FROM msdb.dbo.sysjobactivity AS sja
	INNER JOIN msdb.dbo.sysjobs AS sj ON sja.job_id = sj.job_id
	WHERE sja.start_execution_date IS NOT NULL
	   AND sja.stop_execution_date IS NULL
	   AND sj.name = '[DBA] REINDEX AUTOMATION - REINDEX MOD0'
)

EXEC msdb..sp_start_job '[DBA] REINDEX AUTOMATION - REINDEX MOD1'
IF not exists( 
	SELECT top 1 sj.name
	FROM msdb.dbo.sysjobactivity AS sja
	INNER JOIN msdb.dbo.sysjobs AS sj ON sja.job_id = sj.job_id
	WHERE sja.start_execution_date IS NOT NULL
	   AND sja.stop_execution_date IS NULL
	   AND sj.name = '[DBA] REINDEX AUTOMATION - REINDEX MOD1'
)

EXEC msdb..sp_start_job '[DBA] REINDEX AUTOMATION - REINDEX MOD1'
IF not exists( 
	SELECT top 1 sj.name
	FROM msdb.dbo.sysjobactivity AS sja
	INNER JOIN msdb.dbo.sysjobs AS sj ON sja.job_id = sj.job_id
	WHERE sja.start_execution_date IS NOT NULL
	   AND sja.stop_execution_date IS NULL
	   AND sj.name = '[DBA] REINDEX AUTOMATION - REINDEX MOD2'
)

EXEC msdb..sp_start_job '[DBA] REINDEX AUTOMATION - REINDEX MOD2'



END


