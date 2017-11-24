

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.procedure_name 
* 작성정보    : 2006-08-14  오경배
* 관련페이지  :  
* 내용        : 1분마다 SMS_Send_List 의 대상을 EMS 발송 시스템의 발송 테이블로 
                insert 하고 데몬으로 발송
* 수정정보    : 2007-07-03 by ceusee (choi bo ra)
                컬럼 변경으로 방식 수정
                2007-08-27 by ceusee 컬럼 변경
                2007-09-29 by ceusee 실행한 날짜 계산해서 메일 발송
                2007-11-06 by choi bo ra job 메일 발송 테이블 변경
                2007-12-26 by choi bo ra job 단계 세분화 작업
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_InsertEMSDaemon
    @type  INT

AS
/* COMMON DECLARE */
SET NOCOUNT ON  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  

/* USER DECLARE */
DECLARE @minSeqNo   INT
DECLARE @maxSeqNo   INT
DECLARE @loopCount  INT
DECLARE @i INT
SET @minSeqNo = 0
SET @maxSeqNo = 0
SET @loopCount = 0
SET @i = 1

/* BODY */

-- Step 1: select 
SELECT @minSeqNo= ISNULL(MIN(SeqNo),0), @maxSeqNo= ISNULL(MAX(SeqNo),0)
FROM dbo.EMSSendMaster
WHERE sendFlag = 1 -- 발송 전
IF @@ERROR <> 0  GOTO ERRORHANDLER

IF @minSeqNo > 0 AND @maxSeqNo > 0 
BEGIN
   
    IF ((@maxSeqNo - @minSeqNo) + 1 ) > 100  SET @loopCount = ((@maxSeqNo - @minSeqNo) + 1 ) % 100        --100건씩 처리
	ELSE SET @loopCount = 1


        WHILE (@i <= @loopCount)
       BEGIN
      IF @type = 1
      BEGIN
        -- Step 2 담당자에게 메일 발송
       INSERT INTO [211.115.74.45].EMS.dbo.AUTO_DBA_JOB (email, cust_nm, title, content1, content2, content3, content4, content5)
        SELECT  email, ems_send_nm
    			,('JOB' + '['+ @@servername + ']: ' + jobName + '이/가 '+ case runStatus 
    									when 1 then '성공' 
    									when 2 then '재시도'
    									when 3 then '취소됨'
    									else '실패' 
    									END) AS title
    			,('JOB' + '['+ @@servername + ']: ' + jobName + '이/가 '+ case runStatus 
    									when 1 then '성공' 
    									when 2 then '재시도'
    									when 3 then '취소됨'
    									else '실패'     									    
    									END) AS content1
    			,operatorName as content2
    			, (CONVERT ( DATETIME, RTRIM(rundate)) +  ( runtime * 9 + runtime % 10000 * 6  + runtime % 100 * 10  + 25 * runduration ) / 216e4  ) as content3
    			,cast(jobStepId as varchar)+ '단계'  as content4
    			,message as content5
        FROM  EMSSendMaster with (nolock)
		WHERE seqNo >= @minSeqNo AND seqNo <= (@minSeqNo + 99) and sendFlag = 1

		
		IF @@ERROR <> 0 RETURN;
       END
       IF @type = 2
       BEGIN
		-- Step 3 DBA에게 메일 발송
		INSERT INTO [211.115.74.45].EMS.dbo.AUTO_DBA_JOB (email, cust_nm, title, content1, content2, content3, content4, content5)
        SELECT  distinct opt.email, opt.operatorName
    			,('JOB' + '['+ @@servername + ']: ' + jobName + '이/가 '+ case runStatus 
    									when 1 then '성공'
    									when 2 then '재시도'
    									when 3 then '취소됨' 
    									else '실패' 
    									END) AS title
    			,('JOB' + '['+ @@servername + ']: ' + jobName + '이/가 '+ case runStatus 
    									when 1 then '성공' 
    									when 2 then '재시도'
    									when 3 then '취소됨'
    									else '실패' 
    									END) AS content1
    			,ems.operatorName as content2
    			, (CONVERT ( DATETIME, RTRIM(rundate)) +  ( runtime * 9 + runtime % 10000 * 6  + runtime % 100 * 10  + 25 * runduration ) / 216e4  ) as content3
    			,cast(jobStepId as varchar)+ '단계' as content4
    			,message as content5
        FROM  EMSSendMaster AS ems with (nolock) JOIN dbo.OperatorSimple AS opt WITH (NOLOCK) ON 1 = 1
		WHERE seqNo >= @minSeqNo AND seqNo <= (@minSeqNo + 99) AND sendFlag = 1 AND opt.temCode = 1
		
		
		IF @@ERROR <> 0 RETURN; 
	
		UPDATE dbo.EMSSendMaster 
		SET sendFlag = 2,
		    changeDate = GETDATE()
		WHERE seqNo >= @minSeqNo AND seqNo <= (@minSeqNo + 99) AND sendFlag = 1
		
		IF @@ERROR <> 0 RETURN; 
		
		SET @i = @i + 1
		SET @minSeqNo = @minSeqNo + 100

    END
END
SET NOCOUNT OFF
RETURN

ERRORHANDLER:
BEGIN
    RETURN -1
END 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_InsertSMSDaemon 
* 작성정보    : 2006-08-14  오경배  
* 관련페이지  :  
* 내용        : 5분마다 SMS_Send_List 의 대상을 SMS 발송 시스템의 발송 테이블로 Insert
                반송 정보 Update
* 수정정보    : 2007-07-06 by ceusee (최보라)
 테이블 구조 변경으로 방식 완전히 변경
 2007-07-13 by ceusee temCode와 상관없이 보내게 변경 
 2007-11-06 by choi bo ra 발송 보낼 사람이 여러명으로 되서 수정
 2007-12-26 by choi bo ra 중복 제거 해서 발송
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_InsertSMSDaemon
    @minSeqNo       INT OUTPUT,
    @maxSeqNo       INT OUTPUT
AS

/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/* USER DECLARE */
DECLARE @serverName NVARCHAR(10)
SET @minSeqNo = 0
SET @maxSeqNo = 0

/* BODY */
-- Step 1 발송건 추출
SELECT @minSeqNo = MIN(seqNo), @maxSeqNo = MAX(SeqNo)  
FROM dbo.SMSSendMaster  WITH (NOLOCK)  
WHERE sendFlag= 1
IF @@ERROR <> 0 GOTO ERRORHANDLER

IF @minSeqNo > 0 AND @maxSeqNo > 0 
BEGIN
    SET @serverName = @@SERVERNAME
 
    WHILE (1 = 1)
    BEGIN
        -- Step 2 담당자에게 SMS
        INSERT INTO sms.kidc_sms.dbo.smscli_tbl_02 (destination, originator, callback, callbackURL, 
                body ,proc_status, teleservice_id )
         SELECT REPLACE(HPNo,'-',''), '160701001001', '15665701', NULL, 
                  'JOB [' + @@serverName + ']' + LEFT(JobName,30) + '::' + CONVERT(VARCHAR(2),jobStepId) +'단계-' 
               + CASE runStatus   when 1 then '성공' 
    									when 2 then '재시도'
    									when 3 then '취소됨'
    									else '실패'  END AS body, '1', '4098'
       FROM dbo.SMSSendMaster with (Nolock)  
       WHERE seqNo = @minSeqNo  
     
       
       IF @@ERROR <> 0  BREAK;
       
       -- Step 3 DBA팀 에게 SMS temCode = 1
       INSERT INTO sms.kidc_sms.dbo.smscli_tbl_02 (destination, originator, callback, callbackURL, 
                body ,proc_status, teleservice_id )
       SELECT DISTINCT REPLACE(opt.HPNo,'-',''), '160701001001', '15665701', NULL, 
                  'JOB [' + @@serverName + ']' + LEFT(JobName,30) + '::' + CONVERT(VARCHAR(2),jobStepId) +'단계-' 
               + CASE runStatus   when 1 then '성공' 
    									when 2 then '재시도'
    									when 3 then '취소됨'
    									else '실패'  END AS body, '1', '4098'
       FROM dbo.SMSSendMaster AS sms WITH (Nolock)  JOIN dbo.OperatorSimple AS opt ON
                1 = 1
       WHERE opt.temCode = 1
       AND seqNo = @minSeqNo 
       
        IF @@ERROR <> 0  BREAK;
        
        -- Step 4 발송 완료로 상태 변경
        UPDATE dbo.SMSSendMaster 
		SET sendFlag = 2,
		    changeDate = GETDATE()
		WHERE seqNo = @minSeqNo
		
		SET @minSeqNo = @minSeqNo + 1
		IF @minSeqNo > @maxSeqNo BREAK;
        
       
    END
END
 
SET NOCOUNT OFF
RETURN

ERRORHANDLER:
BEGIN
    RETURN -1
END
	
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO