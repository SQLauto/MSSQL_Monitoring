/*
blockinglocks
작성일 : 2007-08-06 
작성자 : 윤태진
파라미터 : 
*/
CREATE proc dbo.sp_blockinglocks
@exec_mode int  =1
as
begin
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

	select 
l1.request_session_id
,db.name
,session.host_name
,session.program_name
,session.login_name
,l1.resource_type 
,11.resource_subtype
,l1.resource_description
,l1.Resource_associated_entity_id
,l1.request_mode
,l1.request_type
,l1.request_status
from sys.dm_tran_locks l1 with(nolock) 
inner join sys.dm_tran_locks l2 with(nolock) on ( l1.resource_database_id = l2.resource_database_id and l1.resource_associated_entity_id = l2.resource_associated_entity_id)
inner join master..sysdatabases db with(nolock) on l1.resource_database_id = db.dbid
inner join sys.dm_exec_sessions session with(nolock) on session.session_id = l1.request_session_id
where l1.resource_type != 'DATABASE' --DB lock 제외!
and l1.request_status <> l2.request_status
and l1.request_session_id <> l2.request_session_id
order by l1.resource_description , l1.request_status


		SET NOCOUNT OFF
end



