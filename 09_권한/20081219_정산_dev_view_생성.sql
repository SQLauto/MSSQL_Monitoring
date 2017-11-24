-- =======================================
-- ���� ����� ���� ����
-- =======================================

/*
    dev_view ����
    
    DB���� VIEW DEFINITION ������ �ش�. 
    sp_help
    sp_helptext�� �����ϰ� �ϱ� ����
    
*/

use master
go

-- 1. ���� ���� ����
CREATE LOGIN dev_view WITH PASSWORD ='view3950',
		DEFAULT_DATABASE = ACCTCLOSE,
		CHECK_POLICY = OFF,
		CHECK_EXPIRATION = OFF
GO

		
		

use acctclose
go
exec sp_grantdbaccess  'dev_view', 'dev_view'
go
GRANT VIEW DEFINITION TO dev_view
go

use accounts
go
exec sp_grantdbaccess  'dev_view', 'dev_view'
go
GRANT VIEW DEFINITION TO dev_view
go

use balance
go
exec sp_grantdbaccess  'dev_view', 'dev_view'
go
GRANT VIEW DEFINITION TO dev_view
go

use dba
go
exec sp_grantdbaccess  'dev_view', 'dev_view'
go
GRANT VIEW DEFINITION TO dev_view
go

use dss
go
exec sp_grantdbaccess  'dev_view', 'dev_view'
go
GRANT VIEW DEFINITION TO dev_view
go

use pastacct
go
exec sp_grantdbaccess  'dev_view', 'dev_view'
go
GRANT VIEW DEFINITION TO dev_view
go

use settle
go
exec sp_grantdbaccess  'dev_view', 'dev_view'
go
GRANT VIEW DEFINITION TO dev_view
go

use tax
go
exec sp_grantdbaccess  'dev_view', 'dev_view'
go
GRANT VIEW DEFINITION TO dev_view
go

use worklog
go
exec sp_grantdbaccess  'dev_view', 'dev_view'
go
GRANT VIEW DEFINITION TO dev_view
go

use BI
go
exec sp_grantdbaccess  'dev_view', 'dev_view'
go
GRANT VIEW DEFINITION TO dev_view
go

use stagingdb
go
exec sp_grantdbaccess  'dev_view', 'dev_view'
go
GRANT VIEW DEFINITION TO dev_view
go



use statdb
go
exec sp_grantdbaccess  'dev_view', 'dev_view'
go
GRANT VIEW DEFINITION TO dev_view
go





use RECEIPT
go
exec sp_grantdbaccess  'dev_view', 'dev_view'
go
GRANT VIEW DEFINITION TO dev_view
go



use acctclose
go
-- finsys ���� 
REVOKE EXECUTE ON OBJECT::up_sttl_search_daily_close_sum TO finsys
go
REVOKE EXECUTE ON OBJECT::up_trade_daily_search_test TO finsys
go
REVOKE EXECUTE ON OBJECT::up_sttl_search_daily_close_sum_test TO finsys
go


--- ���� DB�� ���� �߰��ϱ� 

 