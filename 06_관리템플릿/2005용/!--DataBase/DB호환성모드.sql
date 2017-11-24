--==========================
--	호환성 모드 변경
--==========================

EXEC dbo.sp_dbcmptlevel @dbname=N'CREDIT', @new_cmptlevel=90
GO