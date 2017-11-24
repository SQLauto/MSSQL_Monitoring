/*****************************************************************************    
SP��		: up_DBA_get_Disk_Usage_By_Db
�ۼ�����	: 2007-11-16 ������
����		: �ֱ� ������ ��ũ ��� ��Ȳ- DB���� 
******************************************************************************/
--DROP PROCEDURE [dbo].up_DBA_get_Disk_Usage_By_Db

ALTER PROCEDURE [dbo].up_DBA_get_Disk_Usage_By_Db
	@SVR_NM			sysname
AS

BEGIN
	SET NOCOUNT ON  

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  

        /* ���� ��¥ �Է� */
    SELECT sd.svr_id,tb.SVR_NM, tb.DISK_NM, (sl.CAPACITY/1024) as TOTAL,
        (tb.FREE_SPACE / 1024) FREE_SPACE,  
        convert(int,( 1- (convert(numeric(15,2),tb.FREE_SPACE) / sl.CAPACITY )) * 100) as USE_RATE
    FROM dbo.TB_CHK_DISK AS tb WITH(NOLOCK)  
        JOIN SQL_SERVER_LIST AS sd WITH(NOLOCK) ON tb.svr_nm = sd.server_name
        JOIN SERVER_DISK AS sl WITH(NOLOCK) ON sd.svr_id = sl.svr_id  and tb.disk_nm = sl.DRV_LETTER
    WHERE     ((@SVR_NM  is null AND SVR_NM = SVR_NM ) OR (SVR_NM = @SVR_NM))
        AND  tb.reg_dt >= (SELECT dateadd(hh, -1, (convert(datetime,(max(convert(nvarchar(13),reg_dt, 120)) + ':00:00')) )) FROM TB_CHK_DISK with(nolock) )
    ORDER BY tb.SVR_NM, tb.DISK_NM
	
SET NOCOUNT OFF
END
