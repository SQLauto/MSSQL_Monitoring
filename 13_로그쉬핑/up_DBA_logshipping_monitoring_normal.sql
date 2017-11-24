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
* 프로시저명  : dbo.up_DBA_logshipping_monitoring_normal 
* 작성정보    : 2006-05-12 양은선
* 관련페이지  :  
* 내용        : 매일 6시, 22시(주말은 14시 추가) 정상적으로 복원된 마지막 복원 파일 알려줌
* 수정정보    : 
    2006-06-21 MYLEE SMS 보내는 부분 이민안 대리 빼고, 윤태진 대리 추가    
    2006-08-09    YES  김태환, 최진영, 권병준 추가, LiteSpeed_는 파일명에서 제거    
    2006-08-31 김태환 김기홍 차장 SMS목록에서 제거    
    2006-09-06 김태환 김인현 팀장, 양은선 과장 SMS목록에서 제거  
    2007-01-09 이상훈 대리 SMS목록에 추가  
    2007-08-10 최보라 로직 변경에 따른 테이블 변경, SMS 목록 자동화로 정리 
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
 --2006-08-27 YES lion, customer DB 모니터링 추가    
 ------------------------------------------------------------------------------------------------------------------------------------------------------------    
 SELECT TOP 1 @last_log_file_name_lion = log_file    
 FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
 WHERE user_db_name = 'LION' AND restore_flag = 1    
 ORDER BY reg_dt desc    
    
 SELECT TOP 1 @last_log_file_name_customer = log_file    
 FROM  dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)    
 WHERE user_db_name = 'CUSTOMER' AND restore_flag = 1    
 ORDER BY reg_dt desc    
 
 
  
 SET @msg = '[' + @@SERVERNAME + ']복원성공 : '
 IF @last_log_file_name_tiger IS NOT NULL OR @last_log_file_name_tiger <> '' SET @msg = @msg + ' ' + @last_log_file_name_tiger
 IF @last_log_file_name_settle IS NOT NULL OR @last_log_file_name_settle <> '' SET @msg =@msg + ' ' + @last_log_file_name_settle
 IF @last_log_file_name_event IS NOT NULL OR @last_log_file_name_event <> '' SET @msg =@msg + ' ' + @last_log_file_name_event

     

 SET @msg = replace(@msg, 'tlog_', '')    
 SET @msg = replace(@msg, 'LiteSpeed', '') 
 SET @msg = replace(@msg, '.TRN', '')   
 SET @msg = replace(@msg, convert(varchar,@year), '')  

     
 INSERT INTO [SMS].kidc_sms.dbo.smscli_tbl_02(destination, originator, callback, callbackURL, body,proc_status, teleservice_id )     
 SELECT REPLACE(HPNo, '-', ''), '160701001001', '15665701', null,@msg, '1', '4098' FROM OperatorSimple WITH (NOLOCK) WHERE backupFlag = 1  

  
 SET @msg = '[' + @@SERVERNAME + ']복원성공 : '
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