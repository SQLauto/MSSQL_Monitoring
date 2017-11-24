CREATE proc dbo.up_ADMIN_Server_Disk_Stat_Insert
---------------------------------------------------------------------------------------------------
-- 디스크 공간 DB 입력
---------------------------------------------------------------------------------------------------
	@svr_ip			varchar(15)
,	@drv_letter		varchar(2)
,	@total_space	int
as
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @count int
SET @count = 0
SELECT @count = count(*) from SERVER_DISK where svr_id=@svr_ip and drv_letter = @drv_letter
IF @count > 0 
BEGIN
        UPDATE SERVER_DISK
            SET CAPACITY = @total_space,
                chg_dt = getdate()
        WHERE svr_id= @svr_ip and drv_letter = @drv_letter
END
ELSE
    BEGIN
            INSERT INTO SERVER_DISK (svr_id, drv_letter, capacity, chg_dt)
            VALUES (@svr_ip, @drv_letter, @total_space, getdate())
    END 
