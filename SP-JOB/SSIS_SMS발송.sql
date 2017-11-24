-- ==========================================
-- 글로벌 을 위한 SMS 발송 테이블
-- SSIS에서 사용
-- ==========================================

USE LION
go

-- 파일 그룹 변경해서 사용해야함

/****** 개체:  Table [dbo].[SMSMSG_CHK_SENDYN]    스크립트 날짜: 11/24/2008 13:56:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SMSMSG_CHK_SENDYN](
	[iid] [int] IDENTITY(1,1) NOT NULL,
	[min_iid] [int] NULL,
	[max_iid] [int] NULL,
	[tb_name] [varchar](20) NULL,
 CONSTRAINT [PK_SMSMSG_CHK_SENDYN] PRIMARY KEY NONCLUSTERED 
(
	[iid] ASC
) ON [LION_DATA_FG]
) ON [LION_DATA_FG]
GO
SET ANSI_PADDING OFF
GO


/****** 개체:  Table [dbo].[SMSMSG_ETC]    스크립트 날짜: 11/24/2008 13:56:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SMSMSG_ETC](
	[iid] [int] IDENTITY(1,1) NOT NULL,
	[cust_no] [varchar](10) NULL,
	[cust_nm] [varchar](50) NULL,
	[hp_no] [varchar](20) NOT NULL,
	[sendmsg] [varchar](80) NULL,
	[ret_cd] [varchar](2) NULL,
	[send_yn] [char](1) NULL,
	[send_dt] [datetime] NULL,
	[reg_dt] [datetime] NULL,
	[flow_no] [int] NULL,
	[pack_no] [int] NULL,
	[contr_no] [int] NULL,
	[reg_id] [varchar](10) NULL,
	[rsrv_dt] [smalldatetime] NULL CONSTRAINT [DF__SMSMSG_ETC__RSRV_DT]  DEFAULT (getdate()),
	[send_no] [varchar](20) NULL CONSTRAINT [DF__SMSMSG_ETC__SEND_NO]  DEFAULT ('15665701'),
	[CHG_DT] [datetime] NULL CONSTRAINT [DF__CHG_DT__SMSMSG_ETC]  DEFAULT (getdate()),
 CONSTRAINT [PK__SMSMSG_ETC__IID] PRIMARY KEY NONCLUSTERED 
(
	[iid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [LION_DATA_FG]
) ON [LION_DATA_FG]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [CIDX__SMSMSG_ETC__IID] ON [dbo].[SMSMSG_ETC] 
(
	[iid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [LION_DATA_FG]
GO
CREATE NONCLUSTERED INDEX [IDX__SMSMSG_ETC__DT_YN] ON [dbo].[SMSMSG_ETC] 
(
	[reg_dt] ASC,
	[send_yn] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [LION_DATA_FG]
GO

use dba
go


/*************************************************************************      
* 프로시저명  : dbo.up_DBA_SMS_get_etcSelect_kt  
* 작성정보    : 2008-08-27    
* 관련페이지  : 인성환    
* 내용        : KT SMS전송- 기타 관련     
* 수정정보    : CRM DB로 이전     
**************************************************************************/    
CREATE  PROCEDURE dbo.up_DBA_SMS_get_etcSelect_kt    
AS     
     
 SET NOCOUNT ON    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
     
 DECLARE @miniid int     
 DECLARE @maxiid int     
    
 SELECT @miniid = isnull(min(iid),0),@maxiid = isnull(max(iid),0) FROM dbo.SMSMSG_ETC with(nolock, index=IDX__SMSMSG_ETC__DT_YN) WHERE reg_dt > dateadd(dd, -3, getdate()) and send_yn = 'N' and sendmsg is not null       
    
 --원본테이블에서 SMS실제발송테이블로 들어가는 데이터들의 iid값을 임시테이블에 업데이트     
 IF @miniid <> 0 and @maxiid <> 0     
 BEGIN    
  UPDATE dbo.SMSMSG_CHK_SENDYN    
  SET     
    min_iid = @miniid    
   , max_iid = @maxiid    
  WHERE tb_name = 'ETC'      
      
 END    
    
 BEGIN     
  SELECT     
    rtrim(ltrim(convert( varchar(15), replace(hp_no,'-','')))) COLLATE Korean_Wansung_CS_AS as hp_no 
   ,  '160701001004' COLLATE Korean_Wansung_CS_AS  as origin    
   ,  convert( varchar(15), send_no) COLLATE Korean_Wansung_CS_AS as send_no  
   ,  '1' COLLATE Korean_Wansung_CS_AS as proc_status  
   ,  rsrv_dt as reserve_date    
   ,  isnull(sendmsg,'') COLLATE Korean_Wansung_CS_AS  as sendmsg  
   ,  flow_no    
   ,  pack_no    
   ,  contr_no    
   ,  reg_id COLLATE Korean_Wansung_CS_AS as reg_id      
   , cust_no COLLATE Korean_Wansung_CS_AS as cust_no     
  FROM dbo.SMSMSG_ETC with(nolock)    
  WHERE iid >= @miniid    
    AND iid <= @maxiid    
      
 END     
    
 SET NOCOUNT OFF 
go

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
go

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_SMS_update_SENDYN_ETC
* 작성정보    : 2008-04-07
* 관련페이지  : 안지원
* 내용        : SENDYN update
* 수정정보    : CRM DB로 이전 
	grant execute on dbo.up_DBA_SMS_update_SENDYN_ETC to goodsdaq
	grant execute on dbo.up_DBA_SMS_update_SENDYN_ETC to backend
	grant execute on dbo.up_DBA_SMS_update_SENDYN_ETC to dev
**************************************************************************/
CREATE  PROCEDURE dbo.up_DBA_SMS_update_SENDYN_ETC		
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	DECLARE @miniid int 
		DECLARE @maxiid int 

	--업데이트 된 iid를 구한다	
	SELECT  @miniid = min_iid , @maxiid = max_iid FROM dbo.SMSMSG_CHK_SENDYN WITH(NOLOCK) WHERE tb_name = 'ETC'

	IF @miniid = 0 AND @maxiid = 0
	BEGIN
		RETURN
	END
	ELSE
	BEGIN
		UPDATE 	
			dbo.SMSMSG_ETC
		SET send_yn = 'Y', send_dt = getdate() 
		WHERE  iid >= @miniid AND iid <= @maxiid
	END	

	SET NOCOUNT OFF

go
