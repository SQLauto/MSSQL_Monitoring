USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_log_size]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************
* 프로시저명  : dbo.up_mon_collect_log_size  
* 작성정보    : 2010-08-06 by choi bo ra   
* 관련페이지  :   
* 내용        :   
* 수정정보    :  2013-05-09 서은미 로그사이즈/오픈트랜잭션 old_start_time 정보 alert에 추가
			    2013-05-09 서은미 로그사이즈 10기가 이상일 경우 alert오도록 변경
				exec up_mon_collect_log_size 'I', 70, 'N'
**************************************************************************************/  
CREATE PROCEDURE [dbo].[up_mon_collect_log_size]
	 @site			char(1) 		 = 'G'   
    --,@db_name       VARCHAR(125)      --target database name    
    ,@limit_ratio   INT = 90           --limit used ratio  
    ,@checkpoint 	char(1) = 'N'      --checkpoint 여부
AS  
/* COMMON DECLARE */  
SET NOCOUNT ON  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED   
SET QUERY_GOVERNOR_COST_LIMIT 0   
/* USER DECLARE */  
DECLARE @sql_version INT 
DECLARE @backup 	int  
DECLARE @sql 		NVARCHAR(500)    
DECLARE @i 	 		int
DECLARE @tot_count	int
DECLARE @dbcc  		VARCHAR(100)    
DECLARE @sms_msg 	VARCHAR(80)  
DECLARE @db_name	varchar(256)
DECLARE @reg_date datetime 
DECLARE @sms		VARCHAR(200)
DECLARE @backup_path VARCHAR(100), @recovery_model VARCHAR(20), @backup_type INT, @filename VARCHAR(100) 
DECLARE @log_size  INT
DECLARE @opentran_duration INT

/* BODY */  
 
 
exec UP_SWITCH_PARTITION @table_name = 'DB_MON_LOG_SIZE',@column_name = 'reg_date'  


SET @sql_version =  @@microsoftversion / 0x01000000
SET @i = 1
set @reg_date  = getdate()
 --------------------------------------------------------------------    
 -- 각 db 별 log 사용량 조회    
 ---------------------------------------------------------------------    
 
   
    
   
 DECLARE @db_ratio INT    
 CREATE TABLE #tmp_dbcc    
 (    
  seqno INT NOT NULL IDENTITY(1,1)    
  ,dbnm VARCHAR(256)    
  ,log_size NUMERIC(20,8)    
  ,used_ratio NUMERIC(20,8)    
  ,status INT    
 )    
      
 SET @dbcc = 'DBCC SQLPERF(LOGSPACE)'    
   
 INSERT INTO #tmp_dbcc (dbnm, log_size, used_ratio , status)    
 EXEC(@dbcc)    
  
 SET @tot_count = @@ROWCOUNT
 IF @tot_count <= 0 RETURN     
     
 SET @db_ratio = 0
 SET @backup =0    
  
 SET @I  = 1
 	
 
 -- db loop 
 while (@i <= @tot_count)
 begin

	SET @recovery_model = ''
	SET @opentran_duration = 0
	SET @log_size = 0

 	SELECT @db_ratio = CONVERT(INT , used_ratio), @log_size =CONVERT(INT , log_size)
	, @recovery_model =   recovery_model_desc  , @db_name =  t.dbnm
	FROM #tmp_dbcc as t    
		JOIN sys.databases as d with(nolock)  on t.dbnm  = d.name
		LEFT JOIN DBMON.DBO.DB_MON_LOG_SIZE_DATABASE AS D1 WITH(NOLOCK) ON T.DBNM = D1.DB_NAME 
	WHERE  state_desc = 'online'
		AND D1.DB_NAME IS NULL
		and t.seqno = @i
 
  	if @recovery_model = '' 
	begin

	      
			set @i = @i + 1
			continue;
			
	end 

  	
  	--backup_type(1:native, 2:litespeed), backup_path 
		SELECT  TOP 1 @filename =  bf.physical_device_name
	, @backup_path = reverse( right(reverse( bf.physical_device_name), len( bf.physical_device_name) - charindex( '\', reverse( bf.physical_device_name), 1) + 1)) 
	FROM msdb.dbo.backupmediafamily bf with(nolock)
		join msdb.dbo.backupset bs with(nolock)  on bf.media_set_id = bs.media_set_id    
	WHERE bs.database_name = @db_name AND backup_start_date > DATEADD(day, -1, GETDATE()) and type='L'
	ORDER BY backup_start_date DESC

  	
  	IF CHARINDEX('LiteSpeed', @filename) > 0 
		SET @backup_type = 2
	ElSE 
		SET @backup_type = 1

  	
	 --------------------------------------------------------------------    
	 -- transaction log backup    
	 ---------------------------------------------------------------------    
	 IF @db_ratio >= @limit_ratio    
	 BEGIN  
	 	
	 	CREATE TABLE #OpenTranStatus
	 	 (
			ActiveTransaction varchar(25),
			Details sql_variant 
		 )

 		SET @sql = 'USE [' +@db_name + '] ' + char(10)   
		   + 'DBCC OPENTRAN WITH TABLERESULTS, NO_INFOMSGS'  

    	INSERT INTO #OpenTranStatus exec sp_executesql @sql  
    	
    	INSERT INTO DB_MON_OPENTRAN(REG_DATE,DB_NAME,ActiveTransaction,Details)
		SELECT getdate() REG_DATE,@db_name [db_name],ActiveTransaction, Details FROM #OpenTranStatus;

		SELECT @opentran_duration = datediff(minute,convert(datetime,details),getdate())
		FROM #OpenTranStatus where ActiveTransaction='OLDACT_STARTTIME'
		
   		DROP TABLE #OPENTRANSTATUS 

		
		-- 백업
		if @db_name  != 'tempdb'
		begin
			  select @backup=count(*) from  sys.sysprocesses with (nolock) 
		  	  where cmd like 'BACKUP%' and dbid = db_id(@db_name)
			  
			  --SELECT 'BACKUP 실행중', @backup, @db_name,@db_ratio,@recovery_model

		  	  
		  	  if @backup = 0
		  	  begin
				  	  	
		  	  	IF @recovery_model = 'SIMPLE'
		  	  	BEGIN
		  	  		
					if @sql_version < 10
					begin
						 SET @sql = 'BACKUP LOG ['  + @db_name + '] WITH TRUNCATE_ONLY' 
						 EXEC( @sql )        
					end
				END
				ELSE -- FULL 
				BEGIN
					IF @SITE = 'I'
					BEGIN
						
						
						SET @backup_path = @backup_path + 
						        @DB_NAME + '_log_' + convert(varchar(8),GETDATE(),112) +                                                 
  								convert(varchar(2),GETDATE(),108) + substring(convert(varchar(5),GETDATE(),108),4,2) +                                           
  								right('00000' + convert(varchar, DATEPART ( s ,    getdate() ) ), 2) + '.Trn'  
  								
						SET @SQL  = 'BACKUP LOG [' + @DB_NAME + '] TO DISK = ''' + @backup_path +  ''''
						
						--print @sql
			
						EXEC( @sql )   
						
					END
					ELSE IF @SITE = 'G'
					BEGIN
						SET @sql = 'DECLARE @ret_code INT;'
						SET @sql = @sql + 'EXEC DBA.dbo.up_DBA_Daily_DatabaseBackup '+@db_name+', 2, '+CONVERT(VARCHAR(1),@backup_type)+', ''LOG'', '''+@backup_path+''',16, 2097152, 0, 0, @ret_code output ; IF @ret_code <> 0 RETURN'
						EXEC( @sql )     
					END
				
				END
				
		  	 end
		  
		end
		else  --TEMPDB 
		begin
			if @checkpoint = 'Y'
			begin

				UPDATE DB_MON_LOG_SIZE
					SET CHECKPOINT_START_DATE = GETDATE()
				WHERE REG_DATE = @REG_DATE AND DB_NAME = @DB_NAME
		

				SET @sql = 'use tempdb' + char(10) 
							+ 'checkpoint'

				exec sp_executesql @sql

				update DB_MON_LOG_SIZE
					set checkpoint_end_date = getdate()
				where reg_date = @reg_date and db_name = @db_name

			end

		end
			 
			 
	      IF @db_ratio >=@limit_ratio AND @log_size > 10240
	      BEGIN
	      	
			 --------------------------------------------------------------------    
			 -- SMS 발송  
			 ---------------------------------------------------------------------  
			 SET @sms_msg = '['+ @@SERVERNAME + '] ' + @db_name + '로그 ' +  CONVERT(VARCHAR(10) , @db_ratio) + '%를 넘음'  + ', logsize(MB)=' +  CONVERT(VARCHAR(10), @log_size)+ ', 오픈트랜(분)=' +  CONVERT(VARCHAR(10), @opentran_duration)
			
			 if @site = 'G'
			 BEGIN
				set @sms = 'sqlcmd -S GCONTENTSDB,3950 -E -Q"exec sms_admin.dbo.up_dba_send_short_msg ''DBA'',''' + @sms_msg + '''"'
				exec xp_cmdshell  @sms 
			 END
			 else if @site = 'I'
			 begin
			 	
	  			set @sms = 'sqlcmd -S epdb2 -E -Q"exec smsdb.dbo.up_dba_send_short_msg ''DBA'',''' + @sms_msg + '''"'  
	  			exec xp_cmdshell  @sms 
	  		 end 
		              
			 INSERT INTO DB_MON_LOG_SIZE   
			 (reg_date, db_name, use_ratio, limit_ratio)  
			 VALUES   
			(getdate(), @db_name, @db_ratio, @limit_ratio)  
			 
	     END  
	  
	   
	END  
   
   set @i = @i  + 1
   
end
RETURN 



GO
