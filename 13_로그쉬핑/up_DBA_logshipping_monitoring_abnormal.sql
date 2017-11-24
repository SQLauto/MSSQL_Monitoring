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
* 프로시저명  : dbo.up_DBA_logshipping_monitoring_abnormal 
* 작성정보    : 2006-05-12
* 관련페이지  :  
* 내용        : 1시간 간격으로 6시간 이상 복원이 지연되었는지 모니터링
* 수정정보    : 
    2006-06-21 MYLEE SMS 보내는 부분 이민안 대리 빼고, 윤태진 대리 추가    
    2006-08-09    YES  김태환, 최진영, 권병준 추가    
    2006-08-27   YES  lion, customer DB 모니터링 추가    
    2006-08-31 김태환 김기홍 차장 SMS목록에서 제거    
    2006-09-06 김태환 김인현 팀장, 양은선 과장 SMS목록에서 제거    
    2007-01-09 SMS목록에서 오경배 과장 제거, 이상훈 대리 추가 
    2007-08-10 by 최보라 테이블 변경에 따른 로직 변경 
    2008-04-18 by 최보라 로그 복원시간이 아닌 파일 복원이름 으로 체크
**************************************************************************/
 CREATE  PROCEDURE dbo.up_DBA_logshipping_monitoring_abnormal    
AS    
    
 SET NOCOUNT ON    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
     
 DECLARE @hour int, @year int, @serverName    NVARCHAR(10)    
 DECLARE @last_restore_time_tiger smalldatetime, @last_restore_time_settle smalldatetime, @last_restore_time_event smalldatetime, @msg varchar(2000)    
 DECLARE @last_restore_time_lion smalldatetime, @last_restore_time_customer smalldatetime    
 SET @msg = ''    
     
 --tiger의 마지막 로그복원 성공시간    
 SELECT TOP 1 @last_restore_time_tiger = convert(smalldatetime, (left(right(log_file, 16),4) + '-'+
	substring(right(log_file, 16),5,2) + '-' + 
	substring(right(log_file, 16),7,2) + ' ' +
	substring(right(log_file, 16),9,2) + ':00:00'), 120)        
 FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
 WHERE user_db_name = 'TIGER' AND restore_flag = 1   
 ORDER BY reg_dt desc    
     
 --settle의 마지막 로그복원 성공시간    
 SELECT TOP 1 @last_restore_time_settle = convert(smalldatetime, (left(right(log_file, 16),4) + '-'+
	substring(right(log_file, 16),5,2) + '-' + 
	substring(right(log_file, 16),7,2) + ' ' +
	substring(right(log_file, 16),9,2) + ':00:00'), 120)     
 FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
 WHERE user_db_name = 'SETTLE' AND restore_flag = 1    
 ORDER BY reg_dt desc    
     
 --event의 마지막 로그복원 성공시간    
 SELECT TOP 1 @last_restore_time_event = convert(smalldatetime, (left(right(log_file, 16),4) + '-'+
	substring(right(log_file, 16),5,2) + '-' + 
	substring(right(log_file, 16),7,2) + ' ' +
	substring(right(log_file, 16),9,2) + ':00:00'), 120)        
 FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
 WHERE user_db_name = 'EVENT' AND restore_flag = 1    
 ORDER BY reg_dt desc    
     
 --lion의 마지막 로그복원 성공시간    
 SELECT TOP 1 @last_restore_time_lion = convert(smalldatetime, (left(right(log_file, 16),4) + '-'+
	substring(right(log_file, 16),5,2) + '-' + 
	substring(right(log_file, 16),7,2) + ' ' +
	substring(right(log_file, 16),9,2) + ':00:00'), 120)       
 FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
 WHERE user_db_name = 'LION' AND restore_flag = 1  
 ORDER BY reg_dt desc    
     
 --customer의 마지막 로그복원 성공시간    
  SELECT TOP 1 @last_restore_time_customer = convert(smalldatetime, (left(right(log_file, 16),4) + '-'+
	substring(right(log_file, 16),5,2) + '-' + 
	substring(right(log_file, 16),7,2) + ' ' +
	substring(right(log_file, 16),9,2) + ':00:00'), 120)        
  FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
  WHERE user_db_name = 'CUSTOMER' AND restore_flag = 1    
  ORDER BY reg_dt desc    
     
 --마지막 로그복원 시간과 6시간 이상 차이가 나는지 체크    
 IF DATEDIFF(hour, @last_restore_time_tiger, getdate()) >= 6 --잠시 수정 by ceusee
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
  SET @msg = @serverName + @msg + '로그복원 6시간 이상 지연됨'    
     
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