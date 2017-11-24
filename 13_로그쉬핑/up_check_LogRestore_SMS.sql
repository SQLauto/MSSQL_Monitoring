

/*************************************************************************  
* 프로시저명  : dbo.up_check_LogRestore_SMS 
* 작성정보    : 2006-11-16	곽형섭
* 관련페이지  :  
* 내용        : 조회용 DB Live 체크후 SMS 메세지 발송
                REFER 때문에 SUBDB3
                실행 주기 : 월 ~ 금 8:54 ~ 18:54 분 까지 매시 55분 수행
			    토      8:54 ~ 12:54 분
* 수정정보    :
**************************************************************************/
CREATE	PROCEDURE dbo.up_check_LogRestore_SMS
as
	declare @hour int,	@isRestore	int,	@msg varchar(50)


 	--	10분후 시각저장
 	select @hour = datepart(hh, getdate())


	--	조회용DB 복원 여부 체크
	if @hour % 2 = 1
	begin
		-- 홀수
		EXEC @isRestore =  subdb3.dba.dbo.up_logrestore_result
		set @msg = convert(varchar(2),@hour) + '시 조회용DB(subdb3)가 아직 복원중.'
	end
	else 
	begin
		-- 짝수
		EXEC @isRestore =  superdb1.dba.dbo.up_logrestore_result
		set @msg = convert(varchar(2),@hour) + '시 조회용DB(superdb1)가 아직 복원중.'
	end


	-- 다음 서비스 예정 조회용DB가 55분까지도 복원중이면 SMS 발송
	if @isRestore = 1 
	begin
		--exec dbo.up_kidcsms_send_SMS '0162609654', @msg					-- 곽형섭
		exec dbo.up_kidcsms_send_SMS '0164436001', @msg					-- 박은정
		exec dbo.up_kidcsms_send_SMS '0162920001', @msg					-- 김영호
		exec dbo.up_kidcsms_send_SMS '01190214129', @msg					-- 윤태진
		exec dbo.up_kidcsms_send_SMS '0177162542', @msg					-- 김태환
		exec dbo.up_kidcsms_send_SMS '01071740589', @msg					-- 이상훈
	end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO