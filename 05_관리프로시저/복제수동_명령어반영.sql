
select a.agent_id, c.publication, sum(d.DelivCmdsInDistDB) as '배포된 명령수', sum(d.UndelivCmdsInDistDB) as '남은배포명령수cnt', max(a.delivery_rate) as delivery_rate
	, convert(varchar, max(a.current_delivery_latency)/60000)+' min '
	 + convert(varchar,(max(a.current_delivery_latency)%60000/1000))+' sec'+'('+convert(varchar, max(a.current_delivery_latency)/1000)+' sec)' as [대기시간]
	 ,max(a.xact_seqno) as xact_seqno
from
 ( select rank() over ( partition by agent_id order by time  desc) as r, 
	agent_id, xact_seqno, delivery_rate, current_delivery_latency from  distribution.dbo.Msdistribution_history  with(nolock) 
   ) as a
join msdistribution_agents c with(nolock)  on a.agent_id = c.id  and a.r =1
join MSdistribution_status d with(nolock)  on c.id = d.agent_id
--join MSrepl_commands d with(nolock) on d.publisher_database_id=c.publisher_database_id
where c.publication = 'REPLTIGER_GOODS2'
group by a.agent_id,c.publication
go

SElect top 5 * from tmp_bochoi_REPLTIGER_GOODS2_20171120 where xact_seqno>0x00579DF9000A5A170001000000000000 order by seq


declare @xact_seqno varbinary(16)

select  @xact_seqno = max(a.xact_seqno)
from
 ( select rank() over ( partition by agent_id order by time  desc) as r, 
	agent_id, xact_seqno, delivery_rate, current_delivery_latency from  distribution.dbo.Msdistribution_history  with(nolock) 
   ) as a
join msdistribution_agents c with(nolock)  on a.agent_id = c.id  and a.r =1
join MSdistribution_status d with(nolock)  on c.id = d.agent_id
--join MSrepl_commands d with(nolock) on d.publisher_database_id=c.publisher_database_id
where c.publication = 'REPLTIGER_GOODS2'
group by a.agent_id,c.publication


select   identity(int,1,1) as seq , art.publication_id, art.article, a.*  into tmp_bochoi_REPLTIGER_GOODS2_20171120
from MSrepl_commands  as a with(nolock) 
	join distribution.dbo.msarticles as art with (nolock)  on art.publication_id = 12   and a.article_id = art.article_id
where publisher_database_id = 1
	and xact_seqno >@xact_seqno 
	and a.article_id in ( 92,93, 94)
order by xact_seqno, command_id



create clustered index cidx__tmp_bochoi_REPLTIGER_GOODS2_20171120 on tmp_bochoi_REPLTIGER_GOODS2_20171120 ( seq) 


/*
select   TOP 10  art.publication_id, art.article, a.*  
from MSrepl_commands  as a with(nolock) 
	join distribution.dbo.msarticles as art with (nolock)  on art.publication_id = 12   and a.article_id = art.article_id
where publisher_database_id = 1
	AND XACT_SEQNO>0x00579E0000098BA80001000000000000
ORDER BY XACT_SEQNO
*/


select top 1 *  from tmp_bochoi_REPLTIGER_GOODS2_20171120 order by seq
-- @min_xact_seqno = 0x00579DEB0009EC640014

select top 1 *  from tmp_bochoi_REPLTIGER_GOODS2_20171120 order by seq desc
-- @max_xact_seqno = 0x00579E5F000BE07A0001

/**************************명령문 알아내기  ***********************************/

declare @i int , @max_xact_seqno  varbinary(16), @min_xact_seqno varbinary(16)
declare @min_xact_seqno_nchar nchar(22), @max_xact_seqno_nchar nchar(22)
declare @article_id int
set @i =169404
set nocount on


--create table tmp_bochoi_rep_log_20171120
--(	seq int,
    
--	min_xact_seqno varbinary(16), 
--	max_xact_seqno varbinary(16),
--	article_id int,
--	row_count int,
--	ins_date datetime
--)


--CREATE TABLE TMP_BOCHOI_REPLTIGER_GOODS2_COMMAND_20171120
--( 
--seq int   IDENTITY (1 , 1)  NOT NULL   , 
--xact_seqno varbinary    NULL   , 
--originator_srvname sysname    NULL   , 
--originator_db sysname    NULL   , 
--article_id int    NULL   , 
--type int    NULL   , 
--partial_command bit    NULL   , 
--hashkey bit    NULL   , 
--originator_publication_id int    NULL   , 
--originator_db_version int    NULL   , 
--originator_lsn varbinary    NULL   , 
--command nvarchar (1024)   NULL   , 
--command_id int    NULL   , 
--RET_CODE int    NULL   , 
--END_DATE datetime    NULL   , 
--command_type int    NULL   , 
--command2 nvarchar (2048)   NULL  
--)  ON [PRIMARY]
--GO
--ALTER TABLE TMP_BOCHOI_REPLTIGER_GOODS2_COMMAND_20171120 ADD CONSTRAINT PK__TMP_BOCH__DDDFBCBE7300926B primary key clustered ([seq] ASC ) ON [PRIMARY] 
--GO


while (@i <= 9681289 )
begin

   select @min_xact_seqno =  min(xact_seqno),  @max_xact_seqno = max(xact_seqno)
   from tmp_bochoi_REPLTIGER_GOODS2_20171120
   where seq >= @i and   seq < @i + 20000

   --select @min_xact_seqno, @max_xact_seqno
   select   @min_xact_seqno_nchar = convert(nchar(22), @min_xact_seqno,1),  @max_xact_seqno_nchar =convert(nchar(22), @max_xact_seqno,1)
   select @min_xact_seqno_nchar, @max_xact_seqno_nchar


   DECLARE vendor_cursor CURSOR FOR 
   select distinct  article_id
   from tmp_bochoi_REPLTIGER_GOODS2_20171120
   where xact_seqno >= @min_xact_seqno and   xact_seqno <= @max_xact_seqno

	OPEN vendor_cursor
	FETCH NEXT FROM vendor_cursor 
	INTO @article_id

	 WHILE @@FETCH_STATUS = 0
	  BEGIN

		insert into TMP_BOCHOI_REPLTIGER_GOODS2_COMMAND_20171120
		(
	xact_seqno
	,originator_srvname
	,originator_db
	,article_id
	,type
	,partial_command
	,hashkey
	,originator_publication_id
	,originator_db_version
	,originator_lsn
	,command
	,command_id
)
		exec sp_browsereplcmds
			-- @xact_seqno_start  = '0x00579DEB0009EC640014'
			--,@xact_seqno_end  = '0x00579DEB0009F1A50003'
			 @xact_seqno_start  = @min_xact_seqno_nchar
			,@xact_seqno_end  = @max_xact_seqno_nchar
			,@publisher_database_id = 1
			,@article_id   = @article_id


		 insert into tmp_bochoi_rep_log_20171120
		 select @i, @min_xact_seqno, @max_xact_seqno, @article_id, @@ROWCOUNT, GETDATE()


	  FETCH NEXT FROM vendor_cursor 
      INTO @article_id
	  END
	  
	  CLOSE vendor_cursor;
      DEALLOCATE vendor_cursor;

	SET @i =@i + 20000


end



update TMP_BOCHOI_REPLTIGER_GOODS2_COMMAND_20171120  set command_type  = case when command like '%insert%' then 1  when case  '%update%' then 2  when case '%delete%' then 3 end


