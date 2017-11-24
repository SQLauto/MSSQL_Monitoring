SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.sp_tmpregenumvalues 
  @hive varchar (40), @key nvarchar (2000), @direct_output int = 0
AS
DECLARE @sql70or80xp sysname
DECLARE @sqlcmd nvarchar (4000)
CREATE TABLE #regdata (RegValue nvarchar(190), RegData nvarchar (1800))
IF CHARINDEX ('7.00.', @@VERSION) = 0
  SET @sql70or80xp = 'master.dbo.xp_instance_regenumvalues'
ELSE
  SET @sql70or80xp = 'master.dbo.xp_regenumvalues'
IF @direct_output = 1 SET @sqlcmd = 'EXEC '
ELSE SET @sqlcmd = 'INSERT INTO #regdata EXEC '
SET @sqlcmd = @sqlcmd + @sql70or80xp + ' @P1, @P2' 
EXEC sp_executesql @sqlcmd, 
  N'@P1 varchar (40), @P2 nvarchar (2000)', 
  @hive, @key
IF @direct_output = 0 SELECT * FROM #regdata

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO