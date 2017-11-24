/*IF EXISTS (SELECT name 
              FROM   sysobjects 
              WHERE  name = N'up_DBA_job_operator_info_insert' 
              AND              type = 'P')
    DROP PROCEDURE  procedure_name
*/

/*************************************************************************  
* ���ν�����  : dbo.up_DBA_job_operator_info_insert 
* �ۼ�����    : 2007-11-07 ������ 
* ����������  :  
* ����        : Job ID�� �ش��ϴ� �߼��� �߰� 
* ��������    :
**************************************************************************/
ALTER PROCEDURE dbo.up_DBA_job_operator_info_insert
     @intOperNo      int,  --�߼��� ��ȣ 
     @strJobId		 varchar(40)	--job ���̵�      
AS
/* COMMON DECLARE */
DECLARE	@intRetVal	smallint

SET NOCOUNT ON

/* USER DECLARE */
	DECLARE @intCnt int
		
/* BODY */
	--�̹� OperatorSimple ���̺� ��ϵǾ� �ִ� �������� Ȯ��
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

