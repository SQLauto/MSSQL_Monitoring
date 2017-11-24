SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
--IF EXISTS (SELECT name 
--	   FROM   sysobjects
--	   WHERE  name = N'up_DBA_getJob_Detail' 
--	   AND 	  type = 'P')
--    DROP PROCEDURE  up_DBA_getJob_Detail
--GO

/*****************************************************************************    
SP��		: up_DBA_getJob_Detail
�ۼ�����	: 2006-08-18  ����ȯ
����		: Jobs���̺� �ִ� JOB��� �� ��ȸ
��������    : 2007-07-20 by ceusee(�ֺ���)
2007-11-06 by choi bo ra, �ڵ� ���� �ð� �߰�
******************************************************************************/
CREATE PROCEDURE [dbo].up_DBA_getJob_Detail
	@strJobId		varchar(40)	-- JOB ID
AS

BEGIN
	SET NOCOUNT ON  

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	
	SELECT JOB.JOB_NAME, OP.operatorName AS OP_NM,  JOb.job_Type,
	        JOB.JOB_HIST_CK, JOB.SMS_CK, JOB.EMS_CK, JOB.MGR_NO, JOB.MONITORING_YN, JOB.KILL_YN, JOB.KILL_DURATION
	FROM dbo.JOBS AS Job JOIN dbo.OperatorSimple AS OP ON JOB.MGR_NO = OP.operatorNo
    WHERE JOB.JOB_ID = @strJobId
	 ORDER BY JOB.JOB_NAME ASC

 	SET NOCOUNT OFF
END
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO