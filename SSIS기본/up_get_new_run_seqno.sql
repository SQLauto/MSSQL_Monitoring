/*************************************************************************  
* 프로시저명  : dbo.up_get_new_run_seqno 
* 작성정보    : 2010-01-18 by 윤태진
* 관련페이지  :  
* 내용        : 패키지 로그 seq_no 가져오기
* 수정정보    :
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
-- package 초기 작동시 -1로 설정되어 동작 하는 부분을 보정함
-----------------------------------------------------------------------
	update a
	set work_seqno = @i 
	from dbo.task_event_log a with(nolock)
	where package_id = @package_id 
	and work_seqno = -1


	set @new_run_seq = @i 
end

--create index idx__package_id_work_seqno on dbo.task_event_log(package_id , work_seqno)