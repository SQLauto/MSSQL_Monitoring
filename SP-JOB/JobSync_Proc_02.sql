

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* ���ν�����  : dbo.procedure_name 
* �ۼ�����    : 2006-08-14  �����
* ����������  :  
* ����        : 1�и��� SMS_Send_List �� ����� EMS �߼� �ý����� �߼� ���̺�� 
                insert �ϰ� �������� �߼�
* ��������    : 2007-07-03 by ceusee (choi bo ra)
                �÷� �������� ��� ����
                2007-08-27 by ceusee �÷� ����
                2007-09-29 by ceusee ������ ��¥ ����ؼ� ���� �߼�
                2007-11-06 by choi bo ra job ���� �߼� ���̺� ����
                2007-12-26 by choi bo ra job �ܰ� ����ȭ �۾�
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
WHERE sendFlag = 1 -- �߼� ��
IF @@ERROR <> 0  GOTO ERRORHANDLER

IF @minSeqNo > 0 AND @maxSeqNo > 0 
BEGIN
   
    IF ((@maxSeqNo - @minSeqNo) + 1 ) > 100  SET @loopCount = ((@maxSeqNo - @minSeqNo) + 1 ) % 100        --100�Ǿ� ó��
	ELSE SET @loopCount = 1


        WHILE (@i <= @loopCount)
       BEGIN
      IF @type = 1
      BEGIN
        -- Step 2 ����ڿ��� ���� �߼�
       INSERT INTO [211.115.74.45].EMS.dbo.AUTO_DBA_JOB (email, cust_nm, title, content1, content2, content3, content4, content5)
        SELECT  email, ems_send_nm
    			,('JOB' + '['+ @@servername + ']: ' + jobName + '��/�� '+ case runStatus 
    									when 1 then '����' 
    									when 2 then '��õ�'
    									when 3 then '��ҵ�'
    									else '����' 
    									END) AS title
    			,('JOB' + '['+ @@servername + ']: ' + jobName + '��/�� '+ case runStatus 
    									when 1 then '����' 
    									when 2 then '��õ�'
    									when 3 then '��ҵ�'
    									else '����'     									    
    									END) AS content1
    			,operatorName as content2
    			, (CONVERT ( DATETIME, RTRIM(rundate)) +  ( runtime * 9 + runtime % 10000 * 6  + runtime % 100 * 10  + 25 * runduration ) / 216e4  ) as content3
    			,cast(jobStepId as varchar)+ '�ܰ�'  as content4
    			,message as content5
        FROM  EMSSendMaster with (nolock)
		WHERE seqNo >= @minSeqNo AND seqNo <= (@minSeqNo + 99) and sendFlag = 1

		
		IF @@ERROR <> 0 RETURN;
       END
       IF @type = 2
       BEGIN
		-- Step 3 DBA���� ���� �߼�
		INSERT INTO [211.115.74.45].EMS.dbo.AUTO_DBA_JOB (email, cust_nm, title, content1, content2, content3, content4, content5)
        SELECT  distinct opt.email, opt.operatorName
    			,('JOB' + '['+ @@servername + ']: ' + jobName + '��/�� '+ case runStatus 
    									when 1 then '����'
    									when 2 then '��õ�'
    									when 3 then '��ҵ�' 
    									else '����' 
    									END) AS title
    			,('JOB' + '['+ @@servername + ']: ' + jobName + '��/�� '+ case runStatus 
    									when 1 then '����' 
    									when 2 then '��õ�'
    									when 3 then '��ҵ�'
    									else '����' 
    									END) AS content1
    			,ems.operatorName as content2
    			, (CONVERT ( DATETIME, RTRIM(rundate)) +  ( runtime * 9 + runtime % 10000 * 6  + runtime % 100 * 10  + 25 * runduration ) / 216e4  ) as content3
    			,cast(jobStepId as varchar)+ '�ܰ�' as content4
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