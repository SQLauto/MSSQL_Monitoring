use dba
go

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO


/*************************************************************************  
* ���ν�����  : dbo.up_DBA_SyncJobs 
* �ۼ�����    : 2007-08-07 ����� 
* ����������  :  
* ����        : 30�� �������� sysjos/sysjobsteps �� Jobs/Jobsteps ���̺�� copy �Ѵ�.  
* ��������    : 2007.06.28 by choi bo ra(ceusee)
                �ߺ��Ǵ� �κ� ����, ���� �����ȹ �輱
                ���� �κ� ����
                up_DBA_SyncJobList_Steps�� �̸� ����, �ǹ� ������ ����
                mgr_no �÷��� 2504 (����ȯ)
                2007-11-06 by choi bo ra JOBS ���̺� �ڵ� ���� �ð� �÷� �߰�, ������ �÷� �߰�
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_SyncJobs    
AS  

    
    SET NOCOUNT ON    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
    
    /* USER DECLARE */
    DECLARE @dtGetdate      DATETIME
    SET @dtGetDate = GETDATE() 
     
    -- Step 1-1 Jobs �ű�
    INSERT INTO dbo.Jobs (job_id, job_name, enabled, date_created, date_modified , mgr_no, reg_DT, CHG_DT, job_id_char)  
    SELECT sysjob.job_id, sysjob.name,  sysjob.enabled,  sysjob.date_created,  sysjob.date_modified, 2504, @dtGetDate, @dtGetDate,
            dbo.fn_hex_to_char(convert(uniqueidentifier,sysjob.job_id), 16) 
    FROM msdb.dbo.sysjobs as sysjob WITH (NOLOCK)  left join  dbo.Jobs AS job WITH (NOLOCK)ON sysjob.job_id = job.job_id
    WHERE job.job_id IS NULL
    
    
    -- Step 1-2 JobSteps �ű�
    INSERT INTO dbo.JobSteps (job_id,step_id, step_name, subsystem, command, database_name, reg_dt, chg_dt)  
    SELECT  sysjobstep.job_id, sysjobstep.step_id, sysjobstep.step_name, sysjobstep.subsystem,
            sysjobstep.command, sysjobstep.database_name, @dtGetDate, @dtGetDate 
    FROM msdb.dbo.sysjobsteps AS sysjobstep WITH(NOLOCK)  LEFT JOIN dbo.JobSteps AS jobstep WITH(NOLOCK) 
            ON sysjobstep.job_id = jobstep.job_id AND sysjobstep.step_id = jobstep.step_id
    WHERE jobstep.job_id IS NULL AND jobstep.step_id IS NULL
    
        
    
    
    --Step 3-1 JobStep ����
    --�ܰ谡 �����Ǿ��ٰ� �߰��� ���� �ֱ� ������ �̸��� ���µ� �Բ� ��������� �Ѵ�.
    --������ Job �������ڸ� �������� �����ߴµ� �׷� ������ ���� �ܰ���� �����Ǿ� ���ʿ��� I/O �߻�
    UPDATE dbo.JobSteps
        SET step_name = sysjobstep.step_name,
            command = sysjobstep.command,
            database_name = sysjobstep.database_name,
            stat = CASE stat WHEN 'S4' THEN 'S2' END,
            chg_dt = @dtGetDate
    FROM msdb.dbo.sysjobsteps AS sysjobstep WITH (NOLOCK) JOIN dbo.JOBSteps AS jobstep WITH (NOLOCK)
            ON sysjobstep.job_id = jobstep.job_id
            AND sysjobstep.step_id = jobstep.step_id
    WHERE (jobstep.step_name <> sysjobstep.step_name  collate Korean_Wansung_CI_AS 
            AND jobstep.command = sysjobstep.command collate Korean_Wansung_CI_AS
            AND jobstep.database_name <> sysjobstep.database_name collate Korean_Wansung_CI_AS)
            OR jobstep.stat = 'S4' 
    
    
    --Step 3-2 Jobs ����
    UPDATE dbo.jobs
        SET job_name = sysjob.name,
            enabled = sysjob.enabled,
            date_modified = sysjob.date_modified,
            chg_dt = @dtGetDate
    FROM msdb.dbo.sysjobs as sysjob with (nolock) join dbo.Jobs as job with (nolock) 
        ON sysjob.job_id = job.job_id
    WHERE sysjob.date_modified <> job.date_modified
    
    
    -- Step 4 ����
    -- 4-1 Jobs ����
    UPDATE dbo.Jobs
        SET stat = 'S4',
            enabled = 0,
            chg_dt = @dtGetDate
    FROM msdb.dbo.sysjobs as sysjob WITH (NOLOCK) RIGHT JOIN  dbo.JOBs AS job WITH (NOLOCK) ON sysjob.job_id = job.job_id
    WHERE sysjob.job_id is null AND job.stat <> 'S4'
    
    -- 4-2 JobSteps ����
    UPDATE dbo.JobSteps
        SET stat = 'S4',
            chg_dt = @dtGetDate
    FROM msdb.dbo.sysjobsteps AS sysjobstep WITH(NOLOCK) RIGHT JOIN dbo.JobSteps AS jobstep WITH(NOLOCK)
            ON sysjobstep.job_id = jobstep.job_id AND sysjobstep.step_id = jobstep.step_id
    WHERE sysjobstep.job_id IS NULL AND sysjobstep.step_id IS NULL
            AND jobstep.stat <> 'S4'
            
    SET NOCOUNT OFF
    RETURN
    GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO


