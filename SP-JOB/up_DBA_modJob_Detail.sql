SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
--IF EXISTS (SELECT name 
--	   FROM   sysobjects
--	   WHERE  name = N'up_DBA_modJob_Detail' 
--	   AND 	  type = 'P')
--    DROP PROCEDURE  up_DBA_modJob_Detail
--GO
/*****************************************************************************    
SP명		: up_DBA_modJob_Detail
작성정보	: 2006-08-18  김태환
내용		: Jobs테이블에 있는 JOB목록 상세 조회
수정정보    : 
2007-11-06 by choi bo ra 담당자 선정하면 Job
******************************************************************************/
CREATE PROCEDURE dbo.up_DBA_modJob_Detail
	@strJobId		    varchar(40),	-- JOB ID
	@intOID			    int,		    -- 담당자 코드
	@intJob_Type        int,
	@strJobHistCK		char(1),		-- 히스토리 저장여부
	@strSMS		        char(1),		-- SMS
	@strEMS			    char(1),		-- EMS
	@strMonitoringYn	char(1),		-- 모니터링 여부
	@strKillYn		    char(1),	    -- 자동종료 (Y:자동 종료, N:종료하지않음, A:종료하지만 시간체크)
	@intKill_duration   int             -- 종료시간
AS

DECLARE	@row_count	smallint

BEGIN
	SET NOCOUNT ON  
	
	UPDATE dbo.JOBS
	      SET mgr_no = @intOID,
	             job_type  = @intJob_type,
	             job_hist_ck = @strJobHistCK,
	             sms_ck = @strSMS,
	             ems_ck = @strEMS,
	             monitoring_yn = @strMonitoringYn,
	             kill_yn = @strKillYn,
	             kill_duration = @intKill_duration
	 WHERE JOB_ID = @strJobId

	IF @@ERROR <> 0  SELECT -1  AS intRetVal
	
	
	SELECT @row_count = COUNT(*) FROM JOBS_OPERATOR WITH (NOLOCK)
	WHERE job_id = @strJobId AND operatorNo = @intOID 
	 
	IF @@ERROR <> 0 SELECT -1  AS intRetVal
    
    IF @row_count = 0 
    BEGIN
         INSERT dbo.JOBS_OPERATOR (job_id, operatorno, reg_dt)
         VALUES (@strJobId, @intOID, getdate())
         
         IF @@ERROR <> 0 SELECT -1   AS intRetVal
    END
    
	
    SELECT 0 AS intRetVal
 	SET NOCOUNT OFF
END

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO