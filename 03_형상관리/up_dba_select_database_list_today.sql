/*************************************************************************  
* ���ν�����: dbo.up_dba_select_database_list_today
* �ۼ�����	: 2012-11-28 by choi bo ra
* ����������:  
* ����		:  
* ��������	:
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_database_list_today
	@site			char(1), 
	@server_id		int

AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */


/* BODY */
SELECT * 
FROM DBO.DATABASE_LIST_TODAY WITH(NOLOCK) WHERE SERVER_ID = @SERVER_ID


    
go