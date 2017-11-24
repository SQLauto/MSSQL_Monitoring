SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects
	   WHERE  name = N'up_DBA_logshipping_monitoring_abnormal' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_logshipping_monitoring_abnormal
*/

/*************************************************************************  
* ���ν�����  : dbo.up_DBA_logshipping_monitoring_abnormal 
* �ۼ�����    : 2006-05-12
* ����������  :  
* ����        : 1�ð� �������� 6�ð� �̻� ������ �����Ǿ����� ����͸�
* ��������    : 
    2006-06-21 MYLEE SMS ������ �κ� �̹ξ� �븮 ����, ������ �븮 �߰�    
    2006-08-09    YES  ����ȯ, ������, �Ǻ��� �߰�    
    2006-08-27   YES  lion, customer DB ����͸� �߰�    
    2006-08-31 ����ȯ ���ȫ ���� SMS��Ͽ��� ����    
    2006-09-06 ����ȯ ������ ����, ������ ���� SMS��Ͽ��� ����    
    2007-01-09 SMS��Ͽ��� ����� ���� ����, �̻��� �븮 �߰� 
    2007-08-10 by �ֺ��� ���̺� ���濡 ���� ���� ���� 
    2008-04-18 by �ֺ��� �α� �����ð��� �ƴ� ���� �����̸� ���� üũ
**************************************************************************/
 CREATE  PROCEDURE dbo.up_DBA_logshipping_monitoring_abnormal    
AS    
    
 SET NOCOUNT ON    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
     
 DECLARE @hour int, @year int, @serverName    NVARCHAR(10)    
 DECLARE @last_restore_time_tiger smalldatetime, @last_restore_time_settle smalldatetime, @last_restore_time_event smalldatetime, @msg varchar(2000)    
 DECLARE @last_restore_time_lion smalldatetime, @last_restore_time_customer smalldatetime    
 SET @msg = ''    
     
 --tiger�� ������ �α׺��� �����ð�    
 SELECT TOP 1 @last_restore_time_tiger = convert(smalldatetime, (left(right(log_file, 16),4) + '-'+
	substring(right(log_file, 16),5,2) + '-' + 
	substring(right(log_file, 16),7,2) + ' ' +
	substring(right(log_file, 16),9,2) + ':00:00'), 120)        
 FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
 WHERE user_db_name = 'TIGER' AND restore_flag = 1   
 ORDER BY reg_dt desc    
     
 --settle�� ������ �α׺��� �����ð�    
 SELECT TOP 1 @last_restore_time_settle = convert(smalldatetime, (left(right(log_file, 16),4) + '-'+
	substring(right(log_file, 16),5,2) + '-' + 
	substring(right(log_file, 16),7,2) + ' ' +
	substring(right(log_file, 16),9,2) + ':00:00'), 120)     
 FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
 WHERE user_db_name = 'SETTLE' AND restore_flag = 1    
 ORDER BY reg_dt desc    
     
 --event�� ������ �α׺��� �����ð�    
 SELECT TOP 1 @last_restore_time_event = convert(smalldatetime, (left(right(log_file, 16),4) + '-'+
	substring(right(log_file, 16),5,2) + '-' + 
	substring(right(log_file, 16),7,2) + ' ' +
	substring(right(log_file, 16),9,2) + ':00:00'), 120)        
 FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
 WHERE user_db_name = 'EVENT' AND restore_flag = 1    
 ORDER BY reg_dt desc    
     
 --lion�� ������ �α׺��� �����ð�    
 SELECT TOP 1 @last_restore_time_lion = convert(smalldatetime, (left(right(log_file, 16),4) + '-'+
	substring(right(log_file, 16),5,2) + '-' + 
	substring(right(log_file, 16),7,2) + ' ' +
	substring(right(log_file, 16),9,2) + ':00:00'), 120)       
 FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
 WHERE user_db_name = 'LION' AND restore_flag = 1  
 ORDER BY reg_dt desc    
     
 --customer�� ������ �α׺��� �����ð�    
  SELECT TOP 1 @last_restore_time_customer = convert(smalldatetime, (left(right(log_file, 16),4) + '-'+
	substring(right(log_file, 16),5,2) + '-' + 
	substring(right(log_file, 16),7,2) + ' ' +
	substring(right(log_file, 16),9,2) + ':00:00'), 120)        
  FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
  WHERE user_db_name = 'CUSTOMER' AND restore_flag = 1    
  ORDER BY reg_dt desc    
     
 --������ �α׺��� �ð��� 6�ð� �̻� ���̰� ������ üũ    
 IF DATEDIFF(hour, @last_restore_time_tiger, getdate()) >= 6 --��� ���� by ceusee
 BEGIN
    IF LEN(@msg) > 0 SET @msg = @msg + ','
    SET @msg = @msg + 'TIGER '  
 END  
     
 IF DATEDIFF(hour, @last_restore_time_settle, getdate()) >= 6   
 BEGIN
    IF LEN(@msg) > 0 SET @msg = @msg + ','
    SET @msg = @msg + 'SETTLE '  
 END      
     
 IF DATEDIFF(hour, @last_restore_time_event, getdate()) >= 6    
  BEGIN
    IF LEN(@msg) > 0 SET @msg = @msg + ','
    SET @msg = @msg + 'EVENT '  
 END   
     
 IF DATEDIFF(hour, @last_restore_time_lion, getdate()) >= 6   
 BEGIN
    IF LEN(@msg) > 0 SET @msg = @msg + ','
    SET @msg = @msg + 'LION '  
 END  
     
  IF DATEDIFF(hour, @last_restore_time_customer, getdate()) >= 6    
   BEGIN
    IF LEN(@msg) > 0 SET @msg = @msg + ','
    SET @msg = @msg + 'CUSTOMER '  
 END    
     
 IF len(@msg) > 0    
 BEGIN   
  SET @serverName = '['+ @@SERVERNAME + ']' 
  SET @msg = @serverName + @msg + '�α׺��� 6�ð� �̻� ������'    
     
 INSERT INTO [SMS].kidc_sms.dbo.smscli_tbl_02(destination, originator, callback, body,proc_status, teleservice_id )     
 SELECT REPLACE(HPNo, '-', ''), '160701001001', '15665701', @msg, '1', '4098' FROM OperatorSimple WITH (NOLOCK) WHERE backupFlag = 1 

END  
SET NOCOUNT OFF
RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO