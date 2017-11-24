/*************************************************************************  
* 프로시저명  : dbo.up_reg_task_event 
* 작성정보    : 2010-01-18 by 윤태진
* 관련페이지  :  
* 내용        : 패키지 log  이벤트 insert
* 수정정보    :
**************************************************************************/
CREATE proc [dbo].[up_reg_task_event]
    @package_id varchar(512) --0
    ,@task_id varchar(512)   --1
    ,@event_nm varchar(30)   --2
    ,@work_seqno int         --3
    ,@loop_seqno int =null   --4
    ,@error_code int =null   --5
    ,@error_desc varchar(max) = null --6
    ,@source_id  varchar(512) = null --7
    ,@source_nm varchar(max) = null  --8
    ,@source_desc varchar(max) = null --9
    ,@option1 varchar(512) =null
    ,@option2 varchar(512) =null
as 
begin
set nocount on
set transaction isolation level read uncommitted


---------------------------------------------------------------
-- load event_type
---------------------------------------------------------------
declare @event_type int
select @event_type = event_type from dbo.package_event_type with(nolock) where event_nm = @event_nm

if @event_type is not null
begin
	insert into dbo.task_event_log
	(
	package_id
	,task_id
	,event_type
	,error_code
	,error_desc
	,source_id
	,source_nm
	,source_desc
	,work_seqno
    ,loop_seqno
	,user_option1
	,user_option2
	)
	values(@package_id , @task_id , @event_type , @error_code , 
	    @error_desc , @source_id , @source_nm , @source_desc , @work_seqno , 
	    @loop_seqno , @option1 , @option2)
	
end



end

