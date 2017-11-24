
/*************************************************************************      
* ���ν�����  : dbo.up_DBA_send_sms_byTeam     
* �ۼ�����    : 2008-10-10 ������  
* ����������  :      
* ����        : �������� SMS ������ ���ν���    1:DBA��, 2:DB������, 3:DW��
* ��������    : KIDC -> KT SMS ���� 
**************************************************************************/    
CREATE PROCEDURE dbo.up_DBA_send_sms_byTeam
	@team_code	TINYINT,
	@sms_type	TINYINT = 1,	
	@msg		VARCHAR(50)
AS
/* COMMON DECLARE */    
SET NOCOUNT ON    
    
/* USER DECLARE */    
    
/* BODY */    
IF @sms_type = 1    
BEGIN    
  
    INSERT INTO KT_SMS.KT_SMS.dbo.smscli_tbl_etc(tran_phone, tran_callback, tran_msg ,tran_status, tran_type )         
		SELECT REPLACE(HPNo, '-','') AS hp_no, '15665701' AS tran_callback, @msg AS tran_msg, '1' AS tran_status, '4098' AS tran_type
		FROM dbo.OperatorSimple WITH(NOLOCK) WHERE temCode = @team_code
        
    IF @@ERROR <> 0 RETURN    

END    
ELSE IF @sms_type = 2    
BEGIN    
    INSERT INTO SMS2.info_sms.smsadmin.smscli_tbl_order(tran_phone, tran_callback, tran_msg, tran_status, tran_date, tran_type)    
		SELECT REPLACE(HPNo, '-','') AS hp_no, '15665701' AS tran_callback, @msg AS tran_msg, '1' AS tran_status, GETDATE() as tran_date, 0 AS tran_type
		FROM dbo.OperatorSimple WITH(NOLOCK) WHERE temCode = @team_code
	
	IF @@ERROR <> 0 RETURN    
     
END    
     
RETURN