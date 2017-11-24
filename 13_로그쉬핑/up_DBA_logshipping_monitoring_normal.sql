SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects
	   WHERE  name = N'up_DBA_logshipping_monitoring_normal' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_logshipping_monitoring_normal
    */
GO

/*************************************************************************  
* ���ν�����  : dbo.up_DBA_logshipping_monitoring_normal 
* �ۼ�����    : 2006-05-12 ������
* ����������  :  
* ����        : ���� 6��, 22��(�ָ��� 14�� �߰�) ���������� ������ ������ ���� ���� �˷���
* ��������    : 
    2006-06-21 MYLEE SMS ������ �κ� �̹ξ� �븮 ����, ������ �븮 �߰�    
    2006-08-09    YES  ����ȯ, ������, �Ǻ��� �߰�, LiteSpeed_�� ���ϸ��� ����    
    2006-08-31 ����ȯ ���ȫ ���� SMS��Ͽ��� ����    
    2006-09-06 ����ȯ ������ ����, ������ ���� SMS��Ͽ��� ����  
    2007-01-09 �̻��� �븮 SMS��Ͽ� �߰�  
    2007-08-10 �ֺ��� ���� ���濡 ���� ���̺� ����, SMS ��� �ڵ�ȭ�� ���� 
**************************************************************************/
CREATE  PROCEDURE dbo.up_DBA_logshipping_monitoring_normal    
AS    
    
SET NOCOUNT ON    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
    
DECLARE @weekday int, @hour int, @year int    
DECLARE @last_log_file_name_tiger varchar(50), @last_log_file_name_settle varchar(50), @last_log_file_name_event varchar(50), @msg varchar(8000)    
DECLARE @last_log_file_name_lion varchar(50), @last_log_file_name_customer varchar(50)    
    
SET DATEFIRST 1    
SET @weekday = DATEPART(dw, GETDATE())    
SET @hour = DATEPART(hh, GETDATE())    
SET @year = DATEPART(year, GETDATE())    
    
IF (@weekday < 6 AND @hour <> 14) OR (@weekday >= 6)    
BEGIN    
    
    SELECT TOP 1 @last_log_file_name_tiger = log_file    
    FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
    WHERE user_db_name = 'TIGER' AND restore_flag = 1    
    ORDER BY reg_dt desc    
     
    
    SELECT TOP 1 @last_log_file_name_settle = log_file    
    FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
    WHERE user_db_name = 'SETTLE' AND restore_flag = 1    
    ORDER BY reg_dt desc    
    
    SELECT TOP 1 @last_log_file_name_event = log_file    
    FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
    WHERE user_db_name = 'EVENT' AND restore_flag = 1    
    ORDER BY reg_dt desc    
 
  ------------------------------------------------------------------------------------------------------------------------------------------------------------    
 --2006-08-27 YES lion, customer DB ����͸� �߰�    
 ------------------------------------------------------------------------------------------------------------------------------------------------------------    
 SELECT TOP 1 @last_log_file_name_lion = log_file    
 FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
 WHERE user_db_name = 'LION' AND restore_flag = 1    
 ORDER BY reg_dt desc    
    
 SELECT TOP 1 @last_log_file_name_customer = log_file    
 FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
 WHERE user_db_name = 'CUSTOMER' AND restore_flag = 1    
 ORDER BY reg_dt desc    
 
 
  
 SET @msg = '[' + @@SERVERNAME + ']�������� : '
 IF @last_log_file_name_tiger IS NOT NULL OR @last_log_file_name_tiger <> '' SET @msg = @msg + ' ' + @last_log_file_name_tiger
 IF @last_log_file_name_settle IS NOT NULL OR @last_log_file_name_settle <> '' SET @msg =@msg + ' ' + @last_log_file_name_settle
 IF @last_log_file_name_event IS NOT NULL OR @last_log_file_name_event <> '' SET @msg =@msg + ' ' + @last_log_file_name_event

     

 SET @msg = replace(@msg, 'tlog_', '')    
 SET @msg = replace(@msg, 'LiteSpeed', '') 
 SET @msg = replace(@msg, '.TRN', '')   
 SET @msg = replace(@msg, convert(varchar,@year), '')  

     
 INSERT INTO [SMS].kidc_sms.dbo.smscli_tbl_02(destination, originator, callback, callbackURL, body,proc_status, teleservice_id )     
 SELECT REPLACE(HPNo, '-', ''), '160701001001', '15665701', null,@msg, '1', '4098' FROM OperatorSimple WITH (NOLOCK) WHERE backupFlag = 1  

  
 SET @msg = '[' + @@SERVERNAME + ']�������� : '
 IF @last_log_file_name_lion IS NOT NULL OR @last_log_file_name_lion <> '' SET @msg =@msg + ' ' + @last_log_file_name_lion
 IF @last_log_file_name_customer IS NOT NULL OR @last_log_file_name_customer <> '' SET @msg =@msg + ' ' + @last_log_file_name_customer
 SET @msg = replace(@msg, 'tlog_', '')    
 SET @msg = replace(@msg, 'LiteSpeed', '') 
 SET @msg = replace(@msg, '.TRN', '')   
 SET @msg = replace(@msg, convert(varchar,@year), '')    
 
 INSERT INTO [SMS].kidc_sms.dbo.smscli_tbl_02(destination, originator, callback, callbackURL, body,proc_status, teleservice_id )     
 SELECT REPLACE(HPNo, '-', ''), '160701001001', '15665701', null,@msg, '1', '4098' FROM OperatorSimple WITH (NOLOCK) WHERE backupFlag = 1  

    
END    
GO
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO