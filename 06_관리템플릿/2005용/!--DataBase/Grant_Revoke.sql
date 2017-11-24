--===============================
-- 권한 부여 (GRANT/REVOKE)
--===============================
USE <dbusername, sysname, usedbname>
GO

-- 1. 객체에대한 권한
GRANT SELECT ON [dbo].[<object,sysname,object>] TO [<loginname,sysname,loginname>]
GO
REVOKE SELECT ON [dbo].[<object,sysname,object>] TO [<loginname,sysname,loginname>]
GO


--2.객체 컬럼에대한 권한
GRANT SELECT ON [dbo].[<object,sysname,object>]  (column,...) TO [<loginname,sysname,loginname>] AS [dbo]
GO

--3.스키마 권한
GRANT permission  [ ,...n ] ON SCHEMA :: schema_name
    TO database_principal [ ,...n ]
    [ WITH GRANT OPTION ]
    [ AS granting_principal ]
GO

REVOKE VIEW DEFINITION ON SCHEMA::[dev] TO [backend] AS [dev]
GO