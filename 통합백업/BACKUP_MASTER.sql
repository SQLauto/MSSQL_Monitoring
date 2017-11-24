/*----------------------------------------------------
    Date    : 2007-12-17
    Note    : 통합 백업 성공 실패를 위한 정보 테이블
    No.     :
*----------------------------------------------------*/
 
 USE DBA
 GO
 
CREATE TABLE dbo.BACKUP_MASTER
(
	seq_no          INT           NOT NULL IDENTITY(1,1),
	server_name		NVARCHAR(128) NOT NULL,
	database_name	NVARCHAR(128) NOT NULL,
	backup_flag		TINYINT		  NOT NULL,  --1: DB + LOG, --2:DB, --3:LOG
	backup_type	    TINYINT		  NOT NULL,  --1: ONLINE BACKUP, --2: FILE BACKUP
	san_flag	    TINYINT		  NOT NULL,  --1: SAN 백업, -2: 네트워크 백업	
	backup_cycle    TINYINT       NOT NULL,  --1: 일, 2: 주, 3 : 월
	backup_day      TINYINT       NOT NULL,  -- cycle에 따른 입력
	reg_date		DATETIME	  NOT NULL CONSTRAINT DF__BACKUP_MASTER__REG_DATE DEFAULT (GETDATE()),
	chg_date		DATETIME	  NOT NULL CONSTRAINT DF__BACKUP_MASTER__CHG_DATE DEFAULT (GETDATE())
) ON [PRIMARY]
GO

ALTER TABLE dbo.BACKUP_MASTER ADD CONSTRAINT PK__BACKUP_MASTER__SEQ_NO PRIMARY KEY NONCLUSTERED
    (seq_no) WITH (FILLFACTOR = 90) ON [PRIMARY]

CREATE CLUSTERED INDEX CIDX__BACKUP_MASTER__SERVER_NAME__DATABASE_NAME ON dbo.BACKUP_MASTER
    (server_name, database_name)  WITH (FILLFACTOR = 90) ON [PRIMARY]
GO


CREATE TABLE dbo.BACKUP_DETAIL
(  
    seq_no                  INT             NOT NULL IDENTITY(1,1),
    server_name             NVARCHAR(128)   NOT NULL,
    database_name           NVARCHAR(128)   NOT NULL,
    backup_set_id           INT             NOT NULL,
    family_sequence_number  INT             NOT NULL, 
    type                    NVARCHAR(20)    NULL, 
    recovery_model          NVARCHAR(60)    NOT NULL, 
    name                    NVARCHAR(128)   NULL, 
    succesflag              TINYINT         NOT NULL,  -- 1:성공, 2:실패
    backup_diffday          INT             NULL CONSTRAINT DF__BACKUP_DETAIL__BACKUP_DIFFDAY DEFAULT(0),
    backup_start_date       DATETIME        NULL,
    backup_finish_date      DATETIME        NULL,
    backup_size             NVARCHAR(20)    NULL,
    physical_device_name    NVARCHAR(260)   NULL,
    software_build_version  SMALLINT        NULL,
    first_lsn               NUMERIC(25,0)   NULL,
    last_lsn                NUMERIC(25,0)   NULL,
    checkpoint_lsn          NUMERIC(25,0)   NULL,
    database_backup_lsn     NUMERIC(25,0)   NULL,
    compatibility_level     NVARCHAR(10)    NOT NULL,
    factor                  NVARCHAR(max)   NULL,
    result                  NVARCHAR(max)   NULL,
    reg_dt                  DATETIME        NOT NULL CONSTRAINT DF__BACKUP_DETAIL__REG_DT DEFAULT (GETDATE())
 ) ON [PRIMARY]
 GO
 
 
ALTER TABLE dbo.BACKUP_DETAIL ADD CONSTRAINT PK__BACKUP_DETAIL__SEQ_NO PRIMARY KEY NONCLUSTERED
(SEQ_NO ) WITH (FILLFACTOR = 90) ON [PRIMARY]


CREATE INDEX IDX__BACKUP_DETAIL__SERVER_NAME__DATABASE_NAME ON dbo.BACKUP_DETAIL
    (server_name, database_name) WITH (FILLFACTOR = 90) ON [PRIMARY]
 

    