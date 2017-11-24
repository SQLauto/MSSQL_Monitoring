/*************************************************************************  
* 프로시저명: dbo.up_dba_select_database_list_today
* 작성정보	: 2012-11-28 by choi bo ra
* 관련페이지:  
* 내용		:  
* 수정정보	:
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