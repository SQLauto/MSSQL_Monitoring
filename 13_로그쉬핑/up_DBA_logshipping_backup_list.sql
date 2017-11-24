SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_logshipping_backup_list' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_logshipping_backup_list
GO

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_logshipping_backup_list 
* 작성정보    : 2007-08-10
* 관련페이지  :  
* 내용        : 로그쉬핑 백업 리스트
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_logshipping_backup_list
     @user_db_name      SYSNAME, 
     @from_reg_dt       DATETIME = NULL, 
     @to_reg_dt         DATETIME = NULL,
     @seq_no            INT = 0, 
     @log_file          NVARCHAR(200) = NULL, 
     @ret_code          INT OUTPUT
     
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET @ret_code = -1
/* USER DECLARE */
DECLARE @str_sql        NVARCHAR(2000)
DECLARE @str_where      NVARCHAR(1000)
SET @str_where = ''


/* BODY */
IF @user_db_name = '' OR @user_db_name IS NULL
BEGIN
    SET @ret_code = 11
    RETURN
END

IF (@from_reg_dt IS NULL OR @to_reg_dt IS NULL) OR (@from_reg_dt > @to_reg_dt)
BEGIN
    SET @ret_code = 1  -- 검색일자 입력
    RETURN
END

SET @to_reg_dt = DATEADD(ss, -1, DATEADD(dd, 1,@to_reg_dt))

SET @str_where = ' WHERE user_db_name = ''' + UPPER(@user_db_name) + '''
						AND reg_dt >= ''' + CONVERT(NVARCHAR, @from_reg_dt) + ''' AND reg_dt <= ''' + CONVERT(NVARCHAR, @to_reg_dt) + ''''


IF @seq_no <> 0 
BEGIN
    IF @str_where =  '' SET @str_where = ' WHERE '
    ELSE SET @str_where = @str_where + ' AND '
        
    SET @str_where = @str_where + ' seq_no = ' + CONVERT(NVARCHAR, @seq_no)
END


IF @log_file <> '' OR @log_file IS NOT NULL
BEGIN
    IF @str_where =  '' SET @str_where = ' WHERE '
    ELSE SET @str_where = @str_where + ' AND '
        
    SET @str_where = @str_where + ' log_file = ''' + @log_file + ''''
END


SET @str_sql = N'SELECT seq_no, backup_no, log_file, backup_type, backup_flag, 
                        backup_start_time, backup_end_time, backup_duration, 
                        error_code, copy_106, copy_117, copy_107, reg_dt
                 FROM dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)'
			    
SET @str_where = @str_where + ' ORDER BY seq_no DESC'
SET @str_sql = @str_sql + @str_where
EXEC sp_executesql @str_sql
SET @ret_code = @@ERROR
IF @ret_code <> 0  RETURN

SEt @ret_code = 0

RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO