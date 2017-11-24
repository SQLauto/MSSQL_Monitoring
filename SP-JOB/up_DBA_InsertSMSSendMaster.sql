SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
--IF EXISTS (SELECT name 
--	   FROM   sysobjects
--	   WHERE  name = N'up_DBA_InsertSMSSendMaster' 
--	   AND 	  type = 'P')
--    DROP PROCEDURE  up_DBA_InsertSMSSendMaster
--GO
/*************************************************************************  
* ���ν�����  : dbo.DBA_InsertSMSSendMaster 
* �ۼ�����    : 2007-07-05
* ����������  :  
* ����        : 5�и��� jobhistory ���� SMS �߼۴�� ����Ʈ�� SMSSendMaster
                �� insert �ϰ� hist ���̺� update  
* ��������    : ������ �ִ°��� �����ϰ� ���� ����
2007-07-13 by ceusee temCode�� ������� ������ ���� 
2007-11-06 by ceusee(choi bo ra) ����� ���������� ���� 
2007-12-26 by choi bo ra �۾� �������� ���� ���� ������ ���� 
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_InsertSMSSendMaster
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/* USER DECLARE */
DECLARE @dtGetDate      DATETIME
SET @dtGetDate = GETDATE()
/* BODY */
-- Step 1 1�ð����� ����� �� �߿� ���ǿ� �ش��ϴ� SMS ������ Insert
-- ��, ������ ��� �۾��� �Ϸ�Ǿ��� ������ Step�� ������. 
-- ������ �ܰ躰�� �� ������ �Ǿ� �־���
INSERT dbo.SMSSendMaster (jobHistId, jobId, jobName, jobStepId, operatorName, HPNo, sendFlag, 
        runStatus, registerDate, changeDate, sms_send_nm)
SELECT history.job_hist_id, history.job_id, job.job_name, history.step_id, 
    (select operatorname from dbo.OperatorSimple with (nolock) where operatorno = job.mgr_no) as operatorName,
	opt.HPNo,  1, run_status, @dtGetDate, @dtGetDate, opt.operatorName AS sms_send_nm
FROM  (SELECT job_id, MAX(job_hist_id) job_hist_id, MAX(step_id) AS step_id ,MAX(run_status) AS run_status
        FROM dbo.JobHistory  WITH (NOLOCK) 
        WHERE ( sms_ck = 'A' OR (sms_ck = 'S' AND run_status = 1) OR (sms_ck = 'F' AND run_status = 0))
                AND step_id <> 0 AND DATEDIFF(MI, reg_dt, GETDATE()) < 60
                AND smsFlag = 1 AND run_status <> 4
        GROUP BY job_id, reg_dt ) AS history 
        JOIN dbo.Jobs AS job WITH (NOLOCK) ON history.job_id = job.job_id 
        JOIN dbo.JOBS_OPERATOR AS jobopt WITH (NOLOCK) ON job.job_id = jobopt.job_id
		JOIN dbo.OperatorSimple AS opt WITH (NOLOCK) ON opt.operatorNo = jobopt.operatorNo 
WHERE job.enabled = 1 AND job.stat = 'S2'

IF @@ERROR <> 0 GOTO ERRORHANDLER

-- Step 2
UPDATE dbo.JobHistory
SET   SMSFlag = 2
FROM  dbo.JobHistory AS history WITH (NOLOCK) JOIN SMSSendMaster AS sms WITH (NOLOCK)
        ON history.job_hist_id = sms.jobHistId
WHERE history.SMSFlag = 1 AND DATEDIFF(MI, history.reg_dt, GETDATE()) < 60
        AND sms.registerDate = sms.changeDate

IF @@ERROR <> 0 GOTO ERRORHANDLER

SET NOCOUNT OFF
RETURN

ERRORHANDLER:
BEGIN
    
    RETURN 
END

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO