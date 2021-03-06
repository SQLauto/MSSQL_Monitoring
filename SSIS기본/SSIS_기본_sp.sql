
/****** 개체:  Table [dbo].[package_event_type]    스크립트 날짜: 02/16/2010 14:02:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PACKAGE_EVENT_TYPE](
	[event_type] [int] IDENTITY(1,1) NOT NULL,
	[event_nm] [varchar](10) NULL,
	[reg_dt] [datetime] NULL DEFAULT (getdate()),
 CONSTRAINT [PK__PACKAGE_EVENT_TYPE] PRIMARY KEY CLUSTERED 
(
	[event_type] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** 개체:  Table [dbo].[package_event_log]    스크립트 날짜: 02/16/2010 14:02:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PACKAGE_EVENT_LOG](
	[seqno] [int] IDENTITY(1,1) NOT NULL,
	[package_id] [varchar](512) NULL,
	[event_type] [int] NULL,
	[fire_dt] [datetime] NULL DEFAULT (getdate()),
	[reg_dt] [datetime] NULL DEFAULT (getdate()),
	[error_code] [int] NULL,
	[error_desc] [varchar](max) NULL,
	[source_id] [varchar](512) NULL,
	[source_nm] [varchar](max) NULL,
	[source_desc] [varchar](max) NULL,
 CONSTRAINT [PK__PACKAGE_EVENT_LOG_SEQNO] PRIMARY KEY NONCLUSTERED 
(
	[seqno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [CIDX__PACKAGE_EVENT_LOG__FIRE_DT] ON [dbo].[package_event_log] 
(
	[fire_dt] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** 개체:  Table [dbo].[task_event_log]    스크립트 날짜: 02/16/2010 14:01:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TASK_EVENT_LOG](
	[seqno] [int] IDENTITY(1,1) NOT NULL,
	[package_id] [varchar](512) NULL,
	[task_id] [varchar](512) NULL,
	[event_type] [int] NULL,
	[fire_dt] [datetime] NULL DEFAULT (getdate()),
	[reg_dt] [datetime] NULL DEFAULT (getdate()),
	[error_code] [int] NULL,
	[error_desc] [varchar](max) NULL,
	[source_id] [varchar](512) NULL,
	[source_nm] [varchar](max) NULL,
	[source_desc] [varchar](max) NULL,
	[work_seqno] [int] NULL,
	[loop_seqno] [int] NULL,
	[user_option1] [varchar](512) NULL,
	[user_option2] [varchar](512) NULL,
 CONSTRAINT [PK__TASK_EVENT_LOG__SEQNO] PRIMARY KEY NONCLUSTERED 
(
	[seqno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [CIDX__TASK_EVENT_LOG] ON [dbo].[task_event_log] 
(
	[fire_dt] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IDX__TASK_EVENT_LOG__PACKAGE_ID__TASK_ID] ON [dbo].[task_event_log] 
(
	[package_id] ASC,
	[task_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IDX__TASK_EVENT_LOG__PACKAGE_ID__WORK_SEQNO] ON [dbo].[task_event_log] 
(
	[package_id] ASC,
	[work_seqno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IDX__TASK_EVNET_LOG__TASK_ID] ON [dbo].[task_event_log] 
(
	[task_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** 개체:  Table [dbo].[PACKAGE_TASK]    스크립트 날짜: 02/16/2010 14:01:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PACKAGE_TASK](
	[seqno] [int] IDENTITY(1,1) NOT NULL,
	[package_id] [varchar](512) NULL,
	[task_id] [varchar](512) NULL,
	[task_nm] [varchar](max) NULL,
	[task_desc] [varchar](max) NULL,
	[reg_dt] [datetime] NULL DEFAULT (getdate()),
	[parent_id] [varchar](512) NULL,
	[deploy_mode] [varchar](10) NULL,
	[deploy_stat] [varchar](10) NULL,
 CONSTRAINT [PK__PACKAGE_TASK_SEQNO] PRIMARY KEY NONCLUSTERED 
(
	[seqno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [CIDX__PACKAGE_TASK__PACKAGE_TASK] ON [dbo].[PACKAGE_TASK] 
(
	[task_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IDX__PACKAGE_TASK__PACKAGE_ID] ON [dbo].[PACKAGE_TASK] 
(
	[package_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** 개체:  Table [dbo].[package_meta]    스크립트 날짜: 02/16/2010 14:02:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PACKAGE_META](
	[seqno] [int] IDENTITY(1,1) NOT NULL,
	[package_nm] [varchar](200) NULL,
	[reg_operator] [int] NULL,
	[rel_job_name] [varchar](512) NULL,
	[rel_job_id] [varchar](40) NULL,
	[package_path] [varchar](512) NULL,
	[config_path] [varchar](512) NULL,
	[reg_dt] [datetime] NULL DEFAULT (getdate()),
	[chg_dt] [datetime] NULL DEFAULT (getdate()),
	[use_yn] [int] NULL,
	[package_id] [varchar](512) NULL,
 CONSTRAINT [PK__PACKAGE_META__SEQNO] PRIMARY KEY CLUSTERED 
(
	[seqno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** 개체:  Table [dbo].[package_connection]    스크립트 날짜: 02/16/2010 14:02:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PACKAGE_CONNECTION](
	[seqno] [int] IDENTITY(1,1) NOT NULL,
	[meta_seq] [int] NULL,
	[connection_name] [varchar](200) NULL,
	[connection_string] [varchar](1000) NULL,
	[reg_dt] [datetime] NULL DEFAULT (getdate()),
	[chg_dt] [datetime] NULL,
	[use_yn] [int] NULL,
 CONSTRAINT [PK__PACKAGE_CONNECTION] PRIMARY KEY CLUSTERED 
(
	[seqno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** 개체:  Table [dbo].[package_loop_seqno]    스크립트 날짜: 02/16/2010 14:02:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PACKAGE_LOOP_SEQNO](
	[loop_seq] [int] IDENTITY(1,1) NOT NULL,
	[reg_dt] [datetime] NULL DEFAULT (getdate()),
	[package_id] [varchar](512) NULL,
 CONSTRAINT [pk__package_loop_seqno] PRIMARY KEY CLUSTERED 
(
	[loop_seq] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** 개체:  Table [dbo].[package_run_seqno]    스크립트 날짜: 02/16/2010 14:02:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PACKAGE_RUN_SEQNO](
	[run_seq] [int] IDENTITY(1,1) NOT NULL,
	[reg_dt] [datetime] NULL DEFAULT (getdate()),
	[package_id] [varchar](512) NULL,
 CONSTRAINT [pk__package_run_seqno] PRIMARY KEY CLUSTERED 
(
	[run_seq] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** 개체:  Table [dbo].[PACKAGE]    스크립트 날짜: 02/16/2010 14:02:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PACKAGE](
	[seqno] [int] IDENTITY(1,1) NOT NULL,
	[package_nm] [varchar](512) NOT NULL,
	[package_desc] [varchar](max) NULL,
	[reg_dt] [datetime] NULL CONSTRAINT [DF__PACKAGE__reg_dt__7C8480AE]  DEFAULT (getdate()),
	[package_id] [varchar](512) NOT NULL,
	[deploy_mode] [varchar](10) NULL,
	[deploy_stat] [varchar](10) NULL,
 CONSTRAINT [PK__PACKAGE__SEQNO] PRIMARY KEY NONCLUSTERED 
(
	[seqno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [CIDX__PACKAGE__PACKAGE_ID] ON [dbo].[PACKAGE] 
(
	[package_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** 개체:  StoredProcedure [dbo].[up_reg_task_info]    스크립트 날짜: 02/16/2010 14:01:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* 프로시저명  : dbo.up_reg_task_info 
* 작성정보    : 2010-01-18 by 윤태진
* 관련페이지  :  
* 내용        : 패키지 정보  task 입력
* 수정정보    :
**************************************************************************/
CREATE proc [dbo].[up_reg_task_info]
    @package_id varchar(512)
    ,@parent_task_id varchar(512)
    ,@task_id varchar(512)
    ,@task_nm varchar(max)
    ,@task_desc varchar(max)
    ,@deploy_mode varchar(10)
    ,@deploy_state varchar(10)
    --,@task_seqno int output
as
begin

set nocount on
set transaction isolation level READ UNCOMMITTED

if not exists(select top 1 task_id from dbo.package_task with(nolock) where task_id = @task_id)
begin
	insert into dbo.package_task(package_id , parent_id , task_id , task_nm , task_desc , deploy_mode , deploy_stat)
	values(@package_id , @parent_task_id , @task_id , @task_nm , '' , @deploy_mode , @deploy_state)
end
else
begin
	delete dbo.package_task where package_id = @package_id and task_id = @task_id

	insert into dbo.package_task(package_id , parent_id , task_id , task_nm , task_desc , deploy_mode , deploy_stat)
	values(@package_id , @parent_task_id , @task_id , @task_nm , '' , @deploy_mode , @deploy_state)
end


end
GO
/****** 개체:  StoredProcedure [dbo].[up_reg_task_event]    스크립트 날짜: 02/16/2010 14:01:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* 프로시저명  : dbo.up_reg_task_event 
* 작성정보    : 2010-01-18 by 윤태진
* 관련페이지  :  
* 내용        : 패키지 이벤트 로그  입력
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
	values(@package_id , @task_id , @event_type , @error_code , @error_desc , @source_id , @source_nm , @source_desc , @work_seqno , @loop_seqno , @option1 , @option2)
	
end



end
GO
/****** 개체:  StoredProcedure [dbo].[up_reg_package_event]    스크립트 날짜: 02/16/2010 14:01:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* 프로시저명  : dbo.up_reg_package_event 
* 작성정보    : 2010-01-18 by 윤태진
* 관련페이지  :  
* 내용        : 패키지 log  이벤트 insert
* 수정정보    :
**************************************************************************/
CREATE proc [dbo].[up_reg_package_event] 
@package_id varchar(512)
,@pakcage_nm varchar(max)
,@event_nm varchar(30)
,@error_code int =null
,@error_desc varchar(max) = null
,@source_id  varchar(512) = null
,@source_nm varchar(max) = null
,@source_desc varchar(max) = null
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
	insert into dbo.package_event_log
	(
	 package_id 
	,event_type 
	,error_code 
	,error_desc
	,source_id 
	,source_nm
	,source_desc
	)
	values(@package_id , @event_type , @error_code , @error_desc , @source_id , @source_nm , @source_desc)

end

end
GO
/****** 개체:  StoredProcedure [dbo].[up_get_new_run_seqno]    스크립트 날짜: 02/16/2010 14:01:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* 프로시저명  : dbo.up_get_new_run_seqno 
* 작성정보    : 2010-01-18 by 윤태진
* 관련페이지  :  
* 내용        : 패키지 이벤트 로그 seq_no 셋팅
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
GO
/****** 개체:  StoredProcedure [dbo].[up_reg_package_meta_info]    스크립트 날짜: 02/16/2010 14:01:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* 프로시저명  : dbo.up_reg_package_meta_info 
* 작성정보    : 2010-01-18 by 윤태진
* 관련페이지  :  
* 내용        : 패캐지 메타 정보 입력
* 수정정보    :
**************************************************************************/
CREATE proc [dbo].[up_reg_package_meta_info] 
    @package_nm varchar(200) 
    ,@package_path varchar(512)
    ,@config_path varchar(512)
    ,@package_id varchar(512)
    --,@meta_seq  int output
as
begin
set nocount on
set transaction isolation level read uncommitted

	declare @new_seq int 
	
	if exists(select top 1 * from dbo.package_meta with(nolock) where package_id = @package_id)
	begin
		set @new_seq  = -1 
	end
	else
	begin
		insert into dbo.package_meta(package_id , package_nm , package_path , config_path , reg_dt , use_yn)
		values (@package_id , @package_nm  ,@package_path , @config_path , getdate() , 1)
		--set @new_seq = scope_identity()
	end	
	
	--set @meta_seq = @new_seq 

end
GO
/****** 개체:  StoredProcedure [dbo].[up_reg_connection_info]    스크립트 날짜: 02/16/2010 14:01:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* 프로시저명  : dbo.up_reg_connection_info 
* 작성정보    : 2010-01-18 by 윤태진
* 관련페이지  :  
* 내용        : 패키지 connetion 정보 입력
* 수정정보    :
**************************************************************************/
create proc [dbo].[up_reg_connection_info]
    @package_id varchar(512)
    ,@connection_name varchar(512)
    ,@connection_string varchar(512)
as
begin
set nocount on
set transaction isolation level read uncommitted

declare @meta_seq int 
set @meta_seq = null 
------------------------------------------------
-- meta info sync
------------------------------------------------
--if exists(select top 1 seqno from dbo.package_meta where package_id = @package_id )
select @meta_seq = seqno
from dbo.package_meta with(nolock)
where package_id = @package_id 

