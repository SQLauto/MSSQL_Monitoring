/*----------------------------------------------------
    Date    : 2007-11-06
    Note    : EMS DBA �ڵ� ���� ������ ���
    No.     : 
*----------------------------------------------------*/
USE EMS
GO

CREATE TABLE dbo.AUTO_DBA_JOB
(
    iid         INT IDENTITY(1,1) NOT NULL,
    reg_dt      DATETIME          NOT NULL CONSTRAINT DF__AUTO_DBA_JOB__REG_DT DEFAULT(GETDATE()),
    email       VARCHAR(100)      NULL,
    cust_nm     varchar(20)       NULL,
    title       varchar(200)      NULL,
    content1    varchar(200)      NULL, -- ����
    content2    varchar(50)       NULL, -- �����
    content3    varchar(50)       NULL, -- ����ð�
    content4    varchar(10)       NULL, -- �ܰ�
    content5    varchar(6000)     NULL,
    mail_send_yn char(1)          NOT NULL CONSTRAINT DF__AUTO_DBA_JOB__MAIL_SEND_YN DEFAULT ('N')
) ON  [AUTO120_DAT]

ALTER TABLE dbo.AUTO_DBA_JOB ADD CONSTRAINT PK__AUTO_DBA_JOB__IID PRIMARY KEY CLUSTERED (iid) ON [AUTO120_DAT]
CREATE NONCLUSTERED INDEX  IDX__AUTO_DBA_JOB__MAIL_SEND_YN ON AUTO_DBA_JOB (mail_send_yn) ON [AUTO120_IDX]
CREATE NONCLUSTERED INDEX  IDX__AUTO_DBA_JOB__REG_DT ON AUTO_DBA_JOB (reg_dt) ON [AUTO120_IDX]
GO
