
/*
	작성정보 :	2007-12-24 이익두
	관련페이지 :	
	내용	:  카드 실패 카드별 및 실패사유별로 건수 Cnt
	수정정보	: 
	grant exec on dbo.up_DBA_monitoring_Card_Maincard_Fail_Cnt to backend
*/
CREATE PROCEDURE dbo.up_DBA_monitoring_Card_Maincard_Fail_Cnt
@type  char(1), --10분 G 1분 M  1시간 H
@srch_dt datetime
as
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
		st.SttlKind_Nm  as cardname,
		ca.RET_MEAN		as ret_mean,
		count(*)		as card_cnt
	from tiger.dbo.dscardacpt ca with(nolock)
	inner loop join tiger.dbo.sttltool st with(nolock) on st.SttlKind_Seq = ca.maincard
	where ca.ret_cd = '-3'
	and ca.acpt_dt >= @srch_sdt
	and ca.acpt_dt <= @srch_edt
	group by st.SttlKind_Nm, ca.RET_MEAN
	order by st.SttlKind_Nm asc, count(*) desc
    option (maxdop 1, force order)

    set nocount off

