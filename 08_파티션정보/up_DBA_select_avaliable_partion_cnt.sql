/*************************************************************************  
* ���ν�����  : dbo.up_DBA_select_avaliable_partion_cnt
* �ۼ�����    : 2008-01-02 ����ȯ
* ����������  :  
* ����        : DB�� ��Ƽ�Ǻ� ���� ��Ƽ�� ����
* ��������    : 
**************************************************************************/
CREATE PROC dbo.up_DBA_select_avaliable_partion_cnt
AS
    set nocount on
    set transaction isolation level read uncommitted

    SELECT db_name, name, count(*)
      FROM dbo.PARTITION_TABLE_INFO WITH (NOLOCK)
     WHERE rows = 0
       AND range is not null
     GROUP BY db_name, name
     ORDER BY db_name, name

    set nocount off
