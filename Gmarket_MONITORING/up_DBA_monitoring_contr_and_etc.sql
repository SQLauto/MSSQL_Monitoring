
/*************************************************************************  
* ���ν�����  : up_DBA_monitoring_contr_and_etc
* �ۼ�����    : 2007-12-04 ����ȯ
* ����������  :  
* ����        : ��ȸ�������� ü������, ü��Ǽ�, ī����� ��� �Ǽ�, 
                ī�� ���ΰǼ�, ȸ�����ԿϷ�Ǽ�, ��ǰ��� �Ϸ� �Ǽ� ��ȸ
* ��������    : 2008-01-08 ����ȯ ü����г������� ����ֹ� ���� ����(STAT <> 'CS'
                2008-01-14 ����ȯ �ֹ��Ǽ�, ��ü�� �Ǽ� ���� �߰�
* ����        : grant exec on dbo.up_DBA_monitoring_contr_and_etc to backend              
**************************************************************************/
CREATE procedure dbo.up_DBA_monitoring_contr_and_etc
as 
    set nocount on 
    set transaction isolation level read uncommitted
    set query_governor_cost_limit 0

    declare 	@srch_sdt           datetime    -- ��ȸ����
            ,	@srch_edt           datetime	-- ��ȸ��
            ,   @contr_wait_cnt		int         -- ü��������
            ,	@contr_cnt 		    int         -- ü��Ǽ�
            ,   @contr_fail_cnt     int         -- ü����аǼ�
            ,	@card_wait_cnt 		int         -- ī�� ���� ��� �Ǽ�
            , 	@card_acpt_se_cnt  	int         -- ī�� ���� �Ǽ�
            ,   @card_fail_cnt      int         -- ī�� ���� �Ǽ�
            ,	@custom_reg_cnt  	int         -- ȸ�����ԿϷ� �Ǽ�
            , 	@goods_reg_cnt		int         -- ��ǰ��� �Ϸ� �Ǽ�
            ,   @front_contr_cnt    int         -- ��ü�� �Ǽ�
            ,   @order_cnt          int         -- �����ֹ��Ǽ�
	, @max_pack_no int
	, @new_max_pack_no int

    set @srch_edt = convert(char(16), getdate(), 121) + ':00.000'
    set @srch_sdt = convert(char(16), dateadd(mi, -1, @srch_edt), 121)+ ':00.000'

    --�ʱ�ȭ
    set @contr_wait_cnt   = 0 
    set @contr_cnt 		  = 0
    set @card_wait_cnt 	  = 0
    set @card_acpt_se_cnt = 0
    set @card_fail_cnt    = 0
    set @custom_reg_cnt   = 0
    set @goods_reg_cnt 	  = 0
    set @front_contr_cnt  = 0
    set @order_cnt        = 0

    --ü�����
    SELECT @contr_wait_cnt = isnull(count(*), 0)
      FROM lion.dbo.dsorderindex with (nolock)
     WHERE stat='NN'

    --ü����а�
    SELECT @contr_fail_cnt = isnull(count(*), 0)
      FROM tiger.dbo.dsorderbuf as ot with(nolock) 
     WHERE ot.order_dt >= @srch_sdt
       AND ot.order_dt < @srch_edt
       AND ot.contr_amt = 0
       AND ot.stat <> 'RD'
       AND ot.stat <> 'CS'
       AND ot.stat <> 'MS'
     OPTION (MAXDOP 1)

    --�ֹ��Ǽ�
    SELECT @order_cnt = isnull(count(*), 0)
      FROM tiger.dbo.dsorderbuf as ot with (nolock, index=CIDX__order_dt)
     WHERE ot.order_dt >= @srch_sdt
       AND ot.order_dt < @srch_edt
       AND ot.order_way_kind <> 'BAR'
       AND ot.stat = 'RD'
    OPTION (MAXDOP 1)

