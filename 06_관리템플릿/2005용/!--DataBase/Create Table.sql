-- ===============================
-- Create Table 
-- ===============================

IF OBJECT_ID('dbo.testTable', 'U') IS NOT NULL
  DROP TABLE dbo.testTable
GO

-- 1-1. ���̺� ����
CREATE TABLE dbo.testTable (
    col1        INT         NOT NULL CONSTRAINT  PK_testTable_col1 PRIMARY KEY CLUSTERED,
    col2        INT         IDENTITY(1,1) NOT NULL,
    col3        NVARCHAR    NULL CONSTRAINT UK_testTable_col3 UNIQUE
) ON [PRIMARY]
GO

-- 1-2. ���̺� ����
CREATE TABLE dbo.testTable (
    col1        INT         NOT NULL,
    col2        INT         IDENTITY(1,1) NOT NULL,
    col3        NVARCHAR    NULL
) ON [PRIMARY]
GO

ALTER TABLE dbo.testTable
    ADD CONSTRAINT PK_testTable_col1 PRIMARY KEY  NONCLUSTERED|CLUSTERED 
        ( col1 ) ON [PRIMARY]
GO


-- 1-3 üũ ����
CREATE TABLE dbo.testTable (
    col1        INT         NOT NULL,
    col2        INT         NOT NULL CONSTRAINT CK_testTable_check(col3 > 3)
    col3        NVARCHAR    NULL
) ON [PRIMARY]
GO


-- 1-4 �÷� �߰��ϸ鼭 DF, Check ����
ALTER TABLE dbo.testTable ADD USE_YN CHAR(1) NOT NULL 
	 CONSTRAINT DF_�� DEFAULT('N'), CONSTRAINT CK_test CHECK (����)
GO

ALTER TABLE [dbo].[testTable]  WITH CHECK ADD  CONSTRAINT CK_�� 
	CHECK  (USE_YN = 'N' or USE_YN = 'Y')
GO

