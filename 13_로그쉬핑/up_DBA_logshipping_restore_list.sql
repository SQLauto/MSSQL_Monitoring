SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*
IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_logshipping_restore_list' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_logshipping_restore_list
*/

/*************************************************************************  
* ���ν�����  : dbo.up_DBA_logshipping_restore_list 
* �ۼ�����    : 2007-08-10 �ֺ���
* ����������  :  
* ����        : �α׽��� ���� ����Ʈ
* ��������    : 2007-08-27 ����ȯ
*               from_reg_dt, to_reg_dt datetime->char(10)���� ����
                flag���� case�� ó��
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_logshipping_restore_list
     @user_db_name      SYSNAME, 
     @from_reg_dt       CHAR(10) = NULL, 
     @to_reg_dt         CHAR(10) = NULL,
     @seq_no            INT = 0, 
     @log_file          NVARCHAR(200) = NULL, 
     @copy_flag         TINYINT = 0,
     @restore_flag      TINYINT = 0, 
     @ret_code          INT OUTPUT
     
AS
    /* COMMON DECLARE */
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    SET @ret_code = -1

    /* USER DECLARE */
    DECLARE @str_sql        NVARCHAR(3000)
    DECLARE @str_where      NVARCHAR(1000)
    DECLARE @start_dt       DATETIME
    DECLARE @end_dt         DATETIME

    SET @str_where = ''

    -- ��¥ format�� �°� ����
    SET @start_dt = @from_reg_dt + ' 00:00:00.000'
    SET @end_dt = @to_reg_dt + ' 23:59:59.999'
        
    /* BODY */
    IF @user_db_name = '' OR @user_db_name IS NULL
    BEGIN
        SET @ret_code = 11
        RETURN
    END
    
    IF (@from_reg_dt IS NULL OR @to_reg_dt IS NULL) OR (@from_reg_dt > @to_reg_dt)
    BEGIN
        SET @ret_code = 1  -- �˻����� �Է�
        RETURN
    END
    
    SET @to_reg_dt = DATEADD(ss, -1, DATEADD(dd, 1,@to_reg_dt))
    
    SET @str_where = ' WHERE user_db_name = ''' + UPPER(@user_db_name) + '''
    						AND reg_dt >= ''' + CONVERT(NVARCHAR, @start_dt) + ''' AND reg_dt <= ''' + CONVERT(NVARCHAR, @end_dt) + ''''
    
    
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
    
    
    IF @copy_flag <> 0 
    BEGIN
        IF @str_where =  '' SET @str_where = ' WHERE '
        ELSE SET @str_where = @str_where + ' AND '
            
        SET @str_where = @str_where + ' copy_flag = ' + CONVERT(NVARCHAR, @copy_flag)
    END
    
    IF @restore_flag <> 0 
    BEGIN
        IF @str_where =  '' SET @str_where = ' WHERE '
        ELSE SET @str_where = @str_where + ' AND '
            
        SET @str_where = @str_where + ' restore_flag = ' + CONVERT(NVARCHAR, @copy_flag)
    END
    
    
    SET @str_sql = N'SELECT
                            seq_no
                    ,       backup_no
                    ,       log_file
                    ,       case copy_flag when 0 then ''���'' when 1 then ''�Ϸ�'' when 2 then ''����'' end
                    ,       copy_end_time
                    ,       case restore_type when 0 then ''Native'' else ''LiteSpeed'' end
                    ,       case restore_flag when 0 then ''���'' when 1 then ''�Ϸ�'' when 2 then ''����'' end
                    ,       restore_start_time
                    ,       restore_end_time
                    ,       restore_duration
                    ,       error_code
                    ,       case delete_flag when 0 then ''���'' when 1 then ''�Ϸ�'' when 2 then ''����'' end
                    ,       delete_time
                    ,       reg_dt
                     FROM dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)'
    			    
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