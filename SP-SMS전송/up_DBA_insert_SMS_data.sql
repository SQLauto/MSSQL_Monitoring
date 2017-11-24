/*************************************************************************  
* 프로시저명  : dbo.up_DBA_insert_SMS_data
* 작성정보    : 2007-12-10
* 관련페이지  : 이벤트성 sms전송시 @intCnt건씩 보내는 프로시저    
* 내용        :
* 수정정보    : 안지원
*  exec  dbo.up_DBA_insert_SMS_data 500
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_insert_SMS_data     	
	@intCnt			 int 				--끊어서 보낼 갯수     
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @total_cnt int
DECLARE @loop_cnt int

/* BODY */

SET @loop_cnt = 1

WHILE (@loop_cnt <=869024)
BEGIN
	INSERT INTO info_sms.smsadmin.smscli_tbl_event
	(	
		tran_phone
	, 	tran_callback
	, 	tran_status
	,	tran_date
	, 	tran_msg
	)
	SELECT
		replace(hp_no, '-', '')
	, 	'15665701' 
	, 	'1'
	, 	getdate()
	, 	'[G마켓]' +cust_nm + '님께 식품할인 쿠폰 2장이발급되었습니다=>내 쿠폰함 확인'
	FROM dbo.TMPJUNG071210 with(nolock)
	WHERE seq_no >= @loop_cnt and seq_no < @loop_cnt + @intCnt

	SET @loop_cnt = @loop_cnt + @intCnt

-- 	WAITFOR DELAY '00:00:01'
END 



RETURN






