
/*************************************************************************  
* ���ν�����  : up_DBA_monitoring_contr_fail_detail
* �ۼ�����    : 2008-01-08 ����ȯ
* ����������  :  
* ����        : 
* ��������    : �����ֹ� �� �߰�
				2008-01-28 �ֱ��� 
* ����        : grant exec on dbo.up_DBA_monitoring_contr_fail_detail to backend              
**************************************************************************/
CREATE PROC dbo.up_DBA_monitoring_contr_fail_detail
    @srch_dt        datetime        -- ��ȸ ����
,   @type           char(1)         -- Ÿ��(G:10��, M:1��, H:�ð�)
AS
    set nocount on
    set transaction isolation level read uncommitted
    set query_governor_cost_limit 1500

    declare 	@srch_sdt           datetime    -- ��ȸ����
            ,	@srch_edt           datetime	-- ��ȸ��

    IF @type = 'G'
    BEGIN
        set @srch_sdt = convert(char(16), @srch_dt, 121) + ':00.000'
        set @srch_edt = convert(char(16), dateadd(mi, 10, @srch_sdt), 121)+ ':00.000'
    END
    ELSE IF @type = 'M'
    BEGIN
        set @srch_edt = convert(char(16), @srch_dt, 121) + ':00.000'
        set @srch_sdt = convert(char(16), dateadd(mi, -1, @srch_edt), 121)+ ':00.000'
    END    
    ELSE IF @type = 'H'
    BEGIN
        set @srch_sdt = convert(char(16), @srch_dt, 121) + ':00.000'
        set @srch_edt = convert(char(16), dateadd(hh, 1, @srch_sdt), 121)+ ':00.000'
    END    
    ELSE
    BEGIN
        set @srch_sdt = convert(char(16), @srch_dt, 121) + ':00.000'
        set @srch_edt = convert(char(16), dateadd(mi, 1, @srch_sdt), 121)+ ':00.000'
    END    

--    print @srch_sdt
--    print @srch_edt
      
    SELECT 
        do.order_dt
    ,   CASE do.stat
        WHEN 'RN' THEN '�ش� �ֹ����¿� ���� ������ �������̺� ��� �ֹ��� ������ ����'
        WHEN 'RR' THEN '�ش� �ֹ��� �̹� �ż�/�ŵ� ���̺� ����'
        WHEN 'RX' THEN '������ ������ ����ó���� �ȵ� ������'
        WHEN 'RT' THEN 'ī������� �ǰ� ���������� ü��ó���� ��'
        WHEN 'EX' THEN '��ȿ�Ⱓ�� ���� ������'
        WHEN 'XX' THEN 'dsorderindex���� �����ϰ� dsorder���� ���� �ֹ�'
        WHEN 'NT' THEN 'Ư����ǰ ���������� ���� ���� ��ҵ� ��ٱ��� �ֹ�'
        WHEN 'NC' THEN '������'
        WHEN 'CN' THEN '����ֹ��� ��� ����ϰ��� �ϴ� �ֹ��� ����'
        WHEN 'CA' THEN '����ϰ��� �ϴ� �ֹ��� �̹� ó���� ����'
        WHEN 'MN' THEN '�����ֹ��� ��� �����ϰ��� �ϴ� �ֹ��� ����'
        WHEN 'MA' THEN '�����ϰ��� �ϴ� �ֹ��� �̹� ó���� ����'
        WHEN 'RD' THEN '�ֹ��� ������ ����'
        WHEN 'MC' THEN '�����ڰ������� �������� ���� ���'
        ELSE 'UNKNOWN'
        END as contr_fail_detail
    ,   do.stat
    ,   do.pack_no
    ,   do.order_no
    ,   do.gd_no
    ,   left(gd.gd_nm, 50) as gd_nm
	,	do.order_price		as order_price
	,	do.order_amt		as order_amt
	,	(
		select top 1 
		'�Ǹ���ID : ' + cast(cu.login_id as char(10)) + ' / ' + 
		'���� : ' + replace(convert(char(10), ds.ORDER_PRICE), '.00', '') + ' / ' + 
		'��� : ' + convert(char(5), remain) + '<br/> ' +
		'�ֹ��� : ' + convert(varchar(10), ds.order_dt,121) + ' / ' +
		'��ȿ�Ⱓ : ' + convert(varchar(10), ds.expire_dt,121)
		from tiger.dbo.dsorderbuf_sell ds with(nolock) 
		inner join tiger.dbo.custom cu with(nolock) on ds.cust_no = cu.cust_no
		where ds.order_no = do.contr_order_no and ds.gd_no = do.gd_no
		)	as sell_order
      FROM tiger.dbo.dsorderbuf as do with (nolock)
     INNER JOIN tiger.dbo.goods as gd with (nolock) on do.gd_no = gd.gd_no
     WHERE do.order_dt >= @srch_sdt
       AND do.order_dt <= @srch_edt
       AND do.contr_amt = 0
       AND do.stat <> 'RD'
       AND do.stat <> 'CS'
       AND do.stat <> 'MS'
     ORDER BY do.pack_no, do.order_no
     OPTION (maxdop 1)
set nocount off

