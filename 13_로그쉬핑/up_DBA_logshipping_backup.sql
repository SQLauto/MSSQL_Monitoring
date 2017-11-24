SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects
	   WHERE  name = N'up_DBA_logshipping_backup' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_logshipping_backup
*/

/*************************************************************************  
* ���ν�����  : dbo.up_DBA_logshipping_backup 
* �ۼ�����    : 2007-08-01 by choi bo ra(ceusee)
* ����������  : 
* ����        : �����ͺ��̽��� Ʈ������ �α׹�� ����
* ��������    :
    ������ up_DBA_BackupLog_LiteSpeed, Native ����� ���� ������ȹ���� �Ǿ��ִ�
    ���� ���ϵǰ� ������
    2006-09-27 ����ȯ maxtransfer�� ����  
       @maxtransfersize = 4194304 ==> @maxtransfersize = 2097152  
    2006-10-13 ����ȯ maxtransfer�� ����  
       @maxtransfersize = 2097152 ==> @maxtransfersize = 1048576  
    2006-11-07 ����ȯ IOflag�� ������ LiteSpeed defalut���� ����  
       @ioflag=OVERLAPPED  
       @ioflag='FILE_EXTENSION=-1'  
       @ioflag=NO_BUFFERING  
    2006-11-07 ����ȯ thread count : 16-8�� ����  
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
     SET @ret_code = 11 -- �����ͺ��̽� �� �Է�
     RETURN
END

IF @file_dir = '' OR @file_dir = NULL
BEGIN
    SET @ret_code = 12    -- ���丮 ��� �Է�
    RETURN
END



IF @backup_type = 1 
BEGIN
    SET @backup_type_name = @user_db_name + '_tlog'
END
ELSE IF @backup_type = 2 
BEGIN
    SET @backup_type_name = 'LiteSpeed_' + @user_db_name + '_tlog'
END
ELSE
BEGIN
    SET @ret_code = 13    -- Ʈ�����Ƿα� ������ �� �� �Ǿ����ϴ�.
    RETURN
END

-- ���� �̸�
SET @backup_file_name = @backup_type_name + '_'
                    + replace(replace(convert(char(10), @dtGetDate, 121), '-', ''), ' ', '')   
                    + right(replace('00' + convert(char(2), datepart(hh, @dtGetDate)), ' ', ''), 2)  
                    + right(replace('00' + convert(char(2), datepart(mi, @dtGetDate)), ' ', ''), 2)  
                    + '.TRN'  
-- ��ü���
SET @backup_full_name = @file_dir + '\' + @user_db_name + '\' + @backup_file_name
-- �����
SET @backup_name = @user_db_name + ' Backup'


-- Step 1-1 ����
SELECT @seq_no = ISNULL(MAX(seq_no),0) + 1 , @backup_no = ISNULL(MAX(backup_no),0)
FROM dbo.LOGSHIPPING_BACKUP_LIST WITH (NOLOCK)
WHERE user_db_name = @user_db_name

SET @ret_code = @@ERROR
IF @ret_code <> 0 RETURN


-- Step 1-2 ���ϸ� Insert
INSERT INTO dbo.LOGSHIPPING_BACKUP_LIST 
    (user_db_name, seq_no, backup_no, log_file, backup_type, backup_flag, backup_start_time, backup_end_time,
     error_code, copy_106, copy_117, copy_107, reg_dt)
VALUES(@user_db_name, @seq_no, @backup_no, @backup_file_name, @backup_type, 0, null, null,
        0, 0, 0, 0, @dtGetDate)

SET @ret_code = @@ERROR
IF @ret_code <> 0 RETURN

-- Step 2. ���
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
        ,@threads = 8  
        ,@buffercount = 20  
         --,@with = 'SKIP'  
         --,@with = 'STATS = 10'  

END

-- Step 3. error check
IF @ret_code <> 0  -- ����
BEGIN
    UPDATE dbo.LOGSHIPPING_BACKUP_LIST 
    SET backup_flag = 2, -- �������
        error_code = @ret_code
    WHERE user_db_name = @user_db_name AND seq_no = @seq_no
    
    SET @ret_code = @@ERROR
    IF @ret_code <> 0 RETURN
END
ELSE
BEGIN
    UPDATE dbo.LOGSHIPPING_BACKUP_LIST 
    SET backup_flag = 1, -- �������
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

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO