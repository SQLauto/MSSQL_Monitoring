USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_alert_kill_user_session]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 프로시저명: dbo.up_mon_alert_kill_user_session
* 작성정보	: 2013-07-23 by choi bo ra
* 관련페이지:  
* 내용		:  
* 수정정보	: 6시간 동안 아무 작업도 하지 않은 사용자 session kill
			  2013-09-17 by choi bo ra kpid가 활성화 되어 있어도 클라이언트가 
			  down 되었을 경우 waittype =0x0063 추가
			  2014-10-20 by choi bo ra ebaykorea\ 계정으로 사용하기 때문에 제거
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_alert_kill_user_session]
 	@hour		 int  = 6

AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */  
declare @i TINYINT, @total_cnt tinyint
declare @str_sql nvarchar(100)

/* BODY*/

-- 세선 정보 담기
select identity (tinyint, 1,1) as seqno , convert(nvarchar(10), spid) as session_id
	into #tmp_kill_session
from sys.sysprocesses with(nolock)  
where spid >50
	and not loginame like 'dba%' 
	and program_name in
	(
	'Microsoft SQL Server Management Studio - 쿼리'
	,'GSQLGateForMSSQLMain.exe'
	,'Microsoft SQL Server Management Studio'
	) 
	-- kpid가 활성화 되어 있어도 클라이언트가 down 되었을 경우 waittype =0x0063 --ASYNC_NETWORK_IO
	and ((open_tran = 0 and kpid =0) or ( open_tran =0 and kpid !=0 and waittype =0x0063))
	and last_batch < convert(datetime, convert(nvarchar(10),dateadd(hh,-1*@hour,getdate()), 121) )
	--and ( loginame like 'ed1%' or loginame like 'od1%' OR loginame like 'da%' OR loginame like 'sl%')


set @total_cnt = @@rowcount


set @i =1 
while @i <= @total_cnt
begin
	
	select @str_sql = 'KILL ' + session_id from  #tmp_kill_session where seqno = @i
	
	exec sp_executesql @str_sql
	set @i = @i + 1
end



GO