update TMP_BOCHOI_REPLTIGER_GOODS2_COMMAND_20171120 set command2 = 
				case when charindex('2017-11', command) > 0  and isdate(substring(command, charindex('2017-11', command), 23)) = 1   then 
					replace(command, substring(command, charindex('2017-11', command), 23), ''''+ substring(command, charindex('2017-11', command), 23) + '''' )
				when charindex('2017-11', command) > 0  and isdate(substring(command, charindex('2017-11', command), 19)) = 1 then
					replace(command, substring(command, charindex('2017-11', command), 19), ''''+ substring(command, charindex('2017-11', command), 19) + '''' )
				else command end 

update TMP_BOCHOI_REPLTIGER_GOODS2_COMMAND_20171120  
	set command2 = 'SET IDENTITY_INSERT ' +  M.article + ' ON; ' + command2 +  ' SET IDENTITY_INSERT ' +  m.article + ' OFF;' + CHAR(10)
from msarticles as  m 
	join TMP_BOCHOI_REPLTIGER_GOODS2_COMMAND_20171120 as t on m.article_id = t.article_id
where T.command_type =1


-- 검증 필요 

select top 10 COMMAND2, * from TMP_BOCHOI_REPLTIGER_GOODS2_COMMAND_20171120 with(nolock) where command_type =1
select top 10  command2, command , *
from TMP_BOCHOI_REPLTIGER_GOODS2_COMMAND_20171120 with(nolock)
where charindex('2017-11', command)  = 0


select top 10  command2, command , *
from TMP_BOCHOI_REPLTIGER_GOODS2_COMMAND_20171120 WITH(NOLOCK)
where charindex('2017-11', command)  > 0  and isdate(substring(command, charindex('2017-11', command), 19)) = 1



/**************** 타켓 반영하기 *******************************/


SET NOCOUNT ON
DECLARE @START_I  INT , @END_I  INT 
DECLARE @ERROR INT, @XACT_SEQNO VARBINARY(16), @XACT_SEQNO_before VARBINARY(16)
SELECT TOP 1 @START_I = SEQ FROM TMP_BOCHOI_REPLTIGER_GOODS2_COMMAND_20171120 WITH(NOLOCK) WHERE RET_CODE  IS NULL ORDER BY SEQ ASC
SELECT @END_I = MAX(SEQ) FROM TMP_BOCHOI_REPLTIGER_GOODS2_COMMAND_20171120 WITH(NOLOCK) 

DECLARE @COMMAND NVARCHAR(4000)

WHILE (@START_I <= @END_I)
BEGIN
	
SELECT  @COMMAND = COMMAND2,  @XACT_SEQNO = XACT_SEQNO FROM TMP_BOCHOI_REPLTIGER_GOODS2_COMMAND_20171120 WITH(NOLOCK)
WHERE SEQ =@START_I 
PRINT @COMMAND
PRINT @XACT_SEQNO

IF @I =1
	SET @XACT_SEQNO_before =@XACT_SEQNO

BEGIN TRY
	EXEC SP_EXECUTESQL @COMMAND

	UPDATE TMP_BOCHOI_REPLTIGER_GOODS2_COMMAND_20171120 
	SET RET_CODE =0, END_DATE = GETDATE()
	WHERE SEQ =@START_I
		

  IF @XACT_SEQNO_before != @XACT_SEQNO
  BEGIN
		EXEC SP_SETSUBSCRIPTIONXACTSEQNO @PUBLISHER='GMKT2008'
		, @PUBLISHER_DB='TIGER'
		, @PUBLICATION='REPLTIGER_GOODS2'
		, @XACT_SEQNO = @XACT_SEQNO_before -- 한트랜잭션에 여러 명령어가 있다. 이렇게 새로운 것으로 바뀔 때 완료된것을 지워야 한다. 
  
  END


END TRY
BEGIN CATCH
	SET @ERROR = ERROR_NUMBER()
	IF  @ERROR =2627-- PK 에러
	BEGIN
		UPDATE TMP_BOCHOI_REPLTIGER_GOODS2_COMMAND_20171120 
		SET RET_CODE =@ERROR, END_DATE = GETDATE()
		WHERE SEQ =@START_I


	END
	ELSE 
	BEGIN
		UPDATE TMP_BOCHOI_REPLTIGER_GOODS2_COMMAND_20171120 
		SET RET_CODE =@ERROR, END_DATE = GETDATE()
		WHERE SEQ =@START_I

		BREAK;
	END
END CATCH



SET @START_I =@START_I + 1
SET @XACT_SEQNO_before =@XACT_SEQNO

	 
END





-- 모니터링 쿼리 
with mon as (
select count(*) as total
	, datediff(mi, MIN(end_date), max(isnull(end_date,getdate()))) as dur_mi
	, max(end_date) as [완료]
	, sum(case when ret_code is not null then 1 else 0 end) / datediff(ss, MIN(end_date), max(isnull(end_date,getdate()))) *60  as [분당건수]
	, sum(case when ret_code is not null then 1 else 0 end) as success_cnt
	, sum(case when ret_code !=0 then 1 else 0 end) as error_cnt
	, sum(case when ret_code is null then 1 else 0 end) as remain_cnt
	,sum(case when ret_code is null then 1 else 0 end)  / (sum(case when ret_code is not null then 1 else 0 end) / datediff(mi, MIN(end_date), max(isnull(end_date,getdate()))) ) as [완료예상분]
from dba.dbo.TMP_BOCHOI_REPLTIGER_GOODS2_COMMAND_20171120 with(nolock) 
)
select *, dateadd(mi, mon.[완료예상분], [완료]) as [완료예상시간] from mon







/***********************  명령어 skip *****************************/
EXEC sp_setsubscriptionxactseqno @publisher='GMKT2008'
, @publisher_db='TIGER'
, @publication='REPLTIGER_GOODS2'
, @xact_seqno = 0x004DD835000003710001  ---> 위해서 나온 Xact_seq_no 지정 해야함. 지정하지 않으면 모두 skip 하기 때문에 조심해야 함



