SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
--IF EXISTS (SELECT name
--    FROM sysobjects
--    WHERE name = N'up_DBA_InsertEMSSendMaster'
--    AND type = 'P')
--    DROP PROCEDURE up_DBA_InsertEMSSendMaster
--GO
 /*************************************************************************    
* ���ν�����  : up_DBA_InsertEMSSendMaster   
* �ۼ�����    : 2006-08-16  �����  
* ����������  :    
* ����        : 1�и��� job_hist ���� EMS �߼۴�� ����Ʈ�� EMS_Send_List��   
                insert �ϰ� hist ���̺� update  
* ��������    : 2007-07-03 by ceusee(choi bo ra)  
                �� DB�� ������ ���̺� ����  
                JobHistory���̺� sendflag �÷� ���� (1: �߼���, 2: �߼���)  
                ���� wile ���� �ʰ� ��, 1�� ���� ����Ǳ� ������ �߼��� �����Ͱ� ���� ����  
                2007-11-06 by ceusee(choi bo ra) ����� ���������� ���� 
                2007-12-26 by choi bo ra �۾� �������� ���� ���� ������ ���� 
**************************************************************************/  
CREATE PROCEDURE dbo.up_DBA_InsertEMSSendMaster   
AS  
  
/* COMMON DECLARE */  
SET NOCOUNT ON    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
  
/* USER DECLARE */  
DECLARE @dtGetDate        DATETIME  
SET @dtGetDate = GETDATE()  
  
  
/* BODY */  
-- Step 1. EMS ���� ���̺� INSERT  
INSERT INTO dbo.EMSSendMaster   
        (jobHistId, jobId, jobName, jobStepId, operatorName, Email, sendFlag,   
        runStatus, runDate, runTime, message, registerDate, changeDate, runduration, ems_send_nm)  
SELECT history.job_hist_id, job.job_id, job.job_name,  step.step_id,
		(select operatorname from dbo.OperatorSimple with (nolock) where operatorno = job.mgr_no) as operatorName, 
		opt.Email, 1,  
        history.run_status, history.run_date, history.run_time, history.message,@dtGetDate, @dtGetDate,
        history.run_duration , opt.operatorName as ems_send_nm 
FROM dbo.Jobs AS job WITH (NOLOCK) JOIN dbo.JobHistory AS history WITH (NOLOCK)   
        ON job.job_id = history.job_id   
        JOIN dbo.JobSteps AS step WITH (NOLOCK) ON history.job_id = step.job_id AND history.step_id = step.step_id  
        JOIN dbo.JOBS_OPERATOR AS jobopt WITH (NOLOCK) ON job.job_id = jobopt.job_id
		JOIN dbo.OperatorSimple AS opt WITH (NOLOCK) ON opt.operatorNo = jobopt.operatorNo 
WHERE job.enabled = 1 AND job.stat = 'S2' AND history.EMSFlag = 1  
        AND history.run_date = CONVERT(NVARCHAR(8), @dtGetDate, 112)  
        AND ((history.ems_ck = 'A') OR (history.ems_ck = 'S' AND history.run_status = 1)  
                OR (history.ems_ck = 'F' AND history.run_status = 0)  
                OR (history.run_status = 3)  
            )  
        AND history.run_status <> 4
ORDER BY history.job_hist_id  
  
IF @@ERROR <> 0 GOTO ERRORHANDLER  
  
-- Step 2. EMS �߼��� ���·� ����  
UPDATE dbo.JobHistory  
SET EMSFlag = 2  
FROM dbo.JobHistory AS history WITH (NOLOCK) JOIN EMSSendMaster AS ems WITH (NOLOCK)  
        ON history.job_hist_id = ems.jobHistId  
WHERE history.EMSFlag = 1 AND history.run_date = CONVERT(NVARCHAR(8), GETDATE(), 112)  
      AND ems.registerDate = ems.changeDate  
IF @@ERROR <> 0 GOTO ERRORHANDLER         
  
SET NOCOUNT OFF  
RETURN  
  
ERRORHANDLER:  
BEGIN  
    RETURN  -1  
END  
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

