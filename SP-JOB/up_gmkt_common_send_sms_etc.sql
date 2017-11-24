/*
	작성	: 20071024 이성근
	내용	: SMS 발송용 공용 SP (etc)
	수정	: 2008-03-06 고정민 비회원일때   sms 발송되지 않도록 수정
			  2008-03-20 이익두 url 필드 추가
			  
	grant exec on dbo.up_gmkt_common_send_sms_etc to backend
	grant exec on dbo.up_gmkt_common_send_sms_etc to dev
	grant exec on dbo.up_gmkt_common_send_sms_etc to goodsdaq
	dbo.up_gmkt_common_send_sms_etc '016-499-8823','SMS발송테스트','rickyr',0,'110651576','백형일',317842042,302677151,'2007-11-07 16:00:00'
*/
Create proc dbo.up_gmkt_common_send_sms_etc
	@hp_no		varchar(20)
,	@sendmsg	varchar(80)
,	@reg_id		varchar(10)
,	@flow_no	int
,	@cust_no	varchar(10)	= NULL
,	@cust_nm	varchar(50)	= NULL
,	@pack_no	int		= NULL
,	@contr_no	int		= NULL
,	@rsrv_dt	smalldatetime	= NULL
,	@url		varchar(200)	= ''
as
set nocount on
set transaction isolation level read uncommitted

	if @cust_no = '' set @cust_no = NULL
	if @cust_nm = '' set @cust_nm = NULL 
	if (@pack_no = '' or @pack_no = 0) set @pack_no = NULL
	if (@contr_no = '' or @pack_no = 0) set @contr_no = NULL
	if @rsrv_dt = '' set @rsrv_dt = NULL

	declare @ret_code smallint

	-- 핸드폰 번호 유효성 체크
	set @hp_no = replace(@hp_no, '-', '')
	if (len(@hp_no) < 10) or (left(@hp_no,3) not in ('010', '011', '016', '017', '018', '019')) or (len(@sendmsg) = 0) 
	begin
		set @ret_code = -1
		if (@@nestlevel = 1)
			select @ret_code as ret_code
		return
	end

	-- 비회원일때   sms 발송되지 않도록 수정
--	if @cust_no in ('100543129', '100428809')
--	begin
--		set @ret_code = -1
--		if (@@nestlevel = 1)
--			select @ret_code as ret_code
--		return		
--	end 


	if (@rsrv_dt is null)
		set @rsrv_dt = getdate()

	insert into dbo.smsmsg_etc (cust_no, cust_nm, hp_no, sendmsg, send_yn, reg_dt, flow_no, pack_no, contr_no, reg_id, rsrv_dt)
		 values (@cust_no, @cust_nm, @hp_no, @sendmsg, 'N', getdate(), @flow_no, @pack_no, @contr_no, @reg_id, @rsrv_dt)

	if (@@rowcount > 0)
		set @ret_code = 0
	else
		set @ret_code = -1

	insert into dbo.sms_send_log (flow_no, url)
		select @flow_no, @url

	if (@@nestlevel = 1)
		select @ret_code as ret_code

set nocount off