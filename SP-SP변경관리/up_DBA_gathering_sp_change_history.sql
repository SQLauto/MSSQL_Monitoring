/*************************************************************************  
* ���ν�����  : dbo.up_DBA_gathering_sp_change_history
* �ۼ�����    : 2007-10-30 ����ȯ
* ����������  :  
* ����        : ���� ���/���� �Ǵ� sp ��� ����
* ��������    : 2009-05 �ֺ��� ��ȸ�� DB���� ����ǰ� ����, ���� ����
* ���๮      : EXEC dbo.up_DBA_gathering_sp_change_history
**************************************************************************/
CREATE PROC dbo.up_DBA_gathering_sp_change_history
AS
    set nocount on
    set transaction isolation level read uncommitted

    declare     @stDate     datetime
    declare     @edDate     datetime

    --���� �������� ����� sp�� ����
    set @stDate = convert(char(10), getdate(), 121) + ' 00:00:00.000'
    set @edDate = convert(char(10), getdate(), 121) + ' 23:59:59.999'

    INSERT INTO dbo.object_change_hist
    (
        sp_nm
    ,   obj_id
    ,   schem_id
    ,   create_dt
    ,   modify_dt
    )
    SELECT 
            name
        ,   object_id
        ,   schema_id
        ,   create_date
        ,   modify_date
      FROM tiger.sys.objects with (nolock)
     WHERE ((create_date >= @stDate AND create_date <= @edDate)
        OR (modify_date >= @stDate AND modify_date <= @edDate))
       AND type = 'P'
     ORDER BY create_date asc, modify_date asc

    set nocount off