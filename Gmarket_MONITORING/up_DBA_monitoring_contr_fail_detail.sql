
/*************************************************************************  
* 프로시저명  : up_DBA_monitoring_contr_fail_detail
* 작성정보    : 2008-01-08 김태환
* 관련페이지  :  
* 내용        : 
* 수정정보    : 팔자주문 상세 추가
				2008-01-28 최길형 
* 권한        : grant exec on dbo.up_DBA_monitoring_contr_fail_detail to backend              
**************************************************************************/
CREATE PROC dbo.up_DBA_monitoring_contr_fail_detail
    @srch_dt        datetime        -- 조회 일자
,   @type           char(1)         -- 타입(G:10분, M:1분, H:시간)
AS
    set nocount on
    set transaction isolation level read uncommitted
    set query_governor_cost_limit 1500

    declare 	@srch_sdt           datetime    -- 조회시작
            ,	@srch_edt           datetime	-- 조회끝

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
        WHEN 'RN' THEN '해당 주문계좌에 대한 정보가 계좌테이블에 없어서 주문을 삭제한 상태'
        WHEN 'RR' THEN '해당 주문이 이미 매수/매도 테이블에 존재'
        WHEN 'RX' THEN '데이터 문제로 흥정처리가 안되 삭제됨'
        WHEN 'RT' THEN '카드승인이 되고 정상적으로 체결처리가 됨'
        WHEN 'EX' THEN '유효기간이 지나 삭제됨'
        WHEN 'XX' THEN 'dsorderindex에는 존재하고 dsorder에는 없는 주문'
        WHEN 'NT' THEN '특정상품 재고없음으로 인해 동반 취소된 장바구니 주문'
        WHEN 'NC' THEN '재고없음'
        WHEN 'CN' THEN '취소주문인 경우 취소하고자 하는 주문이 없음'
        WHEN 'CA' THEN '취소하고자 하는 주문이 이미 처리된 상태'
        WHEN 'MN' THEN '수정주문인 경우 수정하고자 하는 주문이 없음'
        WHEN 'MA' THEN '수정하고자 하는 주문이 이미 처리된 상태'
        WHEN 'RD' THEN '주문이 읽혀진 상태'
        WHEN 'MC' THEN '구매자결제금이 원가보다 적은 경우'
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
		'판매자ID : ' + cast(cu.login_id as char(10)) + ' / ' + 
		'가격 : ' + replace(convert(char(10), ds.ORDER_PRICE), '.00', '') + ' / ' + 
		'재고 : ' + convert(char(5), remain) + '<br/> ' +
		'주문일 : ' + convert(varchar(10), ds.order_dt,121) + ' / ' +
		'유효기간 : ' + convert(varchar(10), ds.expire_dt,121)
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

