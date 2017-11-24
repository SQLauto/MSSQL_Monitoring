
          
  use master
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLLitespeedmaint]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[sp_SQLLitespeedmaint]
GO

CREATE PROCEDURE sp_SQLLitespeedmaint
(
   @database      sysname,                   -- database name
   @backuptype    varchar(4),                -- LOG | DB | DIFF
   @backupfldr    varchar(200),              -- folder to write backup
   @reportfldr    varchar(200) = NULL,       -- folder to write text report 
   @verify        bit = 1,                   -- verify backup
   @dbretainunit  varchar(10),               -- minutes | hours | days | weeks | months | copies
   @dbretainval   int = 1,                   -- specifies how many retainunits to keep backup
   @rptretainunit varchar(10) = NULL,        -- minutes | hours | days | weeks | months | copies
   @rptretainval  int = 1,                   -- specifies how many retainunits to keep reports
   @jobid         uniqueidentifier = NULL,   -- used to determine job name for report
   @failonlog     bit = 0,                   -- fail if cannot write text report
   @delfirst      bit = 0,                   -- delete before backup (handy if space issues)
   @checkattrib   bit = 1,                   -- check if archive bit is cleared before deleting
   @EncryptionKey varchar(1024) = NULL,      -- key used to encrypt backups
   @Threads       int = NULL,                -- number of threads to use for SQLLiteSpeed
   @Priority      int = 0,                   -- base priority of SQLLiteSpeed process ( 0 | 1 | 2 )
   @affinity      int = 0,                   -- cpu affinity for SQLLitespeed (bitmask)
   @logging       int = 1,                   -- SQLLitespeed logging level ( 0 | 1 | 2 )
   @debug         bit = 0,                   -- print commands to be executed
   @override      bit = 0,                   -- override safety warning for dangerous parameters
   @usexp         bit = 0,                   -- flag to indicate whether to use xp's or cmdline
   @report        bit = 0                    -- flag to indicate whether to generate report
)
AS
/* 
   sp_SQLLitespeedmaint
   
   This procedure mimics the backup capabilities of xp_sqlmaint but uses 
   SQL Litespeed to perform the database and log backups. This version 
   requires the latest version of SQL Litespeed supporting the new affinity
   parameter from http://www.sqllitespeed.com/slsdefault.asp. Thus you get
   all the benefits of SQL Litespeed including faster,smaller more secure
   backups plus the benefits of xp_sqlmaint, standard backup naming,reporting
   and old backup housekeeping. This procedure is designed to run on SQL2000.
   This procedure requires the target directories to exist, it does not create
   them for you. This is because we use another script to generate all our
   maintenance jobs and that does all that sort of work for us. It would however
   be trivial to add this functionality if it is required.
      
   **Additional Information**

   This procedure will not run on servers in fiber mode (lightweight pooling)
   This is because it use sp_OA extended procedures in order to write it's
   maintenance report. If you can live without that feature then you can remove
   the code that writes the report.

   The default for the @checkattrib parameter is 1 which means that the procedure
   checks the archive bit on a backup before trying to delete it. This means it
   will not delete a backup unless the archive flag is cleared. This is intended
   behaviour and acts as a safeguard.

   This procedure will return an error if it fails to delete an old backup or report
   This is by design and in keeping with the behaviour of xp_sqlmaint

   The report includes timings of backup operations that assumes less than 24 hours.

   Since this procedure is usually scheduled as a job I tend to use the [JOBID] TSQL
   job step token to supply the @jobid parameter. For more on SQL Agent tokens see BOL

   ** Changes 19/11/2003 **
   @report will supress creation of the report file to help minimise memory issues with sp_OA*
   @usexp will allow use of the litespeed executable instead of the extended procedures
   Changed folder existence test to use xp_fileexist when not generating report (no FSO)
   Made jobid nullable to allow easier testing and no report scenario
   Made @reportfldr and @rptretainunit nullable for when @report = 0
   
   
   Date           Author                  Notes
   16/05/2003     Jasper Smith            Initial release
   19/11/2003     Jasper Smith            Added @usexp and @report flags (see above)
   10/12/2003     Jasper Smith            Fix for cmdline and spaces in database names
   19/01/2004     Jasper Smith            Clean up cmdline job history output for version 3.0.123.1
   12/02/2004     Jasper Smith            Added logging for command line as it is now an option in 3.0.123.1
   05/03/2004     Jasper Smith            Added output parsing for verify to trap errors for commandline
   12/03/2004     Jasper Smith            Change to database existence check to cope with autoclose databases
   20/04/2004     Jasper Smith            Changed version check to allow running on SQL2005
   10/05/2004     Jasper Smith            Added output parsing for backup to trap errors for commandline
   25/05/2004     Jasper Smith            Modified to allow backup retention using number of files not date

*/


SET NOCOUNT ON

/************************
   VARIABLE DECLARATION
************************/

   DECLARE @fso             int 
   DECLARE @file            int 
   DECLARE @reportfilename  varchar(400) 
   DECLARE @backupfilename  varchar(400) 
   DECLARE @delfilename     varchar(400)
   DECLARE @cmd             varchar(650)
   DECLARE @exepath         varchar(255)
   DECLARE @jobname         nvarchar(256)
   DECLARE @exists          varchar(5)
   DECLARE @start           datetime
   DECLARE @finish          datetime
   DECLARE @runtime         datetime
   DECLARE @output          varchar(200)
   DECLARE @errormsg        varchar(210)
   DECLARE @datepart        nchar(2)
   DECLARE @execmd          nvarchar(1000)
   DECLARE @delcmd          nvarchar(1000)
   DECLARE @exemsg          varchar(8000)
   DECLARE @filecount       int              ; SET @filecount    = 0
   DECLARE @delcount        int              ; SET @delcount     = 0
   DECLARE @hr              int              ; SET @hr           = 0
   DECLARE @ret             int              ; SET @ret          = 0
   DECLARE @cmdret          int              ; SET @cmdret       = 0
   DECLARE @delbkflag       int              ; SET @delbkflag    = 0
   DECLARE @delrptflag      int              ; SET @delrptflag   = 0
   DECLARE @filecrt         int              ; SET @filecrt      = 0
   DECLARE @user            sysname          ; SET @user         = SUSER_SNAME()
   DECLARE @jobdt           datetime         ; SET @jobdt        = GETDATE()
   DECLARE @jobstart        char(12)         ; 
   DECLARE @stage           int              ; SET @stage        = 1
   DECLARE @litespeedkey    nvarchar(100)    ; 

   SET @jobstart = CONVERT(char(8),@jobdt,112)+LEFT(REPLACE(CONVERT(char(8),@jobdt,108),':',''),4)   
   -- Note this key may change in future versions
   SET @litespeedkey = N'SOFTWARE\DBAssociates\SQLLiteSpeed\Engine'    

   CREATE TABLE #files(filename varchar(255))  
   CREATE TABLE #exists(exist int,isdir int,parent int)
   CREATE TABLE #output(txt varchar(255))

/**********************************
     INITIALIZE FSO IF @report = 1
***********************************/

   IF @report = 1
   BEGIN
      EXEC @hr=sp_OACreate 'Scripting.FileSystemObject',@fso OUT 
      IF @hr <> 0 
      BEGIN   
         EXEC sp_OAGetErrorInfo @fso
         RAISERROR('Error creating File System Object',16,1)
         SET @ret = 1
      	GOTO CLEANUP	
      END
   END

