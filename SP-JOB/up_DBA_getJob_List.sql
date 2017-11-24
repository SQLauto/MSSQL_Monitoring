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
SP명		: up_DBA_getJob_List
작성정보	: 2006-08-18  김태환
내용		: Jobs테이블에 있는 JOB목록 조회
수정내역    : 2007-07-20 by ceusee
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
	             CASE JOB.JOB_HIST_CK WHEN 'Y' THEN '예' ELSE '아니오' END as JOB_HIST_CK,
	             CASE JOB.SMS_CK WHEN 'S' THEN '성공시' 
				  WHEN 'F' THEN '실패시'
				  WHEN 'N' THEN 'X'
				  WHEN 'A' THEN '모두' END AS SMS_CK,
	             CASE JOB.EMS_CK WHEN 'S' THEN '성공시' 
				  WHEN 'F' THEN '실패시'
				  WHEN 'N' THEN 'X'
				  WHEN 'A' THEN '모두' END AS EMS_CK,
	             '', JOB.JOB_ID, 
  	             CASE JOB.ENABLED WHEN 1 THEN '사용' ELSE '미사용' END as ENABLED,	
  	             CASE JOB.STAT WHEN 'S2' THEN '등록' ELSE '삭제' END as STAT,
	             CASE JOB.MONITORING_YN WHEN 'Y' THEN '사용' ELSE '미사용' END as MONITORING_YN		
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