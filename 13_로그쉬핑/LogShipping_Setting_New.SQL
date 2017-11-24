/*==========================================
  2011.10.11 LogShipping 처리를 위한것.
*===========================================*/

/*==========================================
  Target DB
*===========================================*/


use logshipping_db
go

CREATE TABLE LOGSHIPPING_RESTORE_LIST
( 
        user_db_name sysname    NOT NULL   , 
        seq_no int    NOT NULL   , 
        backup_no int    NOT NULL   , 
        log_file nvarchar (200)   NOT NULL   , 
        copy_flag tinyint    NOT NULL  CONSTRAINT DF__LOGSHIPPING_RESTORE_LIST__COPY_FLAG DEFAULT ((0))  , 
        copy_end_time datetime    NULL   , 
        restore_type smallint    NOT NULL  CONSTRAINT DF__LOGSHIPPING_RESTORE_LIST__RESTORE_TYPE DEFAULT ((1))  , 
        restore_flag smallint    NOT NULL  CONSTRAINT DF__LOGSHIPPING_RESTORE_LIST__RESTORE_FLAG DEFAULT ((0))  , 
        restore_start_time datetime    NULL   , 
        restore_end_time datetime    NULL   , 
        restore_duration int    NOT NULL  CONSTRAINT DF__LOGSHIPPING_RESTORE_LIST__RESTORE_DURATION DEFAULT ((0))  , 
        delete_flag tinyint    NOT NULL  CONSTRAINT DF__LOGSHIPPING_RESTORE_LIST__DELETE_FLAG DEFAULT ((0))  , 
        delete_time datetime    NULL   , 
        error_code int    NOT NULL  CONSTRAINT DF__LOGSHIPPING_RESTORE_LIST__ERROR_CODE DEFAULT ((0))  , 
        reg_dt datetime    NOT NULL  CONSTRAINT DF__LOGSHIPPING_RESTORE_LIST__REG_DT DEFAULT (getdate())  , 
        copy_start_time datetime    NULL  
)  ON [PRIMARY]
GO
ALTER TABLE LOGSHIPPING_RESTORE_LIST ADD CONSTRAINT PK_LOGSHIPPING_RESTORE_LIST primary key clustered ([user_db_name] ASC, [seq_no] ASC  ) ON [PRIMARY] 
GO
CREATE nonclustered INDEX IDX__LOGISHIPPING_RESTORE_LIST__RESTORE_FLAG ON LOGSHIPPING_RESTORE_LIST ([restore_flag] ASC ) ON [PRIMARY] 
GO

--=====================================    
-- 프로시저    
--=====================================    
      
/*************************************************************************    
* 프로시저명  : dbo.up_DBA_logshipping_restore   
* 작성정보    : 2007-08-03 choi bo ra(ceusee)  
* 관련페이지  :    
* 내용        : 트랜젝션 로그 파일 복원  
* 수정정보    : 2007-08-20 종료일자 수정  
			   2012-05-17  홀수/짝수 체크하지 않게 처리
**************************************************************************/  
ALTER PROCEDURE dbo.up_DBA_logshipping_restore  
    @user_db_name       SYSNAME,   
    @file_dir           NVARCHAR(256) = NULL,  
    @standy_dir         NVARCHAR(256),  
    @hour               INT,           -- 1:홀수시간, 2:짝수시간  
    @ret_code           INT  OUTPUT  
AS  
/* COMMON DECLARE */  
SET NOCOUNT ON  
SET @ret_code = -1  
  
/* USER DECLARE */  
DECLARE @min_seq_no             INT  
DECLARE @max_seq_no             INT  
DECLARE @restore_type   TINYINT  
DEClARE @dtGetDate              DATETIME  
DECLARE @log_file_name          NVARCHAR(200)  
DECLARE @restore_full_name      NVARCHAR(256)  
DECLARE @standy_file_name       NVARCHAR(256)  
SET @min_seq_no = 0  
SET @max_seq_no = 0  
  
  
/* BODY */  
SET @user_db_name = UPPER(@user_db_name)  
IF @user_db_name IS NULL  
BEGIN  
     SET @ret_code = 11 -- 데이터베이스 명 입력  
     RETURN  
END  
  
  
IF @file_dir = '' OR @file_dir = NULL  
BEGIN  
    SET @ret_code = 12    -- 디렉토리 경로 입력  
    RETURN  
END  
  
IF @standy_dir = '' OR @standy_dir = NULL  
BEGIN  
    SET @ret_code = 14    -- 디렉토리 경로 입력  
    RETURN  
END  
  
 
  
/* 
-- 실행될 시간 체크  
IF @hour = 1  AND (DATEPART(HH,GETDATE())%2) = 0  -- 홀수시간  
BEGIN  
    SET @ret_code = 0  
    RETURN  
END  
ELSE IF @hour = 2  AND (DATEPART(HH,GETDATE())%2) = 1  -- 짝수시간  
BEGIN  
    SET @ret_code = 0  
    RETURN  
END  
  
*/  

IF @standy_dir IS NOT NULL
	SET @standy_file_name = 'STANDBY= N''' + @standy_dir + '\' + @user_db_name + '_StandBy.tdf'''  
  
  
-- Step 1. 복원할 파일 정보 확인  
SELECT @min_seq_no = MIN(seq_no), @max_seq_no = MAX(seq_no)   
FROM dbo.LOGSHIPPING_RESTORE_LIST  WITH (NOLOCK)  
WHERE user_db_name = @user_db_name AND restore_flag <> 1  AND copy_flag = 1  AND restore_end_time is null  
  
SET @ret_code = @@ERROR  
IF @ret_code <> 0 RETURN  
  
  
-- Step 2. 복원  
IF @min_seq_no <>  0 AND  @max_seq_no <>  0  
BEGIN  
    WHILE (@min_seq_no <= @max_seq_no)  
    BEGIN  
        
      
    IF @hour = 1  AND (DATEPART(HH,GETDATE())%2) = 0  -- 홀수시간  
    BEGIN  
        SET @ret_code = 0  
        BREAK  
    END  
    ELSE IF @hour = 2  AND (DATEPART(HH,GETDATE())%2) = 1  -- 짝수시간  
    BEGIN  
        SET @ret_code = 0  
        BREAK  
    END   
       
    IF @hour > 0 and DATEPART(MI,GETDATE()) >= @hour BREAK;  
          
    SELECT @log_file_name = log_file, @restore_type = restore_type   
    FROM dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)   
        WHERE user_db_name = @user_db_name AND seq_no = @min_seq_no  
    SET @ret_code = @@ERROR  
    IF @ret_code <> 0 BREAK;  
  
   
    IF @log_file_name <> '' OR @log_file_name  IS NOT NULL  
    BEGIN  
        SET @restore_full_name = @file_dir + '\' + @user_db_name + '\' + @log_file_name  
        SET @dtGetDate = GETDATE()  
           
  
        UPDATE dbo.LOGSHIPPING_RESTORE_LIST SET restore_start_time =@dtGetDate   
        WHERE user_db_name = @user_db_name AND seq_no = @min_seq_no  
             
        SET @ret_code = @@ERROR  
        IF @ret_code <> 0 BREAK;  
             
        -- 사용자 Kill  
        --EXEC master.dbo.sp_dba_process_user_kill @user_db_name  
        --SET @ret_code = @@ERROR  
        --IF @ret_code <> 0 BREAK;  
  
   IF @restore_type = 1  
   BEGIN  

	IF @standy_dir is not null
	BEGIN

		RESTORE LOG @user_db_name    
		FROM DISK = @restore_full_name    
		WITH STANDBY=@standy_file_name    
  
	END
	ELSE
	BEGIN

		RESTORE LOG @user_db_name    
		FROM DISK = @restore_full_name    
		WITH NORECOVERY
		
	END
  
	
   SET @ret_code = @@ERROR  
   END  
   ELSE IF @restore_type = 2  
   BEGIN  
		IF @standy_dir is not null
		BEGIN
			EXEC @ret_code = master.dbo.xp_restore_log     
				@database = @user_db_name,  
				@filename = @restore_full_name,  
				@logging = 2,   
				@with =  @standy_file_name    
		END	 
    
		ELSE
		BEGIN
			EXEC @ret_code = master.dbo.xp_restore_log     
				@database = @user_db_name,  
				@filename = @restore_full_name,  
				@logging = 2,   
				@with = 'NORECORY'
		END

   END
	 
     
   IF @ret_code <> 0   -- 에러  
   BEGIN  
    UPDATE dbo.LOGSHIPPING_RESTORE_LIST   
                SET restore_flag = 2,   
                    --restore_end_time = GETDATE(),   
                    --restore_duration = DATEDIFF(ss, @dtGetDate, GETDATE()),  
                    error_code = @ret_code           
                WHERE user_db_name = @user_db_name AND seq_no = @min_seq_no   
                  
    BREAK; --LOOP 빠져나감   
      
  
  
   END  
   ELSE   -- 성공  
   BEGIN  
    UPDATE dbo.LOGSHIPPING_RESTORE_LIST SET restore_flag = 1, restore_end_time = GETDATE(),   
      restore_duration = DATEDIFF(ss, @dtGetDate, GETDATE()), error_code = 0  
    WHERE user_db_name = @user_db_name AND seq_no = @min_seq_no  
         
    SET @ret_code = @@ERROR  
    IF @ret_code <> 0 RETURN  
   END  
  END    
          
        SET @min_seq_no = @min_seq_no + 1  
   
    END  --Loop End  
END  
      
SET @ret_code = 0  
RETURN  
GO

-- 복원할 파일 정보 가져오기


-- 복원 SP
-- EXEC DBO.up_DBA_logshipping_restore  'MAINDB2', 'FILE경로', NULL, 0, @RET_CODE OUTPUT
-- 복원 완료한 FILE 정보


    
    
/*************************************************************************        
* 프로시저명  : dbo.up_DBA_loghsipping_restore_complete       
* 작성정보    : 2007-08-07 choi bo ra (ceusee)      
* 관련페이지  :        
* 내용        : 복원 완료한 파일 정보      
* 수정정보    :      
**************************************************************************/      
CREATE PROCEDURE [dbo].[up_DBA_loghsipping_restore_complete]      
    @user_db_name       SYSNAME,      
    @seq_no             INT OUTPUT,      
    @log_file           NVARCHAR(200) OUTPUT,       
    @ret_code           INT OUTPUT               
AS      
/* COMMON DECLARE */      
SET NOCOUNT ON      
      
/* USER DECLARE */      
SET @log_file =  ''      
SET @ret_code =  -1      
      
/* BODY */      
IF @user_db_name = '' OR @user_db_name IS NULL      
BEGIN      
    SET @ret_code = 11 -- 데이터베이스 명을 입력하세요.      
    RETURN      
END      
  
-- 복원완료되고 삭제 안된것      
SELECT @seq_no = ISNULL(MIN(seq_no),0)      
FROM dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)      
WHERE user_db_name = @user_db_name AND delete_flag = 0 AND restore_flag= 1     
  
      
SET @ret_code = @@ERROR      
IF @ret_code <> 0  RETURN      
      
IF @seq_no <> 0      
BEGIN      
    SELECT @log_file = log_file      
    FROM dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)      
    WHERE user_db_name = @user_db_name AND seq_no = @seq_no      
END      
      
SET @ret_code = @@ERROR      
IF @ret_code <> 0  RETURN      
      
SET @ret_code= 0       
SET NOCOUNT OFF      
RETURN 
go
  
  
/*************************************************************************      
* 프로시저명  : dbo.up_DBA_logshipping_deletefile_complate     
* 작성정보    : 2007-08-07    
* 관련페이지  :      
* 내용        : 카피한 파일을 복원완료 했으면 삭제하고 완료 처리    
* 수정정보    :    
**************************************************************************/    
CREATE PROCEDURE [dbo].[up_DBA_logshipping_deletefile_complete]    
    @user_db_name       SYSNAME,    
    @seq_no             INT,    
    @log_file           NVARCHAR(200),    
    @ret_code           INT OUTPUT    
         
AS    
/* COMMON DECLARE */    
SET NOCOUNT ON    
    
/* USER DECLARE */    
SET @ret_code = -1    
/* BODY */    
IF @user_db_name = '' OR @user_db_name IS NULL    
BEGIN    
    SET @ret_code = 11 -- 데이터베이스 명을 입력하세요.    
    RETURN    
END    
    
    
UPDATE dbo.LOGSHIPPING_RESTORE_LIST    
    SET delete_flag = 1,    
        delete_time = GETDATE()    
WHERE user_db_name = @user_db_name AND seq_no = @seq_no AND log_file = @log_file    
    
SET @ret_code = @@ERROR    
IF @ret_code <> 0 RETURN    
    
SET @ret_code = 0    
    
RETURN
go

/*************************************************************************        
* 프로시저명  : dbo.up_DBA_loghsipping_restore_file       
* 작성정보    : 2007-08-02 choi bo ra (ceusee)      
* 관련페이지  :        
* 내용        : 복원할 파일 정보 가져오기      
* 수정정보    :      
**************************************************************************/      
ALTER PROCEDURE dbo.up_DBA_loghsipping_restore_file
	@file_dir		nvarchar(256)          
AS      
/* COMMON DECLARE */      
SET NOCOUNT ON      
      
/* USER DECLARE */      
declare @min_iid int , @max_iid int      
declare @log_file nvarchar(200)      
declare @seq_no int, @user_db_name sysname      
declare @target_dir  nvarchar(50)      
declare @cmd nvarchar(400)      
      
      
      
/* BODY */      
      
DECLARE @copy_table TABLE             
(                    
  iid INT IDENTITY(1,1) PRIMARY KEY,            
  user_db_name sysname,      
  seq_no int,      
  log_file nvarchar(200)      
)        
      
      
insert into @copy_table      
SELECT  user_db_name, seq_no, log_file     -- , copy_flag ,restore_flag
FROM   LOGSHIPPING_DB.dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)      
WHERE  copy_flag = 0 AND restore_flag= 0       
order by  reg_dt, user_db_name      


set @max_iid = @@rowcount      
set @min_iid = 1      
      
      
while  (@min_iid <= @max_iid )      
begin      
      
   set @cmd = 'robocopy.exe  \\192.168.100.1\I$\BACKUPDB\'      
   print @cmd     
 
  select   @user_db_name = user_db_name, @seq_no = seq_no ,       
   @log_file = @file_dir + '\' + user_db_name + '\ ' + log_file      
 from  @copy_table      
 where iid = @min_iid      
       
 UPDATE LOGSHIPPING_RESTORE_LIST set copy_start_time = getdate()       
 where user_db_name = @user_db_name and seq_no = @seq_no      
       
 set @cmd = @cmd + @user_db_name + ' ' + @log_file + ' /Z /E /NJH /NJS /NP'      
      
 print @cmd      
 EXEC master..xp_cmdshell @cmd      
      
 -- copy 완료      
 UPDATE LOGSHIPPING_RESTORE_LIST set copy_end_time = getdate(), copy_flag = 1      
 WHERe user_db_name = @user_db_name and seq_no = @seq_no      
       
 set @min_iid = @min_iid + 1      
      
end
 go
 
  
/*************************************************************************        
* 프로시저명  : dbo.up_DBA_loghsipping_delete_file       
* 작성정보    : 2007-08-02 choi bo ra (ceusee)      
* 관련페이지  :        
* 내용        : 복원할 파일 정보 가져오기      
* 수정정보    :      
**************************************************************************/      
ALTER PROCEDURE dbo.up_DBA_loghsipping_delete_file
	@file_dir		nvarchar(256)        
AS      
/* COMMON DECLARE */      
SET NOCOUNT ON      
      
/* USER DECLARE */      
declare @min_iid int , @max_iid int      
declare @log_file nvarchar(200)      
declare @seq_no int, @user_db_name sysname      
declare @target_dir  nvarchar(50)      
declare @cmd nvarchar(400)      
      
      
      
/* BODY */      
      
DECLARE @delete_table TABLE             
(                    
  iid INT IDENTITY(1,1) PRIMARY KEY,            
  user_db_name sysname,      
  seq_no int,      
  log_file nvarchar(200)      
)        
      
      
insert into @delete_table      
SELECT  user_db_name, seq_no, log_file      
FROM   LOGSHIPPING_DB.dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)      
WHERE  restore_flag= 1  and delete_flag = 0     
order by  reg_dt, user_db_name      
      
set @max_iid = @@rowcount      
set @min_iid = 1      
      
      
while  (@min_iid <= @max_iid )      
begin      
          
      
 select   @user_db_name = user_db_name, @seq_no = seq_no ,       
   @log_file = 'DEL ' + @file_dir +'\' + user_db_name + '\' + log_file      
 from  @delete_table      
 where iid = @min_iid      
       
      
 print @cmd      
 EXEC master..xp_cmdshell @cmd      
      
 -- copy 완료      
 UPDATE LOGSHIPPING_RESTORE_LIST set delete_time = getdate(), delete_flag = 1      
 WHERe user_db_name = @user_db_name and seq_no = @seq_no      
       
 set @min_iid = @min_iid + 1      
      
end


go

/*==========================================
   Source DB JOB
*===========================================*/

CREATE TABLE LOGSHIPPING_BACKUP_LIST
( 
    user_db_name sysname    NOT NULL   , 
    seq_no int    NOT NULL   , 
    backup_no int    NOT NULL   , 
    log_file nvarchar (200)   NOT NULL   , 
    backup_type tinyint    NOT NULL  CONSTRAINT DF__LOGSHIPPING_BACKUP_LIST__BACKUP_TYPE DEFAULT ((1))  , 
    backup_flag tinyint    NOT NULL  CONSTRAINT DF__LOGSHIPPING_BACKUP_LIST__BACKUP_FLAG DEFAULT ((0))  , 
    backup_start_time datetime    NULL   , 
    backup_end_time datetime    NULL   , 
    backup_duration int    NOT NULL  CONSTRAINT DF__LOGSHIPPING_BACKUP_LIST__BACKUP_DURATION DEFAULT ((0))  , 
    delete_flag tinyint    NOT NULL  CONSTRAINT DF__LOGSHIPPING_BACKUP_LIST__DELETE_FLAG DEFAULT ((0))  , 
    delete_time datetime    NULL   , 
    error_code int    NOT NULL  CONSTRAINT DF__LOGSHIPPING_BACKUP_LIST__ERROR_CODE DEFAULT ((0))  , 
    copy_106 bit    NOT NULL  CONSTRAINT DF__LOGSHIPPING_BACKUP_LIST__COPY_106 DEFAULT ((1))  , 
    copy_117 bit    NOT NULL  CONSTRAINT DF__LOGSHIPPING_BACKUP_LIST__COPY_117 DEFAULT ((1))  , 
    copy_107 bit    NOT NULL  CONSTRAINT DF__LOGSHIPPING_BACKUP_LIST__COPY_107 DEFAULT ((1))  , 
    reg_dt datetime    NOT NULL  CONSTRAINT DF__LOGSHIPPING_BACKUP_LIST__REG_DT DEFAULT (getdate()) 
)  ON [PRIMARY]
GO
ALTER TABLE LOGSHIPPING_BACKUP_LIST ADD CONSTRAINT PK_LOGSHIPPING_BACKUP_LIST primary key clustered ([user_db_name] ASC, [seq_no] ASC  ) ON [PRIMARY] 
GO
CREATE nonclustered INDEX IDX__LOGISHIPPING_BACKUP_LIST__BACKUP_FLAG ON LOGSHIPPING_BACKUP_LIST ([backup_flag] ASC ) ON [PRIMARY] 
GO


--=======================================================
-- 프로시저
--=======================================================
  
/*************************************************************************      
* 프로시저명  : dbo.up_DBA_logshipping_insert_file     
* 작성정보    : 2007-08-02 choi bo ra(ceusee)    
* 관련페이지  :      
* 내용        : 백업받은 파일을 복원테이블에 입력    
* 수정정보    :    
**************************************************************************/    
CREATE PROCEDURE dbo.up_DBA_logshipping_insert_file      
     @server_name       SYSNAME,      
     @user_db_name      SYSNAME,     
     @ret_code          INT OUTPUT      
AS      
/* COMMON DECLARE */      
SET NOCOUNT ON      
SET @ret_code = -1      
/* USER DECLARE */      
DECLARE @dtGetDate      DATETIME     
DECLARE @from_seq_no    INT     
DEClARE @backup_max_seq_no INT    
DECLARE @backup_min_seq_no INT    
SET @dtGetDate = GETDATE()      
      
/* BODY */      
SET @user_db_name = UPPER(@user_db_name)      
IF @user_db_name = '' OR @user_db_name  IS NULL      
BEGIN      
    SET @ret_code = 11 -- 데이터베이스 명을 입력하세요.      
    RETURN      
END      
--=============================
--	링크드 서버 setting
--=============================
IF @server_name = 'LOGSHIPPING'      
BEGIN      
    --superdb1      
        
    SELECT @backup_min_seq_no = MIN(seq_no) , @backup_max_seq_no = MAX(seq_no)     
    FROM dbo.LOGSHIPPING_BACKUP_LIST     
    WHERE user_db_name  = @user_db_name AND backup_flag = 1 -- 백업 성공한것      
                AND copy_106 = 0    
                  
  
    
    IF @backup_max_seq_no <>  0 AND  @backup_min_seq_no <>  0    
    BEGIN    
    
        WHILE (@backup_max_seq_no >= @backup_min_seq_no)    
        BEGIN    
    
               
         SELECT @from_seq_no = ISNULL(MAX(seq_no),0) + 1 FROM LOGSHIPPING.LOGSHIPPING_DB.dbo.LOGSHIPPING_RESTORE_LIST WHERE user_db_name = @user_db_name    
         IF @from_seq_no = 0 RETURN    
     
             
        INSERT INTO LOGSHIPPING.LOGSHIPPING_DB.dbo.LOGSHIPPING_RESTORE_LIST      
             (user_db_name, seq_no, backup_no, log_file, copy_flag, copy_end_time, restore_type, restore_flag,       
              restore_start_time, restore_end_time, restore_duration, error_code, reg_dt)        
         SELECT user_db_name, @from_seq_no, backup_no, log_file, 0, null, backup_type, 0,      
                 NULL, NULL, 0, 0, @dtGetDate      
         FROM dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)      
         WHERE user_db_name  = @user_db_name AND backup_flag = 1 -- 백업 성공한것      
                 AND copy_106 = 0  AND seq_no = @backup_min_seq_no    
                     
        SET @ret_code = @@ERROR      
        IF @ret_code <> 0 RETURN     
            
        UPDATE dbo.LOGSHIPPING_BACKUP_LIST    
        SET copy_106 = 1    
        WHERE user_db_name  = @user_db_name AND backup_flag = 1 -- 백업 성공한것      
                AND copy_106 = 0 AND seq_no = @backup_min_seq_no      
                    
        SET @ret_code = @@ERROR      
        IF @ret_code <> 0 RETURN     
    
        SET @backup_min_seq_no =  @backup_min_seq_no + 1    
 END    
   END    
END      
  
      
SET @ret_code = 0      
SET NOCOUNT OFF      
RETURN      
SET QUOTED_IDENTIFIER ON 
go



  
  
/*************************************************************************        
* 프로시저명  : dbo.up_DBA_logshipping_backup       
* 작성정보    : 2007-08-01 by choi bo ra(ceusee)      
* 관련페이지  :       
* 내용        : 데이터베이스의 트랜젝션 로그백업 관리      
* 수정정보    :      
    기존에 up_DBA_BackupLog_LiteSpeed, Native 백업은 유지 관리계획으로 되어있는      
    것을 통일되게 변경함      
    2006-09-27 김태환 maxtransfer값 변경        
       @maxtransfersize = 4194304 ==> @maxtransfersize = 2097152        
    2006-10-13 김태환 maxtransfer값 변경        
       @maxtransfersize = 2097152 ==> @maxtransfersize = 1048576        
    2006-11-07 김태환 IOflag의 설정을 LiteSpeed defalut으로 변경        
       @ioflag=OVERLAPPED        
       @ioflag='FILE_EXTENSION=-1'        
       @ioflag=NO_BUFFERING        
    2006-11-07 최보라 thread count : 16-8로 조정        
**************************************************************************/      
CREATE PROCEDURE dbo.up_DBA_logshipping_backup    
    @user_db_name       SYSNAME,       
    @backup_type        TINYINT = 1,  --1:Native, 2:LiteSpeed,      
    @file_dir           NVARCHAR(256) = NULL,      
    @seq_no             INT OUTPUT,      
    @ret_code           INT  OUTPUT      
AS      
/* COMMON DECLARE */      
SET NOCOUNT ON      
SET @ret_code = -1      
      
/* USER DECLARE */      
DECLARE @backup_file_name      NVARCHAR(100)      
DECLARE @backup_type_name      NVARCHAR(25)      
DECLARE @backup_full_name      NVARCHAR(256)      
DECLARE @backup_name           NVARCHAR(50)      
DECLARE @dtGetDate             DATETIME      
DECLARE @backup_no             INT      
      
SET @dtGetDate = GETDATE()      
SET @seq_no = 0      
      
/* BODY */      
SET @user_db_name = UPPER(@user_db_name)      
IF @user_db_name IS NULL      
BEGIN      
     SET @ret_code = 11 -- 데이터베이스 명 입력      
     RETURN      
END      
      
IF @file_dir = '' OR @file_dir = NULL      
BEGIN      
    SET @ret_code = 12    -- 디렉토리 경로 입력      
    RETURN      
END      
      
      
IF @backup_type = 1       
BEGIN      
    SET @backup_type_name = @user_db_name + '_TLOG'      
END      
ELSE IF @backup_type = 2       
BEGIN      
    SET @backup_type_name =  @user_db_name + '_TLOG_' +  'LITESPEED'    
    
END      
ELSE      
BEGIN      
    SET @ret_code = 13    -- 트랜젝션로그 유형이 잘 못 되었습니다.      
    RETURN      
END      
      
-- 파일 이름      
SET @backup_file_name = @backup_type_name + '_'      
                    + replace(replace(convert(char(10), @dtGetDate, 121), '-', ''), ' ', '')         
                    + right(replace('00' + convert(char(2), datepart(hh, @dtGetDate)), ' ', ''), 2)        
                    + right(replace('00' + convert(char(2), datepart(mi, @dtGetDate)), ' ', ''), 2)        
                    + '.TRN'        
-- 전체경로      
SET @backup_full_name = @file_dir + '\' + @user_db_name + '\' + @backup_file_name      
-- 백업명      
SET @backup_name = @user_db_name + ' BACKUP'   
  

/*
-- 이틀 전 삭제 하는 부분 제외
  
declare @log_full_name varchar(100)  
declare @day varchar(8)  
set @day = convert(varchar(8),  dateadd(d ,-2, getdate()), 112)  
 
IF @backup_type = 1
	SET @log_full_name = 'DEL ' + @file_dir + '\' + @user_db_name  + '\' +  REPLACE(@user_db_name,' ','_') + '_TLOG' + @day + '*.TRN'  
IF @backup_type = 2
	SET @log_full_name = 'DEL ' + @file_dir + '\' + @user_db_name  + '\' +  REPLACE(@user_db_name,' ','_') + '_TLOG_LITESPEED' + @day + '*.TRN'  
EXEC master..xp_cmdshell @log_full_name  


*/
  
      
  
-- Step 1-1 파일      
SELECT @seq_no = ISNULL(MAX(seq_no),0) + 1 , @backup_no = ISNULL(MAX(backup_no),0)      
FROM dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)      
WHERE user_db_name = @user_db_name      
      
SET @ret_code = @@ERROR      
IF @ret_code <> 0 RETURN      
      
      
-- Step 1-2 파일명 Insert      
INSERT INTO dbo.LOGSHIPPING_BACKUP_LIST       
    (user_db_name, seq_no, backup_no, log_file, backup_type, backup_flag, backup_start_time, backup_end_time,      
     error_code, copy_106, copy_117, copy_107, reg_dt)      
VALUES(@user_db_name, @seq_no, @backup_no, @backup_file_name, @backup_type, 0, null, null,      
        0, 0, 0, 0, @dtGetDate)      
      
SET @ret_code = @@ERROR      
IF @ret_code <> 0 RETURN      
      
-- Step 2. 백업      
IF @backup_type = 1      
BEGIN      
    BACKUP LOG @user_db_name      
        TO DISK = @backup_full_name      
          
    SET @ret_code = @@ERROR      
          
END      
ELSE IF @backup_type = 2  -- LiteSpeed      
BEGIN      
      
    
     EXEC @ret_code = master.dbo.xp_backup_log         
         @database = @user_db_name        
        ,@filename = @backup_full_name        
        ,@backupname = @backup_name        
        ,@init = 1        
        ,@logging = 2        
        ,@maxtransfersize = 1048576        
        --,@ioflag=OVERLAPPED        
        --,@ioflag='FILE_EXTENSION=-1'        
        --,@ioflag=NO_BUFFERING        
        ,@threads = 4        
        ,@buffercount = 10        
        --,@with = 'SKIP'        
        --,@with = 'STATS = 10'        
      
END      
      
    
-- Step 3. error check      
IF @ret_code <> 0  -- 실패      
BEGIN      
    UPDATE dbo.LOGSHIPPING_BACKUP_LIST       
    SET backup_flag = 2, -- 백업실패      
        error_code = @ret_code      
    WHERE user_db_name = @user_db_name AND seq_no = @seq_no      
          
    SET @ret_code = @@ERROR      
    IF @ret_code <> 0 RETURN      
END      
ELSE      
BEGIN      
    
    UPDATE dbo.LOGSHIPPING_BACKUP_LIST       
    SET backup_flag = 1, -- 백업성공      
        backup_start_time = @dtGetDate,      
        backup_end_time = GETDATE(),      
        backup_duration = DATEDIFF(s, @dtGetDate, GETDATE()),      
        error_code = 0      
    WHERE user_db_name = @user_db_name AND seq_no = @seq_no      
          
    SET @ret_code = @@ERROR      
    IF @ret_code <> 0 RETURN      
END      
      
SET @ret_code = 0      
SET NOCOUNT OFF      
RETURN      
go