/*----------------------------------------------------
    Date    : 2007-10-31
    Note    : sys.syscacheobjects 
    No.     :
*----------------------------------------------------*/
USE DBA
GO



CREATE TABLE dbo.SYSCACHE_EXEC_STATS
(
    seq_no              INT             IDENTITY(1,1) NOT NULL,
    reg_dt              NVARCHAR(10)    NOT NULL CONSTRAINT DF__SYSCACHE_EXEC_STATS_REG_DT  DEFAULT CONVERT(NVARCHAR(10), GETDATE(), 120),
    objid               INT             NOT NULL,
    objname             SYSNAME         NULL,
    usecounts           INT             NOT NULL CONSTRAINT DF__SYSCACHE_EXEC_STATS__USECOUNTS DEFAULT 0,
    execution_count     INT             NOT NULL CONSTRAINT DF__SYSCACHE_EXEC_STATS__EXECUTION_COUNT DEFAULT 0,
    plan_generation_num INT             NOT NULL CONSTRAINT DF__SYSCACHE_EXEC_STATS__PLAN_GENERATION_NUM DEFAULT 0,
    total_elapsed_time  DECIMAL(12,8)   NOT NULL CONSTRAINT DF__SYSCACHE_EXEC_STATS__TOTAL_ELAPSED_TIME DEFAULT 0,
    avg_elapsed_time    DECIMAL(12,8)   NOT NULL CONSTRAINT DF__SYSCACHE_EXEC_STATS__AVG_ELAPSED_TIME DEFAULT 0,
    total_worker_time   DECIMAL(12,8)   NOT NULL CONSTRAINT DF__SYSCACHE_EXEC_STATS__TOTAL_WORKER_TIME DEFAULT 0,
    avg_worker_time     DECIMAL(12,8)   NOT NULL CONSTRAINT DF__SYSCACHE_EXEC_STATS__AVG_WORKER_TIME DEFAULT 0,
    total_logical_reads BIGINT          NOT NULL CONSTRAINT DF__SYSCACHE_EXEC_STATS__TOTAL_LOGICAL_READS DEFAULT 0,
    total_logical_writes BIGINT         NOT NULL CONSTRAINT DF__SYSCACHE_EXEC_STATS__TOTAL_LOGICAL_WRITES DEFAULT 0,
    total_physical_reads BIGINT         NOT NULL CONSTRAINT DF__SYSCACHE_EXEC_STATS__TOTAL_PHYSICAL_READS DEFAULT 0,
    avg_logical_reads    BIGINT         NOT NULL CONSTRAINT DF__SYSCACHE_EXEC_STATS__AVG_LOGICAL_READES DEFAULT 0,
    avg_logical_writes   BIGINT         NOT NULL CONSTRAINT DF__SYSCACHE_EXEC_STATS__AVG_LOGICAL_WRITES DEFAULT 0,
    avg_physical_reads   BIGINT         NOT NULL CONSTRAINT DF__SYSCACHE_EXEC_STATS__AVG_PHYSICAL_READS DEFAULT 0,
    cacheobjtype        NVARCHAR(34)    NULL,
    objtype             NVARCHAR(16)    NULL,
    bucketid            INT             NOT NULL,
    dbname              SYSNAME         NOT NULL,
    setopts             INT             NULL,
    plan_handle         varbinary(64)    NULL,
    sql_handle          varbinary(64)    NULL
 ) ON [PRIMARY]
GO     
    
ALTER TABLE dbo.SYSCACHE_EXEC_STATS  ADD CONSTRAINT PK__SYSCACHE_EXEC_STATS__SEQ_NO PRIMARY KEY NONCLUSTERED
    (seq_no) ON [PRIMARY]
    
CREATE CLUSTERED INDEX CIDX__SYSCACHE_EXEC_STATS__REG_DT ON dbo.SYSCACHE_EXEC_STATS      (reg_dt) ON [PRIMARY]
GO       