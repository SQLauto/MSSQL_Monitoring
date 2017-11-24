/*************************************************************************  
* ���ν�����  : dbo.up_get_new_run_seqno 
* �ۼ�����    : 2010-01-18 by ������
* ����������  :  
* ����        : ��Ű�� �α� seq_no ��������
* ��������    :
**************************************************************************/
CREATE proc [dbo].[up_get_new_run_seqno]
    @package_id varchar(512)
    ,@new_run_seq int output
as
begin
set nocount on
	declare @i int 

	insert into dbo.package_run_seqno(reg_dt , package_id) values(getdate() ,@package_id)
	set @i = scope_identity()

-----------------------------------------------------------------------
-- package �ʱ� �۵��� -1�� �����Ǿ� ���� �ϴ� �κ��� ������
-----------------------------------------------------------------------
	update a
	set work_seqno = @i 
	from dbo.task_event_log a with(nolock)
	where package_id = @package_id 
	and work_seqno = -1


	set @new_run_seq = @i 
end

--create index idx__package_id_work_seqno on dbo.task_event_log(package_id , work_seqno)