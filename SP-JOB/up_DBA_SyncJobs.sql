SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_SyncJobs' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_SyncJobs
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
            stat = CASE stat WHEN 'S4' THEN 'S2' ELSE stat END,
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