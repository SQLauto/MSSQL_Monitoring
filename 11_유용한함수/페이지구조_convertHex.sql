/****** Object:  View dbo.ConvertHex    Script Date: 11/17/1999 10:05:25 AM ******/
if exists (select * from sysobjects where id = object_id(N'[dbo].[convertHex]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dbo].[convertHex]
GO

SET QUOTED_IDENTIFIER  ON    SET ANSI_NULLS  ON 
GO

/****** Object:  View dbo.ConvertHex    Script Date: 11/17/1999 10:05:25 AM ******/
CREATE View convertHex AS
SELECT 	convert(char(30), name) AS 'object_name', 
	id, 
	indid, 
	convert(varchar(2), (convert(int, substring(first, 6, 1)) * power(2, 8)) + (convert(int, substring(first, 5, 1)))) + ':' +
	convert(varchar(11), 
	(convert(int, substring(first, 4, 1)) * power(2, 24)) + 
	(convert(int, substring(first, 3, 1)) * power(2, 16)) + 
	(convert(int, substring(first, 2, 1)) * power(2, 8)) + 
	(convert(int, substring(first, 1, 1)))) AS "firstDec",
	first,
	convert(varchar(2), (convert(int, substring(root, 6, 1)) * power(2, 8)) + (convert(int, substring(root, 5, 1)))) + ':' +
	convert(varchar(11), 
	(convert(int, substring(root, 4, 1)) * power(2, 24)) + 
	(convert(int, substring(root, 3, 1)) * power(2, 16)) + 
	(convert(int, substring(root, 2, 1)) * power(2, 8)) + 
	(convert(int, substring(root, 1, 1)))) AS "rootDec",
	root,
	convert(varchar(2), (convert(int, substring(firstIAM, 6, 1)) * power(2, 8)) + (convert(int, substring(firstIAM, 5, 1)))) + ':' +
	convert(varchar(11), 
	(convert(int, substring(firstIAM, 4, 1)) * power(2, 24)) + 
	(convert(int, substring(firstIAM, 3, 1)) * power(2, 16)) + 
	(convert(int, substring(firstIAM, 2, 1)) * power(2, 8)) + 
	(convert(int, substring(firstIAM, 1, 1)))) AS "firstIAMDec",
	firstIAM
FROM sysindexes

GO

SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON 
GO