if @meta_seq is not null
begin
	insert into dbo.package_connection(meta_seq , connection_name , connection_string , reg_dt , use_yn)
	values(@meta_seq , @connection_name , @connection_string , getdate()  , 1)
end


end
GO
/****** 개체:  StoredProcedure [dbo].[up_reg_package_connection_info]    스크립트 날짜: 02/16/2010 14:01:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* 프로시저명  : dbo.up_reg_package_connection_info 
* 작성정보    : 2010-01-18 by 윤태진
* 관련페이지  :  
* 내용        : 패키지 connetion 정보 입력
* 수정정보    :
**************************************************************************/
create proc [dbo].[up_reg_package_connection_info]
    @meta_seq int 
    ,@connection_name varchar(200)
    ,@connection_string varchar(1000)
as
begin
set nocount on
set transaction isolation level read uncommitted

insert into dbo.package_connection (meta_seq , connection_name , connection_string , reg_dt , use_yn)
values ( @meta_seq , @connection_name , @connection_string , getdate() , 1)


end
GO
/****** 개체:  StoredProcedure [dbo].[up_clear_connection_info]    스크립트 날짜: 02/16/2010 14:01:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* 프로시저명  : dbo.up_clear_connection_info 
* 작성정보    : 2010-01-18 by 윤태진
* 관련페이지  :  
* 내용        : 패키지 connection 정보 clear, 상태 업데이트
* 수정정보    :
**************************************************************************/
create proc [dbo].[up_clear_connection_info] 
        @meta_seq int 
as 
begin
set nocount on
set transaction isolation level read uncommitted

update  a
set use_yn = 0
,chg_dt = getdate()
from dbo.package_connection a with(nolock)
where meta_seq = @meta_seq

end
GO
/****** 개체:  StoredProcedure [dbo].[up_get_new_loop_seqno]    스크립트 날짜: 02/16/2010 14:01:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* 프로시저명  : dbo.up_get_new_loop_seqno 
* 작성정보    : 2010-01-18 by 윤태진
* 관련페이지  :  
* 내용        : 패키지 loop seq_no
* 수정정보    :
**************************************************************************/
CREATE proc [dbo].[up_get_new_loop_seqno]
    @package_id varchar(512)
,@new_loop_seq int output
as
begin
set nocount on
	declare @i int 


	insert into dbo.package_loop_seqno(reg_dt , package_id) values(getdate() , @package_id)
	set @i  = scope_identity()

	set @new_loop_seq = @i 
end
GO
/****** 개체:  StoredProcedure [dbo].[up_load_package_list]    스크립트 날짜: 02/16/2010 14:01:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* 프로시저명  : dbo.up_load_package_list 
* 작성정보    : 2010-01-18 by 윤태진
* 관련페이지  :  
* 내용        : 패키지 리스트 load
* 수정정보    :
**************************************************************************/
CREATE proc [dbo].[up_load_package_list] 
as
begin
set nocount on
set transaction isolation level read uncommitted

select seqno 
, package_nm 
, package_desc
, package_id
, deploy_mode 
, deploy_stat
, convert(varchar(10) , reg_dt , 121) as reg_dt
from dbo.package with(nolock)
order by seqno desc

end
GO
/****** 개체:  StoredProcedure [dbo].[up_reg_package_info]    스크립트 날짜: 02/16/2010 14:01:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[up_reg_package_info]
@package_id varchar(512)
,@package_nm varchar(max)
,@package_desc varchar(max)
,@deploy_mode varchar(10) 
,@deploy_state varchar(10)
as
begin
set nocount on
set transaction isolation level READ UNCOMMITTED

declare @package_seqno int 
set @package_seqno = -1;


if not exists(select top 1 package_id from dbo.PACKAGE with(nolock) where package_id = @package_id)
begin
	insert into dbo.PACKAGE(package_id , package_nm , package_desc , deploy_mode , deploy_stat)
	values(@package_id , @package_nm , @package_desc , @deploy_mode , @deploy_state)
	
end
else
begin
	delete dbo.package where package_id = @package_id 
	
	insert into dbo.PACKAGE(package_id , package_nm , package_desc , deploy_mode , deploy_stat)
	values(@package_id , @package_nm , @package_desc , @deploy_mode , @deploy_state)
	
end

end
GO
