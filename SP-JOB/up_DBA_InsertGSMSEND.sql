SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
IF EXISTS (SELECT name 
	   FROM   sysobjects
	   WHERE  name = N'up_DBA_InsertGSMSEND' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_InsertGSMSEND
GO

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_InsertGSMSEND 
* 작성정보    : 2006-08-14  오경배   
* 관련페이지  :  
* 내용        :
* 수정정보    : 2007-07-06 by choi bo ra
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_InsertGSMSEND
    @minSeqNo       INT = 0,
    @maxSeqNo       INT = 0
AS

    
/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
/* USER DECLARE */
DECLARE @serverId       VARCHAR(10)

/* BODY */
IF @minSeqNo > 0 AND @maxSeqNo > 0 
BEGIN
    
    -- Step 1 : 서버 아이디 찾음
    Select @serverId = svr_id  
    FROM  gdm01.admin.dbo.sql_server_list  
    WHERE SQL_SVR_NAME = @@ServerName 
     
 
    -- Step 2: GMSM_SEND_LIST Insert
    INSERT gdm01.admin.dbo.GSMS_SEND_List (job_hist_id, svr_id, op_nm, hp_no, 
            job_name, sms_ck, run_status, step_id, send_ck, reg_dt, chg_dt) 
    SELECT sms.jobHistId, @serverId, sms.operatorName, sms.HPNo, sms.jobName, history.SMS_ck, sms.runStatus, 
            sms.jobStepId, sms.sendFlag, sms.registerDate, sms.changeDate
    FROM dbo.SMSSendMaster AS sms WITH (NOLOCK) JOIN dbo.JobHistory AS history WITH (NOLOCK)
        ON sms.jobHistId = history.job_hist_id
    WHERE seqNo >= @minSeqNo AND seqNo <= @maxSeqNo AND sendFlag = 2
    
  IF @@ERROR <> 0 RETURN
END
SET NOCOUNT OFF
RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO