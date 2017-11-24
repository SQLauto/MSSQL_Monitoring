
/*
 작성정보 : 2008-01-15 이익두
 관련페이지 : 
 내용 :  카드 실패 건 상세
 수정정보 : 
 grant exec on dbo.up_DBA_monitoring_Card_Fail_Detail to backend
*/
CREATE PROCEDURE dbo.up_DBA_monitoring_Card_Fail_Detail
    @type  char(1), --10분 G 1분 M  1시간 H
    @srch_dt datetime
AS
    set nocount on
    set transaction isolation level read uncommitted
    set query_governor_cost_limit 0

    declare 	@srch_sdt           datetime    -- 조회시작
	          ,	@srch_edt           datetime	-- 조회끝

    set @srch_sdt = convert(char(16), dateadd(mi, -1, @srch_dt), 121) + ':00.000'

    if @type = 'G'
    begin
	    set @srch_edt = convert(char(16), dateadd(mi, 10, @srch_sdt), 121)+ ':00.000'
    end
    else if @type = 'M'
    begin
	    set @srch_edt = convert(char(16), dateadd(mi, 1, @srch_sdt), 121)+ ':00.000'
    end
    else if @type = 'H'
    begin
	    set @srch_edt = convert(char(16), dateadd(hh, 1, @srch_sdt), 121)+ ':00.000'
    end
    else
    begin
	    return 0
    end

	select
	tt.pack_no			as pack_no,
	tt.buy_order_no		as order_no,
	tt.gd_no			as gd_no,
	left(gd.gd_nm, 50)	as gd_nm,
	ca.ret_mean			as ret_mean
	from tiger.dbo.dscardacpt ca with(nolock, index=idx__acpt_dt__ret_cd)
	inner loop join tiger.dbo.dscontr tt with(nolock) on tt.contr_dt <> '' and tt.pack_no = ca.pack_no
	inner loop join tiger.dbo.goods gd with(nolock) on gd.gd_no = tt.gd_no
	where ca.ret_cd = '-3'
	and ca.acpt_dt >= @srch_sdt
	and ca.acpt_dt < @srch_edt
    order by pack_no, order_no
    option (maxdop 1, force order)

    set nocount off


