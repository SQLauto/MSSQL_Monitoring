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
* 프로시저명  : dbo.up_DBA_job_operator_info_del 
* 작성정보    : 2007-11-07 안지원 
* 관련페이지  :  
* 내용        : JOBS_OPERTOR 테이블에서 delete
* 수정정보    : 
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


