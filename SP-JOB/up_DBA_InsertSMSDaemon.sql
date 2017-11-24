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
* ���ν�����  : dbo.up_DBA_InsertSMSDaemon 
* �ۼ�����    : 2006-08-14  �����  
* ����������  :  
* ����        : 5�и��� SMS_Send_List �� ����� SMS �߼� �ý����� �߼� ���̺�� Insert
                �ݼ� ���� Update
* ��������    : 2007-07-06 by ceusee (�ֺ���)
 ���̺� ���� �������� ��� ������ ����
 2007-07-13 by ceusee temCode�� ������� ������ ���� 
 2007-11-06 by choi bo ra �߼� ���� ����� ���������� �Ǽ� ����
 2007-12-26 by choi bo ra �ߺ� ���� �ؼ� �߼�
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
-- Step 1 �߼۰� ����
SELECT @minSeqNo = MIN(seqNo), @maxSeqNo = MAX(SeqNo)  
FROM dbo.SMSSendMaster  WITH (NOLOCK)  
WHERE sendFlag= 1
IF @@ERROR <> 0 GOTO ERRORHANDLER

IF @minSeqNo > 0 AND @maxSeqNo > 0 
BEGIN
    SET @serverName = @@SERVERNAME
 
    WHILE (1 = 1)
    BEGIN
        -- Step 2 ����ڿ��� SMS
        INSERT INTO sms.kidc_sms.dbo.smscli_tbl_02 (destination, originator, callback, callbackURL, 
                body ,proc_status, teleservice_id )
         SELECT REPLACE(HPNo,'-',''), '160701001001', '15665701', NULL, 
                  'JOB [' + @@serverName + ']' + LEFT(JobName,30) + '::' + CONVERT(VARCHAR(2),jobStepId) +'�ܰ�-' 
               + CASE runStatus   when 1 then '����' 
    									when 2 then '��õ�'
    									when 3 then '��ҵ�'
    									else '����'  END AS body, '1', '4098'
       FROM dbo.SMSSendMaster with (Nolock)  
       WHERE seqNo = @minSeqNo  
     
       
       IF @@ERROR <> 0  BREAK;
       
       -- Step 3 DBA�� ���� SMS temCode = 1
       INSERT INTO sms.kidc_sms.dbo.smscli_tbl_02 (destination, originator, callback, callbackURL, 
                body ,proc_status, teleservice_id )
       SELECT DISTINCT REPLACE(opt.HPNo,'-',''), '160701001001', '15665701', NULL, 
                  'JOB [' + @@serverName + ']' + LEFT(JobName,30) + '::' + CONVERT(VARCHAR(2),jobStepId) +'�ܰ�-' 
               + CASE runStatus   when 1 then '����' 
    									when 2 then '��õ�'
    									when 3 then '��ҵ�'
    									else '����'  END AS body, '1', '4098'
       FROM dbo.SMSSendMaster AS sms WITH (Nolock)  JOIN dbo.OperatorSimple AS opt ON
                1 = 1
       WHERE opt.temCode = 1
       AND seqNo = @minSeqNo 
       
        IF @@ERROR <> 0  BREAK;
        
        -- Step 4 �߼� �Ϸ�� ���� ����
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