/*
-- ��ü��Ǽ� (�ε��� ������ ���ϰ� ������ �ε����� ����ϱ� ���� pack_no�� ���� ����
    select @max_pack_no = max_pack_no from dba.dbo.front_dscontr__max__pack_no with(nolock)
    select @new_max_pack_no = max(pack_no) from tiger.dbo.front_dscontr with(nolock, index=cidx__front_dscontr__pack_no)

 select @front_contr_cnt = isnull(count(*), 0)
   from tiger.dbo.front_dscontr as tt with(nolock, index=cidx__front_dscontr__pack_no)
   where pack_no > @max_pack_no and pack_no <= @new_max_pack_no
option (maxdop 1)

  update dba.dbo.front_dscontr__max__pack_no
  set max_pack_no = @new_max_pack_no
*/
    --��ü��Ǽ�
/*    SELECT @front_contr_cnt = isnull(count(*), 0)
      FROM tiger.dbo.front_dscontr as tt with (nolock, index=CIDX__FRONT_DSCONTR__PACK_NO)
     WHERE pack_no <> ''
	   AND tt.contr_dt >= @srch_sdt
       AND tt.contr_dt < @srch_edt
    OPTION (MAXDOP 1)
*/

    --�ŷ���, ī�����, ī����ΰ�
	SELECT @contr_cnt 	 = isnull(sum (CASE WHEN tt.acnt_way in ('A2', 'A7') and tt.acnt_stat ='SX'  THEN 0 ELSE 1 END ), 0)
	    ,  @card_wait_cnt 	 = isnull(sum (CASE WHEN tt.acnt_way in ('A2','A7') and tt.acnt_stat ='SN' and tt.acpt_yn='W' THEN 1 ELSE 0 END ), 0)
	    ,  @card_acpt_se_cnt = isnull(sum (CASE WHEN tt.acnt_way in ('A2','A7') and tt.acnt_stat ='SE' and tt.acpt_yn='Y' THEN 1 ELSE 0 END ), 0)
	  FROM tiger.dbo.dscontr as tt with (nolock)
	 WHERE tt.contr_dt >= @srch_sdt
       AND tt.contr_dt < @srch_edt
       AND (tt.cashpay_way <> 'E' OR tt.cashpay_way is null)
     OPTION (MAXDOP 1)

    --ī����ν��а�
    SELECT @card_fail_cnt = isnull(count(*), 0)
      FROM tiger.dbo.dscontr as ds with (nolock)
     WHERE ds.contr_dt >= @srch_sdt
       AND ds.contr_dt < @srch_edt
       AND ds.acnt_way in ('A2', 'A7') and ds.acnt_stat ='SX'
     OPTION (MAXDOP 1)

    --ȸ����ϰ�
	SELECT @custom_reg_cnt = isnull(count(*), 0)
	  FROM ccmng.dbo.cc_custom_grouping as cu with (nolock)
	 WHERE cu.reg_dt >= @srch_sdt
       AND cu.reg_dt < @srch_edt

    --��ǰ ��ϰ�
	SELECT @goods_reg_cnt= isnull(count(*), 0)
   	  FROM lion.dbo.goods_change_hist as gd with (nolock)
	 WHERE gd.reg_dt >= @srch_sdt
       AND gd.reg_dt < @srch_edt


    insert into monitoring.dbo.collect_contr
    (
        collect_dt
    ,   contr_wait_cnt
    ,   contr_cnt
    ,   contr_fail_cnt
    ,   card_wait_cnt
    ,   card_acpt_se_cnt
    ,   card_fail_cnt
    ,   custom_reg_cnt
    ,   goods_reg_cnt
    ,   collect_date
    ,   collect_hour
    ,   collect_min
    ,   order_cnt
    ,   front_contr_cnt
    )
    SELECT 	@srch_edt           as collect_dt
        ,   @contr_wait_cnt		as contr_wait_cnt
        ,	@contr_cnt 		    as contr_cnt
        ,   @contr_fail_cnt     as contr_fail_cnt
        ,	@card_wait_cnt 		as card_wait_cnt
        ,	@card_acpt_se_cnt 	as card_acpt_se_cnt
        ,   @card_fail_cnt      as card_fail_cnt
        ,	@custom_reg_cnt 	as custom_reg_cnt
        ,	@goods_reg_cnt		as goods_reg_cnt
        ,   convert(char(10), @srch_edt, 121) as collect_date
        ,   datepart(hh, @srch_edt) as collect_hour
        ,   datepart(mi, @srch_edt) as collect_min
        ,   @order_cnt          as order_cnt
        ,   @front_contr_cnt    as front_contr_cnt

    set nocount off