/*************************************************************************  
* ���ν�����  : dbo.up_DBA_SyncJobHistory 
* �ۼ�����    : 2007-08-07 �����
* ����������  : 1�� �������� sysjobhistory �� Jobhistory ���̺�� copy �Ѵ�.  
* ����        : 
* ��������    : 2007.06.28 by choi bo ra(ceusee)
                up_DBA_SyncJObHist���� �̸� ����
                ���� ����Ǳ� ������ ���� ó���� ���� �ʴ´�.
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_SyncJobHistory    
AS

    /* COMMON DECLARE */
    SET NOCOUNT ON    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
    
    /* USER DECLARE */
    DECLARE @count      INT
    DECLARE @totCount   INT
    DECLARE @rowSet     INT
    DECLARE @i          INT
    DECLARE @errCode    INT
    DECLARE @dtGetDate  DATETIME
    DECLARE @strGetDate NVARCHAR(10)
    SET @dtGetdate = GETDATE()
    SET @strGetDate = CONVERT(NVARCHAR(10),@dtGetdate,120)
    SET @count = 0
    SET @rowSet = 5000        -- MainDB �������� 5000õ ó��(��Ʋġ�� 10���� ����)
    SET @i = 0
    
    /* BODY */
    -- �۾�Histroy ��Ʋ�� �����Ѵ�.
    IF DATEPART(hh, @dtGetDate) = 1  AND DATEPART(mi, @dtGetDate) < 30
    BEGIN
    
        SELECT @count = COUNT(*) FROM dbo.JobHistory WITH(NOLOCK) 
        WHERE reg_dt < DATEADD(DD,-2, CONVERT(datetime, @strGetDate , 120))
        SET @totCount = @count
      
        IF @totCount > 0 
        BEGIN
           IF @totCount > 10000             -- ���� ���� ó��
           BEGIN
                
                SET ROWCOUNT @rowSet      
                WHILE (1 = 1)
                BEGIN
                     --BEGIN TRAN
                     DELETE dbo.JobHistory WHERE reg_dt < DATEADD(DD,-2, CONVERT(datetime, @strGetDate, 120))
                     IF @@ERROR <> 0 GOTO ERRORHANDLER
                     
                     SET @count = @count - @rowSet
                     
                    -- COMMIT
                     IF @count <= 0 BREAK
    
                     WAITFOR DELAY '00:00:00.100'
                     SET @i = @i + 1
                END
                
                SET ROWCOUNT 0
           END
           ELSE
           BEGIN
               DELETE dbo.JobHistory WHERE reg_dt < DATEADD(DD,-2, CONVERT(datetime, @strGetDate, 120))
               IF @@ERROR <> 0 RETURN -1   
           END
        END
    END
    
    -- ����
    SELECT @totCount = COUNT(*) FROM dbo.JobHistory WITH (NOLOCK)
    IF @totCount = 0                         -- ���� ó���϶� �۾��ؾ���
    BEGIN

        INSERT INTO dbo.JobHistory(job_hist_id, job_id, step_id, MESSAGE,
                RUN_STATUS, RUN_DATE, RUN_TIME, RUN_DURATION, SMS_CK, EMS_CK, SMSFlag, EMSFlag, REG_DT)  
        SELECT syshistory.instance_id, syshistory.job_id, syshistory.step_id, syshistory.message, 
                syshistory.Run_status, syshistory.run_date, syshistory.run_time,syshistory.run_duration, 
                job.SMS_CK, job.EMS_CK, 1, 1, @dtGetdate
        FROM msdb.dbo.sysjobhistory AS syshistory WITH (NOLOCK) JOIN dbo.Jobs AS job WITH (NOLOCK)
            ON syshistory.job_id = job.job_id
        WHERE job.job_hist_ck = 'Y' AND syshistory.run_date >= CONVERT(INT, CONVERT(NVARCHAR(8),DATEADD(DD,-2,  @strGetDate), 112))
    END
    ELSE IF @totCount > 0 
    BEGIN
        INSERT INTO dbo.JobHistory(job_hist_id, job_id, step_id, MESSAGE,
                RUN_STATUS, RUN_DATE, RUN_TIME, RUN_DURATION,SMS_CK, EMS_CK, SMSFlag, EMSFlag, REG_DT)
        SELECT syshistory.instance_id, syshistory.job_id, syshistory.step_id, syshistory.message, 
               syshistory.Run_status, syshistory.run_date, syshistory.run_time,syshistory.run_duration, 
               job.SMS_CK, job.EMS_CK, 1,1, @dtGetdate
        FROM msdb.dbo.sysjobhistory AS syshistory WITH (NOLOCK) JOIN dbo.Jobs AS job WITH (NOLOCK)
            ON syshistory.job_id  = job.job_id
        WHERE job.job_hist_ck = 'Y' AND syshistory.instance_id > 
                        (SELECT MAX(job_hist_id) FROM dbo.JobHistory with (nolock) ) 
        ORDER BY syshistory.instance_id
    END
    
    SET NOCOUNT OFF
    RETURN

    ERRORHANDLER:
    BEGIN
        IF @@TRANCOUNT <> 0 ROLLBACK
        RETURN 
    END	
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO


/*************************************************************************  
* ���ν�����  : dbo.fn_hex_to_char 
* �ۼ�����    : 2007-07-11
* ����������  :  
* ����        : Job���̵��� ������
* ��������    :
**************************************************************************/
CREATE function fn_hex_to_char (
  @x varbinary(100), -- binary hex value
  @l int -- number of bytes
  ) returns varchar(200)
 as 
-- Written by: Gregory A. Larsen
-- Date: May 25, 2004
-- Description:  This function will take any binary value and return 
--               the hex value as a character representation.
--               In order to use this function you need to pass the 
--               binary hex value and the number of bytes you want to
--               convert.
begin

declare @i varbinary(10)
declare @digits char(16)
set @digits = '0123456789ABCDEF'
declare @s varchar(100)
declare @h varchar(100)
declare @j int
set @j = 0 
set @h = ''
-- process all  bytes
while @j < @l
begin
  set @j= @j + 1
  -- get first character of byte
  set @i = substring(cast(@x as varbinary(100)),@j,1)
  -- get the first character
  set @s = cast(substring(@digits,@i%16+1,1) as char(1))
  -- shift over one character
  set @i = @i/16 
  -- get the second character
  set @s = cast(substring(@digits,@i%16+1,1) as char(1)) + @s
  -- build string of hex characters
  set @h = @h + @s
end
return(@h)
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO


/************************************************************************  
* ���ν�����  : dbo.up_DBA_SyncOperator 
* �ۼ�����    : 2007-07-01 by ceusee (choi bo ra)
                AccountDB����� Tiger ���� operator�� �ʿ��� ������ ������
* ����������  :  
* ����        :
* ��������    : 2007-07-31 by ceusee (choi bo ra), ���� ������ ������
                2007-08-27 by ceusee (choi bo ra), AccountDB�� ���õ� ���� �°�
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_SyncOperator
AS

/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
/* USER DECLARE */

/* BODY */
-- ����� ���� ó��

DELETE  dbo.OperatorSimple
FROM AccountDB.Tiger.dbo.Operator AS M JOIN dbo.OperatorSimple AS O WITH (NOLOCK)
    ON M.Oid = O.operatorNo 
WHERE   M.onoff = 'N' 

-- �ű� �Ի��� �Է�
-- DBA�� SMS �÷��� ������ 0 ���� �Ѵ�. 

INSERT dbo.OperatorSimple (operatorNo, operatorId, sabun, temCode, operatorName, 
        HPNo, Email, jobFlag, dbFlag, backupFlag, logicFlag, HWFlag, registerDate, changeDate)
SELECT M.OId, M.OP_Id, M.sabun, 0, M.OP_NM, M.HP_No, M.Email, 0, 0, 0, 0, 0, M.Reg_DT, ISNULL(M.Chg_DT, GETDATE()) 
FROM AccountDB.Tiger.dbo.Operator AS M LEFT JOIN dbo.OperatorSimple AS O WITH (NOLOCK)
    ON M.Oid = O.operatorNo 
WHERE O.operatorId IS NULL AND M.onoff = 'Y'

IF @@ERROR <> 0 GOTO ERRORHANDLER

-- �������� Update
UPDATE dbo.OperatorSimple
SET HPNo = M.HP_No,
    Email = M.Email,
    jobflag = OS.jobFlag,
    dbFlag = OS.dbFlag,
    logicFlag = OS.logicFlag,
    temCode = OS.temCode,
    backupFlag = OS.backupFlag,
    hwFlag = OS.hwFlag,
    changeDate = ISNULL(OS.changeDate,GETDATE())
FROM AccountDB.Tiger.dbo.Operator AS M JOIN dbo.OperatorSimple AS O WITH (NOLOCK)
    ON M.Oid = O.operatorNo JOIN AccountDB.DBA.dbo.OperatorSimple AS OS 
    ON M.Oid = OS.operatorNo
WHERE ISNULL(OS.changeDate,GETDATE()) <> ISNULL(O.changeDate,GETDATE()) AND M.onoff = 'Y'

IF @@ERROR <> 0 GOTO ERRORHANDLER

SET NOCOUNT OFF
RETURN


ERRORHANDLER:
BEGIN
    IF @@TRANCOUNT > 0 ROLLBACK
    RETURN 
END

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO


/*************************************************************************  
* ���ν�����  : dbo.up_DBA_DeleteEMSSendMaster 
* �ۼ�����    : 2007-07-06 by ceusee (choi bo ra)
* ����������  :  
* ����        : ���� ó�� ���۵� �ð��� ���� �۾� �����Ѵ�.
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_DeleteEMSSendMaster
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
/* USER DECLARE */
DECLARE @dtGetDate      DATETIME
DECLARE @hour           INT
DECLARE @strGetDate     NVARCHAR(10)
SET @dtGetDate = GETDATE()
SET @hour = DATEPART( hh, @dtGetdate)
SET @strGetDate = CONVERT(NVARCHAR(10),getdate(),120)

/* BODY */
-- Step 1
-- �۾��� �����ϴ� ���� 0 ~ 1�� ���̿� ���� �۾�, 2Ʋ ������ ������ ����
IF @hour >= 0 AND @hour < 1         
BEGIN
    DELETE EMSSendMaster WHERE sendFlag = 2 AND changeDate < DATEADD(DD,-2, CONVERT(datetime, @strGetDate , 120))
    IF @@ERROR <> 0 GOTO ERRORHANDLER
END

SET NOCOUNT OFF
RETURN

ERRORHANDLER:
BEGIN
    RETURN 
END

GO
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

 /*************************************************************************    
* ���ν�����  : up_DBA_InsertEMSSendMaster   
* �ۼ�����    : 2006-08-16  �����  
* ����������  :    
* ����        : 1�и��� job_hist ���� EMS �߼۴�� ����Ʈ�� EMS_Send_List��   
                insert �ϰ� hist ���̺� update  
* ��������    : 2007-07-03 by ceusee(choi bo ra)  
                �� DB�� ������ ���̺� ����  
                JobHistory���̺� sendflag �÷� ���� (1: �߼���, 2: �߼���)  
                ���� wile ���� �ʰ� ��, 1�� ���� ����Ǳ� ������ �߼��� �����Ͱ� ���� ����  
                2007-11-06 by ceusee(choi bo ra) ����� ���������� ���� 
                2007-12-26 by choi bo ra �۾� �������� ���� ���� ������ ���� 
**************************************************************************/  
CREATE PROCEDURE dbo.up_DBA_InsertEMSSendMaster   
AS  
  
/* COMMON DECLARE */  
SET NOCOUNT ON    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
  
