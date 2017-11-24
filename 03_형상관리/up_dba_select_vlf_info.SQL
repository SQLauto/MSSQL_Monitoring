/*************************************************************************  
* 프로시저명  : dbo.up_dba_select_vlf_info
* 작성정보     : 2010-02-17 by 노상국
* 관련패키지  : 
* 내용           : VLF 정보를 select * from dbo.vlfcnt_working 에 담기
* 수정정보     : sql2000, DB online인것만 조사하도록 수정
* 실행 예시    : dbo.up_dba_select_vlf_info 1, 1

CREATE TABLE [dbo].[vlfcnt_working](	[dbname] [nvarchar](128) NULL,	[vlf_count] [int] NULL,	
[stat2_count] [int] NULL,	[server_id] [int] NULL,	[instance_id] [int] NULL) 

**************************************************************************/  
create proc dbo.up_dba_select_vlf_info
@server_id int,
@instance_id int

as


/* COMMON DECLARE */
begin

SET NOCOUNT ON
SET FMTONLY OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


/* USER DECLARE */

declare @version int
declare @idx int, @cnt int
declare @dbname		varchar(50)
declare @dbstatus		varchar(30)
declare @command		varchar(8000) 

SET @version =  convert(int, left( convert(nvarchar(10), serverproperty('productversion')), 1)) --sql 버젼 확인

/* BODY */

		declare @tbl_dbname table ( seq int identity(1, 1) primary key , dbname nvarchar(128) )  --db 명 저장 테이블 변수 선언



		if @version < 9  --sql2000
			begin
				insert into @tbl_dbname(dbname) select name from master..sysdatabases with(nolock)  where dbid > 4 order by dbid;
			end
		else						--sql2005
			begin
				insert into @tbl_dbname(dbname) select name from sys.databases with(nolock) where state_desc = 'ONLINE' and database_id > 4 order by database_id;
			end




--		declare @vlfcnt table ( dbname nvarchar(128), vlf_count int, stat2_count int)


		if exists (    select  * from tempdb.dbo.sysobjects o  where o.xtype in ('U')    and o.id = object_id(N'tempdb..#vlftemp'))
		DROP TABLE #vlftemp;

		create table #vlftemp(   -- DB별 dbcc info() 실행한 결과를 임시 저장하는 테이블
							fileid bigint ,
							filesize bigint ,
							startoffset bigint,
							fseqno bigint ,
							status bigint ,
							parity bigint ,
							createLSN varchar(100)
						)
	
		select @cnt = count(*) from @tbl_dbname
		set @idx = 1

		truncate table dbo.vlfcnt_working  --working 테이블 truncate

		while (@idx <= @cnt)
		begin
				select @dbname = dbname from @tbl_dbname where seq = @idx

			    select @dbstatus =convert(nvarchar(128), DatabasePropertyEx(@dbname, 'Status'), 1) -- online 상태인지 확인하기
				if (@dbstatus = 'ONLINE')
					begin
						set @command = 'insert into #vlftemp execute(''dbcc loginfo(' + @dbname+')'')'

						--print @command
						execute(@command)
						declare @cnt1 int , @cnt2 int 
						select @cnt1 = count(*)
						from #vlftemp with(nolock)

						select @cnt2 = count(*)
						from #vlftemp with(nolock)
						where status = 2
						
						

						insert into dbo.vlfcnt_working(server_id, instance_id, dbname , vlf_count , stat2_count)
						values(@server_id, @instance_id, @dbname, @cnt1 , @cnt2)
--
--						insert into @vlfcnt(dbname , vlf_count , stat2_count)
--						values(@dbname, @cnt1 , @cnt2)
						
						truncate table #vlftemp

				end
				set @idx = @idx +1
			    
				
				
		end
		
--	select @server_id as server_id, @instance_id as instanceid, dbname, vlf_count, stat2_count from @vlfcnt order by dbname

return

end					



																	