/************************
       CHECK INPUT
************************/

   -- check SQL2000 or higher
   IF (select SUBSTRING(@@version,(CHARINDEX('-',@@version)+2),1))<8
	BEGIN                   				
   	RAISERROR('SQL2000 or higher is required for sp_SQLLitespeedmaint',16,1)
      SET @ret = 1
   	GOTO CLEANUP	
	END
   
   -- check sysadmin
   IF IS_SRVROLEMEMBER('sysadmin') = 0
	BEGIN                   				
   	RAISERROR('The current user %s is not a member of the sysadmin role',16,1,@user)
      SET @ret = 1
   	GOTO CLEANUP	
	END

   -- check SQLLitespeed extended procedures are present
   IF NOT EXISTS(SELECT * FROM master.dbo.sysobjects (nolock)
                 WHERE [name] = 'xp_backup_database' AND xtype='X')
	BEGIN                   				
   	RAISERROR('SQLLitespeed is not installed on this instance',16,1)
      SET @ret = 1
   	GOTO CLEANUP	
	END

   -- check database exists and is online
   IF (DB_ID(@database) IS NULL) OR (DATABASEPROPERTYEX(@database,'Status')<>'ONLINE')
	BEGIN                   				
   	RAISERROR('Database %s is invalid or database status is not ONLINE',16,1,@database)
      SET @ret = 1
   	GOTO CLEANUP		
	END

   -- check @backuptype is valid
   IF UPPER(@backuptype) NOT IN ('LOG','DB','DIFF')
	BEGIN                   				
   	RAISERROR('%s is not a valid option for @backuptype',16,1,@backuptype)
      SET @ret = 1
   	GOTO CLEANUP		
	END

   -- check recovery mode is correct if trying log backup
   IF (DATABASEPROPERTYEX(@database,'Recovery')='SIMPLE' and @backuptype = 'LOG')
	BEGIN                   				
   	RAISERROR('%s is not a valid option for database %s because it is in SIMPLE recovery mode',16,1,@backuptype,@database)
      SET @ret = 1
   	GOTO CLEANUP	
	END

   -- check that @backupfldr exists on the server
   IF @report = 1
   BEGIN
      EXEC sp_OAMethod @fso,'FolderExists',@exists OUT,@backupfldr
      IF @exists <> 'True'
   	BEGIN                   				
      	RAISERROR('The folder %s does not exist on this server',16,1,@backupfldr)
         SET @ret = 1
      	GOTO CLEANUP	
   	END
   END
   ELSE
   BEGIN
      INSERT #exists
      EXEC master.dbo.xp_fileexist @backupfldr
      IF (SELECT MAX(isdir) FROM #exists)<>1
   	BEGIN                   				
      	RAISERROR('The folder %s does not exist on this server',16,1,@backupfldr)
         SET @ret = 1
      	GOTO CLEANUP	
   	END
   END

   -- check @backupfldr has no spaces
   IF CHARINDEX(CHAR(32),@backupfldr)>0
   BEGIN
      	RAISERROR('The backup folder path "%s" cannot contain spaces',16,1,@backupfldr)
         SET @ret = 1
      	GOTO CLEANUP	
   END

   -- check that @reportfldr exists on the server
   IF @reportfldr IS NOT NULL or @report = 1
   BEGIN
      IF @report = 1
      BEGIN
         EXEC sp_OAMethod @fso,'FolderExists',@exists OUT,@reportfldr
         IF @exists <> 'True'
      	BEGIN                   				
         	RAISERROR('The folder %s does not exist on this server',16,1,@reportfldr)
            SET @ret = 1
         	GOTO CLEANUP	
      	END
      END
      ELSE
      BEGIN
         DELETE #exists
         INSERT #exists
         EXEC master.dbo.xp_fileexist @reportfldr
         IF (SELECT MAX(isdir) FROM #exists)<>1
      	BEGIN                   				
         	RAISERROR('The folder %s does not exist on this server',16,1,@reportfldr)
            SET @ret = 1
         	GOTO CLEANUP	
      	END
      END
   END

   -- check @reportfldr has no spaces
   IF CHARINDEX(CHAR(32),@reportfldr)>0
   BEGIN
      	RAISERROR('The report folder path "%s" cannot contain spaces',16,1,@reportfldr)
         SET @ret = 1
      	GOTO CLEANUP	
   END

   -- check @dbretainunit is a vaild value
   IF UPPER(@dbretainunit) NOT IN ('MINUTES','HOURS','DAYS','WEEKS','MONTHS','COPIES')
 	BEGIN                   				
   	RAISERROR('%s is not a valid value for @dbretainunit (''minutes | hours | days | weeks | months | copies'')',16,1,@dbretainunit)
      SET @ret = 1
   	GOTO CLEANUP	
	END

   --check @dbretainval is a vaild value
   IF @dbretainval<1
 	BEGIN                   				
   	RAISERROR('%i is not a valid value for @dbretainval (must be >0)',16,1,@dbretainval)
      SET @ret = 1
   	GOTO CLEANUP	
	END

   -- check @rptretainunit is a vaild value if present
   IF UPPER(@rptretainunit) NOT IN ('MINUTES','HOURS','DAYS','WEEKS','MONTHS','COPIES') and @rptretainunit IS NOT NULL
 	BEGIN                   				
   	RAISERROR('%s is not a valid value for @rptretainunit (''minutes | hours | days | weeks | months | copies'')',16,1,@rptretainunit)
      SET @ret = 1
   	GOTO CLEANUP	
	END

   --check @rptretainval is a vaild value
   IF @rptretainval<1
 	BEGIN                   				
   	RAISERROR('%i is not a valid value for @rptretainval (must be >0)',16,1,@rptretainval)
      SET @ret = 1
   	GOTO CLEANUP	
	END

   -- check dangerous parameter combination if @override <> 1
   IF (@dbretainval = 1 AND @checkattrib = 0 AND @delfirst = 1 and @override <> 1)
 	BEGIN         
      SET @errormsg = 'You have chosen to retain only 1 backup , not to check ' + CHAR(13) 
                    + 'if it''s on tape and delete old backups first. This is ' + CHAR(13)  
                    + 'a dangerous combination of parameters that requires the' + CHAR(13)  
                    + '@override parameter to be set to 1'      				
   	RAISERROR(@errormsg,16,1)
      SET @ret = 1
   	GOTO CLEANUP		
	END

/*****************************
   GET EXE PATH IF @usexp = 0
******************************/

   IF @usexp = 0
   BEGIN
      EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE',@litespeedkey,N'ExePath',@value=@exepath OUTPUT
      IF @@ERROR<>0 or (NULLIF(@exepath,'') IS NULL)
      BEGIN
         RAISERROR('Error reading path to litespeed executable from registry',16,1)
         SET @ret = 1
      	GOTO CLEANUP	         
      END
      ELSE
         SET @exepath = '""' + @exepath + '"'
   END

/***********************************
   INITIALIZE REPORT IF @report = 1
************************************/

   -- generate filenames
   IF RIGHT(@reportfldr,1)<>'\' SET @reportfldr = @reportfldr + '\'
   IF RIGHT(@backupfldr,1)<>'\' SET @backupfldr = @backupfldr + '\'

   SELECT @reportfilename = @reportfldr + REPLACE(@database,' ','_') +
   CASE WHEN UPPER(@backuptype) = 'DB'   THEN '_FullDBBackupSLS_report_'
        WHEN UPPER(@backuptype) = 'DIFF' THEN '_DiffDBBackupSLS_report_'
        WHEN UPPER(@backuptype) = 'LOG'  THEN '_LogBackupSLS_report_'         
   END + @jobstart + '.txt'

   SELECT @backupfilename = @backupfldr + REPLACE(@database,' ','_') +
   CASE WHEN UPPER(@backuptype) = 'DB'   THEN '_FullDBBackupSLS_'
        WHEN UPPER(@backuptype) = 'DIFF' THEN '_DiffDBBackupSLS_'
        WHEN UPPER(@backuptype) = 'LOG'  THEN '_LogBackupSLS_'         
   END + @jobstart + 
   CASE WHEN UPPER(@backuptype) = 'LOG' THEN '.TRN' ELSE '.BAK' END

   -- if no report just set @reportfilename to NULL
   IF @report = 0 SET @reportfilename = NULL

   IF @debug = 1
   BEGIN
      PRINT '@reportfilename = ' + ISNULL(@reportfilename,'NULL')
      PRINT '@backupfilename = ' + ISNULL(@backupfilename,'NULL')
   END

   IF @report = 1
   BEGIN
      -- create report file
      EXEC @hr=sp_OAMethod @fso, 'CreateTextFile',@file OUT, @reportfilename
      IF (@hr <> 0)
      BEGIN
         EXEC sp_OAGetErrorInfo @fso 
         RAISERROR('Error creating log file',16,1)
         SET @ret = 1
      	GOTO CLEANUP	
      END
      ELSE
         -- set global flag to indicate we have created a report file
         SET @filecrt = 1
   
      -- write header
      EXEC sp_OAMethod @file,'WriteLine',NULL,''
      SET @output = 'SQLLitespeed backup, Logged on to SQL Server [' + @@SERVERNAME + '] as ' + '[' + @user + ']'
      IF @debug = 1 PRINT @output
      EXEC sp_OAMethod @file,'WriteLine',NULL,@output
      SET @output = 'MODE : Using ' + CASE WHEN @usexp = 0 then REPLACE(@exepath,'""','"') else 'Extended Stored Procedures' end
      IF @debug = 1 PRINT @output
      EXEC sp_OAMethod @file,'WriteLine',NULL,@output   
      IF @jobid IS NOT NULL
      SELECT @jobname = [name] from msdb.dbo.sysjobs with(nolock) where job_id=@jobid
      SET @output = 'Starting job ''' + ISNULL(@jobname,'NOT SPECIFIED') + ''' on ' + convert(varchar(25),getdate(),100)
      IF @debug = 1 PRINT @output
      EXEC sp_OAMethod @file,'WriteLine',NULL,@output
      EXEC sp_OAMethod @file,'WriteLine',NULL,''
   END
   
   --aaa

/************************
     BACKUP ACTIONS
************************/

   -- if @delfirst = 1  we need to delete prior backups that qualify
   IF @delfirst = 1 GOTO DELFIRST
   -- this label is so that we can return here after deleting files if @delfirst = 1
   DOBACKUP:

   -- set backup start time
   SET @start = GETDATE()

   -- write to text report
   IF @report = 1
   BEGIN
      SET @output = '[' + CAST(@stage as char(1)) + '] Database ' + @database + ': ' +
                    CASE WHEN UPPER(@backuptype) = 'DB'   THEN 'Full Backup '
                         WHEN UPPER(@backuptype) = 'DIFF' THEN 'Differential Backup '
                         WHEN UPPER(@backuptype) = 'LOG'  THEN 'Log Backup '         
                    END + 'starting at ' + CONVERT(varchar(25),@start,100)
      IF @debug = 1 PRINT @output
      EXEC sp_OAMethod @file,'WriteLine',NULL,@output
   END
      
   /************************
          FULL BACKUP
   ************************/

   IF UPPER(@backuptype) = 'DB'
   BEGIN
      IF @usexp = 1   -- use extended stored procedures
      BEGIN
         -- standard full backup
         IF (@EncryptionKey IS NULL AND @Threads IS NULL)
         BEGIN
   
            EXEC @ret = master.dbo.xp_backup_database @database = @database ,
                                                      @filename = @backupfilename,
                                                      @Priority = @Priority,
                                                      @affinity = @affinity,
                                                      @logging  = @logging
         END
         -- full backup with @Threads specified only
         IF (@EncryptionKey IS NULL AND @Threads IS NOT NULL)
         BEGIN
   
            EXEC @ret = master.dbo.xp_backup_database @database = @database ,
                                                      @filename = @backupfilename,
                                                      @Priority = @Priority,
                                                      @threads  = @Threads,
                                                      @affinity = @affinity,
                                                      @logging  = @logging
         END
         -- full backup with @Encryption specified only
         IF (@EncryptionKey IS NOT NULL AND @Threads IS NULL)
         BEGIN
   
            EXEC @ret = master.dbo.xp_backup_database @database = @database ,
                                                      @filename = @backupfilename,
                                                      @Priority = @Priority,
                                                      @encryptionkey = @EncryptionKey,
                                                      @affinity = @affinity,
                                                      @logging  = @logging 
         END
         -- full backup with @Encryption and @Threads
         IF (@EncryptionKey IS NOT NULL AND @Threads IS NOT NULL)
         BEGIN
   
            EXEC @ret = master.dbo.xp_backup_database @database = @database ,
                                                      @filename = @backupfilename,
                                                      @Priority = @Priority,
                                                      @encryptionkey = @EncryptionKey,
                                                      @threads  = @Threads,
                                                      @affinity = @affinity,
                                                      @logging  = @logging
         END
   
         -- backup failure
         IF @ret<>0
         BEGIN
            SET @errormsg = 'Full backup of database ' + @database + ' failed with SQL Native Error : ' + CAST(@ret as varchar(10))
            RAISERROR (@errormsg,16,1)
            SET @output = SPACE(4) + '*** ' + @errormsg + ' ***'
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
               SET @output = SPACE(4) + 'Refer to SQL Error Log and NT Event Log for further details'
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
            GOTO CLEANUP
         END
         ELSE
         -- backup success
         BEGIN
            SET @finish = GETDATE()
            SET @output = SPACE(4) + 'Database backed up to ' + @backupfilename
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
   
            --calculate backup runtime
            SET @runtime = (@finish - @start)
            SET @output = SPACE(4) + 'Full database backup completed in '
                        + CAST(DATEPART(hh,@runtime) as varchar(2)) + ' hour(s) '
                        + CAST(DATEPART(mi,@runtime) as varchar(2)) + ' min(s) '
                        + CAST(DATEPART(ss,@runtime) as varchar(2)) + ' second(s)'
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
         END
      END
      ELSE   -- use executable
      BEGIN
         -- standard full backup
         IF (@EncryptionKey IS NULL AND @Threads IS NULL)
         BEGIN

            SET @execmd = @exepath + ' -S"' + @@SERVERNAME + '" -T -D"' + @database +
                          '" -F"' + @backupfilename + '" -B Database -p"' + CAST(@Priority as nvarchar(10)) +
                          '" -A"' + CAST(@affinity as nvarchar(20)) + '" -L"' + CAST(@logging as char(1)) + '"'

            IF @debug = 1 PRINT @execmd

            TRUNCATE TABLE #output
            INSERT #output
            EXEC @ret = master.dbo.xp_cmdshell @execmd

         END
         -- full backup with @Threads specified only
         IF (@EncryptionKey IS NULL AND @Threads IS NOT NULL)
         BEGIN
   
            SET @execmd = @exepath + ' -S"' + @@SERVERNAME + '" -T -D"' + @database +
                          '" -F"' + @backupfilename + '" -B "Database" -p"' + CAST(@Priority as nvarchar(10)) +
                          '" -A"' + CAST(@affinity as nvarchar(20)) + '" -t"' + CAST(@Threads as nvarchar(20)) + '"' + 
                          '" -L"' + CAST(@logging as char(1)) + '"'

            IF @debug = 1 PRINT @execmd

            TRUNCATE TABLE #output
            INSERT #output
            EXEC @ret = master.dbo.xp_cmdshell @execmd

         END
         -- full backup with @Encryption specified only
         IF (@EncryptionKey IS NOT NULL AND @Threads IS NULL)
         BEGIN
   
            SET @execmd = @exepath + ' -S"' + @@SERVERNAME + '" -T -D"' + @database +
                          '" -F"' + @backupfilename + '" -B "Database" -p"' + CAST(@Priority as nvarchar(10)) +
                          '" -A"' + CAST(@affinity as nvarchar(20)) + '" -K"' + @EncryptionKey + '"' + 
                          '" -L"' + CAST(@logging as char(1)) + '"'

            IF @debug = 1 PRINT @execmd

            TRUNCATE TABLE #output
            INSERT #output
            EXEC @ret = master.dbo.xp_cmdshell @execmd

         END
         -- full backup with @Encryption and @Threads
         IF (@EncryptionKey IS NOT NULL AND @Threads IS NOT NULL)
         BEGIN
   
            SET @execmd = @exepath + ' -S"' + @@SERVERNAME + '" -T -D"' + @database +
                          '" -F"' + @backupfilename + '" -B "Database" -p"' + CAST(@Priority as nvarchar(10)) +
                          '" -A"' + CAST(@affinity as nvarchar(20)) + '" -t"' + CAST(@Threads as nvarchar(20)) + 
                          '" -K"' + @EncryptionKey + '"' + '" -L"' + CAST(@logging as char(1)) + '"'

            IF @debug = 1 PRINT @execmd

            TRUNCATE TABLE #output
            INSERT #output
            EXEC @ret = master.dbo.xp_cmdshell @execmd

         END

         -- output
         DELETE #output 
         WHERE txt IS NULL 
         OR txt like 'Processor Number:%'   
         OR txt like 'Encryption Supported%'   
         OR txt like 'SQL Server Version%' 
         OR txt like 'www.dbassociatesit.com%'
         OR txt like 'Copyright%'

         SET @exemsg = ''
         SELECT @exemsg = COALESCE(@exemsg,'') + txt + ' ' FROM #output
         PRINT @exemsg
   
         -- backup failure
         IF @ret<>0
         BEGIN
            SET @errormsg = 'Full backup of database ' + @database + ' failed with SQL Native Error : ' + CAST(@ret as varchar(10))
            RAISERROR (@errormsg,16,1)
            SET @output = SPACE(4) + '*** ' + @errormsg + ' ***'
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
               SET @output = SPACE(4) + 'Refer to SQL Error Log and NT Event Log for further details'
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
            GOTO CLEANUP
         END
         ELSE
         -- backup success
         BEGIN
            SET @finish = GETDATE()
            SET @output = SPACE(4) + 'Database backed up to ' + @backupfilename
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
   
            --calculate backup runtime
            SET @runtime = (@finish - @start)
            SET @output = SPACE(4) + 'Full database backup completed in '
                        + CAST(DATEPART(hh,@runtime) as varchar(2)) + ' hour(s) '
                        + CAST(DATEPART(mi,@runtime) as varchar(2)) + ' min(s) '
                        + CAST(DATEPART(ss,@runtime) as varchar(2)) + ' second(s)'
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
         END

      END
   END

   /************************
      DIFFERENTIAL BACKUP
   ************************/

   IF UPPER(@backuptype) = 'DIFF'
   BEGIN
      IF @usexp = 1   -- use extended stored procedures
      BEGIN
         -- standard full backup
         IF (@EncryptionKey IS NULL AND @Threads IS NULL)
         BEGIN
   
            EXEC @ret = master.dbo.xp_backup_database @database = @database ,
                                                      @filename = @backupfilename,
                                                      @Priority = @Priority,
                                                      @affinity = @affinity,
                                                      @logging  = @logging,
                                                      @with = 'DIFFERENTIAL'
         END
         -- full backup with @Threads specified only
         IF (@EncryptionKey IS NULL AND @Threads IS NOT NULL)
         BEGIN
   
            EXEC @ret = master.dbo.xp_backup_database @database = @database ,
                                                      @filename = @backupfilename,
                                                      @Priority = @Priority,
                                                      @threads  = @Threads,
                                                      @affinity = @affinity,
                                                      @logging  = @logging,
                                                      @with = 'DIFFERENTIAL'
         END
         -- full backup with @Encryption specified only
         IF (@EncryptionKey IS NOT NULL AND @Threads IS NULL)
         BEGIN
   
            EXEC @ret = master.dbo.xp_backup_database @database = @database ,
                                                      @filename = @backupfilename,
                                                      @Priority = @Priority,
                                                      @encryptionkey = @EncryptionKey,
                                                      @affinity = @affinity,
                                                      @logging  = @logging,
                                                      @with = 'DIFFERENTIAL' 
         END
         -- full backup with @Encryption and @Threads
         IF (@EncryptionKey IS NOT NULL AND @Threads IS NOT NULL)
         BEGIN
   
            EXEC @ret = master.dbo.xp_backup_database @database = @database ,
                                                      @filename = @backupfilename,
                                                      @Priority = @Priority,
                                                      @encryptionkey = @EncryptionKey,
                                                      @threads  = @Threads,
                                                      @affinity = @affinity,
                                                      @logging  = @logging,
                                                      @with = 'DIFFERENTIAL'
         END
   
         -- backup failure
         IF @ret<>0
         BEGIN
            SET @errormsg = 'Full backup of database ' + @database + ' failed with SQL Native Error : ' + CAST(@ret as varchar(10))
            RAISERROR (@errormsg,16,1)
            SET @output = SPACE(4) + '*** ' + @errormsg + ' ***'
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
               SET @output = SPACE(4) + 'Refer to SQL Error Log and NT Event Log for further details'
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
            GOTO CLEANUP
         END
         ELSE
         -- backup success
         BEGIN
            SET @finish = GETDATE()
            SET @output = SPACE(4) + 'Database backed up to ' + @backupfilename
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
   
            --calculate backup runtime
            SET @runtime = (@finish - @start)
            SET @output = SPACE(4) + 'Full database backup completed in '
                        + CAST(DATEPART(hh,@runtime) as varchar(2)) + ' hour(s) '
                        + CAST(DATEPART(mi,@runtime) as varchar(2)) + ' min(s) '
                        + CAST(DATEPART(ss,@runtime) as varchar(2)) + ' second(s)'
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
         END
      END
      ELSE   -- use executable
      BEGIN
         -- standard full backup
         IF (@EncryptionKey IS NULL AND @Threads IS NULL)
         BEGIN

            SET @execmd = @exepath + ' -S"' + @@SERVERNAME + '" -T -D"' + @database +
                          '" -F"' + @backupfilename + '" -B "Database" -p"' + CAST(@Priority as nvarchar(10)) +
                          '" -A"' + CAST(@affinity as nvarchar(10)) + '" -W"DIFFERENTIAL"'+ '" -L"' + CAST(@logging as char(1)) + '"'

            IF @debug = 1 PRINT @execmd

            TRUNCATE TABLE #output
            INSERT #output
            EXEC @ret = master.dbo.xp_cmdshell @execmd

         END
         -- full backup with @Threads specified only
         IF (@EncryptionKey IS NULL AND @Threads IS NOT NULL)
         BEGIN
   
            SET @execmd = @exepath + ' -S"' + @@SERVERNAME + '" -T -D"' + @database +
                          '" -F"' + @backupfilename + '" -B "Database" -p"' + CAST(@Priority as nvarchar(10)) +
                          '" -A"' + CAST(@affinity as nvarchar(10)) + '" -t"' + CAST(@Threads as nvarchar(10)) + 
                          '" -W"DIFFERENTIAL"'+ '" -L"' + CAST(@logging as char(1)) + '"'

            IF @debug = 1 PRINT @execmd

            TRUNCATE TABLE #output
            INSERT #output
            EXEC @ret = master.dbo.xp_cmdshell @execmd

         END
         -- full backup with @Encryption specified only
         IF (@EncryptionKey IS NOT NULL AND @Threads IS NULL)
         BEGIN
   
            SET @execmd = @exepath + ' -S"' + @@SERVERNAME + '" -T -D"' + @database +
                          '" -F"' + @backupfilename + '" -B "Database" -p"' + CAST(@Priority as nvarchar(10)) +
                          '" -A"' + CAST(@affinity as nvarchar(10)) + '" -K"' + @EncryptionKey + '" -W"DIFFERENTIAL"' +
                          '" -L"' + CAST(@logging as char(1)) + '"'

            IF @debug = 1 PRINT @execmd

            TRUNCATE TABLE #output
            INSERT #output
            EXEC @ret = master.dbo.xp_cmdshell @execmd

         END
         -- full backup with @Encryption and @Threads
         IF (@EncryptionKey IS NOT NULL AND @Threads IS NOT NULL)
         BEGIN
   
            SET @execmd = @exepath + ' -S"' + @@SERVERNAME + '" -T -D"' + @database +
                          '" -F"' + @backupfilename + '" -B "Database" -p"' + CAST(@Priority as nvarchar(10)) +
                          '" -A"' + CAST(@affinity as nvarchar(10)) + '" -t"' + CAST(@Threads as nvarchar(10)) + '" -K"' + @EncryptionKey + 
                          '" -W"DIFFERENTIAL"'+ '" -L"' + CAST(@logging as char(1)) + '"'

            IF @debug = 1 PRINT @execmd

            TRUNCATE TABLE #output
            INSERT #output
            EXEC @ret = master.dbo.xp_cmdshell @execmd

         END


         -- output
         DELETE #output 
         WHERE txt IS NULL 
         OR txt like 'Processor Number:%'   
         OR txt like 'Encryption Supported%'   
         OR txt like 'SQL Server Version%'   
         OR txt like 'www.dbassociatesit.com%'
         OR txt like 'Copyright%'

         SET @exemsg = ''
         SELECT @exemsg = COALESCE(@exemsg,'') + txt + ' ' FROM #output
         PRINT @exemsg

         -- check output for errors as the return code is not always set
         IF EXISTS(SELECT * FROM #output WHERE txt like '%Error writing data to file%') SET @ret = -1

         -- backup failure
         IF @ret<>0
         BEGIN
            SET @errormsg = 'Full backup of database ' + @database + ' failed with SQL Native Error : ' + CAST(@ret as varchar(10))
            RAISERROR (@errormsg,16,1)
            SET @output = SPACE(4) + '*** ' + @errormsg + ' ***'
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
               SET @output = SPACE(4) + 'Refer to SQL Error Log and NT Event Log for further details'
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
            GOTO CLEANUP
         END
         ELSE
         -- backup success
         BEGIN
            SET @finish = GETDATE()
            SET @output = SPACE(4) + 'Database backed up to ' + @backupfilename
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
   
            --calculate backup runtime
            SET @runtime = (@finish - @start)
            SET @output = SPACE(4) + 'Full database backup completed in '
                        + CAST(DATEPART(hh,@runtime) as varchar(2)) + ' hour(s) '
                        + CAST(DATEPART(mi,@runtime) as varchar(2)) + ' min(s) '
                        + CAST(DATEPART(ss,@runtime) as varchar(2)) + ' second(s)'
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
         END

      END
   END

   /************************
          LOG BACKUP
   ************************/
   
   IF UPPER(@backuptype) = 'LOG'
   BEGIN
      IF @usexp = 1
      BEGIN
         -- standard log backup
         IF (@EncryptionKey IS NULL AND @Threads IS NULL)
         BEGIN
   
            EXEC @ret = master.dbo.xp_backup_log @database = @database ,
                                                 @filename = @backupfilename,
                                                 @Priority = @Priority,
                                                 @affinity = @affinity,
                                                 @logging  = @logging
         END
         -- log backup with @Threads specified only
         IF (@EncryptionKey IS NULL AND @Threads IS NOT NULL)
         BEGIN
   
            EXEC @ret = master.dbo.xp_backup_log @database = @database ,
                                                 @filename = @backupfilename,
                                                 @Priority = @Priority,
                                                 @threads  = @Threads,
                                                 @affinity = @affinity,
                                                 @logging  = @logging
         END
         -- log backup with @Encryption specified only
         IF (@EncryptionKey IS NOT NULL AND @Threads IS NULL)
         BEGIN
   
            EXEC @ret = master.dbo.xp_backup_log @database = @database ,
                                                 @filename = @backupfilename,
                                                 @Priority = @Priority,
                                                 @encryptionkey = @EncryptionKey,
                                                 @affinity = @affinity,
                                                 @logging  = @logging
         END
         -- log backup with @Encryption and @Threads
         IF (@EncryptionKey IS NOT NULL AND @Threads IS NOT NULL)
         BEGIN
   
            EXEC @ret = master.dbo.xp_backup_log @database = @database ,
                                                 @filename = @backupfilename,
                                                 @Priority = @Priority,
                                                 @encryptionkey = @EncryptionKey,
                                                 @threads  = @Threads,
                                                 @affinity = @affinity,
                                                 @logging  = @logging
         END
   
         -- backup failure
         IF @ret<>0
         BEGIN
            SET @errormsg = 'Log backup of database ' + @database + ' failed with Native Error : ' + CAST(@ret as varchar(10))
            RAISERROR (@errormsg,16,1)
            SET @output = SPACE(4) + '*** ' + @errormsg + ' ***'
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
            GOTO CLEANUP
         END
         ELSE
         -- backup success
         BEGIN
            SET @finish = GETDATE()
            SET @output = SPACE(4) + 'Log backed up to ' + @backupfilename
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
   
            --calculate backup runtime
            SET @runtime = (@finish - @start)
            SET @output = SPACE(4) + 'Log backup completed in '
                        + CAST(DATEPART(hh,@runtime) as varchar(2)) + ' hour(s) '
                        + CAST(DATEPART(mi,@runtime) as varchar(2)) + ' min(s) '
                        + CAST(DATEPART(ss,@runtime) as varchar(2)) + ' second(s)'
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
   
         END
      END
      ELSE -- use executable
      BEGIN
         -- standard log backup
         IF (@EncryptionKey IS NULL AND @Threads IS NULL)
         BEGIN

            SET @execmd = @exepath + ' -S"' + @@SERVERNAME + '" -T -D"' + @database +
                          '" -F"' + @backupfilename + '" -B "Log" -p"' + CAST(@Priority as nvarchar(10)) +
                          '" -A"' + CAST(@affinity as nvarchar(20)) + '"' + '" -L"' + CAST(@logging as char(1)) + '"'

            IF @debug = 1 PRINT @execmd

            TRUNCATE TABLE #output
            INSERT #output
            EXEC @ret = master.dbo.xp_cmdshell @execmd

         END
         -- log backup with @Threads specified only
         IF (@EncryptionKey IS NULL AND @Threads IS NOT NULL)
         BEGIN
   
            SET @execmd = @exepath + ' -S"' + @@SERVERNAME + '" -T -D"' + @database +
                          '" -F"' + @backupfilename + '" -B "Log" -p"' + CAST(@Priority as nvarchar(10)) +
                          '" -A"' + CAST(@affinity as nvarchar(20)) + '" -t"' + CAST(@Threads as nvarchar(20)) + '"' + 
                          '" -L"' + CAST(@logging as char(1)) + '"'

            IF @debug = 1 PRINT @execmd

            TRUNCATE TABLE #output
            INSERT #output
            EXEC @ret = master.dbo.xp_cmdshell @execmd

         END
         -- log backup with @Encryption specified only
         IF (@EncryptionKey IS NOT NULL AND @Threads IS NULL)
         BEGIN
   
            SET @execmd = @exepath + ' -S"' + @@SERVERNAME + '" -T -D"' + @database +
                          '" -F"' + @backupfilename + '" -B "Log" -p"' + CAST(@Priority as nvarchar(10)) +
                          '" -A"' + CAST(@affinity as nvarchar(20)) + '" -K"' + @EncryptionKey + '"' + '" -L"' + CAST(@logging as char(1)) + '"'

            IF @debug = 1 PRINT @execmd

            TRUNCATE TABLE #output
            INSERT #output
            EXEC @ret = master.dbo.xp_cmdshell @execmd

         END
         -- log backup with @Encryption and @Threads
         IF (@EncryptionKey IS NOT NULL AND @Threads IS NOT NULL)
         BEGIN
   
            SET @execmd = @exepath + ' -S"' + @@SERVERNAME + '" -T -D"' + @database +
                          '" -F"' + @backupfilename + '" -B "Log" -p"' + CAST(@Priority as nvarchar(10)) +
                          '" -A"' + CAST(@affinity as nvarchar(20)) + '" -t"' + CAST(@Threads as nvarchar(20)) + 
                          '" -K"' + @EncryptionKey + '"' + '" -L"' + CAST(@logging as char(1)) + '"'

            IF @debug = 1 PRINT @execmd

            TRUNCATE TABLE #output
            INSERT #output
            EXEC @ret = master.dbo.xp_cmdshell @execmd

         END

         -- output
         DELETE #output 
         WHERE txt IS NULL 
         OR txt like 'Processor Number:%'   
         OR txt like 'Encryption Supported%'   
         OR txt like 'SQL Server Version%'   
         OR txt like 'www.dbassociatesit.com%'
         OR txt like 'Copyright%'

         SET @exemsg = ''
         SELECT @exemsg = COALESCE(@exemsg,'') + txt + ' ' FROM #output
         PRINT @exemsg

         -- check output for errors as the return code is not always set
         IF EXISTS(SELECT * FROM #output WHERE txt like '%Error writing data to file%') SET @ret = -1
  
         -- backup failure
         IF @ret<>0
         BEGIN
            SET @errormsg = 'Log backup of database ' + @database + ' failed with Native Error : ' + CAST(@ret as varchar(10))
            RAISERROR (@errormsg,16,1)
            SET @output = SPACE(4) + '*** ' + @errormsg + ' ***'
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
            GOTO CLEANUP
         END
         ELSE
         -- backup success
         BEGIN
            SET @finish = GETDATE()
            SET @output = SPACE(4) + 'Log backed up to ' + @backupfilename
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
   
            --calculate backup runtime
            SET @runtime = (@finish - @start)
            SET @output = SPACE(4) + 'Log backup completed in '
                        + CAST(DATEPART(hh,@runtime) as varchar(2)) + ' hour(s) '
                        + CAST(DATEPART(mi,@runtime) as varchar(2)) + ' min(s) '
                        + CAST(DATEPART(ss,@runtime) as varchar(2)) + ' second(s)'
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
   
         END

      END
   END
   
   /************************
         VERIFY BACKUP
   ************************/

   IF @verify = 1
   BEGIN
   
      -- update stage + times
      SET @stage = (@stage + 1)
      SET @start = GETDATE()

      -- write to text report
      IF @report = 1
      BEGIN
         EXEC sp_OAMethod @file,'WriteLine',NULL,''
         SET @output = '[' + CAST(@stage as char(1)) + '] Database ' + @database + ': Verify Backup File...'
         IF @debug = 1 PRINT @output
         EXEC sp_OAMethod @file,'WriteLine',NULL,@output  
      END
      
      IF @usexp = 1
      BEGIN
         -- encryption was used for the backup
         IF (@EncryptionKey IS NOT NULL)
         BEGIN
            EXEC @ret = master.dbo.xp_restore_verifyonly @filename = @backupfilename,
                                                         @encryptionkey  = @EncryptionKey,
                                                         @logging  = @logging
         END
         ELSE
         BEGIN
            EXEC @ret = master.dbo.xp_restore_verifyonly @filename = @backupfilename,
                                                         @logging  = @logging
         END    
   
         -- verify failure
         IF @ret<>0
         BEGIN
            SET @errormsg = 'Verify of ' + @backupfilename + ' failed with Native Error : ' + CAST(@ret as varchar(10))
            RAISERROR (@errormsg,16,1)
            SET @output = SPACE(4) + '*** ' + @errormsg + ' ***'
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
            GOTO CLEANUP
         END
         ELSE
         -- verify success
         BEGIN
            SET @finish = GETDATE()
            SET @output = SPACE(4) + 'Backup file ' + @backupfilename + ' verified'
            IF @debug = 1 PRINT @output
      
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
   
            --calculate verify runtime
            SET @runtime = (@finish - @start)
            SET @output = SPACE(4) + 'Verify backup completed in '
                        + CAST(DATEPART(hh,@runtime) as varchar(2)) + ' hour(s) '
                        + CAST(DATEPART(mi,@runtime) as varchar(2)) + ' min(s) '
                        + CAST(DATEPART(ss,@runtime) as varchar(2)) + ' second(s)'
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
   
         END
      END
      ELSE   -- use executable
      BEGIN
         -- encryption was used for the backup
         IF (@EncryptionKey IS NOT NULL)
         BEGIN
            SET @execmd = REPLACE(@exepath,'""','"') + ' -S' + @@SERVERNAME + ' -T' +
                          ' -F' + @backupfilename + ' -K' + @EncryptionKey +
                          ' -RVerifyonly -L' + CAST(@logging as char(1))

            IF @debug = 1 PRINT @execmd

            TRUNCATE TABLE #output
            INSERT #output
            EXEC @ret = master.dbo.xp_cmdshell @execmd
         END
         ELSE
         BEGIN
            SET @execmd = REPLACE(@exepath,'""','"') + ' -S' + @@SERVERNAME + ' -T' +
                          ' -F' + @backupfilename + ' -RVerifyonly -L' + CAST(@logging as char(1))

            IF @debug = 1 PRINT @execmd

            TRUNCATE TABLE #output
            INSERT #output
            EXEC @ret = master.dbo.xp_cmdshell @execmd
         END    

         -- output
         DELETE #output 
         WHERE txt IS NULL 
         OR txt like 'Processor Number:%'   
         OR txt like 'Encryption Supported%'   
         OR txt like 'SQL Server Version%'   
         OR txt like 'www.dbassociatesit.com%'
         OR txt like 'Copyright%'

         SET @exemsg = ''
         SELECT @exemsg = COALESCE(@exemsg,'') + txt + ' ' FROM #output
         PRINT @exemsg

         -- check output for errors as the return code is not always set
         IF EXISTS(SELECT * FROM #output WHERE (txt like '%incomplete%' or txt like '%damaged%')) SET @ret = -1
  
         -- verify failure
         IF @ret<>0
         BEGIN
            SET @errormsg = 'Verify of ' + @backupfilename + ' failed with Native Error : ' + CAST(@ret as varchar(10))
            RAISERROR (@errormsg,16,1)
            SET @output = SPACE(4) + '*** ' + @errormsg + ' ***'
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
            GOTO CLEANUP
         END
         ELSE
         -- verify success
         BEGIN
            SET @finish = GETDATE()
            SET @output = SPACE(4) + 'Backup file ' + @backupfilename + ' verified'
            IF @debug = 1 PRINT @output
      
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
   
            --calculate verify runtime
            SET @runtime = (@finish - @start)
            SET @output = SPACE(4) + 'Verify backup completed in '
                        + CAST(DATEPART(hh,@runtime) as varchar(2)) + ' hour(s) '
                        + CAST(DATEPART(mi,@runtime) as varchar(2)) + ' min(s) '
                        + CAST(DATEPART(ss,@runtime) as varchar(2)) + ' second(s)'
            IF @debug = 1 PRINT @output
            IF @report = 1
            BEGIN
               EXEC sp_OAMethod @file,'WriteLine',NULL,@output
            END
   
         END
      END
   END

   -- update stage
   SET @stage = (@stage + 1)

/************************
    DELETE OLD FILES
************************/


   -- we have already deleted files so skip to the end
   IF @delfirst = 1 GOTO CLEANUP

   -- this label is so that we can delete files prior to backup if @delfirst = 1
   DELFIRST:

   /************************
      DELETE OLD BACKUPS
   ************************/

   SET @datepart = CASE 
      WHEN UPPER(@dbretainunit) = 'MINUTES' THEN N'mi'
      WHEN UPPER(@dbretainunit) = 'HOURS'   THEN N'hh'
      WHEN UPPER(@dbretainunit) = 'DAYS'    THEN N'dd'
      WHEN UPPER(@dbretainunit) = 'WEEKS'   THEN N'ww'
      WHEN UPPER(@dbretainunit) = 'MONTHS'  THEN N'yy'
   END

   IF @debug = 1 PRINT '@datepart for backups = ' + @datepart

   -- write to text report
   IF @report = 1
   BEGIN
      EXEC sp_OAMethod @file,'WriteLine',NULL,''
   END
   SET @output = '[' + CAST(@stage as char(1)) + '] Database ' + @database + ': Delete Old Backup Files...'
   IF @debug = 1 PRINT @output
   IF @report = 1
   BEGIN
      EXEC sp_OAMethod @file,'WriteLine',NULL,@output
   END

   -- load files in @backupfldr
   IF @checkattrib = 1
      SET @cmd = 'dir /B /A-D-A /OD ' + @backupfldr + REPLACE(@database,' ','_') +
      CASE WHEN UPPER(@backuptype) = 'DB' THEN '_FullDBBackupSLS_'
           WHEN UPPER(@backuptype) = 'DIFF' THEN '_DiffDBBackupSLS_'
           WHEN UPPER(@backuptype) = 'LOG'  THEN '_LogBackupSLS_' END + '*' +
      CASE WHEN UPPER(@backuptype) = 'LOG' THEN '.TRN' ELSE '.BAK' END 
   ELSE 
      SET @cmd = 'dir /B /A-D /OD ' + + @backupfldr + REPLACE(@database,' ','_') +
      CASE WHEN UPPER(@backuptype) = 'DB' THEN '_FullDBBackupSLS_'
           WHEN UPPER(@backuptype) = 'DIFF' THEN '_DiffDBBackupSLS_'
           WHEN UPPER(@backuptype) = 'LOG'  THEN '_LogBackupSLS_' END + '*' +
      CASE WHEN UPPER(@backuptype) = 'LOG' THEN '.TRN' ELSE '.BAK' END 

   IF @debug = 1 PRINT '@cmd = ' + @cmd

   INSERT #files EXEC master.dbo.xp_cmdshell @cmd
   DELETE #files WHERE filename IS NULL or filename = ISNULL(REPLACE(@backupfilename,@backupfldr,''),'nothing')

   IF @debug = 1 SELECT * FROM #files
   
   -- get count of files that match pattern
   SELECT @filecount = COUNT(*) from #files WHERE PATINDEX('%File Not Found%',filename) = 0

   -- remove files that don't meet retention criteria if there are any files that match pattern
   IF UPPER(@dbretainunit) <> 'COPIES'
   BEGIN
      IF @filecount>0
      BEGIN
         SET @delcmd = N'DELETE #files WHERE DATEADD(' + @datepart + N',' + CAST(@dbretainval as nvarchar(10)) + N',' +
                 'CONVERT(datetime,(SUBSTRING(SUBSTRING(filename,((LEN(filename)-CHARINDEX(''_'',REVERSE(filename)))+2),12),7,2) +''/''
                 + SUBSTRING(SUBSTRING(filename,((LEN(filename)-CHARINDEX(''_'',REVERSE(filename)))+2),12),5,2) +''/''
                 + SUBSTRING(SUBSTRING(filename,((LEN(filename)-CHARINDEX(''_'',REVERSE(filename)))+2),12),1,4) +'' ''
                 + SUBSTRING(SUBSTRING(filename,((LEN(filename)-CHARINDEX(''_'',REVERSE(filename)))+2),12),9,2) +'':''
                 + SUBSTRING(SUBSTRING(filename,((LEN(filename)-CHARINDEX(''_'',REVERSE(filename)))+2),12),11,2)),103)) > ''' + CAST(@jobdt as nvarchar(25)) + N''''
         
         IF @debug = 1 PRINT '@delcmd=' + @delcmd
         EXEC master.dbo.sp_executesql @delcmd
   
         SELECT @delcount = COUNT(*) from #files
      END
      ELSE
      BEGIN
         SELECT @delcount = 0
      END
   END
   ELSE  -- number of copies not date based (include current backup that's not in #files)
   BEGIN
      IF @filecount>0
      BEGIN
         IF @dbretainval>1 
         BEGIN
            SET @delcmd = N'DELETE #files WHERE filename IN(SELECT TOP ' + CAST((@dbretainval-1) as nvarchar(10)) +
                          N' filename FROM #files ORDER BY substring(filename,((len(filename)+2)-charindex(''_'',reverse(filename))),12) DESC)'
   
            IF @debug = 1 PRINT '@delcmd=' + @delcmd
            EXEC master.dbo.sp_executesql @delcmd
         END
   
         SELECT @delcount = COUNT(*) from #files

      END
      ELSE
      BEGIN
         SELECT @delcount = 0
      END
   END

   IF @debug = 1 PRINT '@delcount = ' + STR(@delcount)

   -- if there are any matching files
   IF @filecount>0
   BEGIN
      -- are there any files that need deleting
      IF @delcount>0
      BEGIN
         DECLARE FCUR CURSOR FORWARD_ONLY FOR
         SELECT * FROM #files
         OPEN FCUR
         FETCH NEXT FROM FCUR INTO @delfilename
         WHILE @@FETCH_STATUS=0
         BEGIN
            SET @cmd = 'DEL /Q ' + @backupfldr + @delfilename
            EXEC @cmdret = master.dbo.xp_cmdshell @cmd,no_output   

            -- log failure to delete but don't abort procedure
            IF @cmdret<>0
            BEGIN
               SET @output = SPACE(4) + '*** Error: Failed to delete file ' + @backupfldr + @delfilename + ' ***'
               IF @debug = 1 PRINT @output
               IF @report = 1
               BEGIN
                  EXEC sp_OAMethod @file,'WriteLine',NULL,@output
               END
               SELECT @delbkflag = 1 , @cmdret = 0, @delcount = (@delcount-1)
            END
            ELSE
            BEGIN
               SET @output = SPACE(4) + 'Deleted file ' + @backupfldr + @delfilename
               IF @debug = 1 PRINT @output
               IF @report = 1
               BEGIN
                  EXEC sp_OAMethod @file,'WriteLine',NULL,@output
               END
            END

            FETCH NEXT FROM FCUR INTO @delfilename
         END
         CLOSE FCUR
         DEALLOCATE FCUR
      END
   END

   -- write to text report
   SET @output = SPACE(4) + CAST(@delcount as varchar(10)) + ' file(s) deleted.'
   IF @debug = 1 PRINT @output
   IF @report = 1
   BEGIN
      EXEC sp_OAMethod @file,'WriteLine',NULL,@output
      EXEC sp_OAMethod @file,'WriteLine',NULL,''
   END

   -- clear temporary table and variables
   DELETE #files
   SET @cmd = ''
   SET @delcmd = ''
   SET @delfilename = ''
   SET @datepart = ''
   SET @filecount = 0
   SET @delcount = 0
   SET @cmdret = 0
   SET @stage = @stage + 1


   /************************
      DELETE OLD REPORTS
   ************************/

   IF @rptretainunit IS NOT NULL
   BEGIN
      SET @datepart = CASE 
         WHEN UPPER(@rptretainunit) = 'MINUTES' THEN N'mi'
         WHEN UPPER(@rptretainunit) = 'HOURS'   THEN N'hh'
         WHEN UPPER(@rptretainunit) = 'DAYS'    THEN N'dd'
         WHEN UPPER(@rptretainunit) = 'WEEKS'   THEN N'ww'
         WHEN UPPER(@rptretainunit) = 'MONTHS'  THEN N'yy'
   END

   IF @debug = 1 PRINT '@datepart for reports = ' + @datepart

   -- write to text report
   SET @output = '[' + CAST(@stage as char(1)) + '] Delete Old Report Files...'
   IF @debug = 1 PRINT @output
   IF @report = 1
   BEGIN
      EXEC sp_OAMethod @file,'WriteLine',NULL,@output
   END

   -- load files in @reportfldr
   SET @cmd = 'dir /B /A-D /OD ' + + @reportfldr + REPLACE(@database,' ','_') +
   CASE WHEN UPPER(@backuptype) = 'DB' THEN '_FullDBBackupSLS_report_'
        WHEN UPPER(@backuptype) = 'DIFF' THEN '_DiffDBBackupSLS_report_'
        WHEN UPPER(@backuptype) = 'LOG'  THEN '_LogBackupSLS_report_' END + '*.txt'

   IF @debug = 1 PRINT '@cmd = ' + @cmd

   INSERT #files EXEC master.dbo.xp_cmdshell @cmd
   DELETE #files WHERE filename IS NULL

   IF @debug = 1 SELECT * FROM #files
   
   -- get count of files that match pattern
   SELECT @filecount = COUNT(*) from #files WHERE PATINDEX('%File Not Found%',filename) = 0

   -- remove files that don't meet retention criteria if there are any files that match pattern
   IF UPPER(@rptretainunit) <> 'COPIES'
   BEGIN
      IF @filecount>0
      BEGIN
         SET @delcmd = N'DELETE #files WHERE DATEADD(' + @datepart + N',' + CAST(@rptretainval as nvarchar(10)) + N',' +
                 'CONVERT(datetime,(SUBSTRING(SUBSTRING(filename,((LEN(filename)-CHARINDEX(''_'',REVERSE(filename)))+2),12),7,2) +''/''
                 + SUBSTRING(SUBSTRING(filename,((LEN(filename)-CHARINDEX(''_'',REVERSE(filename)))+2),12),5,2) +''/''
                 + SUBSTRING(SUBSTRING(filename,((LEN(filename)-CHARINDEX(''_'',REVERSE(filename)))+2),12),1,4) +'' ''
                 + SUBSTRING(SUBSTRING(filename,((LEN(filename)-CHARINDEX(''_'',REVERSE(filename)))+2),12),9,2) +'':''
                 + SUBSTRING(SUBSTRING(filename,((LEN(filename)-CHARINDEX(''_'',REVERSE(filename)))+2),12),11,2)),103)) > ''' + CAST(@jobdt as nvarchar(25)) + N''''
         
         IF @debug = 1 PRINT '@delcmd=' + @delcmd
         EXEC master.dbo.sp_executesql @delcmd
   
         SELECT @delcount = COUNT(*) from #files
      END
      ELSE
      BEGIN
         SELECT @delcount = 0
      END
   END
   ELSE  -- number of copies not date based
   BEGIN
      IF @filecount>0
      BEGIN
         SET @delcmd = N'DELETE #FILES WHERE filename IN(SELECT TOP ' + CAST(@rptretainval as nvarchar(10)) +
                       N' filename FROM #files ORDER BY substring(filename,((len(filename)+2)-charindex(''_'',reverse(filename))),12) DESC)'

         IF @debug = 1 PRINT '@delcmd=' + @delcmd
         EXEC master.dbo.sp_executesql @delcmd
   
         SELECT @delcount = COUNT(*) from #files
      END
      ELSE
      BEGIN
         SELECT @delcount = 0
      END
   END
   
   IF @debug = 1 PRINT STR(@delcount)

   -- if there are any matching files
   IF @filecount>0
   BEGIN
      -- are there any files that need deleting
      IF @delcount>0
      BEGIN
         DECLARE FCUR CURSOR FORWARD_ONLY FOR
         SELECT * FROM #files
         OPEN FCUR
         FETCH NEXT FROM FCUR INTO @delfilename
         WHILE @@FETCH_STATUS=0
         BEGIN
            SET @cmd = 'DEL /Q ' + @reportfldr + @delfilename
            EXEC @cmdret = master.dbo.xp_cmdshell @cmd,no_output   

            -- log failure to delete but don't abort procedure
            IF @cmdret<>0
            BEGIN

               SET @output = SPACE(4) + '*** Error: Failed to delete file ' + @reportfldr + @delfilename + ' ***'
               IF @debug = 1 PRINT @output
               IF @report = 1
               BEGIN
                  EXEC sp_OAMethod @file,'WriteLine',NULL,@output
               END
               SELECT @delrptflag = 1 , @cmdret = 0, @delcount = (@delcount-1)
            END
            BEGIN
               SET @output = SPACE(4) + 'Deleted file ' + @reportfldr + @delfilename
               IF @debug = 1 PRINT @output
               IF @report = 1
               BEGIN
                  EXEC sp_OAMethod @file,'WriteLine',NULL,@output
               END
            END

            FETCH NEXT FROM FCUR INTO @delfilename
         END
         CLOSE FCUR
         DEALLOCATE FCUR
      END
   END

   -- write to text report
   SET @output = SPACE(4) + CAST(@delcount as varchar(10)) + ' file(s) deleted.'
   IF @debug = 1 PRINT @output
   IF @report = 1
   BEGIN
      EXEC sp_OAMethod @file,'WriteLine',NULL,@output
      EXEC sp_OAMethod @file,'WriteLine',NULL,''
   END

   -- update stage
   SET @stage = @stage + 1
   END
   -- if we got here due to @delfirst = 1 go back and do the backups
   IF @delfirst = 1 GOTO DOBACKUP


/************************
         CLEAN UP 
************************/

   CLEANUP:

   DROP TABLE #files
   DROP TABLE #exists
   DROP TABLE #output

   -- if we encountered errors deleting old backups return failure
   IF @delbkflag<>0
   BEGIN
      SET @errormsg = 'sp_SQLLitespeedmaint encountered errors deleting old backup files' + CHAR(13)
                    + CASE WHEN @report = 1 THEN ('Please see ' + @reportfilename + CHAR(13) + ' for further details') ELSE '' END
      RAISERROR(@errormsg,16,1)
      SET @ret = 1
   END

   -- if we encountered errors deleting old reports return failure
   IF (@delrptflag<>0 AND @delbkflag = 0)
   BEGIN
      SET @errormsg = 'sp_SQLLitespeedmaint encountered errors deleting old report files' + CHAR(13)
                    + CASE WHEN @report = 1 THEN ('Please see ' + @reportfilename + CHAR(13) + ' for further details') ELSE '' END
      RAISERROR(@errormsg,16,1)
      SET @ret = 1
   END
   
   -- if we created a file make sure we write trailer and destroy object
   IF @filecrt = 1
   BEGIN
      -- write final part of report
      EXEC sp_OAMethod @file,'WriteLine',NULL,''
      SET @output = 'SQLLitespeed processing finished at ' + CONVERT(varchar(25),GETDATE(),100) 
                  + ' (Return Code : ' + CAST(@ret as varchar(10)) + ')' 
      IF @debug = 1 PRINT @output
      EXEC sp_OAMethod @file,'WriteLine',NULL,@output
      EXEC sp_OAMethod @file,'WriteLine',NULL,''

      -- destroy file object
      EXEC @hr=sp_OADestroy @file
      IF @hr <> 0 EXEC sp_OAGetErrorInfo @file

   END


   -- destroy fso object
   IF @report = 1
   BEGIN
      EXEC @hr=sp_OADestroy @fso 
      IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso
   END

RETURN @ret
GO


      
    

