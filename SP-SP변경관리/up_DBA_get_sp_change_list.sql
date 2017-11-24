/*************************************************************************  
* ���ν�����  : dbo.up_DBA_get_sp_change_list
* �ۼ�����    : 2007-10-30 ����ȯ
* ����������  :  
* ����        : ���� ���/���� �� SP��� Ȯ��
* ��������    : 2009-05 �ֺ��� ���̺� �̷� ������ �ʰ� ��ȸ�� ó��
* ���๮      : EXEC dbo.up_DBA_get_sp_change_list '2007-10-30'
**************************************************************************/
CREATE PROC dbo.up_DBA_get_sp_change_list
    --@toDay          char(10)            -- ��ȸ ��¥
AS
    set nocount on
    set transaction isolation level read uncommitted

    declare     @stDate     datetime
    declare     @edDate     datetime

    --��ȸ ��¥
    set @stDate = convert(char(10), @toDay, 121) + ' 00:00:00.000'
    set @edDate = convert(char(10), @toDay, 121) + ' 23:59:59.999'

--    INSERT INTO dbo.object_change_hist
--    (
--        sp_nm
--    ,   obj_id
--    ,   schem_id
--    ,   create_dt
--    ,   modify_dt
--    )
    SELECT 
            SCHEMA_NAME(schema_id) + '.' + name as sp_nm
        ,   object_id
        ,   create_date
        ,   modify_date
      FROM tiger.sys.objects with (nolock)
     WHERE ((create_date >= @stDate AND create_date <= @edDate)
        OR (modify_date >= @stDate AND modify_date <= @edDate))
       AND type = 'P'
     ORDER BY create_date ASC, modify_date ASC

    set nocount off

