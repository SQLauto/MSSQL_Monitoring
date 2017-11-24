/*
������(blocking) ��ȸ
�ۼ��� : 2007-07-03 
�ۼ��� : ������
�Ķ���� : 
@exec_mode int  =1  : ������
  -- 1 : ��� �ʵ� display
  --   : �ֿ� �ʵ� display
*/

CREATE proc dbo.up_DBA_CheckProcessStatus2
@exec_mode int  =1
as
begin
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
		
		---------------------------------------------------------------------
		-- temp table �����
		---------------------------------------------------------------------
		
		-- sysprocess 		
		create table #tmp_top_process
		(
			seqno int not null identity(1,1)
		,	spid int 
		,	blocked int
		,	lastwaittype varchar(100)
		,	open_tran int
		,	cmd varchar(100)
		,	hostname varchar(100)
		,	dbid int 
		,	uid int 
		,	cpu numeric(38,0)
		,	physical_io numeric(38,0)
		,	status varchar(100)
		,	waitresource varchar(100)
		,	str_kill varchar(20)
		,	str_dbcc_spid varchar(2000)
		,	str_dbcc_blocked varchar(2000)
		)
		
		-- dbcc inputbuffer
		create table #inputbuffer
		(
			seq int identity primary key
		,	eventtype char(50)
		,	parameters int
		,	eventinfo varchar(max)
		)
		
		---------------------------------------------------------------------
		-- step 1. �ʿ��� process ������ master..sysprocesses���� �о� ���δ�.
		---------------------------------------------------------------------
			insert into #tmp_top_process
			(
				spid 
			,	blocked
			,	lastwaittype
			,	open_tran
			,	cmd
			,	hostname
			,	dbid
			,	uid 
			,	cpu
			,	physical_io
			,	status
			,	waitresource
			,	str_kill
			,	str_dbcc_spid
			,	str_dbcc_blocked
			)

			select top 50
			spid as spid
			,blocked as blocked
			,lastwaittype
			,open_tran
			,cmd
			, convert(varchar(25),hostname) as hostname
			,dbid
			,uid
			,cpu
			,physical_io
			,status
			,waitresource
			,case blocked 
					when null then ''
					else 'KILL ' + convert(varchar(10) , blocked)
			  end 
			,''
			,''
			from master..sysprocesses with(nolock)
			where spid <> blocked 
			and spid > 50 and blocked > 0

		---------------------------------------------------------------------
		-- ���ǿ� �´� process ������ �ٷ� ����
		---------------------------------------------------------------------
		
			if @@rowcount <=0 return 
			
		---------------------------------------------------------------------
		-- step 2. ������ spid�� ���� dbcc inputbuffer ������ spid , blocked�� ����
		--         �����ϰ� �� ���� �ӽ� ���̺� update �Ѵ�.
		---------------------------------------------------------------------
					
			declare @limit_seq int ,@start_seq int , @end_seq int , @process_size int

			set @process_size = 1
			
			select @limit_seq= count(*) from #tmp_top_process with(nolock)
			
			set @start_seq = 1
			set @end_seq = @start_seq + @process_size
			
			while (1=1)
			begin
			
					
					declare @src_spid int , @src_blocked int
					declare @dbcc_inputbuffer varchar(50) , @dbcc_inputbuffer2 varchar(50)
					declare @dbcc_output1 varchar(2000) , @dbcc_output2 varchar(2000)
					---------------------------------------------------------------------
					-- patch 
					---------------------------------------------------------------------
					
					select @src_spid = spid , @src_blocked = blocked 
					from #tmp_top_process with(nolock)
					where seqno = @start_seq
					
					set @dbcc_inputbuffer = 'DBCC INPUTBUFFER(' + convert(varchar(10) , @src_spid ) + ')'
					set @dbcc_inputbuffer2 = 'DBCC INPUTBUFFER(' + convert(varchar(10) , @src_blocked ) + ')'
					
					---------------------------------------------------------------------
					-- dbcc input buffer (spid)
					---------------------------------------------------------------------
					
					insert into #inputbuffer (EventType, Parameters, EventInfo)
					exec(@dbcc_inputbuffer)
					
					
					if @@rowcount > 0
					begin
							select top 1 @dbcc_output1 = EventInfo 
							from #inputbuffer with(nolock)
							order by seq desc
					end
					
					---------------------------------------------------------------------
					-- dbcc input buffer (blocked)
					---------------------------------------------------------------------
					
					insert into #inputbuffer (EventType, Parameters, EventInfo)
					exec(@dbcc_inputbuffer2)
					
					if @@rowcount > 0
					begin
							select top 1 @dbcc_output2 = EventInfo 
							from #inputbuffer with(nolock)
							order by seq desc
					end
					
					
					---------------------------------------------------------------------
					-- update process temp table 
					---------------------------------------------------------------------
					
					update #tmp_top_process
					set str_dbcc_spid = substring(@dbcc_output1  ,1,2000) ,
					str_dbcc_blocked = substring(@dbcc_output2 ,1,2000)
					where seqno = @start_seq
			
					if @end_seq > @limit_seq break;
					
					set @start_seq = @end_seq
					set @end_seq= @start_seq + @process_size
			end

---------------------------------------------------------------------
-- ��� column display mode
---------------------------------------------------------------------
								
if @exec_mode = 1 --FULL		
begin
		select 
				spid 
			--,	blocked
			,	str_kill
			,	isnull(str_dbcc_spid,'') as str_dbcc_spid
			,	isnull(str_dbcc_blocked,'') as str_dbcc_blocked
			,	lastwaittype
			,	open_tran
			,	cmd
			,	hostname
			,	dbid
			,	uid 
			,	cpu
			,	physical_io
			,	status
			,	waitresource
			--,	str_kill
			--,	isnull(str_dbcc_spid,'') as str_dbcc_spid
			--,	isnull(str_dbcc_blocked,'') as str_dbcc_blocked
		from #tmp_top_process
end
else
---------------------------------------------------------------------
-- ������ display
---------------------------------------------------------------------
	
begin
		select 
				spid 
			--,	blocked
			,	str_kill
			,	isnull(str_dbcc_spid,'') as str_dbcc_spid
			,	isnull(str_dbcc_blocked,'') as str_dbcc_blocked
			,	lastwaittype
			,	cmd
			,	hostname
			,	status
			--,	isnull(str_dbcc_spid,'') as str_dbcc_spid
			--,	isnull(str_dbcc_blocked,'') as str_dbcc_blocked
		from #tmp_top_process
end

		
		SET NOCOUNT OFF
end


