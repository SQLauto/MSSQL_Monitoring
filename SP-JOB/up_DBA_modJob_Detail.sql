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
SP��		: up_DBA_modJob_Detail
�ۼ�����	: 2006-08-18  ����ȯ
����		: Jobs���̺� �ִ� JOB��� �� ��ȸ
��������    : 
2007-11-06 by choi bo ra ����� �����ϸ� Job
******************************************************************************/
CREATE PROCEDURE dbo.up_DBA_modJob_Detail
	@strJobId		    varchar(40),	-- JOB ID
	@intOID			    int,		    -- ����� �ڵ�
	@intJob_Type        int,
	@strJobHistCK		char(1),		-- �����丮 ���忩��
	@strSMS		        char(1),		-- SMS
	@strEMS			    char(1),		-- EMS
	@strMonitoringYn	char(1),		-- ����͸� ����
	@strKillYn		    char(1),	    -- �ڵ����� (Y:�ڵ� ����, N:������������, A:���������� �ð�üũ)
	@intKill_duration   int             -- ����ð�
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