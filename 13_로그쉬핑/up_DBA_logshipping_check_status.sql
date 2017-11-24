SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_logshipping_check_status' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_logshipping_check_status
*/
/*************************************************************************  
* 프로시저명  : dbo.up_DBA_logshipping_check_status 
* 작성정보    : 2006-11-16	곽형섭
* 관련페이지  :  
* 내용        : 조회용 DB Live 체크후 SMS 메세지 발송
                REFER 때문에 SUBDB3
                실행 주기 : 월 ~ 금 8:54 ~ 18:54 분 까지 매시 55분 수행
			    토      8:54 ~ 12:54 분
* 수정정보    : 2007-08-12 by 최보라
                프로시저 통일화를 위해 이름 변경, 로직 변경
**************************************************************************/
CREATE	PROCEDURE dbo.up_DBA_logshipping_check_status
    @user_db_name       SYSNAME
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
declare @hour int,	@isRestore	char(1),	@msg varchar(50)
DECLARE @mi  int


--	10분후 시각저장
select @hour = datepart(hh, getdate())
select @mi = datepart(mi, getdate())

IF @mi > 55
BEGIN

    --	조회용DB 복원 여부 체크
    if @hour % 2 = 1
    begin
    	-- 홀수
    	EXEC  dbo.up_DBA_logshipping_status @user_db_name , @isRestore OUTPUT
    	SET @msg = '[' + @@SERVERNAME + ']' + convert(varchar(2),@hour) + '시 ' + @user_db_name + ' 아직 복원중'
    end
    else 
    begin
    	-- 짝수
    	EXEC dbo.up_DBA_logshipping_status @user_db_name, @isRestore OUTPUT
    	SET @msg = '[' + @@SERVERNAME + ']' + convert(varchar(2),@hour) + '시 ' + @user_db_name + ' 아직 복원중'
    end
    

    
    	-- 다음 서비스 예정 조회용DB가 55분까지도 복원중이면 SMS 발송
    	if @isRestore = 'N' 
    	begin
    		-- 예외 사항으로 이름으로 지정했음
    		EXEC dbo.up_DBA_send_sms 1,'0164436001', @MSG					-- 박은정
    		EXEC dbo.up_DBA_send_sms 1,'0162920001', @MSG					-- 김영호
    		EXEC dbo.up_DBA_send_sms 1,'01190214129', @MSG				-- 윤태진
    		EXEC dbo.up_DBA_send_sms 1,'0177162542', @MSG					-- 김태환
    		EXEC dbo.up_DBA_send_sms 1,'0174551104', @msg
    	end
END
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
GO