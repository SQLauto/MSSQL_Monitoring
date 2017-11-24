SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_BackupLog_LiteSpeed' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_BackupLog_LiteSpeed
GO
/**************************************************************************************************************    
SP    명 : up_DBA_BackupLog_LiteSpeed  
작성정보: 2006-08-07 양은선  
내용     : 트랜잭션 로그 백업   
===============================================================================  
    수정정보   
2006-09-27 김태환 maxtransfer값 변경  
   @maxtransfersize = 4194304 ==> @maxtransfersize = 2097152  
2006-10-13 김태환 maxtransfer값 변경  
   @maxtransfersize = 2097152 ==> @maxtransfersize = 1048576  
2006-11-07 김태환 IOflag의 설정을 LiteSpeed defalut으로 변경  
   @ioflag=OVERLAPPED  
   @ioflag='FILE_EXTENSION=-1'  
   @ioflag=NO_BUFFERING  
2006-11-07 김태환 thread count : 16-8로 조정  
  
===============================================================================  
  
**************************************************************************************************************/   
--DROP  PROCEDURE dbo.up_DBA_BackupLog_LiteSpeed  
CREATE  PROCEDURE dbo.up_DBA_BackupLog_LiteSpeed  
 @sp_db_name sysname = ''  --TIGER, SETTLE, EVENT, LION, PAST, CUSTOMER  
AS  
  
SET NOCOUNT ON  
  
DECLARE   
 @var_fullpath   varchar(300)  
, @var_filename  varchar(200)  
, @var_backupname varchar(200)   
,  @var_with   varchar(200)  
,  @var_getdate   datetime  
,  @var_seqno   int  
  
IF @sp_db_name = '' RETURN  
  
-----------------------------------------------------------  
--1. 필요 변수 세팅  
-----------------------------------------------------------  
BEGIN  
 SET @sp_db_name = replace(@sp_db_name, ' ', '')  
 SET @var_getdate = getdate()  
 SET @var_filename =   
     + 'LiteSpeed_'   
     + @sp_db_name   
     + '_tlog_'   
     + replace(replace(convert(char(10), @var_getdate, 121), '-', ''), ' ', '')   
     + right(replace('00' + convert(char(2), datepart(hh, @var_getdate)), ' ', ''), 2)  
     + right(replace('00' + convert(char(2), datepart(mi, @var_getdate)), ' ', ''), 2)  
     + '.TRN'  
 SET @var_filename = replace(@var_filename, ' ', '')  
 SET @var_fullpath = 'G:\super64backup\' + @sp_db_name + '\' + @var_filename   
 SET @var_backupname = @sp_db_name + ' backup'  
   
 --SELECT @var_fullpath, @var_filename, @var_backupname  
END  
  
-----------------------------------------------------------  
--2. 백업 리스트 입력  
-----------------------------------------------------------  
BEGIN  
 IF @sp_db_name = 'TIGER'    INSERT INTO dba.dbo.backup_list(log_file) values(@var_filename)  
 ELSE IF @sp_db_name = 'SETTLE'  INSERT INTO dba.dbo.backup_list_settle(log_file) values(@var_filename)  
 ELSE IF @sp_db_name = 'EVENT'   INSERT INTO dba.dbo.backup_list_event(log_file) values(@var_filename)  
 ELSE IF @sp_db_name = 'LION'   INSERT INTO dba.dbo.backup_list_lion(log_file) values(@var_filename)  
 ELSE IF @sp_db_name = 'PAST'   INSERT INTO dba.dbo.backup_list_past(log_file) values(@var_filename)  
 ELSE IF @sp_db_name = 'CUSTOMER'  INSERT INTO dba.dbo.backup_list_customer(log_file) values(@var_filename)  
  
 SET @var_seqno = SCOPE_IDENTITY()   
END   
  
