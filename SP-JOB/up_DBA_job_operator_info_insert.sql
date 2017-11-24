/*IF EXISTS (SELECT name 
              FROM   sysobjects 
              WHERE  name = N'up_DBA_job_operator_info_insert' 
              AND              type = 'P')
    DROP PROCEDURE  procedure_name
*/

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_job_operator_info_insert 
* 작성정보    : 2007-11-07 안지원 
* 관련페이지  :  
* 내용        : Job ID에 해당하는 발송자 추가 
* 수정정보    :
**************************************************************************/
ALTER PROCEDURE dbo.up_DBA_job_operator_info_insert
     @intOperNo      int,  --발송자 번호 
     @strJobId		 varchar(40)	--job 아이디      
AS
/* COMMON DECLARE */
DECLARE	@intRetVal	smallint

SET NOCOUNT ON

/* USER DECLARE */
	DECLARE @intCnt int
		
/* BODY */
	--이미 OperatorSimple 테이블에 등록되어 있는 직원인지 확인
	SELECT @intCnt = count(*) FROM dbo.OperatorSimple with(nolock) WHERE operatorno = @intOperNo
	
	IF @intCnt > 0 
	BEGIN
		INSERT INTO JOBS_OPERATOR(
			job_id
		,	operatorno
		)
		VALUES(
			@strJobId
		,	@intOperNo
		)		
		
		IF @@ERROR = 0 AND @@ROWCOUNT = 1
		BEGIN
			SELECT @intRetVal = 1
		END
		ELSE
		BEGIN
			SELECT @intRetVal = -1
		END

		RETURN @intRetVal
	END 
	
RETURN

