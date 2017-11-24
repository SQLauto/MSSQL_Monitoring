--===============================
-- ���� �ο� (GRANT/REVOKE)
--===============================
USE <dbusername, sysname, usedbname>
GO

-- 1. ��ü������ ����
GRANT SELECT ON [dbo].[<object,sysname,object>] TO [<loginname,sysname,loginname>]
GO
REVOKE SELECT ON [dbo].[<object,sysname,object>] TO [<loginname,sysname,loginname>]
GO


--2.��ü �÷������� ����
GRANT SELECT ON [dbo].[<object,sysname,object>]  (column,...) TO [<loginname,sysname,loginname>] AS [dbo]
GO

--3.��Ű�� ����
GRANT permission  [ ,...n ] ON SCHEMA :: schema_name
    TO database_principal [ ,...n ]
    [ WITH GRANT OPTION ]
    [ AS granting_principal ]
GO

REVOKE VIEW DEFINITION ON SCHEMA::[dev] TO [backend] AS [dev]
GO