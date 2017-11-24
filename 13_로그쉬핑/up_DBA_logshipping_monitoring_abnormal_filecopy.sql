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
* 프로시저명  : dbo.up_DBA_logshipping_monitoring_abnormal_filecopy 
* 작성정보    : 2006-07-12 양은선 
* 관련페이지  :  
* 내용        : 1시간 간격으로 1시간 이상 파일카피가 지연되었는지 모니터링    
* 수정정보    :
    2006-08-31 김태환 김기홍 차장 SMS목록에서 제거    
    2006-09-06 김태환 김인현 팀장, 양은선 과장 SMS목록에서 제거    
    2007-01-09 이상훈 대리 SMS목록에 추가  
    2007-07-06 by 최보라  파일 카피하는 시간으로 컬럼으로 변경, 서버명 제대로 명시
    2007-07-07 by 최보라  Tiger, Customer 로그를 백업안하는 시간을 체크에서 비워야함
    2007-08-10 by 최보라  테이블 변경에 따른 로직 변경
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
     
 --tiger의 마지막 파일카피 성공시간 
 --tiger의 백업이 오전 5시 15분 부터 오전 2시 49분 59초 사이테 발생

 IF @hour < 3 AND @hour  > 5 
 BEGIN  
     SELECT TOP 1 @last_copy_time_tiger = copy_end_time    
     FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
     WHERE user_db_name = 'TIGER' AND copy_flag = 1     
     ORDER BY reg_dt desc   
     
      --마지막 파일카피 시간과 1시간 이상 차이가 나는지 체크    
     IF DATEDIFF(mi, @last_copy_time_tiger, getdate()) >= 100
     BEGIN
      IF LEN(@msg) > 0 SET @msg = @msg + ','      
      SET @msg = @msg + 'TIGER'    
     END
 END 
     
 --settle의 마지막 파일카피 성공시간    
 SELECT TOP 1 @last_copy_time_settle = copy_end_time    
 FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
 WHERE user_db_name = 'SETTLE' AND copy_flag = 1    
 ORDER BY reg_dt desc 
 
 IF DATEDIFF(mi, @last_copy_time_settle, getdate()) >= 100 
 BEGIN
  IF LEN(@msg) > 0 SET @msg = @msg + ','   
  SET @msg = @msg + 'SETTLE'    
 END   
     
 --event의 마지막 파일카피 성공시간    
 SELECT TOP 1 @last_copy_time_event = copy_end_time    
 FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
 WHERE user_db_name = 'EVENT' AND copy_flag = 1  
 ORDER BY reg_dt desc 
 
 IF DATEDIFF(mi, @last_copy_time_event, getdate()) >= 100    
 BEGIN
  IF LEN(@msg) > 0 SET @msg = @msg + ','  
  SET @msg = @msg + 'EVENT'
 END   
     
 --customer의 마지막 파일카피 성공시간 
 --매일 오전 4시 13분 ~ 오전 2시 59분 사이 발생
 IF @hour < 2 AND @hour > 3
 BEGIN
     SELECT TOP 1 @last_copy_time_customer = copy_end_time    
     FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
     WHERE user_db_name = 'CuSTOMER' AND copy_flag = 1   
     ORDER BY reg_dt desc
     
     IF @hour >= 4  and @hour <= 5 -- 오전 4시 13분에 실행되니까. 5시 10분까지 안되면 에러
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

     
 --lion의 마지막 파일카피 성공시간    
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
  SET @msg = '[' + @serverName + '] ' + @msg + '파일카피 1시간30분이상 지연'    
     
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