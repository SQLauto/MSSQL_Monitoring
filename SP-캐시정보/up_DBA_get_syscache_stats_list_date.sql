/*************************************************************************  
* ���ν�����  : dbo.up_DBA_get_syscache_stats_list_date
* �ۼ�����    : 2007-11-06 ������
* ����������  :  
* ����        : ������ ���� Ȯ��
* ��������    : 
* ���๮      : EXEC dbo.up_DBA_get_sp_change_recent_list_date '2007-10-30'
**************************************************************************/
CREATE PROC dbo.up_DBA_get_syscache_stats_list_date
AS
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    SELECT DISTINCT convert(char(10), reg_dt, 121) as date_list
    FROM dbo. SYSCACHE_EXEC_STATS with (nolock)
    WHERE reg_dt <> ''
    ORDER BY date_list DESC

    SET NOCOUNT OFF


