/*************************************************************************  
* ���ν�����  : dbo.up_DBA_insert_SMS_data
* �ۼ�����    : 2007-12-10
* ����������  : �̺�Ʈ�� sms���۽� @intCnt�Ǿ� ������ ���ν���    
* ����        :
* ��������    : ������
*  exec  dbo.up_DBA_insert_SMS_data 500
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_insert_SMS_data     	
	@intCnt			 int 				--��� ���� ����     
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
	, 	'[G����]' +cust_nm + '�Բ� ��ǰ���� ���� 2���̹߱޵Ǿ����ϴ�=>�� ������ Ȯ��'
	FROM dbo.TMPJUNG071210 with(nolock)
	WHERE seq_no >= @loop_cnt and seq_no < @loop_cnt + @intCnt

	SET @loop_cnt = @loop_cnt + @intCnt

-- 	WAITFOR DELAY '00:00:01'
END 



RETURN






