use tempdb;
GO
CREATE PROCEDURE dbo.tempdbstress
AS
SET NOCOUNT ON;
SELECT TOP(5000) a.name, replicate(a.status,4000) as col2
into #t1
FROM master..spt_values a
CROSS JOIN master..spt_values b OPTION (MAXDOP 1);
GO