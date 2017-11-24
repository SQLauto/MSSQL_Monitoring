CREATE PROC dbo.sp_pssdiag_cleanup @AppName sysname='PSSDIAG'
AS
  EXEC dbo.sp_trace 'OFF', @AppName=@AppName

EXEC('DBCC CACHEPROFILE(2)') -- Turn off cache profiling (wrap in EXEC() to prevent error on 7.0)

DECLARE @spid int, @cmd varchar(30)
DECLARE osqls CURSOR FOR
SELECT spid FROM master..sysprocesses
WHERE hostname=@AppName AND spid<>@@SPID
FOR READ ONLY

OPEN osqls
FETCH osqls INTO @spid
WHILE @@FETCH_STATUS=0 BEGIN
  SET @cmd='KILL '+CAST(@spid AS varchar)
  EXEC(@cmd)
  FETCH osqls INTO @spid
END
CLOSE osqls
DEALLOCATE osqls

--Assuming that these procs actually ship with the product, there's no 
--reason to drop them
/*
	--Drop our procs
	IF OBJECT_ID('dbo.sp_code_runner','P') IS NOT NULL
		DROP PROC dbo.sp_code_runner

	IF OBJECT_ID('dbo.sp_trace','P') IS NOT NULL
		DROP PROC dbo.sp_trace

	IF OBJECT_ID('dbo.sp_blocker_pss70','P') IS NOT NULL
		DROP PROC dbo.sp_blocker_pss70

	IF OBJECT_ID('dbo.sp_blocker_pss80','P') IS NOT NULL
		DROP PROC dbo.sp_blocker_pss80

	IF OBJECT_ID('dbo.sp_sqldiag','P') IS NOT NULL
		DROP PROC dbo.sp_sqldiag

	IF OBJECT_ID('dbo.sp_tmpregread','P') IS NOT NULL
		DROP PROC dbo.sp_tmpregread

	IF OBJECT_ID('dbo.sp_tmpregenumvalues','P') IS NOT NULL
		DROP PROC dbo.sp_tmpregenumvalues
*/

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO