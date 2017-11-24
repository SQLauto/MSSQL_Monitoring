SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_monitroing_querystat 
* 작성정보    : 2010-02-25 by choi bo ra
* 관련페이지  :  
* 내용        : 2000용 syscacheobjects 적재
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_monitroing_querystat
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
INSERT INTO dbo.MONITOR_QUERYSTAT
 ( reg_dt, bucketid,cacheobjtype,objtype,objid,dbid, dbname,
    usecounts,pagesused,sql)
   
select getdate() as reg_dt,
    bucketid, cacheobjtype, objtype, objid, dbid, db_name(dbid) as dbname,
    sum(usecounts) as usecounts,sum(pagesused) as pagesused, max(sql) as sql
from master.dbo.syscacheobjects with (nolock)
where dbid   >= 4  --and bucketid = 28867
group by bucketid,cacheobjtype,objtype,objid,dbid,db_name(dbid)
order by usecounts desc

RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO



/*************************************************************************  
* 프로시저명  : dbo.up_dba_monitroing_querystat_term 
* 작성정보    : 2010-02-25 by choi bo ra
* 관련페이지  :  
* 내용        : 2000용 syscacheobjects 비교
* 수정정보    :
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_monitroing_querystat_term
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @max_date datetime, @now datetime  
/* BODY */

  
select @max_date = max(reg_dt) from MONITOR_QUERYSTAT with (nolock)  

  
select 
    reg_dt,
    bucketid, cacheobjtype, objtype, objid, dbid, db_name(dbid) as dbname,
    usecounts, pagesused, sql
into #querystat_to   
from MONITOR_QUERYSTAT with (nolock)  
where reg_dt = @max_date  

select @max_date = max(reg_dt) from MONITOR_QUERYSTAT with (nolock) where reg_dt < @max_date  
select 
    reg_dt,
    bucketid, cacheobjtype, objtype, objid, dbid, db_name(dbid) as dbname,
    usecounts, pagesused, sql
into #querystat_from  
from MONITOR_QUERYSTAT with (nolock)  
where reg_dt = @max_date  

set @now = getdate()

INSERT MONITOR_QUERYSTAT_TERM
    (reg_dt, from_dt, to_dt, bucketid, cacheobjtype,objtype, dbid, dbname, objid, sql, min_usecounts, min_pagesused)
SELECT @now as reg_dt, f.reg_dt as  from_dt, t.reg_dt as to_dt
        , t.bucketid, t.cacheobjtype,t.objtype,t.dbid, t.dbname, t.objid, t.sql
        , round((t.usecounts - isnull(f.usecounts, 0)) * 60 /datediff(ss, f.reg_dt, t.reg_dt),0) as min_usecounts
        , round((t.pagesused - isnull(f.pagesused, 0)) * 60 /datediff(ss, f.reg_dt, t.reg_dt),0) as min_pagesused
FROM #querystat_to as t with (nolock)
    left join #querystat_from as f with (nolock)  
        on  t.bucketid = f.bucketid and t.cacheobjtype= f.cacheobjtype
            and t.objtype  = f.objtype and t.objid = f.objid and t.sql = f.sql
WHERE (t.usecounts - f.usecounts) > 0
ORDER BY round((t.usecounts - isnull(f.usecounts, 0)) * 60 /datediff(ss, f.reg_dt, t.reg_dt),0) desc

drop table #querystat_from
drop table #querystat_to

RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO


/*************************************************************************  
* 프로시저명  : dbo.up_dba_monitroing_querystat_del 
* 작성정보    : 2010-02-25 by choi bo ra
* 관련페이지  :  
* 내용        : 2000용 syscacheobjects 비교
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_monitroing_querystat_del
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @del_dt  datetime, @row_count int
/* BODY */

set @del_dt = convert(varchar(10),dateadd(dd, -10, getdate()), 121)
set @row_count = 0

SET ROWCOUNT 500
while( 1=1)
begin
     delete MONITOR_QUERYSTAT where  reg_dt < @del_dt
     
     SET @rowcunt = @@ROWCOUNT
     if @row_count < 500 break
     
end
      
while( 1=1)
begin
     delete MONITOR_QUERYSTAT_TERM where  reg_dt < @del_dt
     
     SET @rowcunt = @@ROWCOUNT
     if @row_count < 500 break
     
end

SET ROWCOUNT 0
    

RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****************************************
    TABLE 정보
****************************************/
CREATE TABLE MONITOR_QUERYSTAT
(
    seq_no      int  identity(1,1) not null,
    reg_dt      datetime not null,
    bucketid    int     null,
    cacheobjtype    nvarchar(17)    null,
    objtype         nvarchar(8) null,
    objid           int null,
    dbid            smallint   null,
    dbname          nvarchar(100) null,
    usecounts       int null,
    pagesused       int null,
    sql             nvarchar(3900) null,
    CONSTRAINT PK__MONITOR_QUERYSTAT__SEQ_NO PRIMARY KEY NONCLUSTERED (seq_no)
  )
  
CREATE INDEX CIDX__MONITOR_QUERYSTAT__REG_DT  ON MONITOR_QUERYSTAT (REG_DT ) 
;

CREATE TABLE MONITOR_QUERYSTAT_TERM
(
    seq_no      int  identity(1,1) not null,
    reg_dt      datetime not null,
    from_dt     datetime not null,
    to_dt       datetime not null,
    bucketid    int     null,
    cacheobjtype    nvarchar(17)    null,
    objtype         nvarchar(8) null,
    dbid            smallint   null,
    dbname          nvarchar(100) null,
    objid           int null,
    sql             nvarchar(3900) null,
    min_usecounts       int null,
    min_pagesused       int null,
    CONSTRAINT PK__MONITOR_QUERYSTAT_TERM__SEQ_NO PRIMARY KEY NONCLUSTERED (seq_no)
  )
  
CREATE INDEX CIDX__MONITOR_QUERYSTAT_TERM__REG_DT  ON MONITOR_QUERYSTAT (REG_DT desc) 
;