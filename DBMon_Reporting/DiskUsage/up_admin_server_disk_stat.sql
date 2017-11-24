ALTER proc dbo.up_ADMIN_Server_Disk_Stat
---------------------------------------------------------------------------------------------------
-- 서버별 디스크 정보 가져오기
---------------------------------------------------------------------------------------------------
	@svr_nm		varchar(20) = ''
as
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @SVR_ID INT

	SET @SVR_ID = (SELECT SVR_ID FROM SQL_SERVER_LIST WITH(NOLOCK) WHERE SQL_SVR_NAME = @SVR_NM)

	SELECT	SD.DRV_LETTER AS DRV_LETTER, 
			SD.CAPACITY AS TOTALDISK
	FROM SERVER_DISK SD WITH(NOLOCK) 
	WHERE SD.SVR_ID=@SVR_ID 

SET NOCOUNT OFF
