SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
--IF EXISTS (SELECT name 
--	   FROM   sysobjects
--	   WHERE  name = N'up_DBA_InsertSMSDaemon' 
--	   AND 	  type = 'P')
--    DROP PROCEDURE  up_DBA_InsertSMSDaemon
--GO

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