/* USER DECLARE */  
DECLARE @dtGetDate        DATETIME  
SET @dtGetDate = GETDATE()  
  
  
/* BODY */  
-- Step 1. EMS ���� ���̺� INSERT  
INSERT INTO dbo.EMSSendMaster   
        (jobHistId, jobId, jobName, jobStepId, operatorName, Email, sendFlag,   
        runStatus, runDate, runTime, message, registerDate, changeDate, runduration, ems_send_nm)  
SELECT history.job_hist_id, job.job_id, job.job_name,  step.step_id,
		(select operatorname from dbo.OperatorSimple with (nolock) where operatorno = job.mgr_no) as operatorName, 
		opt.Email, 1,  
        history.run_status, history.run_date, history.run_time, history.message,@dtGetDate, @dtGetDate,
        history.run_duration , opt.operatorName as ems_send_nm 
FROM dbo.Jobs AS job WITH (NOLOCK) JOIN dbo.JobHistory AS history WITH (NOLOCK)   
        ON job.job_id = history.job_id   
        JOIN dbo.JobSteps AS step WITH (NOLOCK) ON history.job_id = step.job_id AND history.step_id = step.step_id  
        JOIN dbo.JOBS_OPERATOR AS jobopt WITH (NOLOCK) ON job.job_id = jobopt.job_id
		JOIN dbo.OperatorSimple AS opt WITH (NOLOCK) ON opt.operatorNo = jobopt.operatorNo 
WHERE job.enabled = 1 AND job.stat = 'S2' AND history.EMSFlag = 1  
        AND history.run_date = CONVERT(NVARCHAR(8), @dtGetDate, 112)  
        AND ((history.ems_ck = 'A') OR (history.ems_ck = 'S' AND history.run_status = 1)  
                OR (history.ems_ck = 'F' AND history.run_status = 0)  
                OR (history.run_status = 3)  
            )  
        AND history.run_status <> 4
ORDER BY history.job_hist_id  
  
IF @@ERROR <> 0 GOTO ERRORHANDLER  
  
-- Step 2. EMS �߼��� ���·� ����  
UPDATE dbo.JobHistory  
SET EMSFlag = 2  
FROM dbo.JobHistory AS history WITH (NOLOCK) JOIN EMSSendMaster AS ems WITH (NOLOCK)  
        ON history.job_hist_id = ems.jobHistId  
WHERE history.EMSFlag = 1 AND history.run_date = CONVERT(NVARCHAR(8), GETDATE(), 112)  
      AND ems.registerDate = ems.changeDate  
IF @@ERROR <> 0 GOTO ERRORHANDLER         
  
SET NOCOUNT OFF  
RETURN  
  
ERRORHANDLER:  
BEGIN  
    RETURN  -1  
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
* ���ν�����  : dbo.up_DBA_job_operator_info_del 
* �ۼ�����    : 2007-11-07 ������ 
* ����������  :  
* ����        : JOBS_OPERTOR ���̺��� delete
* ��������    : 
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_job_operator_info_del
     @strJobId      varchar(40) ,
     @intOperNo		int
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
	DELETE FROM dbo.JOBS_OPERATOR 	
	WHERE job_id = @strJobId  AND operatorno = @intOperNo
	
	IF @@ERROR <> 0 RETURN


RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO



/*************************************************************************  
* ���ν�����  : dbo.up_DBA_job_operator_info_insert 
* �ۼ�����    : 2007-11-07 ������ 
* ����������  :  
* ����        : Job ID�� �ش��ϴ� �߼��� �߰� 
* ��������    :
**************************************************************************/
ALTER PROCEDURE dbo.up_DBA_job_operator_info_insert
     @intOperNo      int,  --�߼��� ��ȣ 
     @strJobId		 varchar(40)	--job ���̵�      
AS
/* COMMON DECLARE */
DECLARE	@intRetVal	smallint

SET NOCOUNT ON

/* USER DECLARE */
	DECLARE @intCnt int
		
/* BODY */
	--�̹� OperatorSimple ���̺� ��ϵǾ� �ִ� �������� Ȯ��
	SELECT @intCnt = count(*) FROM dbo.OperatorSimple with(nolock) WHERE operatorno = @intOperNo
	
	IF @intCnt > 0 
	BEGIN
		INSERT INTO JOBS_OPERATOR(
			job_id
		,	operatorno
		)
		VALUES(
			@strJobId
		,	@intOperNo
		)		
		
		IF @@ERROR = 0 AND @@ROWCOUNT = 1
		BEGIN
			SELECT @intRetVal = 1
		END
		ELSE
		BEGIN
			SELECT @intRetVal = -1
		END

		RETURN @intRetVal
	END 
	
RETURN
go



/*************************************************************************  
* ���ν�����  : dbo.up_DBA_job_operator_info_select 
* �ۼ�����    : 2007-11-07 ������ 
* ����������  :  
* ����        : JOBS_OPERTOR ���̺� insert
* ��������    : exec dbo.up_DBA_job_operator_info_select '8AFC4BEA-41E1-4F48-A144-533443AD9C8A'
**************************************************************************/
ALTER PROCEDURE dbo.up_DBA_job_operator_info_select
     @strJobId      varchar(40)
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
	SELECT 
			Jop.seq_no as seq_no
		,	Jop.job_id as job_id
		,	Jop.operatorno as operatorno
		,	Jop.reg_dt as reg_dt
		,	Sop.operatorName as operatorName  
	FROM dbo.JOBS_OPERATOR AS Jop with(nolock)
	INNER JOIN dbo.OperatorSimple AS Sop with(nolock) ON Jop.operatorno = Sop.operatorno
	WHERE job_id = @strJobId

	IF @@ERROR <> 0 RETURN

RETURN
go
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*****************************************************************************    
SP��		: up_DBA_modJob_Detail
�ۼ�����	: 2006-08-18  ����ȯ
����		: Jobs���̺� �ִ� JOB��� �� ��ȸ
��������    : 
2007-11-06 by choi bo ra ����� �����ϸ� Job
******************************************************************************/
CREATE PROCEDURE dbo.up_DBA_modJob_Detail
	@strJobId		    varchar(40),	-- JOB ID
	@intOID			    int,		    -- ����� �ڵ�
	@intJob_Type        int,
	@strJobHistCK		char(1),		-- �����丮 ���忩��
	@strSMS		        char(1),		-- SMS
	@strEMS			    char(1),		-- EMS
	@strMonitoringYn	char(1),		-- ����͸� ����
	@strKillYn		    char(1),	    -- �ڵ����� (Y:�ڵ� ����, N:������������, A:���������� �ð�üũ)
	@intKill_duration   int             -- ����ð�
AS

DECLARE	@row_count	smallint

BEGIN
	SET NOCOUNT ON  
	
	UPDATE dbo.JOBS
	      SET mgr_no = @intOID,
	             job_type  = @intJob_type,
	             job_hist_ck = @strJobHistCK,
	             sms_ck = @strSMS,
	             ems_ck = @strEMS,
	             monitoring_yn = @strMonitoringYn,
	             kill_yn = @strKillYn,
	             kill_duration = @intKill_duration
	 WHERE JOB_ID = @strJobId

	IF @@ERROR <> 0  SELECT -1  AS intRetVal
	
	
	SELECT @row_count = COUNT(*) FROM JOBS_OPERATOR WITH (NOLOCK)
	WHERE job_id = @strJobId AND operatorNo = @intOID 
	 
	IF @@ERROR <> 0 SELECT -1  AS intRetVal
    
    IF @row_count = 0 
    BEGIN
         INSERT dbo.JOBS_OPERATOR (job_id, operatorno, reg_dt)
         VALUES (@strJobId, @intOID, getdate())
         
         IF @@ERROR <> 0 SELECT -1   AS intRetVal
    END
    
	
    SELECT 0 AS intRetVal
 	SET NOCOUNT OFF
END

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* ���ν�����  : dbo.up_dba_select_operator 
* �ۼ�����    : 2008-06-30 by choi bo ra
* ����������  :  
* ����        : Accountdb�� �ִ� tiger�� operator�� select �Ѵ�.
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_operator
    @onoff   char(1)
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT M.OId, M.OP_Id, M.sabun, M.OP_NM, M.HP_No, M.Email, M.Reg_DT, ISNULL(M.Chg_DT, GETDATE()) as chg_dt
FROM Tiger.dbo.Operator AS M WITH (NOLOCK) 
WHERE M.onoff = @onoff
ORDER BY M.OId


RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* ���ν�����  : dbo.up_dba_select_operatorsimple 
* �ۼ�����    : 2008-06-30 by choi bo ra
* ����������  :  
* ����        : OperatorSimple ���̺��� operatrNo ��ȸ
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_operatorsimple
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT operatorNo
    ,jobflag 
    ,dbFlag
    ,logicFlag 
    ,temCode
    ,backupFlag 
    ,hwFlag 
    ,changeDate
FROM DBA.dbo.OperatorSimple with (nolock)
ORDER BY operatorNo

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* ���ν�����  : dbo.up_dba_select_target_operatorsimple 
* �ۼ�����    : 2008-06-30 by choi bo ra
* ����������  :  
* ����        : update �ؾ��� 
                OperatorSimple ���̺��� operatrNo ��ȸ
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_target_operatorsimple
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT operatorNo, changedate
FROM DBA.dbo.OperatorSimple with (nolock)
ORDER BY operatorNo

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

 /*************************************************************************    
* ���ν�����  : up_DBA_InsertEMSSendMaster   
* �ۼ�����    : 2006-08-16  �����  
* ����������  :    
* ����        : 1�и��� job_hist ���� EMS �߼۴�� ����Ʈ�� EMS_Send_List��   
                insert �ϰ� hist ���̺� update  
* ��������    : 2007-07-03 by ceusee(choi bo ra)  
                �� DB�� ������ ���̺� ����  
                JobHistory���̺� sendflag �÷� ���� (1: �߼���, 2: �߼���)  
                ���� wile ���� �ʰ� ��, 1�� ���� ����Ǳ� ������ �߼��� �����Ͱ� ���� ����  
                2007-11-06 by ceusee(choi bo ra) ����� ���������� ���� 
                2007-12-26 by choi bo ra �۾� �������� ���� ���� ������ ���� 
**************************************************************************/  
CREATE PROCEDURE dbo.up_DBA_InsertEMSSendMaster   
AS  
  
/* COMMON DECLARE */  
SET NOCOUNT ON    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
  
/* USER DECLARE */  
DECLARE @dtGetDate        DATETIME  
SET @dtGetDate = GETDATE()  
  
  
/* BODY */  
-- Step 1. EMS ���� ���̺� INSERT  
INSERT INTO dbo.EMSSendMaster   
        (jobHistId, jobId, jobName, jobStepId, operatorName, Email, sendFlag,   
        runStatus, runDate, runTime, message, registerDate, changeDate, runduration, ems_send_nm)  
SELECT history.job_hist_id, job.job_id, job.job_name,  step.step_id,
		(select operatorname from dbo.OperatorSimple with (nolock) where operatorno = job.mgr_no) as operatorName, 
		opt.Email, 1,  
        history.run_status, history.run_date, history.run_time, history.message,@dtGetDate, @dtGetDate,
        history.run_duration , opt.operatorName as ems_send_nm 
FROM dbo.Jobs AS job WITH (NOLOCK) JOIN dbo.JobHistory AS history WITH (NOLOCK)   
        ON job.job_id = history.job_id   
        JOIN dbo.JobSteps AS step WITH (NOLOCK) ON history.job_id = step.job_id AND history.step_id = step.step_id  
        JOIN dbo.JOBS_OPERATOR AS jobopt WITH (NOLOCK) ON job.job_id = jobopt.job_id
		JOIN dbo.OperatorSimple AS opt WITH (NOLOCK) ON opt.operatorNo = jobopt.operatorNo 
WHERE job.enabled = 1 AND job.stat = 'S2' AND history.EMSFlag = 1  
        AND history.run_date = CONVERT(NVARCHAR(8), @dtGetDate, 112)  
        AND ((history.ems_ck = 'A') OR (history.ems_ck = 'S' AND history.run_status = 1)  
                OR (history.ems_ck = 'F' AND history.run_status = 0)  
                OR (history.run_status = 3)  
            )  
        AND history.run_status <> 4
ORDER BY history.job_hist_id  
  
IF @@ERROR <> 0 GOTO ERRORHANDLER  
  
-- Step 2. EMS �߼��� ���·� ����  
UPDATE dbo.JobHistory  
SET EMSFlag = 2  
FROM dbo.JobHistory AS history WITH (NOLOCK) JOIN EMSSendMaster AS ems WITH (NOLOCK)  
        ON history.job_hist_id = ems.jobHistId  
WHERE history.EMSFlag = 1 AND history.run_date = CONVERT(NVARCHAR(8), GETDATE(), 112)  
      AND ems.registerDate = ems.changeDate  
IF @@ERROR <> 0 GOTO ERRORHANDLER         
  
SET NOCOUNT OFF  
RETURN  
  
ERRORHANDLER:  
BEGIN  
    RETURN  -1  
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
* ���ν�����  : dbo.up_DBA_DeleteSMSSendMaster 
* �ۼ�����    : 2007-07-06 by ceusee (choi bo ra)
* ����������  :  
* ����        : ���� ó�� ���۵� �ð��� ���� �۾� �����Ѵ�.
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_DeleteSMSSendMaster
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
/* USER DECLARE */
DECLARE @dtGetDate      DATETIME
DECLARE @hour           INT
DECLARE @strGetDate     NVARCHAR(10)
SET @dtGetDate = GETDATE()
SET @hour = DATEPART( hh, @dtGetdate)
SET @strGetDate = CONVERT(NVARCHAR(10),getdate(),120)

/* BODY */
-- Step 1
-- �۾��� �����ϴ� ���� 0 ~ 1�� ���̿� ���� �۾�, 2Ʋ ������ ������ ����
IF @hour >= 0 AND @hour < 1         
BEGIN
    DELETE SMSSendMaster WHERE sendFlag = 2 AND changeDate < DATEADD(DD,-2, CONVERT(datetime, @strGetDate , 120))
    IF @@ERROR <> 0 GOTO ERRORHANDLER
END

SET NOCOUNT OFF
RETURN

ERRORHANDLER:
BEGIN
    RETURN 
END

GO
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* ���ν�����  : dbo.up_update_operatorsimple 
* �ۼ�����    : 2008-06-30
* ����������  :  
* ����        : Ÿ���� �Ǵ� Operatorsiple ���̺� ���泻�� ����
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_update_operatorsimple
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
UPDATE dbo.OperatorSimple
SET HPNo = T.HPNO,
    Email = T.EMAIL,
    jobflag = T.JOBFLAG,
    dbFlag = T.DBFLAG,
    logicFlag = T.logicFlag,
    temCode = T.temCode,
    backupFlag = T.backupFlag,
    hwFlag = T.hwFlag,
    changedate= ISNULL(T.chg_dt,GETDATE())
FROM dbo.DBA_OPERATOR_TEMP AS T JOIN dbo.OperatorSimple AS O WITH (NOLOCK)
    ON T.Oid = O.operatorNo 

RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO


/*************************************************************************  
* ���ν�����  : dbo.up_DBA_GrantRevokeMonitoring 
* �ۼ�����    : 2007-07-13 by choi bo ra (ceusee)
* ����������  :  
* ����        : ����/���� ����͸��� �ϱ����� ���� ����
                jobFlag : 1
                dbFlag : 2
                backupFlag : 3
                logicFlag : 4
                HWFlag : 5
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_GrantRevokeMonitoring
    @operatorNo         INT = 0,
    @workFlag           TINYINT = 1, 
    @grantFlag          TINYINT = 1
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
IF @workFlag = 1 -- Job
BEGIN
    
    UPDATE OperatorSimple
    SET jobFlag = @grantFlag
    WHERE operatorNo = @operatorNo
    
    IF @@ERROR <> 0 RETURN

END
ELSE IF @workFlag = 2 --DB
BEGIN
    
    UPDATE OperatorSimple
    SET dbFlag = @grantFlag
    WHERE operatorNo = @operatorNo
    
    IF @@ERROR <> 0 RETURN

END
ELSE IF @workFlag = 3 --DB
BEGIN
    
    UPDATE OperatorSimple
    SET backupFlag = @grantFlag
    WHERE operatorNo = @operatorNo
    
     IF @@ERROR <> 0 RETURN

END
ELSE IF @workFlag = 4 --logicFlag
BEGIN
    
    UPDATE OperatorSimple
    SET logicFlag = @grantFlag
    WHERE operatorNo = @operatorNo
    
     IF @@ERROR <> 0 RETURN

END
ELSE IF @workFlag = 5 --HWFlag
BEGIN
    
    UPDATE OperatorSimple
    SET HWFlag = @grantFlag
    WHERE operatorNo = @operatorNo
    
     IF @@ERROR <> 0 RETURN

END
SET NOCOUNT OFF
RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

