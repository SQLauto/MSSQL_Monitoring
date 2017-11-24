/*============================================================================    
�� �� �� : �輼��    
�� �� �� : 2009.02.16    
�ۼ����� : DBMS�� ���ɸ���Ϳ��� �߻���Ű�� ALERT�� �����ϰ� SMS�� ���޵Ǵ�     
     ���� �����ϱ� ���Ͽ� ����    
�������� :   2009.07.14 Bug Fix  
    2010-04-22 by choi bo ra CPU ��Ȳ �и�, local system ���� ����  
    Ŭ�������� ��� @@servername�ϸ� �ùٸ� ���� �ƴ�  
    2011-03-15 by �輼��, ����, ���� ���� ���� ���� �����ϰ� ����
============================================================================*/    
ALTER PROCEDURE dbo.up_mon_alert_system   
  @type  char(10)  = 'TOTAL'  
  ,@cpu_count int  = 1  
  ,@pMessage NVARCHAR(4000)  
  ,@sms_yn char(1) = 'N'  
  
AS    
    
SET NOCOUNT ON    
    
 DECLARE @vSeq INT    
 DECLARE @vTimeDiff INT    
 DECLARE @vCounter NVARCHAR(500) 
 DECLARE @vInterval INT    
 DECLARE @vValue NVARCHAR(200)    
    
 DECLARE @vDateTime DATETIME    
    
 -- 5�� �������� SMS �߼�    
 SET @vInterval = 10
    
 SET @vDateTime = GETDATE()    
 -- Message Sample    
 --SET @pMessage= 'User Connections,2010-04-22 11:00:55,\SQLServer:General Statistics\User Connections,46,over 10'    
 --SET @pMessage= 'CPU,2010-04-22 10:54:04,\Processor(_Total)\% Processor Time,27.6492764927649,over 10'     
 --SET @pMessage= 'Blocking,2009-04-18 03:23:50,\SQLServer:General Statistics\Processes blocked,72,over 20'  
 --SET @pMessage = 'MAINDB2_CPU,2011-03-15 05:04:11,\\maindb2\Processor(_Total)\% Processor Time,0.882978022613246,�� 1'  
 -- �Էµ� �޽����� � ���� ���� ���� ������ ���� (User Connections or CPU)    
 
IF  charindex('_',@pMessage) > charindex(',',@pMessage)-1
    SET @vCounter = substring(@pMessage, 1,  charindex(',',@pMessage)-1 )    
ELSE
    SET @vCounter = substring(@pMessage, charindex('_',@pMessage) + 1, charindex(',',@pMessage) -charindex('_',@pMessage) - 1 )

INSERT INTO dbo.DB_MON_ALERT_SYSTEM(reg_date, message, Counter, Sent)    
VALUES(@vDateTime,@pMessage, @vCounter, 0);    


-- ����  
 exec msdb.dbo.sp_start_job '[DB_COLLECT] DB_MON_SYSPROCESS'  
 
--counter ����

