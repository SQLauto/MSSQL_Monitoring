--====================================================
-- DB 파일 사이즈 계산
-- ===================================================

DECLARE @db_name SYSNAME
SET @db_name = 'PASTACCT'

SELECT
	sysfiles.name AS LogicalFileName,
	CAST(sysfiles.size/128.0 AS int) AS FileSize,
	g.groupname, 
	sysfiles.name AS LogicalFileName, sysfiles.filename AS PhysicalFileName, 
	CONVERT(sysname,DatabasePropertyEx(@db_name,'Status')) AS Status, 
	CONVERT(sysname,DatabasePropertyEx(@db_name,'Updateability')) AS Updateability, 
	CONVERT(sysname,DatabasePropertyEx(@db_name,'Recovery')) AS RecoveryMode, 
	CAST(sysfiles.size/128.0 - CAST(FILEPROPERTY(sysfiles.name, 'SpaceUsed' ) AS int)/128.0 AS int) AS FreeSpaceMB, 
	CAST(100 * (CAST (((sysfiles.size/128.0 -CAST(FILEPROPERTY(sysfiles.name, 
	'SpaceUsed' ) AS int)/128.0)/(sysfiles.size/128.0)) 
	AS decimal(4,2))) AS varchar(8)) + '%' AS FreeSpacePct, 
	sysfiles.growth, sysfiles.maxsize,
	GETDATE() as PollDate 
FROM dbo.sysfiles join  sys.sysfilegroups as g on sysfiles.groupid = g.groupid
ORDER BY g.groupname, sysfiles.name
