SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects
	   WHERE  name = N'up_DBA_logshipping_monitoring_abnormal_filecopy' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_logshipping_monitoring_abnormal_filecopy
*/

/*************************************************************************  
* ���ν�����  : dbo.up_DBA_logshipping_monitoring_abnormal_filecopy 
* �ۼ�����    : 2006-07-12 ������ 
* ����������  :  
* ����        : 1�ð� �������� 1�ð� �̻� ����ī�ǰ� �����Ǿ����� ����͸�    
* ��������    :
    2006-08-31 ����ȯ ���ȫ ���� SMS��Ͽ��� ����    
    2006-09-06 ����ȯ ������ ����, ������ ���� SMS��Ͽ��� ����    
    2007-01-09 �̻��� �븮 SMS��Ͽ� �߰�  
    2007-07-06 by �ֺ���  ���� ī���ϴ� �ð����� �÷����� ����, ������ ����� ���
    2007-07-07 by �ֺ���  Tiger, Customer �α׸� ������ϴ� �ð��� üũ���� �������
    2007-08-10 by �ֺ���  ���̺� ���濡 ���� ���� ����
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_logshipping_monitoring_abnormal_filecopy
AS

 SET NOCOUNT ON    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
     
 DECLARE @hour int, @year int
 DECLARE @serverName    NVARCHAR(10)
 DECLARE @last_copy_time_tiger smalldatetime, @last_copy_time_settle smalldatetime, @last_copy_time_event smalldatetime, @msg varchar(2000)    
 DECLARE @last_copy_time_customer smalldatetime, @last_copy_time_past smalldatetime, @last_copy_time_lion smalldatetime    
     
 SET @msg = ''    
 SET @hour = DATEPART(hh, GETDATE())
     
 --tiger�� ������ ����ī�� �����ð� 
 --tiger�� ����� ���� 5�� 15�� ���� ���� 2�� 49�� 59�� ������ �߻�

 IF @hour < 3 AND @hour  > 5 
 BEGIN  
     SELECT TOP 1 @last_copy_time_tiger = copy_end_time    
     FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
     WHERE user_db_name = 'TIGER' AND copy_flag = 1     
     ORDER BY reg_dt desc   
     
      --������ ����ī�� �ð��� 1�ð� �̻� ���̰� ������ üũ    
     IF DATEDIFF(mi, @last_copy_time_tiger, getdate()) >= 100
     BEGIN
      IF LEN(@msg) > 0 SET @msg = @msg + ','      
      SET @msg = @msg + 'TIGER'    
     END
 END 
     
 --settle�� ������ ����ī�� �����ð�    
 SELECT TOP 1 @last_copy_time_settle = copy_end_time    
 FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
 WHERE user_db_name = 'SETTLE' AND copy_flag = 1    
 ORDER BY reg_dt desc 
 
 IF DATEDIFF(mi, @last_copy_time_settle, getdate()) >= 100 
 BEGIN
  IF LEN(@msg) > 0 SET @msg = @msg + ','   
  SET @msg = @msg + 'SETTLE'    
 END   
     
 --event�� ������ ����ī�� �����ð�    
 SELECT TOP 1 @last_copy_time_event = copy_end_time    
 FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
 WHERE user_db_name = 'EVENT' AND copy_flag = 1  
 ORDER BY reg_dt desc 
 
 IF DATEDIFF(mi, @last_copy_time_event, getdate()) >= 100    
 BEGIN
  IF LEN(@msg) > 0 SET @msg = @msg + ','  
  SET @msg = @msg + 'EVENT'
 END   
     
 --customer�� ������ ����ī�� �����ð� 
 --���� ���� 4�� 13�� ~ ���� 2�� 59�� ���� �߻�
 IF @hour < 2 AND @hour > 3
 BEGIN
     SELECT TOP 1 @last_copy_time_customer = copy_end_time    
     FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
     WHERE user_db_name = 'CuSTOMER' AND copy_flag = 1   
     ORDER BY reg_dt desc
     
     IF @hour >= 4  and @hour <= 5 -- ���� 4�� 13�п� ����Ǵϱ�. 5�� 10�б��� �ȵǸ� ����
     BEGIN
        IF DATEDIFF(mi, @last_copy_time_customer, getdate()) >= 250
        BEGIN
            SET @msg = @msg + 'CUST' 
        END
     END
          
     IF DATEDIFF(mi, @last_copy_time_customer, getdate()) >= 100 
     BEGIN
      IF LEN(@msg) > 0 SET @msg = @msg + ','     
      SET @msg = @msg + 'CUST' 
     END
 END 

     
 --lion�� ������ ����ī�� �����ð�    
 SELECT TOP 1 @last_copy_time_lion = copy_end_time    
 FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
 WHERE user_db_name = 'LION' AND copy_flag = 1    
 ORDER BY reg_dt desc    
     

IF DATEDIFF(mi, @last_copy_time_lion, getdate()) >= 100
 BEGIN
  IF LEN(@msg) > 0 SET @msg = @msg + ','      
  SET @msg = @msg + 'LION'  
 END  
      
     

 IF len(@msg) > 0    
 BEGIN    
  SET @serverName = @@SERVERNAME
  SET @msg = '[' + @serverName + '] ' + @msg + '����ī�� 1�ð�30���̻� ����'    
     
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