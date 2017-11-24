SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_replication_mon_delivery_article
* 작성정보    : 2011-01-06 by 최보라
* 관련페이지  : 
* 내용        : replication delivery article 처리
* 수정정보    : exec up_dba_replication_mon_delivery_article 'G'
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_replication_mon_delivery_article 
    @site   char(1) 
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/* USER DECLARE */
DECLARE @rowcount int, @i  int
DECLARE @article nvarchar(20), @publication nvarchar(20)
        ,@remain_transaction int, @article_id int, @msg varchar(80)
SET @rowcount = 0
set @i = 1


/* BODY */
select identity(int, 1, 1) as seq, al.publication, al.article_id, al.article, al.remain_transaction
	into #WORK_REPL_DELIVERY
from 
	(select p.publication, art.article_id, art.article, count(*) as remain_transaction
	from
	(select a.id ,a.name ,a.publisher_database_id ,a.publication  
		   , max(h.xact_seqno) as last_xact_seqno, max(time) as last_tt   
	from distribution.dbo.msdistribution_agents a with(nolock)  
	inner join distribution.dbo.Msdistribution_history  h with(nolock) on a.id  = h.agent_id   
	where h.xact_seqno > 0x0  
	group by a.id , a.name , a.publisher_database_id  ,a.publication  
	) as last
	  inner join distribution.dbo.MSpublications as p with (nolock) on p.publication = last.publication  
	  inner join distribution.dbo.msarticles as art with (nolock)  on art.publication_id = p.publication_id  
	  inner join distribution..msrepl_commands  as c with(nolock) on c.publisher_database_id = last.publisher_database_id
		and c.article_id = art.article_id and  c.xact_seqno >= last.last_xact_seqno
	group by p.publication, art.article_id, art.article ) as al
inner join DBA_REPL_DELIVERY_ARTICLE as dr with (nolock) on dr.article_id = al.article_id 
			and dr.publication = al.publication  and al.remain_transaction >= dr.standard_point

/*select identity(int, 1, 1) as seq, a.publication, a.article_id,a.article, max(a.remain_transaction) as remain_transaction
into #WORK_REPL_DELIVERY
from 
	(select p.publication, art.article_id, art.article,  --, sum(s.UndelivCmdsInDistDB)
		  -- count(c.xact_seqno) as remain_transaction
		 (select count(xact_seqno) from distribution..msrepl_commands with(nolock) 
			where publisher_database_id  = last.publisher_database_id 
			  and article_id = art.article_id 
			and xact_seqno >= last.last_xact_seqno
		 ) as remain_transaction
	from
		( select a.id ,a.name ,a.publisher_database_id ,a.publication
			, max(h.xact_seqno) as last_xact_seqno, max(time) as last_tt 
		from distribution.dbo.msdistribution_agents a with(nolock)
		inner join distribution.dbo.Msdistribution_history  h with(nolock) on a.id  = h.agent_id 
		where h.xact_seqno > 0x0
		group by a.id , a.name , a.publisher_database_id  ,a.publication 
		) as last
		inner join distribution.dbo.Msdistribution_history as h with (nolock) on h.agent_id = last.id and h.time = last.last_tt
		inner join distribution.dbo.MSpublications as p with (nolock) on p.publication = last.publication
		inner join distribution.dbo.msarticles as art with (nolock)  on art.publication_id = p.publication_id
		--left join distribution.dbo.MSdistribution_status  as s with (nolock) on s.agent_id = h.agent_id  
		--    and s.article_id = art.article_id
	) as a
  join DBA_REPL_DELIVERY_ARTICLE as dr with (nolock) on dr.article_id = a.article_id 
			and dr.publication = a.publication  and a.remain_transaction >= dr.standard_point
group by a.publication, a.article_id,a.article
order by a.article_id
*/

SET @rowcount = @@ROWCOUNT