set @vValue = left(SUBSTRING(@pMessage,CHARINDEX(',',@pMessage,CHARINDEX('\',@pMessage) + 1)+1 
,CHARINDEX(',',@pMessage,CHARINDEX(',',@pMessage,CHARINDEX('\',@pMessage) + 1)+1) - CHARINDEX(',',@pMessage,CHARINDEX('\',@pMessage) + 1)-1) , 5)
        
        + ',' + SUBSTRING(@pMessage,CHARINDEX(',',@pMessage,CHARINDEX(',',@pMessage,CHARINDEX(',',@pMessage,CHARINDEX('\',@pMessage) + 1)+1))+1,20)

set @pMessage = SUBSTRING(@pMessage,CHARINDEX(',',@pMessage)+1, CHARINDEX(',',@pMessage,CHARINDEX(',',@pMessage) + 1) - CHARINDEX(',',@pMessage)-1)

-- ���� �߼� ���� check
DECLARE @sFlag tinyint  
SET @sFlag = 0  
  
IF (@vCounter = N'CPU')  
BEGIN  
 IF ((SELECT TOP 1 DATEDIFF(mi,reg_date,GETDATE()) FROM dbo.DB_MON_ALERT_SYSTEM with (nolock) WHERE Counter=N'CPU' 
        AND Sent=1 ORDER BY reg_date DESC) >= @vInterval)    
  OR ((SELECT TOP 1 DATEDIFF(mi,reg_date,GETDATE()) FROM dbo.DB_MON_ALERT_SYSTEM with (nolock) WHERE Counter=N'CPU' 
        AND Sent=0 ORDER BY reg_date DESC) >= @vInterval)  
 BEGIN  
  SET @sFlag = 1  
 END  
END  
ELSE IF (@vCounter = N'User Connections')  
BEGIN  
 IF ((SELECT TOP 1 DATEDIFF(mi,reg_date,GETDATE()) FROM dbo.DB_MON_ALERT_SYSTEM with (nolock) 
        WHERE Counter=N'User Connections' AND Sent=1 ORDER BY reg_date DESC) >= @vInterval)  
  OR ((SELECT TOP 1 DATEDIFF(mi,reg_date,GETDATE()) FROM dbo.DB_MON_ALERT_SYSTEM with (nolock) 
        WHERE Counter=N'User Connections' AND Sent=0 ORDER BY reg_date DESC) >= @vInterval)  
 BEGIN  
  SET @sFlag = 1  
  select @sFlag
 END  
END  
ELSE IF (@vCounter = N'Blocking')  
BEGIN  
 IF ((SELECT TOP 1 DATEDIFF(mi,reg_date,GETDATE()) FROM dbo.DB_MON_ALERT_SYSTEM with (nolock)  WHERE Counter=N'Blocking' 
        AND Sent=1 ORDER BY reg_date DESC) >= @vInterval)  
  OR ((SELECT TOP 1 DATEDIFF(mi,reg_date,GETDATE()) FROM dbo.DB_MON_ALERT_SYSTEM with (nolock)  WHERE Counter=N'Blocking' 
        AND Sent=0 ORDER BY reg_date DESC)   >= @vInterval)
 BEGIN  
  SET @sFlag = 1  
 END  
END  

   
IF @sFlag = 1   and  @sms_yn = 'Y'  
BEGIN   
   DECLARE @vDiff INT    
   SET @vDiff = 0    
    
   PRINT 'ù��° ���� üũ Ȯ��'    
    
   IF ((@vCounter = N'Blocking') AND     
      EXISTS(SELECT session_id FROM sys.dm_exec_requests WHERE blocking_session_id > 0))    
  OR    
  (@vCounter <> N'Blocking')    
 BEGIN    
   
  IF (@vCounter = N'Blocking')  exec msdb.dbo.sp_start_job N'[DB_COLLECT] DB_MON_BLOCKING'  
    
  UPDATE dbo.DB_MON_ALERT_SYSTEM    
  SET Sent = 1    
  WHERE seq_no = IDENT_CURRENT('DB_MON_ALERT_SYSTEM')   
  
     
    --SMS �߼�  
    declare @sms varchar(200)
    set @pMessage = N'['+@@ServerName+N'] '+ @vCounter + '-' + @pMessage + ' ' + @vValue  
    set @sms = 'sqlcmd -S epdb2 -E -Q"exec smsdb.dbo.up_dba_send_short_msg ''DBA'',''' + @pMessage + '''"'
    exec xp_cmdshell  @sms
     
   --exec custinfodb.SMS_ADMIN.dbo.up_DBA_send_short_msg  'DBA', @pMessage  
        
  END    
END  

 /*  
 -- �޽��� SMS�� ���� �� �ִ� ũ��� ����ó��  
 -- cpu    
 IF (@vCounter = N'CPU')    
  BEGIN    
   IF @type = 'TOTAL'  
   BEGIN  
         --SET @pMessage = REPLACE(@pMessage, '\\' + @@servername + '\Processor(_Total)\% Processor Time,','')   
         SET @pMessage = REPLACE(@pMessage, '\Processor(_Total)\% Processor Time,','') -- local system���� ����  
         SET @vValue = SUBSTRING(@pMessage, CHARINDEX(',',@pMessage)+21,20)    
         SET @vValue = CAST(ROUND(CAST(SUBSTRING(@vValue, 1, CHARINDEX(',',@vValue)-1) AS Float),1) AS NVARCHAR(20))+'%'    
   END  
   ELSE IF @type = 'SQL'  
   BEGIN  
     --SET @pMessage = REPLACE(@pMessage, '\\' + @@servername + '\Process(sqlservr)\% Processor Time,','')    
     SET @pMessage = REPLACE(@pMessage, '\Process(sqlservr)\% Processor Time,','')    
     SET @vValue = SUBSTRING(@pMessage, CHARINDEX(',',@pMessage)+21,20)  
     -- 2657.0265702657�� ���� Process:%Processor Time���� CPU������ ������ ROUND 1ó��    
     SET @vValue = CAST(ROUND(CAST(SUBSTRING(@vValue, 1, CHARINDEX(',',@vValue)-1) AS Float)/@cpu_count,1) AS NVARCHAR(20))+'%'      
   END  
   
     
   SET @pMessage = SUBSTRING(@pMessage, 1, 24)    
   SET @pMessage = N'['+@@ServerName+N']'+@pMessage+ @vValue    
 END  
 -- Connection    
 ELSE IF (@vCounter = N'User Connections')    
  BEGIN    
   --SET @pMessage = REPLACE(@pMessage, '\\' + @@servername + '\SQLServer:General Statistics\User Connections,','')  
   SET @pMessage = REPLACE(@pMessage, '\SQLServer:General Statistics\User Connections,','')  
   SET @pMessage = N'['+@@ServerName+N']'+@pMessage    
   
  END    
 -- Processes Blocked  
 ELSE      
  BEGIN    
   --SET @pMessage = REPLACE(@pMessage, '\\' + @@servername + '\SQLServer:General Statistics\Processes blocked,','')   
   SET @pMessage = REPLACE(@pMessage, '\SQLServer:General Statistics\Processes blocked,','')     
   SET @pMessage = N'['+@@ServerName+N']'+@pMessage    
  END    
END  
*/  
  
  