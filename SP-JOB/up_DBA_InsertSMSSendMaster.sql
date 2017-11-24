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
* 프로시저명  : dbo.DBA_InsertSMSSendMaster 
* 작성정보    : 2007-07-05
* 관련페이지  :  
* 내용        : 5분마다 jobhistory 에서 SMS 발송대상 리스트를 SMSSendMaster
                로 insert 하고 hist 테이블 update  
* 수정정보    : 기존에 있는것을 제거하고 새로 생성
2007-07-13 by ceusee temCode와 상관없이 보내게 변경 
2007-11-06 by ceusee(choi bo ra) 담당자 여려명으로 변경 
2007-12-26 by choi bo ra 작업 진행중인 상태 메일 보내지 않음 
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
-- Step 1 1시간동안 실행된 잡 중에 조건에 해당하는 SMS 내역을 Insert
-- 단, 성공일 경우 작업이 완료되었던 마지막 Step만 보낸다. 
-- 기존은 단계별로 다 보내게 되어 있었음
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