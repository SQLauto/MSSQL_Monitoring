/*
blockinglocks
�ۼ��� : 2007-08-06 
�ۼ��� : ������
�Ķ���� : 
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
		where l1.resource_type != 'DATABASE' --DB lock ����!
		order by l1.resource_description , l1.request_status

		SET NOCOUNT OFF
end