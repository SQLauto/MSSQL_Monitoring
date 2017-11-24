use msdb
go


CREATE FUNCTION [dbo].[udf_schedule_description]
(
	@freq_type INT , 
  @freq_interval INT , 
  @freq_subday_type INT , 
  @freq_subday_interval INT , 
  @freq_relative_interval INT , 
  @freq_recurrence_factor INT , 
  @active_start_date INT , 
  @active_end_date INT, 
  @active_start_time INT , 
  @active_end_time INT ) 
RETURNS NVARCHAR(255) AS 
BEGIN 
DECLARE @schedule_description NVARCHAR(255) 
DECLARE @loop INT 
DECLARE @idle_cpu_percent INT 
DECLARE @idle_cpu_duration INT 

IF (@freq_type = 0x1) -- OneTime 
BEGIN 
SELECT @schedule_description = N'Once on ' + CONVERT(NVARCHAR, @active_start_date) + N' at ' + CONVERT(NVARCHAR, cast((@active_start_time / 10000) as varchar(10)) + ':' + right('00' + cast((@active_start_time % 10000) / 100 as varchar(10)),2)) 
RETURN @schedule_description 
END 
IF (@freq_type = 0x4) -- Daily 
BEGIN 
SELECT @schedule_description = N'Every day ' 
END 
IF (@freq_type = 0x8) -- Weekly 
BEGIN 
SELECT @schedule_description = N'Every ' + CONVERT(NVARCHAR, @freq_recurrence_factor) + N' week(s) on ' 
SELECT @loop = 1 
WHILE (@loop <= 7) 
BEGIN 
IF (@freq_interval & POWER(2, @loop - 1) = POWER(2, @loop - 1)) 
SELECT @schedule_description = @schedule_description + DATENAME(dw, N'1996120' + CONVERT(NVARCHAR, @loop)) + N', '
SELECT @loop = @loop + 1 
END 
IF (RIGHT(@schedule_description, 2) = N', ') 
SELECT @schedule_description = SUBSTRING(@schedule_description, 1, (DATALENGTH(@schedule_description) / 2) - 2) + N' ' 
END 
IF (@freq_type = 0x10) -- Monthly 
BEGIN 
SELECT @schedule_description = N'Every ' + CONVERT(NVARCHAR, @freq_recurrence_factor) + N' months(s) on day ' + CONVERT(NVARCHAR, @freq_interval) + N' of that month ' 
END 
IF (@freq_type = 0x20) -- Monthly Relative 
BEGIN 
SELECT @schedule_description = N'Every ' + CONVERT(NVARCHAR, @freq_recurrence_factor) + N' months(s) on the ' 
SELECT @schedule_description = @schedule_description + 
CASE @freq_relative_interval 
WHEN 0x01 THEN N'first ' 
WHEN 0x02 THEN N'second ' 
WHEN 0x04 THEN N'third ' 
WHEN 0x08 THEN N'fourth ' 
WHEN 0x10 THEN N'last ' 
END + 
CASE 
WHEN (@freq_interval > 00) 
AND (@freq_interval < 08) THEN DATENAME(dw, N'1996120' + CONVERT(NVARCHAR, @freq_interval)) 
WHEN (@freq_interval = 08) THEN N'day' 
WHEN (@freq_interval = 09) THEN N'week day' 
WHEN (@freq_interval = 10) THEN N'weekend day' 
END + N' of that month ' 
END 
IF (@freq_type = 0x40) -- AutoStart 
BEGIN 
SELECT @schedule_description = FORMATMESSAGE(14579) 
RETURN @schedule_description 
END 
IF (@freq_type = 0x80) -- OnIdle 
BEGIN 
EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 
N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', 
N'IdleCPUPercent', 
@idle_cpu_percent OUTPUT, 
N'no_output' 
EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 
N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', 
N'IdleCPUDuration', 
@idle_cpu_duration OUTPUT, 
N'no_output' 
SELECT @schedule_description = FORMATMESSAGE(14578, ISNULL(@idle_cpu_percent, 10), ISNULL(@idle_cpu_duration, 600)) 
RETURN @schedule_description 
END 
-- Subday stuff 
SELECT @schedule_description = @schedule_description + 
CASE @freq_subday_type 
WHEN 0x1 THEN N'at ' + CONVERT(NVARCHAR, cast((@active_start_time / 10000) as varchar(10)) + ':' + right('00' + cast((@active_start_time % 10000) / 100 as varchar(10)),2)) 
WHEN 0x2 THEN N'every ' + CONVERT(NVARCHAR, @freq_subday_interval) + N' second(s)' 
WHEN 0x4 THEN N'every ' + CONVERT(NVARCHAR, @freq_subday_interval) + N' minute(s)' 
WHEN 0x8 THEN N'every ' + CONVERT(NVARCHAR, @freq_subday_interval) + N' hour(s)' 
END 
IF (@freq_subday_type IN (0x2, 0x4, 0x8)) 
SELECT @schedule_description = @schedule_description + N' between ' + 
CONVERT(NVARCHAR, cast((@active_start_time / 10000) as varchar(10)) + ':' + right('00' + cast((@active_start_time % 10000) / 100 as varchar(10)),2) ) + N' and ' + CONVERT(NVARCHAR, cast((@active_end_time / 10000) as varchar(10)) + ':' + right('00' + cast(
(@active_end_time % 10000) / 100 as varchar(10)),2) ) 

