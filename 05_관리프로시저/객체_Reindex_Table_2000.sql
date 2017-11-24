USE DBAdmin
GO
CREATE TABLE dbo.DBA_REINDEX_TARGET_2000
(
ObjectName sysname,
ObjectId int,
IndexName sysname,
IndexId tinyint,
Level tinyint,
Pages int,
Rows bigint,
MinimumRecordSize smallint,
MaximumRecordSize smallint,
AverageRecordSize smallint,
ForwardedRecords bigint,
Extents int,
ExtentSwitches numeric(10,2),
AverageFreeBytes numeric(10,2),
AveragePageDensity numeric(10,2),
ScanDensity numeric(10,2),
BestCount int,
ActualCount int,
LogicalFragmentation numeric(10,2),
ExtentFragmentation numeric(10,2),
CheckDate smalldatetime DEFAULT (GETDATE())
)
GO


-- �ý��� ���� ���ν��� �����ϱ�
USE master
GO
ALTER PROCEDURE sp_DBCCSHOWCONTIG
AS
DBCC SHOWCONTIG WITH TABLERESULTS, ALL_INDEXES, FAST
GO


-- ���� ����
USE maindb1
GO
INSERT INTO DBAdmin.dbo.DBA_REINDEX_TARGET_2000 (
ObjectName, ObjectId, IndexName, IndexId, Level, Pages,
Rows, MinimumRecordSize, MaximumRecordSize,
AverageRecordSize, ForwardedRecords, Extents,
ExtentSwitches, AverageFreeBytes, AveragePageDensity,
ScanDensity, BestCount, ActualCount, LogicalFragmentation,
ExtentFragmentation)
EXEC sp_DBCCSHOWCONTIG
GO
