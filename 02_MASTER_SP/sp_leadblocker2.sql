/*************************************************************************  
* 프로시저명  : dbo.sp_leadblocker2 
* 작성정보    : 2007-08-11 김태환
* 관련페이지  :  
* 내용        :
* 수정정보    : DMV를 이용한 blocked session id 확인
**************************************************************************/
CREATE procedure dbo.sp_leadblocker2 (@latch int = 0, @fast int = 1)  
AS 
	SET NOCOUNT ON

	SELECT 
		'KILL ' + CAST(req.SESSION_ID AS VARCHAR(5)) AS killStr
	,	'DBCC INPUTBUFFER(' + CAST(req.SESSION_ID AS VARCHAR(5)) + ')' AS inputBufferStr
	,	req.open_transaction_count
	,	(select text from sys.dm_exec_sql_text(sql_handle)) as sql
	,	req.last_wait_type
	, 	req.wait_type
	,	req.status
	, 	se.login_name
	,	se.host_name
	,	req.blocking_session_id
	,	DB_NAME(req.database_id) as user_db_name
	FROM sys.dm_exec_requests as req WITH (NOLOCK)
	INNER JOIN sys.dm_exec_sessions as se WITH (NOLOCK) ON req.session_id = se.session_id
	WHERE req.blocking_session_id IN (SELECT blocking_session_id FROM sys.dm_exec_requests WITH (NOLOCK) WHERE blocking_session_id > 0 AND blocking_session_id <> session_id) AND req.blocking_session_id = 0

	SET NOCOUNT OFF

