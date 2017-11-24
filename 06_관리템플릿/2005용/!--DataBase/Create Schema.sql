-- =========================
-- CREATE SCHEMA
-- =========================

CREATE SCHEMA <schema_name, sysname, schema_name> AUTHORIZATION owner_name



-- ex
CREATE SCHEMA [test] AUTHORIZATION [dev]
GO

GRANT INSERT ON SCHEMA::[test] TO [backend] WITH GRANT OPTION 
GO

GRANT REFERENCES ON SCHEMA::[test] TO [backend] WITH GRANT OPTION 
GO

GRANT ALTER ON SCHEMA::[test] TO [backend]
GO

GRANT CONTROL ON SCHEMA::[test] TO [backend]
GO

DENY SELECT ON SCHEMA::[test] TO [backend]
GO


 

use [CUB]
GO
GRANT ALTER ON SCHEMA::[test] TO [backend]
GO
use [CUB]
GO
GRANT CONTROL ON SCHEMA::[test] TO [backend]
GO
use [CUB]
GO
DENY DELETE ON SCHEMA::[test] TO [backend]
GO
use [CUB]
GO
DENY EXECUTE ON SCHEMA::[test] TO [backend]
GO

