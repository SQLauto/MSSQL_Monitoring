/*----------------------------------------------------
    Date    : 2008-11-24
    Note    : EMS DBA 자동 메일 컨텐츠 등록
    No.     : 
*----------------------------------------------------*/

--===================== 싱가폴 
USE NETPION
GO

CREATE TABLE dbo.AUTO_SG_DBA_JOB
(
    autocode    int IDENTITY(1,1) NOT NULL, 
    mailtype    nvarchar(12)      NOT NULL CONSTRAINT DF__AUTO_SG_DBA_JOB_MAIL_TYPE DEFAULT('100'),
    senttime    datetime          NULL,
    sendtime    datetime          NULL,
    opentime    datetime          NULL, 
    mail_send_yn char(1)          NOT NULL CONSTRAINT DF__AUTO_DBA_JOB__MAIL_SEND_YN DEFAULT ('N'),
    email       VARCHAR(100)      NULL,
    cust_nm     varchar(20)       NULL,
    title       varchar(200)      NULL,
    content1    varchar(200)      NULL, -- 제목
    content2    varchar(50)       NULL, -- 담당자
    content3    varchar(50)       NULL, -- 실행시간
    content4    varchar(10)       NULL, -- 단계
    content5    varchar(6000)     NULL,
    CMPNCODE int null,
    reg_dt      DATETIME          NOT NULL CONSTRAINT DF__AUTO_DBA_JOB__REG_DT DEFAULT(GETDATE()),
    
) ON  [PRIMARY]

CREATE CLUSTERED INDEX  CIDX__AUTO_SG_DBA_JOB__REG_DT  ON AUTO_SG_DBA_JOB (reg_dt)
--CREATE NONCLUSTERED INDEX  IDX__AUTO_DBA_JOB__MAIL_SEND_YB ON AUTO_SG_DBA_JOB (mail_send_yn) 
ALTER TABLE dbo.AUTO_SG_DBA_JOB ADD CONSTRAINT PK__AUTO_SG_DBA_JOB__AUTOCODE PRIMARY KEY (autocode) ON [PRIMARY]

GO