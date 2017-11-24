SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects
	   WHERE  name = N'up_DBA_logshipping_insert_file' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_logshipping_insert_file
*/

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_logshipping_insert_file 
* 작성정보    : 2007-08-02 choi bo ra(ceusee)
* 관련페이지  :  
* 내용        : 백업받은 파일을 복원테이블에 입력
* 수정정보    :
**************************************************************************/
ALTER PROCEDURE dbo.up_DBA_logshipping_insert_file  
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
  
 
IF @server_name = 'SUPERDB1'  
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

           
         SELECT @from_seq_no = ISNULL(MAX(seq_no),0) + 1 FROM SUPERDB1.DBA.dbo.LOGSHIPPING_RESTORE_LIST WHERE user_db_name = @user_db_name
         IF @from_seq_no = 0 RETURN
	
         
        INSERT INTO SUPERDB1.DBA.dbo.LOGSHIPPING_RESTORE_LIST  
             (user_db_name, seq_no, backup_no, log_file, copy_flag, copy_end_time, restore_type, restore_flag,   
              restore_start_time, restore_end_time, restore_duration, error_code, reg_dt)    
         SELECT user_db_name, @from_seq_no, backup_no, log_file, 0, NULL, backup_type, 0,  
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
ELSE IF @server_name = 'SUBDB3'  
BEGIN  
    SELECT @backup_min_seq_no = MIN(seq_no) , @backup_max_seq_no = MAX(seq_no) 
    FROM dbo.LOGSHIPPING_BACKUP_LIST 
    WHERE user_db_name  = @user_db_name AND backup_flag = 1 -- 백업 성공한것  
                AND copy_117 = 0

    IF @backup_max_seq_no <>  0 AND  @backup_min_seq_no <>  0
    BEGIN

        WHILE (@backup_max_seq_no >= @backup_min_seq_no)
        BEGIN

           
         SELECT @from_seq_no = ISNULL(MAX(seq_no),0) + 1 FROM SUBDB3.DBA.dbo.LOGSHIPPING_RESTORE_LIST WHERE user_db_name = @user_db_name
         IF @from_seq_no = 0 RETURN
	
         
        INSERT INTO SUBDB3.DBA.dbo.LOGSHIPPING_RESTORE_LIST  
             (user_db_name, seq_no, backup_no, log_file, copy_flag, copy_end_time, restore_type, restore_flag,   
              restore_start_time, restore_end_time, restore_duration, error_code, reg_dt)    
         SELECT user_db_name, @from_seq_no, backup_no, log_file, 0, NULL, backup_type, 0,  
                 NULL, NULL, 0, 0, @dtGetDate  
         FROM dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)  
         WHERE user_db_name  = @user_db_name AND backup_flag = 1 -- 백업 성공한것  
                 AND copy_117 = 0  AND seq_no = @backup_min_seq_no
                 
        SET @ret_code = @@ERROR  
        IF @ret_code <> 0 RETURN 
        
        UPDATE dbo.LOGSHIPPING_BACKUP_LIST
        SET copy_117 = 1
        WHERE user_db_name  = @user_db_name AND backup_flag = 1 -- 백업 성공한것  
                AND copy_117 = 0 AND seq_no = @backup_min_seq_no  
                
        SET @ret_code = @@ERROR  
        IF @ret_code <> 0 RETURN 

        SET @backup_min_seq_no =  @backup_min_seq_no + 1
	END
   END
END  
ELSE IF @server_name = 'SUBDB4'  
BEGIN  
    SELECT @backup_min_seq_no = MIN(seq_no) , @backup_max_seq_no = MAX(seq_no) 
    FROM dbo.LOGSHIPPING_BACKUP_LIST 
    WHERE user_db_name  = @user_db_name AND backup_flag = 1 -- 백업 성공한것  
                AND copy_107 = 0

    IF @backup_max_seq_no <>  0 AND  @backup_min_seq_no <>  0
    BEGIN

        WHILE (@backup_max_seq_no >= @backup_min_seq_no)
        BEGIN

           
         SELECT @from_seq_no = ISNULL(MAX(seq_no),0) + 1 FROM SUBDB4.DBA.dbo.LOGSHIPPING_RESTORE_LIST WHERE user_db_name = @user_db_name
         IF @from_seq_no = 0 RETURN
	
         
        INSERT INTO SUBDB4.DBA.dbo.LOGSHIPPING_RESTORE_LIST  
             (user_db_name, seq_no, backup_no, log_file, copy_flag, copy_end_time, restore_type, restore_flag,   
              restore_start_time, restore_end_time, restore_duration, error_code, reg_dt)    
         SELECT user_db_name, @from_seq_no, backup_no, log_file, 0, NULL, backup_type, 0,  
                 NULL, NULL, 0, 0, @dtGetDate  
         FROM dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)  
         WHERE user_db_name  = @user_db_name AND backup_flag = 1 -- 백업 성공한것  
                 AND copy_107 = 0  AND seq_no = @backup_min_seq_no
                 
        SET @ret_code = @@ERROR  
        IF @ret_code <> 0 RETURN 
        
        UPDATE dbo.LOGSHIPPING_BACKUP_LIST
        SET copy_107 = 1
        WHERE user_db_name  = @user_db_name AND backup_flag = 1 -- 백업 성공한것  
                AND copy_107 = 0 AND seq_no = @backup_min_seq_no  
                
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
GO
SET ANSI_NULLS ON 
GO