IF @@rowcount !=0
BEGIN
    
    WHILE (@rowcount >= @i)
    BEGIN
        
        SELECT @article_id = article_id, @publication = publication
              ,@article =article, @remain_transaction = remain_transaction
        FROM #WORK_REPL_DELIVERY where seq = @i
        
        SET @i = @i + 1
        
        SET @msg = '[' + @site + '복제명령지연] 게시:' + @publication  + ',Article:' + @article 
             + '(' + convert(nvarchar(3),@article_id) + ') :'
             + convert(nvarchar(10),@remain_transaction) + '개'
             
        IF @site = 'G'
        BEGIN
            exec CUSTINFODB.SMS_ADMIN.DBO.UP_DBA_SEND_SHORT_MSG 'DBA' ,@msg    
        END
        ELSE IF @site = 'A'
        BEGIN
            declare @sms varchar(200)
            set @sms = 'sqlcmd -S epdb2 -E -Q"exec smsdb.dbo.up_dba_send_short_msg ''DBA'',''' + @msg + '''"'
			exec xp_cmdshell  @sms
            
        END
            
    END
    
    
END

DROP TABLE #WORK_REPL_DELIVERY
		

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO


SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_replication_mon_delivery
* 작성정보    : 2011-01-06 by 최보라
* 관련페이지  : 
* 내용        : replication delivery 처리
* 수정정보    :
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_replication_mon_delivery 
    @site   char(1) 
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/* USER DECLARE */
DECLARE @rowcount int, @i  int
DECLARE @subscriber_db nvarchar(20), @publication nvarchar(20)
        , @current_delivery_latency int, @agent_id int, @msg varchar(80)
SET @rowcount = 0
set @i = 1


/* BODY */
select identity(int, 1, 1) as seq,  age.id, age.publication, age.name,age.subscriber_db,
     his.current_delivery_latency ,
     his.runstatus,
     --case his.runstatus when 1 then '시작'  
     --     when 2 then '성공'  
     --     when 3 then '진행중'  
     --     when 4 then '유휴상태'  
     --     when 5 then '다시시도'  
     --     when 6 then '실패' end runstatus,  
    convert(nvarchar(19), time, 121) as time, 
    d.standard_point
    into #WORK_REPL_DELIVERY
from
    ( select agent_id, max(xact_seqno) as 'MaxTranNo', max(time) as 'Lasted'
      from distribution.dbo.Msdistribution_history with (nolock)
      where xact_seqno > 0x0 group by agent_id ) as last
    inner join distribution.dbo.Msdistribution_history  as his with (nolock) on  his.agent_id = last.agent_id 
        and his.time  = last.Lasted
    inner join Distribution.dbo.MSdistribution_agents as age with (nolock) 
        on age.id = his.agent_id
    inner join dbo.DBA_REPL_DELIVERY as d with (nolock) 
		on d.publication = age.publication and his.current_delivery_latency >=d.standard_point
order by his.current_delivery_latency desc

SET @rowcount = @@ROWCOUNT

IF @@rowcount !=0
BEGIN
    
    WHILE (@rowcount >= @i)
    BEGIN
        
        SELECT @agent_id = id, @publication = publication
              ,@subscriber_db =subscriber_db, @current_delivery_latency = current_delivery_latency
        FROM #WORK_REPL_DELIVERY where seq = @i
        
        SET @i = @i + 1
        
        SET @msg = '[' + @site + '복제지연] 게시:' + @publication  + ',구독:' + @subscriber_db + ',Agent:'
             + convert(varchar(2), @agent_id) + ':' + convert(nvarchar(10),@current_delivery_latency) + '(ms)'
        
        IF @site ='G'
        BEGIN
            exec CUSTINFODB.SMS_ADMIN.DBO.UP_DBA_SEND_SHORT_MSG 'DBA' ,@msg    
        END
        ELSE IF @site = 'A'
        BEGIN
            declare @sms varchar(200)
            set @sms = 'sqlcmd -S epdb2 -E -Q"exec smsdb.dbo.up_dba_send_short_msg ''DBA'',''' + @msg + '''"'
			exec xp_cmdshell  @sms
        END
            
    END
    
    
END

DROP TABLE #WORK_REPL_DELIVERY
		

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_replication_mon_delivery_all
* 작성정보    : 2011-01-06 by 최보라
* 관련페이지  : 
* 내용        : replication delivery article 처리
* 수정정보    : exec up_dba_replication_mon_delivery_all 'A', 3000
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_replication_mon_delivery_all 
    @site   char(1) ,
    @standard_point int
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/* USER DECLARE */
DECLARE @rowcount int, @i  int
DECLARE @article nvarchar(20), @publication nvarchar(20)
        ,@remain_transaction int, @article_id int, @msg varchar(80)
SET @rowcount = 0
set @i = 1


/* BODY */
select identity(int, 1, 1) as seq ,c.publication, count(*) as remain_transaction
into #WORK_REPL_DELIVERY
from
   (select agent_id, max(xact_seqno) as 'MaxTranNo', max(time) as 'Lasted'
     from distribution.dbo.Msdistribution_history with (nolock)
     where xact_seqno > 0x0  and time > DATEADD(dd, -1, getdate()) group by agent_id 
    ) as a
join distribution.dbo.msdistribution_agents c with(nolock)  on a.agent_id = c.id
join distribution.dbo.MSrepl_commands d with(nolock) on d.publisher_database_id=c.publisher_database_id
where d.xact_seqno > a.MaxTranNo 
group by c.publication

SET @rowcount = @@ROWCOUNT

IF @@rowcount !=0
BEGIN
    
    WHILE (@rowcount >= @i)
    BEGIN
        
        SELECT @publication = publication
              ,@remain_transaction = remain_transaction
        FROM #WORK_REPL_DELIVERY where seq = @i 
        
        SET @i = @i + 1
        
        IF @remain_transaction > @standard_point
        begin
            SET @msg = '[' + @site + '복제명령지연] 게시:' + @publication  + ',Article:' + @article 
                 + '(' + convert(nvarchar(3),@article_id) + ') :'
                 + convert(nvarchar(10),@remain_transaction) + '개'
           -- exec epdb2.smsdb.dbo.up_dba_send_short_msg 'DBA' ,@msg    
        end
    END
    
    
END

DROP TABLE #WORK_REPL_DELIVERY
		

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
