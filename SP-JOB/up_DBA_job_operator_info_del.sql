SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
              FROM   sysobjects 
              WHERE  name = N'up_DBA_job_operator_info_del' 
              AND              type = 'P')
    DROP PROCEDURE  procedure_name
*/

/*************************************************************************  
* ���ν�����  : dbo.up_DBA_job_operator_info_del 
* �ۼ�����    : 2007-11-07 ������ 
* ����������  :  
* ����        : JOBS_OPERTOR ���̺��� delete
* ��������    : 
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_job_operator_info_del
     @strJobId      varchar(40) ,
     @intOperNo		int
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
	DELETE FROM dbo.JOBS_OPERATOR 	
	WHERE job_id = @strJobId  AND operatorno = @intOperNo
	
	IF @@ERROR <> 0 RETURN


RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO


