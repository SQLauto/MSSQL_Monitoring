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
* 프로시저명  : dbo.up_DBA_logshipping_restore_list 
* 작성정보    : 2007-08-10 최보라
* 관련페이지  :  
* 내용        : 로그쉬핑 복원 리스트
* 수정정보    : 2007-08-27 김태환
*               from_reg_dt, to_reg_dt datetime->char(10)으로 변경
                flag값들 case문 처리
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

    -- 날짜 format에 맞게 변경
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
        SET @ret_code = 1  -- 검색일자 입력
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
                    ,       case copy_flag when 0 then ''대기'' when 1 then ''완료'' when 2 then ''실패'' end
                    ,       copy_end_time
                    ,       case restore_type when 0 then ''Native'' else ''LiteSpeed'' end
                    ,       case restore_flag when 0 then ''대기'' when 1 then ''완료'' when 2 then ''실패'' end
                    ,       restore_start_time
                    ,       restore_end_time
                    ,       restore_duration
                    ,       error_code
                    ,       case delete_flag when 0 then ''대기'' when 1 then ''완료'' when 2 then ''실패'' end
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