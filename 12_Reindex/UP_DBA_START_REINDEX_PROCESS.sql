/*****************************************************************************************************************   
. �� �� ��: ����ȯ   
. �� �� ��: 2015-02-02   
. ��������: GmarketDBA�� ����ȯ   
. ��ɱ���: REINDEX �۾� Start
. ���࿹��    
  - exec UP_DBA_START_REINDEX_PROCESS 
*****************************************************************************************************************   
���泻��:   
        ��������        ��������        ������        ��������   
==========================================================================   
       2015-02-02                    ����ȯ        �űԻ��� 
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


