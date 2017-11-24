SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
IF EXISTS (SELECT name 
	   FROM   sysobjects
	   WHERE  name = N'up_DBA_getJob_List' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_getJob_List
GO

/*****************************************************************************    
SP��		: up_DBA_getJob_List
�ۼ�����	: 2006-08-18  ����ȯ
����		: Jobs���̺� �ִ� JOB��� ��ȸ
��������    : 2007-07-20 by ceusee
******************************************************************************/
--DROP PROCEDURE [dbo].up_DBA_getJob_List

CREATE PROCEDURE [dbo].up_DBA_getJob_List
	@intEnabled		smallint = 1,			-- ENABLED
	@strStat			char(2) = 'S2'			-- STAT
	
AS

BEGIN
	SET NOCOUNT ON  

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  


	SELECT JOB.JOB_NAME, CONVERT(char(10), JOB.REG_DT, 121) as REG_DT, OP.operatorName AS OP_NM,
	             CASE JOB.JOB_HIST_CK WHEN 'Y' THEN '��' ELSE '�ƴϿ�' END as JOB_HIST_CK,
	             CASE JOB.SMS_CK WHEN 'S' THEN '������' 
				  WHEN 'F' THEN '���н�'
				  WHEN 'N' THEN 'X'
				  WHEN 'A' THEN '���' END AS SMS_CK,
	             CASE JOB.EMS_CK WHEN 'S' THEN '������' 
				  WHEN 'F' THEN '���н�'
				  WHEN 'N' THEN 'X'
				  WHEN 'A' THEN '���' END AS EMS_CK,
	             '', JOB.JOB_ID, 
  	             CASE JOB.ENABLED WHEN 1 THEN '���' ELSE '�̻��' END as ENABLED,	
  	             CASE JOB.STAT WHEN 'S2' THEN '���' ELSE '����' END as STAT,
	             CASE JOB.MONITORING_YN WHEN 'Y' THEN '���' ELSE '�̻��' END as MONITORING_YN		
	 FROM dbo.JOBS as JOB JOIN OperatorSimple AS OP ON JOB.MGR_NO = OP.operatorNo
	 WHERE JOB.ENABLED = @intEnabled
	      AND JOB.STAT = @strStat
	 ORDER BY JOB.JOB_NAME ASC

 	SET NOCOUNT OFF
END

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO