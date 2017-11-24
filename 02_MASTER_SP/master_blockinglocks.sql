/*
blockinglocks
작성일 : 2007-08-06 
작성자 : 윤태진
파라미터 : 
*/
create proc dbo.sp_blockinglocks
@exec_mode int  =1
as
begin
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

		select 
		l1.request_session_id
		,l1.resource_type 
		,11.resource_subtype
		,l1.resource_description
		,l1.request_mode
		,l1.request_type
		,l1.request_status
		from sys.dm_tran_locks l1 with(nolock)
		where l1.resource_type != 'DATABASE' --DB lock 제외!
		order by l1.resource_description , l1.request_status

		SET NOCOUNT OFF
end