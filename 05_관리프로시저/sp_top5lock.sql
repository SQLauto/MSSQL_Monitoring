/*************************************************************************  
* ���ν�����  : dbo.sp_top5locks
* �ۼ�����    : 2007-08-11 ����ȯ
* ����������  :  
* ����        :
* ��������    : lock�� ���� ��� �ִ� TOP 5 ���μ��� 
**************************************************************************/
CREATE PROCEDURE dbo.sp_top5locks
	@iCount		smallint = 5
AS 
	set nocount on
	set transaction isolation level read uncommitted 

	SELECT 
		'KILL ' + CAST(lock.request_session_id as varchar(5)) as 'KILL'
	,	ca.text as SQL_TEXT
	,	ses.host_name as HOST
	,   datediff(mi, ses.login_time, getdate()) AS '����ð�'
	,	ses.program_name as program_name
	,   ses.login_name
	,	DB_NAME(req.database_id) as user_db_name
	,   ses.client_version
	,	con.client_net_address
	FROM
	(
		select top (@iCount) request_session_id  , count(request_session_id) as cnt
		from sys.dm_tran_locks with(nolock)
		where request_session_id > 50
		group by request_session_id
		order by cnt desc
	)as lock
	inner join sys.dm_exec_requests as req with (nolock) on lock.request_session_id = req.session_id
	inner join sys.dm_exec_sessions as ses with (nolock) on req.session_id = ses.session_id
	inner join sys.dm_exec_connections as con with (nolock) on ses.session_id = con.session_id
	cross apply sys.dm_exec_sql_text (req.sql_handle) as ca

	set nocount off
