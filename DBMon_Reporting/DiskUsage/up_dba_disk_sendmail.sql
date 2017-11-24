/*************************************************************************  
* ���ν�����  : dbo.up_dba_disk_sendmail 
* �ۼ�����    : 2008-01-17
* ����������  : ������
* ����        : ������ ���� ��ũ �뷮 �ޱ� 
* ��������    : exec dbo.up_dba_disk_sendmail 
                2009-04-20 by choi bo ra ������ ���񽺿��� ���� �� �ְ� ����
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_disk_sendmail   
    @svr_nm     sysname 
AS
/* COMMON DECLARE */
SET NOCOUNT ON
/* USER DECLARE */




/* ���� ��¥ �Է� */
SELECT SVR_NM, DISK_NM, (FREE_SPACE / 1024) FREE_SPACE
FROM dbo.TB_CHK_DISK WITH(NOLOCK) WHERE 
     ((@SVR_NM  is null AND SVR_NM = SVR_NM ) OR (SVR_NM = @SVR_NM))
    AND  reg_dt = (SELECT MAX(reg_dt) FROM TB_CHK_DISK with(nolock) 
                        WHERE ((@SVR_NM  is null AND SVR_NM = SVR_NM ) OR (SVR_NM = @SVR_NM))) 
ORDER BY SVR_NM, DISK_NM


RETURN