RETURN @schedule_description 
END
go


CREATE PROCEDURE [dbo].[up_dba_job_info_simple]      
  @job_id             UNIQUEIDENTIFIER = NULL,        
  @job_type           VARCHAR(12)      = NULL,  -- LOCAL or MULTI-SERVER        
  @owner_login_name   sysname          = NULL,        
  @subsystem          NVARCHAR(40)     = NULL,        
  @category_id        INT              = NULL,        
  @enabled            TINYINT          = NULL,        
  @execution_status   INT              = NULL,  -- 0 = Not idle or suspended, 1 = Executing, 2 = Waiting For Thread, 3 = Between Retries, 4 = Idle, 5 = Suspended, [6 = WaitingForStepToFinish], 7 = PerformingCompletionActions        
  @date_comparator    CHAR(1)          = NULL,  -- >, < or =        
  @date_created       DATETIME         = NULL,        
  @date_last_modified DATETIME         = NULL,        
  @description        NVARCHAR(512)    = NULL,  -- We do a LIKE on this so it can include wildcards        
  @schedule_id        INT              = NULL   -- if supplied only return the jobs that use this schedule        
AS        
BEGIN        
  DECLARE @can_see_all_running_jobs INT        
  DECLARE @job_owner   sysname        
        
  SET NOCOUNT ON        
        
  -- By 'composite' we mean a combination of sysjobs and xp_sqlagent_enum_jobs data.        
  -- This proc should only ever be called by sp_help_job, so we don't verify the        
  -- parameters (sp_help_job has already done this).        
        
  -- Step 1: Create intermediate work tables        
  DECLARE @job_execution_state TABLE (job_id                  UNIQUEIDENTIFIER NOT NULL,        
                                     date_started            INT              NOT NULL,        
                                     time_started            INT              NOT NULL,        
                                     execution_job_status    INT              NOT NULL,        
                                     execution_step_id       INT              NULL,        
                                     execution_step_name     sysname          COLLATE database_default NULL,        
                                     execution_retry_attempt INT              NOT NULL,        
                                     next_run_date           INT              NOT NULL,        
                                     next_run_time           INT              NOT NULL,        
                                     next_run_schedule_id    INT              NOT NULL)        
                                           
  DECLARE @filtered_jobs TABLE (job_id                   UNIQUEIDENTIFIER NOT NULL,        
                               date_created             DATETIME         NOT NULL,        
                               date_last_modified       DATETIME         NOT NULL,        
                               current_execution_status INT              NULL,        
                               current_execution_step   sysname          COLLATE database_default NULL,        
                               current_retry_attempt    INT              NULL,        
                               last_run_date            INT              NOT NULL,        
                               last_run_time            INT              NOT NULL,        
                               last_run_outcome         INT              NOT NULL,        
                               next_run_date            INT              NULL,        
                               next_run_time            INT              NULL,        
                               next_run_schedule_id     INT              NULL,        
                               type                     INT              NOT NULL)        
  CREATE TABLE #xp_results (job_id                UNIQUEIDENTIFIER NOT NULL,        
                            last_run_date         INT              NOT NULL,        
                            last_run_time         INT     NOT NULL,        
                            next_run_date         INT              NOT NULL,        
                    next_run_time         INT              NOT NULL,        
                            next_run_schedule_id  INT              NOT NULL,        
                            requested_to_run INT              NOT NULL, -- BOOL        
                            request_source        INT              NOT NULL,        
                            request_source_id     sysname          COLLATE database_default NULL,        
                            running               INT              NOT NULL, -- BOOL        
                            current_step          INT              NOT NULL,        
                            current_retry_attempt INT              NOT NULL,        
                            job_state             INT              NOT NULL)        
        
  -- Step 2: Capture job execution information (for local jobs only since that's all SQLServerAgent caches)        
  SELECT @can_see_all_running_jobs = ISNULL(IS_SRVROLEMEMBER(N'sysadmin'), 0)        
  IF (@can_see_all_running_jobs = 0)        
  BEGIN        
    SELECT @can_see_all_running_jobs = ISNULL(IS_MEMBER(N'SQLAgentReaderRole'), 0)        
  END        
  SELECT @job_owner = SUSER_SNAME()        
        
  IF ((@@microsoftversion / 0x01000000) >= 8) -- SQL Server 8.0 or greater        
    INSERT INTO #xp_results        
    EXECUTE master.dbo.xp_sqlagent_enum_jobs @can_see_all_running_jobs, @job_owner, @job_id        
  ELSE        
    INSERT INTO #xp_results        
    EXECUTE master.dbo.xp_sqlagent_enum_jobs @can_see_all_running_jobs, @job_owner        
        
  INSERT INTO @job_execution_state        
  SELECT xpr.job_id,        
         xpr.last_run_date,        
         xpr.last_run_time,        
         xpr.job_state,        
         sjs.step_id,        
         sjs.step_name,        
         xpr.current_retry_attempt,        
         xpr.next_run_date,        
         xpr.next_run_time,        
         xpr.next_run_schedule_id        
  FROM #xp_results                          xpr        
       LEFT OUTER JOIN msdb.dbo.sysjobsteps sjs ON ((xpr.job_id = sjs.job_id) AND (xpr.current_step = sjs.step_id)),        
       msdb.dbo.sysjobs_view                sjv        
  WHERE (sjv.job_id = xpr.job_id)        
        
  -- Step 3: Filter on everything but dates and job_type        
  IF ((@subsystem        IS NULL) AND        
      (@owner_login_name IS NULL) AND        
      (@enabled          IS NULL) AND        
      (@category_id      IS NULL) AND        
      (@execution_status IS NULL) AND        
      (@description      IS NULL) AND        
      (@job_id           IS NULL))        
  BEGIN        
    -- Optimize for the frequently used case...        
    INSERT INTO @filtered_jobs        
    SELECT sjv.job_id,        
           sjv.date_created,        
           sjv.date_modified,        
           ISNULL(jes.execution_job_status, 4), -- Will be NULL if the job is non-local or is not in @job_execution_state (NOTE: 4 = STATE_IDLE)        
           CASE ISNULL(jes.execution_step_id, 0)        
             WHEN 0 THEN NULL                   -- Will be NULL if the job is non-local or is not in @job_execution_state        
             ELSE CONVERT(NVARCHAR, jes.execution_step_id) + N' (' + jes.execution_step_name + N')'        
           END,        
           jes.execution_retry_attempt,         -- Will be NULL if the job is non-local or is not in @job_execution_state        
           0,  -- last_run_date placeholder    (we'll fix it up in step 3.3)        
           0,  -- last_run_time placeholder    (we'll fix it up in step 3.3)        
           5,  -- last_run_outcome placeholder (we'll fix it up in step 3.3 - NOTE: We use 5 just in case there are no jobservers for the job)        
           jes.next_run_date,                   -- Will be NULL if the job is non-local or is not in @job_execution_state        
           jes.next_run_time,                   -- Will be NULL if the job is non-local or is not in @job_execution_state        
  jes.next_run_schedule_id,            -- Will be NULL if the job is non-local or is not in @job_execution_state        
           0   -- type placeholder             (we'll fix it up in step 3.4)        
    FROM msdb.dbo.sysjobs_view         sjv        
         LEFT OUTER JOIN @job_execution_state jes ON (sjv.job_id = jes.job_id)        
    WHERE ((@schedule_id IS NULL)        
      OR   (EXISTS(SELECT *         
                 FROM msdb.dbo.sysjobschedules as js        
   WHERE (sjv.job_id = js.job_id)        
                   AND (js.schedule_id = @schedule_id))))        
  END        
  ELSE        
  BEGIN        
    INSERT INTO @filtered_jobs        
    SELECT DISTINCT        
           sjv.job_id,        
           sjv.date_created,        
           sjv.date_modified,        
           ISNULL(jes.execution_job_status, 4), -- Will be NULL if the job is non-local or is not in @job_execution_state (NOTE: 4 = STATE_IDLE)        
           CASE ISNULL(jes.execution_step_id, 0)        
             WHEN 0 THEN NULL                   -- Will be NULL if the job is non-local or is not in @job_execution_state        
             ELSE CONVERT(NVARCHAR, jes.execution_step_id) + N' (' + jes.execution_step_name + N')'        
           END,        
           jes.execution_retry_attempt,         -- Will be NULL if the job is non-local or is not in @job_execution_state        
           0,  -- last_run_date placeholder    (we'll fix it up in step 3.3)        
           0,  -- last_run_time placeholder    (we'll fix it up in step 3.3)        
           5,  -- last_run_outcome placeholder (we'll fix it up in step 3.3 - NOTE: We use 5 just in case there are no jobservers for the job)        
           jes.next_run_date,                   -- Will be NULL if the job is non-local or is not in @job_execution_state        
           jes.next_run_time,                   -- Will be NULL if the job is non-local or is not in @job_execution_state        
           jes.next_run_schedule_id,            -- Will be NULL if the job is non-local or is not in @job_execution_state        
           0   -- type placeholder             (we'll fix it up in step 3.4)        
    FROM msdb.dbo.sysjobs_view                sjv        
         LEFT OUTER JOIN @job_execution_state jes ON (sjv.job_id = jes.job_id)        
         LEFT OUTER JOIN msdb.dbo.sysjobsteps sjs ON (sjv.job_id = sjs.job_id)        
    WHERE ((@subsystem        IS NULL) OR (sjs.subsystem            = @subsystem))        
      AND ((@owner_login_name IS NULL)         
          OR (sjv.owner_sid            = msdb.dbo.SQLAGENT_SUSER_SID(@owner_login_name)))--force case insensitive comparation for NT users        
      AND ((@enabled          IS NULL) OR (sjv.enabled              = @enabled))        
      AND ((@category_id      IS NULL) OR (sjv.category_id          = @category_id))        
      AND ((@execution_status IS NULL) OR ((@execution_status > 0) AND (jes.execution_job_status = @execution_status))        
                                       OR ((@execution_status = 0) AND (jes.execution_job_status <> 4) AND (jes.execution_job_status <> 5)))        
      AND ((@description      IS NULL) OR (sjv.description       LIKE @description))        
      AND ((@job_id           IS NULL) OR (sjv.job_id               = @job_id))        
      AND ((@schedule_id IS NULL)        
        OR (EXISTS(SELECT *         
                 FROM msdb.dbo.sysjobschedules as js        
                 WHERE (sjv.job_id = js.job_id)        
                   AND (js.schedule_id = @schedule_id))))        
  END        
        
  -- Step 3.1: Change the execution status of non-local jobs from 'Idle' to 'Unknown'        
  UPDATE @filtered_jobs        
  SET current_execution_status = NULL        
  WHERE (current_execution_status = 4)        
    AND (job_id IN (SELECT job_id        
                    FROM msdb.dbo.sysjobservers        
                    WHERE (server_id <> 0)))        
        
  -- Step 3.2: Check that if the user asked to see idle jobs that we still have some.        
  --           If we don't have any then the query should return no rows.        
  IF (@execution_status = 4) AND        
     (NOT EXISTS (SELECT *        
                  FROM @filtered_jobs        
                  WHERE (current_execution_status = 4)))        
  BEGIN        
    DELETE FROM @filtered_jobs        
  END        
        
  -- Step 3.3: Populate the last run date/time/outcome [this is a little tricky since for        
  --           multi-server jobs there are multiple last run details in sysjobservers, so        
  --           we simply choose the most recent].        
  IF (EXISTS (SELECT *        
              FROM msdb.dbo.systargetservers))        
  BEGIN        
  UPDATE @filtered_jobs        
    SET last_run_date = sjs.last_run_date,        
        last_run_time = sjs.last_run_time,        
        last_run_outcome = sjs.last_run_outcome        
    FROM @filtered_jobs         fj,        
         msdb.dbo.sysjobservers sjs        
    WHERE (CONVERT(FLOAT, sjs.last_run_date) * 1000000) + sjs.last_run_time =        
           (SELECT MAX((CONVERT(FLOAT, last_run_date) * 1000000) + last_run_time)        
            FROM msdb.dbo.sysjobservers        
            WHERE (job_id = sjs.job_id))        
      AND (fj.job_id = sjs.job_id)        
  END        
  ELSE        
  BEGIN        
    UPDATE @filtered_jobs        
    SET last_run_date = sjs.last_run_date,        
        last_run_time = sjs.last_run_time,        
        last_run_outcome = sjs.last_run_outcome        
    FROM @filtered_jobs         fj,        
         msdb.dbo.sysjobservers sjs        
    WHERE (fj.job_id = sjs.job_id)        
  END        
        
  -- Step 3.4 : Set the type of the job to local (1) or multi-server (2)        
  --            NOTE: If the job has no jobservers then it wil have a type of 0 meaning        
  --                  unknown.  This is marginally inconsistent with the behaviour of        
  --                  defaulting the category of a new job to [Uncategorized (Local)], but        
  --                  prevents incompletely defined jobs from erroneously showing up as valid        
  --                  local jobs.        
  UPDATE @filtered_jobs        
  SET type = 1 -- LOCAL        
  FROM @filtered_jobs         fj,        
       msdb.dbo.sysjobservers sjs        
  WHERE (fj.job_id = sjs.job_id)        
    AND (server_id = 0)        
  UPDATE @filtered_jobs        
  SET type = 2 -- MULTI-SERVER        
  FROM @filtered_jobs         fj,        
       msdb.dbo.sysjobservers sjs        
  WHERE (fj.job_id = sjs.job_id)        
    AND (server_id <> 0)        
        
  -- Step 4: Filter on job_type        
  IF (@job_type IS NOT NULL)        
  BEGIN        
    IF (UPPER(@job_type collate SQL_Latin1_General_CP1_CS_AS) = 'LOCAL')        
      DELETE FROM @filtered_jobs        
      WHERE (type <> 1) -- IE. Delete all the non-local jobs        
    IF (UPPER(@job_type collate SQL_Latin1_General_CP1_CS_AS) = 'MULTI-SERVER')        
      DELETE FROM @filtered_jobs        
      WHERE (type <> 2) -- IE. Delete all the non-multi-server jobs        
  END        
        
  -- Step 5: Filter on dates        
  IF (@date_comparator IS NOT NULL)        
  BEGIN        
    IF (@date_created IS NOT NULL)        
    BEGIN        
      IF (@date_comparator = '=')        
        DELETE FROM @filtered_jobs WHERE (date_created <> @date_created)        
      IF (@date_comparator = '>')        
        DELETE FROM @filtered_jobs WHERE (date_created <= @date_created)        
      IF (@date_comparator = '<')        
        DELETE FROM @filtered_jobs WHERE (date_created >= @date_created)        
    END        
    IF (@date_last_modified IS NOT NULL)        
    BEGIN        
      IF (@date_comparator = '=')        
        DELETE FROM @filtered_jobs WHERE (date_last_modified <> @date_last_modified)        
      IF (@date_comparator = '>')        
        DELETE FROM @filtered_jobs WHERE (date_last_modified <= @date_last_modified)        
      IF (@date_comparator = '<')        
        DELETE FROM @filtered_jobs WHERE (date_last_modified >= @date_last_modified)        
    END        
  END        
        
  -- Return the result set (NOTE: No filtering occurs here)        
  INSERT INTO dba.dbo.job_running_status(job_id, job_name, running_status)    
  SELECT sjv.job_id,                  
         sjv.name,        
   @execution_status as running_status      
  FROM @filtered_jobs                         fj        
       LEFT OUTER JOIN msdb.dbo.sysjobs_view  sjv ON (fj.job_id = sjv.job_id)        
       LEFT OUTER JOIN msdb.dbo.sysoperators  so1 ON (sjv.notify_email_operator_id = so1.id)        
       LEFT OUTER JOIN msdb.dbo.sysoperators  so2 ON (sjv.notify_netsend_operator_id = so2.id)        
       LEFT OUTER JOIN msdb.dbo.sysoperators  so3 ON (sjv.notify_page_operator_id = so3.id)        
       LEFT OUTER JOIN msdb.dbo.syscategories sc  ON (sjv.category_id = sc.category_id)        
  ORDER BY sjv.job_id        
        
END 
go