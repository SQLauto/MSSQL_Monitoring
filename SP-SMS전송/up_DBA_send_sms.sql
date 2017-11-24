SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_send_sms' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_send_sms
*/

/*************************************************************************  
* ���ν�����  : dbo.up_DBA_send_sms 
* �ۼ�����    : 2007-08-14 �ֺ���
* ����������  :  
* ����        : ���������� �ǰ��� SMS ������ ���ν���
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_send_sms
     @sms_type      TINYINT = 1,  --1.�ߺ����, 2.�ߺ�������� ����
     @hp_no         VARCHAR(20),
     @msg           VARCHAR(50)
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
IF @sms_type = 1
BEGIN
    INSERT INTO [SMS].kidc_sms.dbo.smscli_tbl_02(destination, originator, callback, body,proc_status, teleservice_id )     
    VALUES (REPLACE(@hp_no, '-',''), '160701001001', '15665701', @msg, '1', '4098')
    
    IF @@ERROR <> 0 RETURN
END
ELSE IF @sms_type = 2
BEGIN
    INSERT INTO SMS2.info_sms.smsadmin.smscli_tbl_order
	    (tran_phone, tran_callback, tran_status, tran_date, tran_msg, tran_type)
	VALUES (REPLACE(@hp_no, '-',''), '15665701', 1, GETDATE(), @msg, 0)
	
	IF @@ERROR <> 0 RETURN
	
END
 
RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO