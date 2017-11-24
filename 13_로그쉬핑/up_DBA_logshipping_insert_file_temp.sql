SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_logshipping_insert_file_temp' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_logshipping_insert_file_temp
*/

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_logshipping_insert_file_temp 
* 작성정보    : 2007-10-23
* 관련페이지  : 
* 내용        : 메인의 장애때문에 임시로 해당 프로시저 생성
* 수정정보    :
**************************************************************************/
ALTER PROCEDURE dbo.up_DBA_logshipping_insert_file_temp
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */

DECLARE @from_seq_no INT, @to_seq_no INT

SELECT @from_seq_no = min(seq_no) , @to_seq_no = max(seq_no)
FROM GMKTSQL2005.DBA.dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)  
WHERE user_db_name = 'CUSTOMER' AND  backup_flag = 1 -- 백업 성공한것   
        AND copy_106 = 0 
IF @@ERROR <> 0 RETURN

INSERT INTO  DBA.dbo.LOGSHIPPING_RESTORE_LIST  
     (user_db_name, seq_no, backup_no, log_file, copy_flag, copy_end_time, restore_type, restore_flag,   
      restore_start_time, restore_end_time, restore_duration, error_code, reg_dt)    
SELECT user_db_name, seq_no, backup_no, log_file, 0, NULL, backup_type, 0,  
     NULL, NULL, 0, 0, GETDATE()  
FROM GMKTSQL2005.DBA.dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)  
WHERE user_db_name = 'CUSTOMER' AND  backup_flag = 1 -- 백업 성공한것   
        AND copy_106 = 0 
        
IF @@ERROR <> 0 RETURN


INSERT INTO  SUBDB3.DBA.dbo.LOGSHIPPING_RESTORE_LIST  
     (user_db_name, seq_no, backup_no, log_file, copy_flag, copy_end_time, restore_type, restore_flag,   
      restore_start_time, restore_end_time, restore_duration, error_code, reg_dt)    
SELECT user_db_name, seq_no, backup_no, log_file, 0, NULL, backup_type, 0,  
     NULL, NULL, 0, 0, GETDATE()  
FROM GMKTSQL2005.DBA.dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)  
WHERE user_db_name = 'CUSTOMER' AND  backup_flag = 1 -- 백업 성공한것   
        AND copy_117 = 0 
        
IF @@ERROR <> 0 RETURN

UPDATE GMKTSQL2005.DBA.dbo.logshipping_backup_list
    SET copy_106 = 1, copy_117 = 1
WHERE user_db_name = 'CUSTOMER' AND (seq_no >= @from_seq_no AND seq_no <= @to_seq_no)

IF @@ERROR <> 0 RETURN



-- TIGER
SELECT @from_seq_no = 0, @to_seq_no = 0
SELECT @from_seq_no = min(seq_no) , @to_seq_no = max(seq_no)
FROM GMKTSQL2005.DBA.dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)  
WHERE user_db_name = 'TIGER' AND  backup_flag = 1 -- 백업 성공한것   
        AND copy_106 = 0 
IF @@ERROR <> 0 RETURN

INSERT INTO  DBA.dbo.LOGSHIPPING_RESTORE_LIST  
     (user_db_name, seq_no, backup_no, log_file, copy_flag, copy_end_time, restore_type, restore_flag,   
      restore_start_time, restore_end_time, restore_duration, error_code, reg_dt)    
SELECT user_db_name, seq_no, backup_no, log_file, 0, NULL, backup_type, 0,  
     NULL, NULL, 0, 0, GETDATE()  
FROM GMKTSQL2005.DBA.dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)  
WHERE user_db_name = 'TIGER' AND  backup_flag = 1 -- 백업 성공한것   
        AND copy_106 = 0 
        
IF @@ERROR <> 0 RETURN


INSERT INTO  SUBDB3.DBA.dbo.LOGSHIPPING_RESTORE_LIST  
     (user_db_name, seq_no, backup_no, log_file, copy_flag, copy_end_time, restore_type, restore_flag,   
      restore_start_time, restore_end_time, restore_duration, error_code, reg_dt)    
SELECT user_db_name, seq_no, backup_no, log_file, 0, NULL, backup_type, 0,  
     NULL, NULL, 0, 0, GETDATE()  
FROM GMKTSQL2005.DBA.dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)  
WHERE user_db_name = 'TIGER' AND  backup_flag = 1 -- 백업 성공한것   
        AND copy_117 = 0 
        
IF @@ERROR <> 0 RETURN

UPDATE GMKTSQL2005.DBA.dbo.logshipping_backup_list
    SET copy_106 = 1, copy_117 = 1
WHERE user_db_name = 'TIGER' AND (seq_no >= @from_seq_no AND seq_no <= @to_seq_no)

IF @@ERROR <> 0 RETURN

-- LION
SELECT @from_seq_no = 0, @to_seq_no = 0
SELECT @from_seq_no = min(seq_no) , @to_seq_no = max(seq_no)
FROM GMKTSQL2005.DBA.dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)  
WHERE user_db_name = 'LION' AND  backup_flag = 1 -- 백업 성공한것   
        AND copy_106 = 0 
IF @@ERROR <> 0 RETURN

INSERT INTO  DBA.dbo.LOGSHIPPING_RESTORE_LIST  
     (user_db_name, seq_no, backup_no, log_file, copy_flag, copy_end_time, restore_type, restore_flag,   
      restore_start_time, restore_end_time, restore_duration, error_code, reg_dt)    
SELECT user_db_name, seq_no, backup_no, log_file, 0, NULL, backup_type, 0,  
     NULL, NULL, 0, 0, GETDATE()  
FROM GMKTSQL2005.DBA.dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)  
WHERE user_db_name = 'LION' AND  backup_flag = 1 -- 백업 성공한것   
        AND copy_106 = 0 
        
IF @@ERROR <> 0 RETURN


INSERT INTO  SUBDB3.DBA.dbo.LOGSHIPPING_RESTORE_LIST  
     (user_db_name, seq_no, backup_no, log_file, copy_flag, copy_end_time, restore_type, restore_flag,   
      restore_start_time, restore_end_time, restore_duration, error_code, reg_dt)    
SELECT user_db_name, seq_no, backup_no, log_file, 0, NULL, backup_type, 0,  
     NULL, NULL, 0, 0, GETDATE()  
FROM GMKTSQL2005.DBA.dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)  
WHERE user_db_name = 'LION' AND  backup_flag = 1 -- 백업 성공한것   
        AND copy_117 = 0 
        
IF @@ERROR <> 0 RETURN

UPDATE GMKTSQL2005.DBA.dbo.logshipping_backup_list
    SET copy_106 = 1, copy_117 = 1
WHERE user_db_name = 'LION' AND (seq_no >= @from_seq_no AND seq_no <= @to_seq_no)

IF @@ERROR <> 0 RETURN

-- SETTLE
SELECT @from_seq_no = 0, @to_seq_no = 0
SELECT @from_seq_no = min(seq_no) , @to_seq_no = max(seq_no)
FROM GMKTSQL2005.DBA.dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)  
WHERE user_db_name = 'SETTLE' AND  backup_flag = 1 -- 백업 성공한것   
        AND copy_106 = 0 
IF @@ERROR <> 0 RETURN

INSERT INTO  DBA.dbo.LOGSHIPPING_RESTORE_LIST  
     (user_db_name, seq_no, backup_no, log_file, copy_flag, copy_end_time, restore_type, restore_flag,   
      restore_start_time, restore_end_time, restore_duration, error_code, reg_dt)    
SELECT user_db_name, seq_no, backup_no, log_file, 0, NULL, backup_type, 0,  
     NULL, NULL, 0, 0, GETDATE()  
FROM GMKTSQL2005.DBA.dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)  
WHERE user_db_name = 'SETTLE' AND  backup_flag = 1 -- 백업 성공한것   
        AND copy_106 = 0 
        
IF @@ERROR <> 0 RETURN


INSERT INTO  SUBDB3.DBA.dbo.LOGSHIPPING_RESTORE_LIST  
     (user_db_name, seq_no, backup_no, log_file, copy_flag, copy_end_time, restore_type, restore_flag,   
      restore_start_time, restore_end_time, restore_duration, error_code, reg_dt)    
SELECT user_db_name, seq_no, backup_no, log_file, 0, NULL, backup_type, 0,  
     NULL, NULL, 0, 0, GETDATE()  
FROM GMKTSQL2005.DBA.dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)  
WHERE user_db_name = 'SETTLE' AND  backup_flag = 1 -- 백업 성공한것   
        AND copy_117 = 0 
        
IF @@ERROR <> 0 RETURN

UPDATE GMKTSQL2005.DBA.dbo.logshipping_backup_list
    SET copy_106 = 1, copy_117 = 1
WHERE user_db_name = 'SETTLE' AND (seq_no >= @from_seq_no AND seq_no <= @to_seq_no)

IF @@ERROR <> 0 RETURN

-- EVENT
SELECT @from_seq_no = 0, @to_seq_no = 0
SELECT @from_seq_no = min(seq_no) , @to_seq_no = max(seq_no)
FROM GMKTSQL2005.DBA.dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)  
WHERE user_db_name = 'EVENT' AND  backup_flag = 1 -- 백업 성공한것   
        AND copy_106 = 0 
IF @@ERROR <> 0 RETURN

INSERT INTO  DBA.dbo.LOGSHIPPING_RESTORE_LIST  
     (user_db_name, seq_no, backup_no, log_file, copy_flag, copy_end_time, restore_type, restore_flag,   
      restore_start_time, restore_end_time, restore_duration, error_code, reg_dt)    
SELECT user_db_name, seq_no, backup_no, log_file, 0, NULL, backup_type, 0,  
     NULL, NULL, 0, 0, GETDATE()  
FROM GMKTSQL2005.DBA.dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)  
WHERE user_db_name = 'EVENT' AND  backup_flag = 1 -- 백업 성공한것   
        AND copy_106 = 0 
        
IF @@ERROR <> 0 RETURN


INSERT INTO  SUBDB3.DBA.dbo.LOGSHIPPING_RESTORE_LIST  
     (user_db_name, seq_no, backup_no, log_file, copy_flag, copy_end_time, restore_type, restore_flag,   
      restore_start_time, restore_end_time, restore_duration, error_code, reg_dt)    
SELECT user_db_name, seq_no, backup_no, log_file, 0, NULL, backup_type, 0,  
     NULL, NULL, 0, 0, GETDATE()  
FROM GMKTSQL2005.DBA.dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)  
WHERE user_db_name = 'EVENT' AND  backup_flag = 1 -- 백업 성공한것   
        AND copy_117 = 0 
        
IF @@ERROR <> 0 RETURN

UPDATE GMKTSQL2005.DBA.dbo.logshipping_backup_list
    SET copy_106 = 1, copy_117 = 1
WHERE user_db_name = 'EVENT' AND (seq_no >= @from_seq_no AND seq_no <= @to_seq_no)

IF @@ERROR <> 0 RETURN



RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO