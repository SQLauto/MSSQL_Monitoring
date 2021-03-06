USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_alert_longtransaction]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*      
Description : 오래된 트랜잭션 찾기      
작성자 : choi bo ra      
작성일 : 2011-04-06 by choi bo ra 변수 선언 문제 해결   
		2013-01-23 by choi bo ra 서비스 계정 포함, 트랜잭션 유형 분류 
		2013-05-06 by choi bo ra IAC-GMKT 통합 버전 배포
		2013-05-07 by Seo Eun Mi 개인계정 예외처리 구문 수정
		2013-07-12 by choi bo ra 제외 계정 테이블 추가
		2013-07-18 by Yoo Jin Ho 제외 계정 테이블 삭제 조건 추가 ( END_DATE IS NOT NULL)
*/      
CREATE PROCEDURE [dbo].[up_mon_alert_longtransaction]  
  @site char(1)     
AS      
BEGIN      
      
SET NOCOUNT ON        
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED        
      
 DECLARE @session_id int, @elasped_time int, @cnt int , @i int ,@rowcount INT
 DECLARE @term int , @sms_yn  char(1), @login_name sysname
 DECLARE @msg varchar(80) 

DELETE DBO.DB_MON_EXCEPTION_LOGINS WHERE START_DATE < DATEADD(DD, -2, CONVERT(NVARCHAR(10), GETDATE(), 121)) AND END_DATE IS NOT NULL
 
if datepart(hh,getdate()) >= 0 and datepart(hh,getdate()) < 8  
	set @term = 90 
else 
	set @term = 5

 IF (@@SERVERNAME LIKE 'BI%') OR (@@SERVERNAME LIKE 'DW%') OR (@@SERVERNAME = 'GCENTERDB') 
	set @term = 180

select @term
set @sms_yn = 'N'
 
declare @log_qeury table (seqno  int identity(1,1) ,  session_id int , diff_time int, login_name sysname null) 
 
INSERT INTO @log_qeury
SELECT   B.session_id      
	,DATEDIFF(mi, A.transaction_begin_time, GETDATE() )
	,D.login_name
FROM sys.dm_tran_active_transactions A WITH (NOLOCK)      
LEFT JOIN sys.dm_tran_session_transactions B WITH (NOLOCK) ON A.transaction_id = B.transaction_id       
LEFT JOIN sys.dm_exec_sessions D ON B.session_id = D.session_id  
WHERE A.transaction_state  in (2,4,5) 
	--2 = 트랜잭션이 활성 상태입니다.
	-- 4 = 분산 트랜잭션에서 커밋 프로세스가 시작되었습니다. 이것은 분산 트랜잭션에만 사용됩니다. 
	--분산 트랜잭션이 여전히 활성 상태지만 더 이상은 처리할 수 없습니다.
	--5 = 트랜잭션이 준비된 상태이며 해결을 기다리고 있습니다. 
AND A.transaction_type  in (1,2,4)
	--1 = 읽기/쓰기 트랜잭션
	--4 = 분산 트랜잭션
	AND   DATEDIFF(mi, A.transaction_begin_time, GETDATE()) > @term
	AND D.login_name not in 
	( 'AUCT_DOM\auctdba00', 'AUCT_DOM\IAC-SQL', 'AUCT_DOM\AGENT_DBA'
	  ,'GMARKETNH\gmarket-sql','GMARKETNH\AGENT_DBA'
	  ,'EBAYKOREA\AGENT_DBA'	)  

	AND D.login_name not like 'EBAYKOREA\cac%'
	--AND D.login_name not like 'EBAYKOREA\zwahn'--20131114 임시
	AND D.LOGIN_NAME NOT IN  ( SELECT LOGIN_ID FROM DBO.DB_MON_EXCEPTION_LOGINS WITH (NOLOCK)
								WHERE START_DATE <= GETDATE() AND ISNULL(END_DATE, '2999-12-31') > GETDATE()) 


set @rowcount = @@rowcount
set @i = 1


while (@i <= @rowcount)
BEGIN
	
set @sms_yn = 'N'
	
select @session_id  = session_id,@elasped_time = diff_time, @login_name = login_name 
from @log_qeury where seqno = @i
and session_id!=113

IF @session_id IS NOT NULL      
BEGIN  
	-- 개인 계정 5분 이상
	IF (@login_name like 'pd1_%'  
	OR @login_name like  'od1_%'  
	OR @login_name like  'ad1_%'  
	OR (@login_name <>   'dw_ssis'  and @login_name like 'dw[_]%')
	OR @login_name like  'da_%'  
	OR (@login_name <>   'dba_ssis'  and @login_name like 'dba[_]%')
	OR @login_name like  'ed1_%' 
	OR @login_name like  'EBAYKOREA\%'
	)
		SET @sms_yn = 'Y'			   
	-- 서비스 계정 1시간 이상.
	ELSE 
		IF @elasped_time >= 60 SET @sms_yn = 'Y'
	

	-- 문자 발송
	IF @sms_yn = 'Y'
	BEGIN
		declare @sms varchar(200)  
		SET @msg = '['+ @@SERVERNAME + ']'  + 'Long Query SPID=' + CAST(@session_id AS varchar(5))   
				+ '('+ @login_name + ') ,elasped(분)=' + CAST(@elasped_time AS varchar(5)) 
     
		IF @Site  = 'G'  
		BEGIN  
  
			set @sms = 'sqlcmd -S GCONTENTSDB,3950 -E -Q"exec sms_admin.dbo.up_dba_send_short_msg ''DBA'',''' + @msg + '''"'  
			exec xp_cmdshell  @sms  
		END  
		ELSE IF @Site ='I'  
		BEGIN  
  			set @sms = 'sqlcmd -S epdb2 -E -Q"exec smsdb.dbo.up_dba_send_short_msg ''DBA'',''' + @msg + '''"'  
			exec xp_cmdshell  @sms  
		END  
    END -- 문자발송 YN
END  -- sessin_id
    
	
SET @i = @i + 1  
END

--SELECT @session_id As session_id, @elasped_time AS elasped_time      
      
      
END 




GO
