/*IF EXISTS (SELECT name 
              FROM   sysobjects 
              WHERE  name = N'up_DBA_job_operator_info_select' 
              AND              type = 'P')
    DROP PROCEDURE  procedure_name
*/

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_job_operator_info_select 
* 작성정보    : 2007-11-07 안지원 
* 관련페이지  :  
* 내용        : JOBS_OPERTOR 테이블에 insert
* 수정정보    : exec dbo.up_DBA_job_operator_info_select '8AFC4BEA-41E1-4F48-A144-533443AD9C8A'
**************************************************************************/
ALTER PROCEDURE dbo.up_DBA_job_operator_info_select
     @strJobId      varchar(40)
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
	SELECT 
			Jop.seq_no as seq_no
		,	Jop.job_id as job_id
		,	Jop.operatorno as operatorno
		,	Jop.reg_dt as reg_dt
		,	Sop.operatorName as operatorName  
	FROM dbo.JOBS_OPERATOR AS Jop with(nolock)
	INNER JOIN dbo.OperatorSimple AS Sop with(nolock) ON Jop.operatorno = Sop.operatorno
	WHERE job_id = @strJobId

	IF @@ERROR <> 0 RETURN

RETURN