-----------------------------------------------------------  
--3. 트랜잭션 로그 백업  
-----------------------------------------------------------  
BEGIN  
/*  
 EXEC master.dbo.xp_backup_log   
  @database = @sp_db_name  
 , @filename = @var_fullpath  
 , @backupname = @var_backupname  
 , @init = 1  
 , @logging = 2  
 , @maxtransfersize = 4194304  
 , @ioflag=OVERLAPPED  
 , @ioflag='FILE_EXTENSION=-1'  
 , @ioflag=NO_BUFFERING  
 -- , @with = 'SKIP'  
 -- , @with = 'STATS = 10'  
*/  
 EXEC master.dbo.xp_backup_log   
          @database = @sp_db_name  
 ,        @filename = @var_fullpath  
 ,        @backupname = @var_backupname  
 ,        @init = 1  
  ,        @logging = 2  
 ,        @maxtransfersize = 1048576  
--  ,        @ioflag=OVERLAPPED  
--  ,        @ioflag='FILE_EXTENSION=-1'  
--  ,        @ioflag=NO_BUFFERING  
 ,        @threads = 8  
 ,        @buffercount = 20  
        -- ,    @with = 'SKIP'  
        -- ,    @with = 'STATS = 10'  
  
 IF @@error <> 0   
 BEGIN   
  IF @sp_db_name = 'TIGER'    UPDATE dba.dbo.backup_list SET err = @@error WHERE seqno = @var_seqno  
  ELSE IF @sp_db_name = 'SETTLE'  UPDATE dba.dbo.backup_list_settle SET err = @@error WHERE seqno = @var_seqno  
  ELSE IF @sp_db_name = 'EVENT'   UPDATE dba.dbo.backup_list_event SET  err = @@error WHERE seqno = @var_seqno  
  ELSE IF @sp_db_name = 'LION'   UPDATE dba.dbo.backup_list_lion SET err = @@error WHERE seqno = @var_seqno  
  ELSE IF @sp_db_name = 'PAST'   UPDATE dba.dbo.backup_list_past SET err = @@error WHERE seqno = @var_seqno  
  ELSE IF @sp_db_name = 'CUSTOMER'  UPDATE dba.dbo.backup_list_customer SET err = @@error WHERE seqno = @var_seqno  
 END   
END  
  
-----------------------------------------------------------  
--4. 백업 리스트 변경  
-----------------------------------------------------------  
BEGIN  
 IF @sp_db_name = 'TIGER'    UPDATE dba.dbo.backup_list SET backup_y = 'Y', backup_end_time = getdate(), backup_duration = datediff(s, backup_start_time, getdate()) WHERE seqno = @var_seqno  
 ELSE IF @sp_db_name = 'SETTLE'  UPDATE dba.dbo.backup_list_settle SET backup_y = 'Y',  backup_end_time = getdate(), backup_duration = datediff(s, backup_start_time, getdate()) WHERE seqno = @var_seqno  
 ELSE IF @sp_db_name = 'EVENT'   UPDATE dba.dbo.backup_list_event SET  backup_y = 'Y', backup_end_time = getdate(), backup_duration = datediff(s, backup_start_time, getdate()) WHERE seqno = @var_seqno  
 ELSE IF @sp_db_name = 'LION'   UPDATE dba.dbo.backup_list_lion SET  backup_y = 'Y', backup_end_time = getdate(), backup_duration = datediff(s, backup_start_time, getdate()) WHERE seqno = @var_seqno  
 ELSE IF @sp_db_name = 'PAST'   UPDATE dba.dbo.backup_list_past SET  backup_y = 'Y', backup_end_time = getdate(), backup_duration = datediff(s, backup_start_time, getdate()) WHERE seqno = @var_seqno  
 ELSE IF @sp_db_name = 'CUSTOMER'  UPDATE dba.dbo.backup_list_customer SET  backup_y = 'Y', backup_end_time = getdate(), backup_duration = datediff(s, backup_start_time, getdate()) WHERE seqno = @var_seqno  
END   
 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO