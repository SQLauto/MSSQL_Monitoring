/*************************************************************************  
* 프로시저명  : dbo.up_DBA_SMS_update_SENDYN_ETC
* 작성정보    : 2008-04-07
* 관련페이지  : 안지원
* 내용        : SENDYN update
* 수정정보    : CRM DB로 이전 
	grant execute on dbo.up_DBA_SMS_update_SENDYN_ETC to goodsdaq
	grant execute on dbo.up_DBA_SMS_update_SENDYN_ETC to backend
	grant execute on dbo.up_DBA_SMS_update_SENDYN_ETC to dev
**************************************************************************/
CREATE  PROCEDURE dbo.up_DBA_SMS_update_SENDYN_ETC		
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	DECLARE @miniid int 
		DECLARE @maxiid int 

	--업데이트 된 iid를 구한다	
	SELECT  @miniid = min_iid , @maxiid = max_iid FROM dbo.SMSMSG_CHK_SENDYN WITH(NOLOCK) WHERE tb_name = 'ETC'

	IF @miniid = 0 AND @maxiid = 0
	BEGIN
		RETURN
	END
	ELSE
	BEGIN
		UPDATE 	
			dbo.SMSMSG_ETC
		SET send_yn = 'Y', send_dt = getdate() 
		WHERE  iid >= @miniid AND iid <= @maxiid
	END	

	SET NOCOUNT OFF
