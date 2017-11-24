-- Create temporary stored procedures in tempdb 
CREATE PROCEDURE dbo.sp_tmpregread 
  @hive varchar (60), @key nvarchar (2000), @value nvarchar (2000), @data nvarchar (4000) = NULL OUTPUT 
AS
DECLARE @sql70or80xp sysname

DECLARE @sqlcmd nvarchar (4000)
-- To avoid osql line wrapping, don't store more than 2000 chars.
CREATE TABLE #regdata (RegValue nvarchar(190), RegData nvarchar (1800))
IF CHARINDEX ('7.00.', @@VERSION) = 0
  SET @sql70or80xp = 'master.dbo.xp_instance_regread'
ELSE
  SET @sql70or80xp = 'master.dbo.xp_regread'
SET @sqlcmd = 'INSERT INTO #regdata EXEC ' + @sql70or80xp + ' @P1, @P2, @P3' 
EXEC sp_executesql @sqlcmd, 
  N'@P1 varchar (40), @P2 nvarchar (2000), @P3 nvarchar (2000)', 
  @hive, @key, @value 
SELECT * FROM #regdata
PRINT ''

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO