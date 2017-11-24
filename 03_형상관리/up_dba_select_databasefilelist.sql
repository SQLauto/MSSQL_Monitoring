SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
 /*************************************************************************      
* 프로시저명  : dbo.up_mon_collect_log_size    
* 작성정보    : 2010-08-06 by choi bo ra     
* 관련페이지  :     
* 내용        :     
* 수정정보    : 2011-06-15 by choi bo ra, 버전,백업 체크   
**************************************************************************/    
ALTER PROCEDURE dbo.up_mon_collect_log_size     
     @db_name       VARCHAR(125)       --target database name      
    ,@limit_ratio   INT = 90           --limit used ratio     
AS    
/* COMMON DECLARE */    
SET NOCOUNT ON    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED     
SET QUERY_GOVERNOR_COST_LIMIT 0     
/* USER DECLARE */    
    
/* BODY */    
    
exec UP_SWITCH_PARTITION @table_name = 'DB_MON_LOG_SIZE',@column_name = 'reg_date'
    
 --------------------------------------------------------------------      
 -- 각 db 별 log 사용량 조회      
 ---------------------------------------------------------------------      
 DECLARE @dbcc  VARCHAR(100)      
 DECLARE @sms_msg VARCHAR(80)     
 DECLARE @today VARCHAR(10)  
 DECLARE @version int  
 SET @today = CONVERT(VARCHAR(10), getdate(), 121)  
      
     
 DECLARE @db_ratio INT      
 CREATE TABLE #tmp_dbcc      
 (      
  seqno INT NOT NULL IDENTITY(1,1)      
  ,dbnm VARCHAR(20)      
  ,log_size NUMERIC(20,8)      
  ,used_ratio NUMERIC(20,8)      
  ,status INT      
 )      
        
 SET @dbcc = 'DBCC SQLPERF(LOGSPACE)'      
     
 INSERT INTO #tmp_dbcc (dbnm, log_size, used_ratio , status)      
 EXEC(@dbcc)      
     
 IF @@ROWCOUNT <= 0 RETURN       
       
 SET @db_ratio = 0      
       
 SELECT @db_ratio = CONVERT(INT , used_ratio)        
 FROM #tmp_dbcc       
 WHERE dbnm = @db_name       
    
    
     
 --------------------------------------------------------------------      
 -- transaction log backup      
 ---------------------------------------------------------------------      
    
     
 IF @db_ratio >= @limit_ratio      
 BEGIN      
  
   IF NOT EXISTS(SELECT * FROM msdb.dbo.backupset WITH(NOLOCK) where database_name = @db_name   
     AND backup_start_date > @today AND backup_finish_date is null  
     AND type in ('D', 'L'))  
   BEGIN 
   
		-- 버전 체크
		SET @version = convert(int, left( convert(nvarchar(10), serverproperty('productversion')), 2))
		IF @version < 10
		BEGIN
			DECLARE @sql VARCHAR(500)      
			SET @sql = 'BACKUP LOG '  + @db_name + ' WITH TRUNCATE_ONLY'      
	             
			EXEC( @sql )
		END       
   END     
         
  IF @db_ratio >=70  
  BEGIN  
   --------------------------------------------------------------------      
   -- SMS 발송    
   ---------------------------------------------------------------------    
   SET @sms_msg = '['+ @@SERVERNAME + '] ' + @db_name + '로그 ' +  CONVERT(VARCHAR(10) , @db_ratio) + '%를 넘음-백업완료'     
   exec CUSTINFODB.sms_admin.dbo.up_dba_send_short_msg 'DBA', @sms_msg    
          
          
   INSERT INTO DB_MON_LOG_SIZE     
   (reg_date, db_name, use_ratio, limit_ratio)    
   VALUES     
   (getdate(), @db_name, @db_ratio, @limit_ratio)    
	 END    
    
 
END    
 

RETURN   
  
  


SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO


