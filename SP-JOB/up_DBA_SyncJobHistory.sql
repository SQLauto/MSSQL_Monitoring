SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_SyncJobHistory' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_SyncJobHistory
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