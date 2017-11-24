/*************************************************************************  
* ���ν�����  : dbo.up_DBA_select_diskalert 
* �ۼ�����    : 2008-01-14 by ������
* ����������  : ���� ������ ��ũ ���� �� ���� �ֽ� ���� SELECT  
* ����        :
* ��������    : 2008-01-17 by choi bo ra , �ֽ� ������ �������� �ϱ�
**************************************************************************/
CREATE  PROCEDURE dbo.up_DBA_select_diskalert   
   
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT 
		--seqno	,	
		server_nm
	,	Drive
	,	FreeMb
	,   log_time
FROM freedisk_hist WITH (NOLOCK)
WHERE log_time >= (SELECT MAX(log_time) FROM freedisk_hist with (nolock))
    --AND server_nm in ('ACCOUNTDB1' , 'ADMINDB1', 'ADMINDB2') and Drive not in ('E', 'F', 'G','H', 'I')

RETURN


