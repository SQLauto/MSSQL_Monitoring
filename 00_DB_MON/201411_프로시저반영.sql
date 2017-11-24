USE DBMON
GO

drop proc [UP_MON_COLLECT_QUERY_STATS_TOTAL_V3]
go

/*********************************  *****************************************************/
/* 2010-08-25 10:52 
 2014-10-27 BY CHOI BO RA  TOTAL_SUM  
*/
CREATE PROCEDURE [DBO].[UP_MON_COLLECT_QUERY_STATS_TOTAL_V3]  
AS  
SET NOCOUNT ON  
  
EXEC UP_SWITCH_PARTITION @TABLE_NAME = 'DB_MON_QUERY_STATS_TOTAL_V3', @COLUMN_NAME = 'REG_DATE'   
EXEC UP_SWITCH_PARTITION @TABLE_NAME = 'DB_MON_QUERY_STATS_TOTAL_CPU', @COLUMN_NAME = 'REG_DATE'    
  
DECLARE @REG_DATE DATETIME  
DECLARE @ERROR_NUM INT, @ERROR_MESSAGE SYSNAME  
SET @REG_DATE = GETDATE() 

BEGIN TRY

   INSERT INTO DB_MON_QUERY_STATS_TOTAL_CPU
	( REG_DATE, CPU_TOTAL)
   SELECT @REG_DATE,
	 SUM(TOTAL_WORKER_TIME) 
   FROM SYS.DM_EXEC_QUERY_STATS  
	WHERE SUBSTRING(SQL_HANDLE, 3, 1) <> 0XFF	

 
--  
INSERT DB_MON_QUERY_STATS_TOTAL_V3  
 (REG_DATE, TYPE,PLAN_HANDLE, STATEMENT_START, STATEMENT_END, DB_ID, OBJECT_ID, SET_OPTIONS, CREATE_DATE,  
  CNT, CPU, WRITES, READS, DURATION, OBJECT_NAME, QUERY_TEXT,sql_handle)   
SELECT 
	 @reg_date, 
	 CASE WHEN CONVERT(VARBINARY, LEFT(SQL_HANDLE, 1)) = 0X02 THEN 'P' ELSE 'S' END TYPE,
	 QS.PLAN_HANDLE,   
	 QS.STATEMENT_START_OFFSET  AS STATEMENT_START,   
	 QS.STATEMENT_END_OFFSET AS STATEMENT_END,   
	 QT.DBID,   
	 QT.OBJECTID,   
	 (SELECT CONVERT(INT, VALUE) FROM SYS.DM_EXEC_PLAN_ATTRIBUTES(QS.PLAN_HANDLE) WHERE ATTRIBUTE = 'SET_OPTIONS') AS SET_OPTIONS,   
	 QS.CREATION_TIME,  
	 QS.EXECUTION_COUNT AS CNT,  
	 QS.TOTAL_WORKER_TIME AS CPU,  
	 QS.TOTAL_LOGICAL_WRITES AS WRITES,  
	 QS.TOTAL_LOGICAL_READS AS READS,  
	 QS.TOTAL_ELAPSED_TIME AS DURATION, 
	 OBJECT_NAME(QT.OBJECTID, QT.DBID)  AS OBJECT_NAME, 
	CASE WHEN CONVERT(VARBINARY, LEFT(SQL_HANDLE, 1)) = 0X02 THEN
			CASE WHEN LEN(QT.TEXT) < (STATEMENT_END_OFFSET / 2) + 1 THEN QT.TEXT
			WHEN SUBSTRING(QT.TEXT, (STATEMENT_START_OFFSET/2), 2) LIKE N'[A-ZA-Z0-9][A-ZA-Z0-9]' THEN QT.TEXT
			ELSE
				CASE
					WHEN STATEMENT_START_OFFSET > 0 THEN
						SUBSTRING
						(	QT.TEXT,((STATEMENT_START_OFFSET/2) + 1),
							(
								CASE
									WHEN STATEMENT_END_OFFSET = -1 THEN 2147483647
									ELSE ((STATEMENT_END_OFFSET - STATEMENT_START_OFFSET)/2) + 1
								END
							)
						)
					ELSE RTRIM(LTRIM(QT.TEXT))
				END
			END
		ELSE NULL END as query_text, 
		QS.SQL_HANDLE
FROM SYS.DM_EXEC_QUERY_STATS   AS QS 
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(QS.PLAN_HANDLE)  AS QT 
WHERE SUBSTRING(QS.SQL_HANDLE, 3, 1) <> 0XFF



--   UPDATE
UPDATE DB_MON_QUERY_STATS_TOTAL_V3
	SET OBJECT_NAME = SUBSTRING(QUERY_TEXT, CHARINDEX('--SP::',QUERY_TEXT)+6, CHARINDEX('::SP', QUERY_TEXT)-6-CHARINDEX('--SP::',QUERY_TEXT))
WHERE REG_DATE = @REG_DATE
	AND TYPE = 'P'
	AND CHARINDEX('::SP', QUERY_TEXT) > 0 
	AND query_text not like '%query_text%'  --    .



/*
INSERT DB_MON_QUERY_STATS_TOTAL_V3  
 (REG_DATE, PLAN_HANDLE, STATEMENT_START, STATEMENT_END, DB_ID, OBJECT_ID, SET_OPTIONS, CREATE_DATE,  
  CNT, CPU, WRITES, READS, DURATION, OBJECT_NAME, QUERY_TEXT)  
SELECT   
 @REG_DATE,  
 QS.PLAN_HANDLE,   
 QS.STATEMENT_START,   
 QS.STATEMENT_END,   
 ISNULL(QT.DBID,-1) AS DB_ID,   
 QT.OBJECTID,   
 (SELECT CONVERT(INT, VALUE) FROM SYS.DM_EXEC_PLAN_ATTRIBUTES(QS.PLAN_HANDLE) WHERE ATTRIBUTE = 'SET_OPTIONS') AS SET_OPTIONS,   
 QS.CREATION_TIME,  
 QS.CNT,  
 QS.CPU,  
 QS.WRITES,  
 QS.READS,  
 QS.DURATION  ,
 SUBSTRING(QT.TEXT, CHARINDEX('--SP::',QT.TEXT)+6, CHARINDEX('::SP', QT.TEXT)-6-CHARINDEX('--SP::',QT.TEXT)) AS OBJECT_NAME 
,CASE WHEN CONVERT(VARBINARY, LEFT(SQL_HANDLE, 1)) = 0X02 THEN 
		SUBSTRING(QT.TEXT, CHARINDEX('SELECT --SP::',QT.TEXT), LEN(QT.TEXT))
 ELSE NULL 
 END AS QUERY_TEXT
FROM (   
 SELECT   
    SQL_HANDLE
  , PLAN_HANDLE   
  , STATEMENT_START_OFFSET AS STATEMENT_START  
  , STATEMENT_END_OFFSET AS STATEMENT_END  
  , CREATION_TIME  
  , EXECUTION_COUNT AS CNT  
  , TOTAL_WORKER_TIME AS CPU  
  , TOTAL_LOGICAL_WRITES AS WRITES  
  , TOTAL_LOGICAL_READS AS READS  
  , TOTAL_ELAPSED_TIME AS DURATION   
 FROM SYS.DM_EXEC_QUERY_STATS  
 WHERE CONVERT(VARBINARY, LEFT(SQL_HANDLE, 1)) IN ( 0X02)
    AND SUBSTRING(SQL_HANDLE, 3, 1) <> 0XFF			-- SYSTEM   
) QS  
CROSS APPLY SYS.DM_EXEC_SQL_TEXT(QS.PLAN_HANDLE) AS QT  
WHERE (CONVERT(VARBINARY, LEFT(SQL_HANDLE, 1)) = 0X02 AND QT.TEXT IS NOT NULL AND QT.TEXT LIKE '%SP::%' AND QT.TEXT LIKE '%::SP%')
*/

END TRY
BEGIN CATCH
	SET @ERROR_NUM = ERROR_NUMBER() 
	SET @ERROR_MESSAGE = ERROR_MESSAGE()

	RAISERROR (N'UP_MON_COLLECT_QUERY_STATS_TOTAL_V3- NUM: %d , MESSAGE: %s', -- MESSAGE TEXT.
           16, 
           1, 
           @ERROR_NUM, 
           @ERROR_MESSAGE);

END CATCH
go

drop proc UP_MON_COLLECT_QUERY_STATS_V3
go
/* 2014-10-28  total_sum_cpu  , wirte   */
CREATE PROCEDURE [dbo].[UP_MON_COLLECT_QUERY_STATS_V3]          
 @min_cpu bigint = 1000          
AS          
SET NOCOUNT ON          
          
exec up_switch_partition @table_name = 'DB_MON_QUERY_STATS_V3', @column_name = 'REG_DATE'    
          
declare @from_date datetime, @to_date datetime, @reg_date datetime                
declare @to_cpu bigint, @from_cpu bigint, @worker_time_min money              
declare @term int, @cpu_term numeric(18, 2)              
                
select @to_date = max(reg_date) from DB_MON_QUERY_STATS_TOTAL_V3 with (nolock)        
        
if exists (select top 1 * from DB_MON_QUERY_STATS_V3 (nolock) where reg_date = @to_date)        
begin        
 print '   .!!!'        
 return        
end        
        
select @TO_CPU = CPU_TOTAL               
from DB_MON_QUERY_STATS_TOTAL_CPU with (nolock)               
where reg_date = @TO_DATE               
                
select db_id, object_name, object_id, plan_handle, statement_start, statement_end, set_options, create_date
, cnt, cpu, writes, reads, duration, query_text,type , sql_handle
into #query_stats_to          
from DB_MON_QUERY_STATS_TOTAL_V3 with (nolock)          
where reg_date = @to_date          
          
select @from_date = max(reg_date) from DB_MON_QUERY_STATS_TOTAL_V3 with (nolock) where reg_date < @to_date                


select @from_cpu = CPU_TOTAL               
from DB_MON_QUERY_STATS_TOTAL_CPU with (nolock)               
where reg_date = @from_date   

           
          
select plan_handle, statement_start, statement_end, set_options, create_date, cnt, cpu, writes, reads, duration    
into #query_stats_from          
from DB_MON_QUERY_STATS_TOTAL_V3 with (nolock)          
where reg_date = @from_date          
          
set @term = datediff(second, @from_date, @to_date)          
          
select @cpu_term = sum(a.cpu - isnull(b.cpu, 0))          
from #query_stats_to a with (nolock)           
 left join #query_stats_from b with (nolock)           
  on a.plan_handle = b.plan_handle and a.statement_start = b.statement_start and a.statement_end = b.statement_end          
          
insert DB_MON_QUERY_STATS_V3          
( reg_date,          
 from_date,          
 db_name,          
 object_name,
 type,         
 db_id,       
 object_id,        
 set_options,          
 statement_start,          
 statement_end,          
 create_date,          
 cnt_min,          
 cpu_rate,          
 cpu_min,          
 reads_min, 
 writes_min,         
 duration_min,          
 cpu_cnt,          
 reads_cnt, 
 writes_cnt,         
 duration_cnt,          
 term,          
 plan_handle,
 cnt_total,
 cpu_total,
 reads_total,
 writes_total,
 duration_total,
 query_text,
 sql_handle
 )          
select         
 reg_date,        
 from_date,        
 db_name,        
 case when object_name is null then '' else object_name end,
 type,
 db_id,       
 object_id,      
 set_options,        
 statement_start,        
 statement_end,        
 create_date,        
 case when term > 30 then cnt_gap * 60 / term else - 1 end as cnt_min,  
 convert(numeric(6, 2), cpu_gap * 100 / @cpu_term) as cpu_rate,        
 case when term > 30 then cpu_gap * 60 / term else -1 end as cpu_min,  
 case when term > 30 then reads_gap * 60 / term else - 1 end as reads_min,  
 case when term > 30 then writes_gap * 60 / term else - 1 end as writes_min, 
 case when term > 30 then duration_gap * 60 / term end as duration_min,  
 case when cnt_gap = 0 then -1 else cpu_gap / cnt_gap end cpu_cnt,        
 case when cnt_gap = 0 then -1 else reads_gap / cnt_gap end reads_cnt,
case when cnt_gap = 0 then -1 else writes_gap / cnt_gap end writes_cnt, 
 case when cnt_gap = 0 then -1 else duration_gap / cnt_gap end duraiton_cnt,        
 term,        
 plan_handle,
 cnt_gap,
 cpu_gap,
 reads_gap,
 writes_gap,
 duration_gap,
 query_text,
 sql_handle    
from         
(        
 select         
  @to_date as reg_date,        
  @from_date as from_date,         
  isnull(db_name(a.db_id), 'PREPARE') as db_name,        
  a.object_name,
  a.type,        
  a.db_id,       
  a.object_id,        
  a.set_options as set_options,        
  a.statement_start as statement_start,        
  a.statement_end as statement_end,        
  a.create_date as create_date,        
  a.cnt - isnull(b.cnt, 0) as cnt_gap,        
  a.cpu - isnull(b.cpu, 0) as cpu_gap,        
  a.reads - isnull(b.reads, 0) as reads_gap,   
  a.writes - isnull(b.writes, 0) as writes_gap,         
  a.duration - isnull(b.duration, 0) as duration_gap,        
  case when datediff(second, @from_date, a.create_date) <= 0 then @term else datediff(second, a.create_date, @to_date) end as term,        
  a.plan_handle,        
  a.query_text,
  a.sql_handle
 from #query_stats_to a with (nolock)         
  left join #query_stats_from b with (nolock)         
   on a.plan_handle = b.plan_handle and a.statement_start = b.statement_start and a.statement_end = b.statement_end and a.create_date = b.create_date        
 ) a        
where (cnt_gap <> 0 or cpu_gap <> 0)        
  and cpu_gap > @min_cpu * @term / 60        
order by cpu_gap desc        
          
drop table #query_stats_to          
drop table #query_stats_from 
go








/*************************************************************************  
* 	: dbo.[UP_MON_COLLECT_QUERY_PLAN_V3]
* 	: 2012-08-02 BY CHOI BO RA
* :  
* 		:  
* 	: PREPARED SQL   . DB_ID  .
**************************************************************************/
CREATE PROCEDURE [DBO].[UP_MON_COLLECT_QUERY_PLAN_V3]        
AS        
SET NOCOUNT ON        
        
DECLARE @REG_DATE DATETIME        
DECLARE @SEQ INT, @MAX INT        
DECLARE @PLAN_HANDLE VARBINARY(64), @STATEMENT_START INT, @STATEMENT_END INT, @CREATE_DATE DATETIME  
DECLARE @DB_ID SMALLINT     
DECLARE @OBJECT_NAME VARCHAR(255)   
        
DECLARE @PLAN_INFO TABLE (        
 SEQ INT IDENTITY(1, 1) PRIMARY KEY,        
 PLAN_HANDLE VARBINARY(64),        
 STATEMENT_START INT,        
 STATEMENT_END INT,        
 CREATE_DATE DATETIME,  
 DB_ID SMALLINT,
 OBJECT_NAME VARCHAR(255)   
)  
        
SELECT @REG_DATE = MAX(REG_DATE) FROM DB_MON_QUERY_STATS_V3 (NOLOCK)        
        
IF EXISTS (SELECT TOP 1 * FROM DB_MON_QUERY_PLAN_V3 (NOLOCK) WHERE REG_DATE = @REG_DATE)        
BEGIN        
 PRINT '   PLAN  !'        
 RETURN        
END        
        
INSERT @PLAN_INFO (PLAN_HANDLE, STATEMENT_START, STATEMENT_END, CREATE_DATE, DB_ID, OBJECT_NAME)        
SELECT PLAN_HANDLE, STATEMENT_START, STATEMENT_END, CREATE_DATE, DB_ID , OBJECT_NAME  
FROM DB_MON_QUERY_STATS_V3 WITH (NOLOCK)         
WHERE REG_DATE = @REG_DATE         
        
SELECT @SEQ = 1, @MAX = @@ROWCOUNT        
        
WHILE @SEQ <= @MAX        
BEGIN        
        
 SELECT @PLAN_HANDLE = PLAN_HANDLE,        
     @STATEMENT_START = STATEMENT_START,        
     @STATEMENT_END = STATEMENT_END,        
     @CREATE_DATE = CREATE_DATE,  
     @DB_ID = DB_ID,        
	 @OBJECT_NAME = OBJECT_NAME
 FROM @PLAN_INFO        
 WHERE SEQ = @SEQ        
         
 SET @SEQ = @SEQ + 1        
   
 IF @DB_ID < 5 CONTINUE  
         
 IF NOT EXISTS (        
  SELECT TOP 1 * FROM DBO.DB_MON_QUERY_PLAN_V3 (NOLOCK)         
  WHERE PLAN_HANDLE = @PLAN_HANDLE AND STATEMENT_START = @STATEMENT_START 
	AND STATEMENT_END = @STATEMENT_END AND CREATE_DATE = @CREATE_DATE)        
 BEGIN        
  
  BEGIN TRY
	  INSERT DB_MON_QUERY_PLAN_V3         
	   (PLAN_HANDLE, STATEMENT_START, STATEMENT_END, CREATE_DATE, SET_OPTIONS, DB_NAME, 
	   OBJECT_NAME, QUERY_PLAN, REG_DATE, UPD_DATE, LINE_START, LINE_END)        
	  SELECT         
		  @PLAN_HANDLE,        
		  @STATEMENT_START,        
		  @STATEMENT_END,        
		  @CREATE_DATE,        
		  0,        
		  DB_NAME(DBID) AS DB_NAME,         
		  OBJECT_NAME(OBJECTID, DBID) AS OBJECT_NAME,        
		  QUERY_PLAN,       
		  @REG_DATE,  
		  @REG_DATE,
		  F.LINE_START, F.LINE_END        
	  FROM SYS.DM_EXEC_TEXT_QUERY_PLAN(@PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END)
		OUTER APPLY DBO.FN_GETOBJECTLINE(@PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END) F    
	  WHERE (DBID >= 5  OR DBID IS NULL )
	       
  END TRY
  BEGIN CATCH		-- XML   (DEPTH  128   )
	  INSERT DB_MON_QUERY_PLAN_V3         
	   (PLAN_HANDLE, STATEMENT_START, STATEMENT_END, CREATE_DATE, SET_OPTIONS, DB_NAME, 
		OBJECT_NAME, QUERY_PLAN, REG_DATE, UPD_DATE, LINE_START, LINE_END)        
	  SELECT @PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END, @CREATE_DATE, 0, 
			 DB_NAME(DBID) AS DB_NAME,
			 @OBJECT_NAME,
			 NULL,
			 @REG_DATE,
			 @REG_DATE,
			 F.LINE_START, F.LINE_END
	  FROM SYS.DM_EXEC_TEXT_QUERY_PLAN(@PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END)      
	  	OUTER APPLY DBO.FN_GETOBJECTLINE(@PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END) F    
  END CATCH
        
 END        
 ELSE   
 BEGIN  
	 UPDATE DB_MON_QUERY_PLAN_V3  
	 SET UPD_DATE = @REG_DATE  
	 WHERE PLAN_HANDLE = @PLAN_HANDLE AND STATEMENT_START = @STATEMENT_START AND STATEMENT_END = @STATEMENT_END AND CREATE_DATE = @CREATE_DATE  
 END  
      
END 
GO

drop proc [up_mon_query_stats_object]
go

create PROCEDURE [dbo].[up_mon_query_stats_object]
 @object_name sysname = null,
 @date datetime = null,  
 @rowcount int = 20  
AS  
SET NOCOUNT ON  

declare @basedate datetime
declare @max int, @seq int
declare @statement_start int, @statement_end int, @set_options int

declare @object table (
	seq int identity(1, 1) primary key,
	statement_start int,
	statement_end int,
	set_options int
)

if @object_name is null
begin
	print '@object_name   !!!'
	return
end

if @date is null set @date =  getdate()  

select @basedate = max(reg_date) from db_mon_query_stats_v3 (nolock) 

insert @object (statement_start, statement_end, set_options)
select statement_start, statement_end, set_options
from db_mon_query_stats_v3 (nolock) 
where object_name = @object_name and reg_date = @basedate
order by statement_start

select @max = @@rowcount, @seq = 1

while @seq <= @max
begin
  
   select @statement_start = statement_start, @statement_end = statement_end, @set_options = set_options
   from @object
   where seq = @seq
   
   set @seq = @seq + 1
  
	select top (@rowcount)  
	s.db_name,  
	s.object_name,  
	s.reg_date as to_date,   
	s.type,
	s.term, 
	s.set_options,  
	p.line_start,  
	p.line_end,  
	s.cnt_min,  
	s.cpu_rate,  
	s.cpu_min,  
	s.reads_min,  
	s.duration_min,  
	s.cpu_cnt,  
	s.reads_cnt,  
	s.duration_cnt,  
	s.plan_handle,
	s.statement_start,
	s.statement_end,
	s.create_date,   	
	s.query_text,
	p.query_plan
	from dbo.db_mon_query_stats_v3 s (nolock)   
	left join  dbo.db_mon_query_plan_v3 p (nolock)  
	  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
--	outer apply dbo.fn_getobjectline(s.plan_handle, s.statement_start, s.statement_end) f  
	where s.reg_date <= @date and s.object_name = @object_name
	  and s.statement_start = @statement_start and s.statement_end = @statement_end and s.set_options = @set_options
	order by s.reg_date desc

end
go

drop proc up_mon_collect_query_stats_daily_v3
go

CREATE PROCEDURE [dbo].[up_mon_collect_query_stats_daily_v3]  
 @date datetime = null  
AS  
SET NOCOUNT ON  
  
exec UP_SWITCH_PARTITION 'DB_MON_QUERY_STATS_DAILY_V2', 'REG_DATE'  
  
declare @from_date datetime, @to_date datetime
declare @wk_from_date datetime, @wk_to_date datetime
declare @total_cpu bigint  

  
if @date is null  
begin  
 set @from_date = convert(datetime, convert(char(10), dateadd(day, -1, getdate()), 121))  
 set @to_date = convert(datetime, convert(char(10), getdate(), 121))  
end  
else   
begin  
 set @from_date = convert(datetime, convert(char(10), @date, 121))  
 set @to_date = convert(datetime, convert(char(10), dateadd(day, 1, @date), 121))  
end  
  
if exists (select top 1 * from DB_MON_QUERY_STATS_DAILY_V2 (nolock) where reg_date = @from_date)   
begin  
 print '   . '  
 return  
end  

set @wk_from_date = CONVERT(char(10), @from_date, 121) + ' 09:00'
set @wk_to_date = CONVERT(char(10), @from_date, 121) + ' 19:00'


select  @total_cpu =SUM(cpu_min) from db_mon_query_stats_v3 with(nolock) 
where reg_date >= @from_date and reg_date < @to_date

insert into  DB_MON_QUERY_STATS_DAILY_V2
(
	reg_date, type, cpu_rate, db_name, object_name, db_id, object_id, statement_start, statement_end,set_options
	,cnt_day, cpu_day, reads_day, writes_day,duration_day, cpu_cnt, reads_cnt,  writes_cnt,duration_cnt
	
)
select convert(nvarchar(10), max(reg_date), 121) , 'A'
	,  convert(numeric(4,2), ( SUM(cpu_min) * 1.00/ @total_cpu) *100) as cpu_rate
	,  DB_NAME, OBJECT_NAME, DB_ID, OBJECT_ID, statement_start, statement_end, set_options
	,  SUM(cnt_min) , SUM(cpu_min) , SUM(reads_min) , SUM(writes_min) ,SUM(duration_min) 
	,  AVG(cpu_cnt) , AVG(reads_cnt) , AVG(writes_cnt), AVG(duration_cnt) 
from db_mon_query_stats_V3 with(nolock) where reg_date >= @from_date and reg_date < @to_date
GROUP BY DB_NAME, OBJECT_NAME, DB_ID, OBJECT_ID, statement_start, statement_end, set_options
ORDER BY  SUM(cpu_min)  desc




select  @total_cpu=SUM(cpu_min) from db_mon_query_stats_V3 with(nolock) 
where reg_date >= @wk_from_date and reg_date < @wk_to_date



insert into  DB_MON_QUERY_STATS_DAILY_V2 
(
	reg_date, type, cpu_rate, db_name, object_name, db_id, object_id, statement_start, statement_end,set_options
	,cnt_day, cpu_day, reads_day, writes_day,duration_day, cpu_cnt, reads_cnt,  writes_cnt,duration_cnt
	
)
select convert(nvarchar(10), max(reg_date), 121) , 'W'
	,  convert(numeric(4,2), ( SUM(cpu_min) * 1.00/ @total_cpu  ) *100.0) as cpu_rate
	,  DB_NAME, OBJECT_NAME, DB_ID, OBJECT_ID, statement_start, statement_end, set_options
	,  SUM(cnt_min) , SUM(cpu_min) , SUM(reads_min) , SUM(writes_min) ,SUM(duration_min) 
	,  AVG(cpu_cnt) , AVG(reads_cnt) , AVG(writes_cnt), AVG(duration_cnt) 
from db_mon_query_stats_V3 with(nolock) where reg_date >= @wk_from_date and reg_date < @wk_to_date
GROUP BY DB_NAME, OBJECT_NAME, DB_ID, OBJECT_ID, statement_start, statement_end, set_options
ORDER BY  SUM(cpu_min) desc
go




/*************************************************************************      

*   : dbo.up_mon_collect_query_stats_gap    

*     : 2010-01-26 by choi bo ra    

*   :     

*         :   qeury cpu/cnt       

*     : exec up_mon_collect_query_stats_gap 11, 10, 2 
			  2014-10-28 by choi bo ra writes    

**************************************************************************/    

ALTER PROCEDURE dbo.up_mon_collect_query_stats_gap    

    @server_id      int    

   ,@top_cnt        int = 20    

   ,@gap            int = 5    

AS    

/* COMMON DECLARE */    

SET NOCOUNT ON    

SET FMTONLY OFF    

/* USER DECLARE */    

declare @from_date datetime, @to_date datetime  , @week_date datetime , @day_date datetime                 

declare @reg_date datetime    

set @reg_date  = convert(nvarchar(15),GETDATE(), 121)  + '0:00'      

    

declare @gubun nvarchar(5), @rank int, @rank_10 int, @rank_week int, @db_name sysname, @object_name sysname    

        ,@statement_start int, @statement_end int,  @set_options int    

    

/* BODY */    

    

select top 1 @to_date = reg_date from DB_MON_QUERY_STATS_V3 with (nolock)  order by reg_date  desc    

select top 1 @from_date = reg_date from DB_MON_QUERY_STATS_V3 with (nolock)      

    where reg_date < @to_date order by reg_date desc    

    

select top 1 @week_date = reg_date from DB_MON_QUERY_STATS_V3 with (nolock)      

    where reg_date <= dateadd(mi,1, dateadd(d, -7, convert(datetime,(convert(nvarchar(17),@to_date, 121) + '00') ))    

    ) order by reg_date desc    

    

select top 1 @day_date = reg_date from DB_MON_QUERY_STATS_V3 with (nolock)      

    where reg_date <= dateadd(mi,1, dateadd(d, -1, convert(datetime,(convert(nvarchar(17),@to_date, 121) + '00') ))    

    ) order by reg_date desc    

    

    

      

--select @to_date as today, @day_date as day_dt, @from_date as from_dt, @week_date as week_dt    

        

DECLARE sp_query_gap CURSOR FOR    

    

SELECT  'CPU' as gubun, T.rank, isnull(F.rank, @top_cnt+10) as day_rank, isnull(W.rank, @top_cnt+10) as week_rank    

    ,  T.db_name, T.object_name     

    --,(F.rank-T.rank) as gap, (W.rank-T.rank) as week_gap    

    , T.statement_start,T.statement_end, T.set_options    

FROM     

( select  top (@top_cnt) row_number() over ( order by cpu_min desc ) rank --, reg_date    

    ,db_name, object_id, object_name    

    ,plan_handle, statement_start,statement_end, set_options, create_date        

from DB_MON_QUERY_STATS_V3 with (nolock)              

where reg_date = @to_date     

order by cpu_min desc ) as T    

LEFT JOIN    

    (select  top (@top_cnt+10) row_number() over ( order by cpu_min desc ) rank --, reg_date    

  ,db_name, object_id, object_name    

  ,plan_handle, statement_start,statement_end, set_options, create_date        

    from DB_MON_QUERY_STATS_V3 with (nolock)              

    where reg_date = @from_date     

    order by cpu_min desc ) AS F  ON T.db_name = F.db_name and  T.object_name =F.object_name    

         and  T.statement_start = F.statement_start and T.statement_end =F.statement_end and T.set_options =F.set_options    

LEFT JOIN     

 (select top (@top_cnt+10) row_number() over ( order by cpu_min desc ) rank--, reg_date    

  ,db_name, object_id, object_name    

  ,plan_handle, statement_start,statement_end, set_options, create_date    

    from DB_MON_QUERY_STATS_V3 with (nolock)              

    where reg_date = @week_date     

    order by cpu_min desc ) AS W ON T.db_name = W.db_name and  T.object_name =W.object_name    

         and  T.statement_start = W.statement_start and T.statement_end =W.statement_end and T.set_options =W.set_options    

WHERE (isnull(F.rank,@top_cnt)-T.rank) > @gap OR F.rank is null  OR (isnull(W.rank,@top_cnt)-T.rank) > @gap  OR T.rank <= 10    

UNION ALL    

SELECT 'CNT' as gubun, T.rank, isnull(F.rank,@top_cnt+10) as day_rank, isnull(W.rank,@top_cnt+10) as week_rank,  T.db_name, T.object_name     
    --,(F.rank-T.rank) as gap, (W.rank-T.rank) as week_gap    

    , T.statement_start,T.statement_end, T.set_options    

FROM     

( select  top (@top_cnt) row_number() over ( order by cnt_min desc ) rank--, reg_date    

    ,db_name, object_id, object_name    

    ,plan_handle, statement_start,statement_end, set_options, create_date        

from DB_MON_QUERY_STATS_V3 with (nolock)              

where reg_date = @to_date     

order by cnt_min desc ) as T    

LEFT JOIN    

    (select  top (@top_cnt+10) row_number() over ( order by cnt_min desc ) rank--, reg_date    

  ,db_name, object_id, object_name    

  ,plan_handle, statement_start,statement_end, set_options, create_date        

    from DB_MON_QUERY_STATS_V3 with (nolock)              

    where reg_date = @day_date     

    order by cnt_min desc ) AS F  ON T.db_name = F.db_name and  T.object_name =F.object_name    

         and  T.statement_start = F.statement_start and T.statement_end =F.statement_end and T.set_options =F.set_options    

LEFT JOIN     

 (select top (@top_cnt+10) row_number() over ( order by cnt_min desc ) rank--, reg_date    

  ,db_name, object_id, object_name    

  ,plan_handle, statement_start,statement_end, set_options, create_date    

    from DB_MON_QUERY_STATS_V3 with (nolock)              

    where reg_date = @week_date     

    order by cnt_min desc ) AS W ON T.db_name = W.db_name and  T.object_name =W.object_name    

         and  T.statement_start = W.statement_start and T.statement_end =W.statement_end and T.set_options =W.set_options    

WHERE (isnull(F.rank,@top_cnt+10)-T.rank) > @gap  OR F.rank is null   OR (isnull(W.rank,@top_cnt)-T.rank) > @gap  OR T.rank <= 10   

ORDER BY gubun, rank    

 



IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WORK_QUERY_STATS_GAP]') AND type in (N'U'))    

CREATE TABLE WORK_QUERY_STATS_GAP    

    (   server_id int, reg_date datetime, collect_date datetime,    

        gubun nvarchar(5), rank int, rank_10 int, rank_week int, db_name sysname, object_name sysname,    

        cnt_min bigint, cpu_min bigint, reads_min bigint, writes_min bigint, duration_min bigint,     

        cpu_cnt bigint, reads_cnt bigint, writes_cnt bigint, duration_cnt bigint, plan_handle varbinary(64),statement_start int,statement_end int,    

        set_options int,create_date datetime    

     )    

       

TRUNCATE TABLE WORK_QUERY_STATS_GAP       

    

--  open    

OPEN sp_query_gap     

FETCH NEXT FROM sp_query_gap into  @gubun, @rank, @rank_10, @rank_week, @db_name,@object_name    

        ,@statement_start,@statement_end, @set_options    

WHILE @@fetch_status = 0           

BEGIN      

    -- collect today    

    insert into WORK_QUERY_STATS_GAP    

    select top 3  @server_id, @reg_date , reg_date as collect_date, @gubun , @rank, @rank_10, @rank_week, @db_name, @object_name    

    ,cnt_min, cpu_min, reads_min, writes_min,duration_min    

    ,cpu_cnt,reads_cnt, writes_cnt,duration_cnt ,plan_handle, statement_start,statement_end, set_options, create_date    

    from DB_MON_QUERY_STATS_V3 with (nolock)              

    where reg_date >= dateadd(mi, -30, @to_date ) and reg_date <= @to_date      

     and  db_name = @db_name and object_name = @object_name    

     and  statement_start = @statement_start and statement_end = @statement_end  and set_options = @set_options    

    order by reg_date desc    

        

    -- collect yesterday    

    insert into WORK_QUERY_STATS_GAP    

    select top 3  @server_id, @reg_date , reg_date as collect_date, @gubun , @rank, @rank_10, @rank_week, @db_name, @object_name    

    ,cnt_min, cpu_min, reads_min, writes_min, duration_min    

    ,cpu_cnt,reads_cnt, writes_cnt,duration_cnt ,plan_handle, statement_start,statement_end, set_options, create_date    

    from DB_MON_QUERY_STATS_V3 with (nolock)              

    where reg_date >= dateadd(mi, -30, @day_date ) and reg_date <= @day_date     

        and  db_name = @db_name and object_name = @object_name    

        and statement_start = @statement_start and statement_end = @statement_end  and set_options = @set_options    

    order by reg_date desc    

        

    -- collect week    

    insert into WORK_QUERY_STATS_GAP    

    select top 3 @server_id, @reg_date , reg_date as collect_date, @gubun , @rank, @rank_10, @rank_week, @db_name, @object_name    

    ,cnt_min, cpu_min, reads_min, writes_min, duration_min    

    ,cpu_cnt,reads_cnt, writes_cnt,duration_cnt ,plan_handle, statement_start,statement_end, set_options, create_date    

    from DB_MON_QUERY_STATS_V3 with (nolock)              

    where reg_date >= dateadd(mi, -30, @week_date ) and reg_date <= @week_date      

        and  db_name = @db_name and object_name = @object_name    

        and  statement_start = @statement_start and statement_end = @statement_end  and set_options = @set_options    

    order by reg_date desc    

    

  FETCH NEXT FROM sp_query_gap into  @gubun, @rank, @rank_10, @rank_week, @db_name,@object_name    

        ,@statement_start,@statement_end,@set_options     

END    

    

CLOSE sp_query_gap           

DEALLOCATE sp_query_gap           

  

--  end    

select * from WORK_QUERY_STATS_GAP    

    

RETURN 
go

drop proc [up_mon_query_stats_log_v2]
go

create PROC [dbo].[up_mon_query_stats_log_v2]
@base_date datetime = '',
@type char(3) = 'CPU',
@diff_order varchar(4) = 'DAY'
AS
BEGIN

SET NOCOUNT ON

DECLARE @now_date datetime, @day_date datetime, @week_date datetime
DECLARE @order1 varchar(20), @order2 varchar(20)

IF @base_date = ''
BEGIN
	SET @base_date = GETDATE()
END

SET @now_date = @base_date
SET @day_date = DATEADD(dd, -1, @base_date)
SET @week_date = DATEADD(dd, -7, @base_date)

SELECT @now_date=MAX(reg_date) from DB_MON_QUERY_STATS_v3 (nolock)
WHERE reg_date <= @now_date

SELECT @day_date=MAX(reg_date) from DB_MON_QUERY_STATS_v3 (nolock)
WHERE reg_date <= @day_date

SELECT @week_date=MAX(reg_date) from DB_MON_QUERY_STATS_v3 (nolock)
WHERE reg_date <= @week_date

SELECT	@now_date as now_date, @day_date as day_date, @week_date as week_date, @type as [1], @diff_order as [2]

SET @order1 = 'diff_day_cpu_min'
SET @order2 = 'diff_week_cpu_min'

IF @type = 'CPU'
BEGIN
SELECT top 10 now_db_name as db, now_object_name
		,now_line_start as line_start , now_line_end as line_end
 		,isnull(now_cnt_min,0) as now_cnt, /*day_cnt_min ,*/ isnull(isnull(now_cnt_min,0) - day_cnt_min,0) as diff_day_cnt, isnull(isnull(now_cnt_min,0) - week_cnt_min,0) as diff_week_cnt
		,isnull(now_cpu_min,0) as now_cpu, /*day_cpu_min,*/ isnull(isnull(now_cpu_min,0) - day_cpu_min,0) as diff_day_cpu, isnull(isnull(now_cpu_min,0) - week_cpu_min,0) as diff_week_cpu
		,isnull(now_cpu_cnt,0) as now_cpu_cnt, /*day_cpu_cnt,*/ isnull(isnull(now_cpu_cnt,0) - day_cpu_cnt,0) as diff_day_cpu_cnt , isnull(isnull(now_cpu_cnt,0) - week_cpu_cnt,0) as diff_week_cpu_cnt
		, CAST(replace(now_set_option,' ','') as VARCHAR)+' | '+CAST(replace(day_set_option,' ','') as VARCHAR)+' | '+ CAST(replace(week_set_option,' ','') as VARCHAR) as set_option
		, 'exec up_mon_query_stats_log_object_v2 ''' + convert(varchar(16),dateadd(mi,1,@now_date),121) + ''',''' + now_object_name + ''',' + CAST(now_line_start as varchar) + ',' + CAST(now_line_end as varchar) + ',' + CAST(now_set_option as varchar) + ',10' as object_detail
    FROM
    (
		SELECT  distinct s.reg_date as now_reg_date, s.db_name as now_db_name, s.object_name as now_object_name, cpu_rate as now_cpu_rate, cnt_min  as now_cnt_min   
                ,(cpu_min /1000) as now_cpu_min,  (duration_min/1000) as now_duration_min    
                ,reads_min as now_reads_min, writes_min as now_writes_min, cpu_cnt as now_cpu_cnt, reads_cnt as now_reads_cnt, writes_cnt as now_writes_cnt, duration_cnt as now_duration_cnt
                ,p.line_start as now_line_start, p.line_end as now_line_end
                ,S.statement_start as now_statement_start, S.statement_end as now_statement_end, S.set_options as now_set_option
        FROM DBMON.dbo.DB_MON_QUERY_STATS_v3 s WITH (NOLOCK)
        left join  dbo.db_mon_query_plan_v3 p (nolock)      
		on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date
        WHERE s.reg_date = @now_date
	) A
	LEFT JOIN
	(     
		SELECT distinct  s.reg_date as day_reg_date, s.db_name as day_db_name, s.object_name as day_object_name, cpu_rate as day_cpu_rate, cnt_min  as day_cnt_min   
                ,(cpu_min /1000) as day_cpu_min,  (duration_min/1000) as day_duration_min    
                ,reads_min as day_reads_min, writes_min as day_writes_min,cpu_cnt as day_cpu_cnt, reads_cnt as day_reads_cnt,writes_cnt as day_writes_cnt, duration_cnt as day_duration_cnt
                ,p.line_start as day_line_start, p.line_end as day_line_end
                ,S.statement_start as day_statement_start, S.statement_end as day_statement_end, S.set_options as day_set_option
        FROM DBMON.dbo.DB_MON_QUERY_STATS_v3 s WITH (NOLOCK)
        left join  dbo.db_mon_query_plan_v3 p (nolock)      
		on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date
        WHERE s.reg_date = @day_date
    ) B ON  now_object_name = day_object_name and now_statement_start=day_statement_start and now_statement_end=day_statement_end and now_set_option = day_set_option
    LEFT JOIN
	(     
		SELECT distinct  s.reg_date as week_reg_date, s.db_name as week_db_name, s.object_name as week_object_name, cpu_rate as week_cpu_rate, cnt_min  as week_cnt_min   
                ,(cpu_min /1000) as week_cpu_min,  (duration_min/1000) as week_duration_min    
                ,reads_min as week_reads_min, writes_min as week_writes_min, cpu_cnt as week_cpu_cnt, reads_cnt as week_reads_cnt, writes_cnt as week_writes_cnt,duration_cnt as week_duration_cnt
                ,p.line_start as week_line_start, p.line_end as week_line_end
                ,S.statement_start as week_statement_start, S.statement_end as week_statement_end, S.set_options as week_set_option
        FROM DBMON.dbo.DB_MON_QUERY_STATS_v3 s WITH (NOLOCK)
        left join  dbo.db_mon_query_plan_v3 p (nolock)      
		on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date    
        WHERE s.reg_date = @week_date
    ) C ON  now_object_name = week_object_name and now_statement_start=week_statement_start and now_statement_end=week_statement_end and now_set_option = week_set_option
    WHERE now_db_name not in ('master','msdb','tempdb','model','distribution','dbmon','dbadmin')

    ORDER BY CASE 
		WHEN @diff_order='DAY' THEN now_cpu_min - day_cpu_min
		WHEN @diff_order='WEEK' THEN  now_cpu_min - week_cpu_min
		END DESC
END
ELSE
BEGIN
	SELECT top 10 now_db_name as db, now_object_name
		,now_line_start as line_start , now_line_end as line_end
       --,now_cpu_rate, day_cpu_rate
		,isnull(now_cnt_min,0) as now_cnt, /*day_cnt_min ,*/ isnull(isnull(now_cnt_min,0) - day_cnt_min,0) as diff_day_cnt, isnull(isnull(now_cnt_min,0) - week_cnt_min,0) as diff_week_cnt
		,isnull(now_cpu_min,0) as now_cpu, /*day_cpu_min,*/ isnull(isnull(now_cpu_min,0) - day_cpu_min,0) as diff_day_cpu, isnull(isnull(now_cpu_min,0) - week_cpu_min,0) as diff_week_cpu
	
		,isnull(now_cpu_cnt,0) as now_cpu_cnt, /*day_cpu_cnt,*/ isnull(isnull(now_cpu_cnt,0) - day_cpu_cnt,0) as diff_day_cpu_cnt , isnull(isnull(now_cpu_cnt,0) - week_cpu_cnt,0) as diff_week_cpu_cnt
		, CAST(replace(now_set_option,' ','') as VARCHAR)+' | '+CAST(replace(day_set_option,' ','') as VARCHAR)+' | '+ CAST(replace(week_set_option,' ','') as VARCHAR) as set_option
		, 'exec up_mon_query_stats_log_object_v2 ''' + convert(varchar(16),dateadd(mi,1,@now_date),121) + ''',''' + now_object_name + ''',' + CAST(now_line_start as varchar) + ',' + CAST(now_line_end as varchar) + ',' + CAST(now_set_option as varchar) + ',10' as object_detail
    FROM
    (
		SELECT distinct  s.reg_date as now_reg_date, s.db_name as now_db_name, s.object_name as now_object_name, cpu_rate as now_cpu_rate, cnt_min  as now_cnt_min   
                ,(cpu_min /1000) as now_cpu_min,  (duration_min/1000) as now_duration_min    
                ,reads_min as now_reads_min, writes_min as now_writes_min, cpu_cnt as now_cpu_cnt, reads_cnt as now_reads_cnt, writes_cnt as now_writes_cnt, duration_cnt as now_duration_cnt
                ,p.line_start as now_line_start, p.line_end as now_line_end
                ,S.statement_start as now_statement_start, S.statement_end as now_statement_end, S.set_options as now_set_option
        FROM DBMON.dbo.DB_MON_QUERY_STATS_v3 s WITH (NOLOCK)
        left join  dbo.db_mon_query_plan_v3 p (nolock)      
		on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date    
        WHERE s.reg_date = @now_date
	) A
	LEFT JOIN
	(     
		SELECT distinct  s.reg_date as day_reg_date, s.db_name as day_db_name, s.object_name as day_object_name, cpu_rate as day_cpu_rate, cnt_min  as day_cnt_min   
                ,(cpu_min /1000) as day_cpu_min,  (duration_min/1000) as day_duration_min    
                ,reads_min as day_reads_min, writes_min as day_writes_min,cpu_cnt as day_cpu_cnt, reads_cnt as day_reads_cnt,writes_cnt as day_writes_cnt, duration_cnt as day_duration_cnt
                ,p.line_start as day_line_start, p.line_end as day_line_end
                ,S.statement_start as day_statement_start, S.statement_end as day_statement_end, S.set_options as day_set_option
        FROM DBMON.dbo.DB_MON_QUERY_STATS_v3 s WITH (NOLOCK)
        left join  dbo.db_mon_query_plan_v3 p (nolock)      
		on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date    
        WHERE s.reg_date = @day_date
    ) B ON  now_object_name = day_object_name and now_statement_start=day_statement_start and now_statement_end=day_statement_end and now_set_option = day_set_option
    LEFT JOIN
	(     
		SELECT  distinct s.reg_date as week_reg_date, s.db_name as week_db_name, s.object_name as week_object_name, cpu_rate as week_cpu_rate, cnt_min  as week_cnt_min   
                ,(cpu_min /1000) as week_cpu_min,  (duration_min/1000) as week_duration_min    
                ,reads_min as week_reads_min, writes_min as week_writes_min, cpu_cnt as week_cpu_cnt, reads_cnt as week_reads_cnt, writes_cnt as week_writes_cnt,duration_cnt as week_duration_cnt
                ,p.line_start as week_line_start, p.line_end as week_line_end
                ,S.statement_start as week_statement_start, S.statement_end as week_statement_end, S.set_options as week_set_option
        FROM DBMON.dbo.DB_MON_QUERY_STATS_v3 s WITH (NOLOCK)
        left join  dbo.db_mon_query_plan_v3 p (nolock)      
		on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date    
        WHERE s.reg_date = @week_date
    ) C ON  now_object_name = week_object_name and now_statement_start=week_statement_start and now_statement_end=week_statement_end and now_set_option = week_set_option
    WHERE now_db_name not in ('master','msdb','tempdb','model','distribution','dbmon','dbadmin')
    /*and CASE 
		WHEN @diff_order = 'DAY' THEN day_cnt_min 
		WHEN @diff_order = 'WEEK' THEN week_cnt_min
		END is not null*/
    ORDER BY CASE 
		WHEN @diff_order='DAY' THEN isnull(isnull(now_cnt_min,0) - day_cnt_min,0)
		WHEN @diff_order='WEEK' THEN  isnull(isnull(now_cnt_min,0) - week_cnt_min,0)
		END DESC
END
END
go

drop proc up_mon_query_stats_log_object_V2
go

create PROC dbo.up_mon_query_stats_log_object_V2
@base_date datetime = '',
@object_name varchar(255),
@line_start int,
@line_end int,
@set_option int,
@rowcount int = 10
as
BEGIN
SET NOCOUNT ON

DECLARE @now_date datetime, @day_date datetime, @week_date datetime

IF @base_date = ''
BEGIN
	SET @base_date = GETDATE()
END

SET @now_date = @base_date
SET @day_date = DATEADD(dd, -1, @base_date)
SET @week_date = DATEADD(dd, -7, @base_date)

SELECT @now_date=MAX(reg_date) from DB_MON_QUERY_STATS_V3 (nolock)
WHERE reg_date <= @now_date

SELECT @day_date=MAX(reg_date) from DB_MON_QUERY_STATS_V3 (nolock)
WHERE reg_date <= @day_date

SELECT @week_date=MAX(reg_date) from DB_MON_QUERY_STATS_V3 (nolock)
WHERE reg_date <= @week_date

SELECT @object_name as [object_name], @now_date as base_date,dateadd(mi,-61,@now_date) as to_date--, dateadd(mi,61,@now_date) as from_date

--Now
SELECT distinct TOP (@rowcount) 
s.reg_date as reg_date, s.db_name as [db_name]
,cnt_min  as cnt_min   
,(cpu_min /1000) as cpu_min,  (duration_min/1000) as duration_min    
,reads_min, writes_min, cpu_cnt as cpu_cnt, reads_cnt as reads_cnt, writes_cnt, duration_cnt as duration_cnt
--,S.statement_start as statement_start, S.statement_end as statement_end
,S.set_options as set_option
,p.line_start, p.line_end as line_end
FROM DBMON.dbo.DB_MON_QUERY_STATS_V3 s WITH (NOLOCK)
left join  dbo.db_mon_query_plan_v3 p (nolock)      
on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date
WHERE s.reg_date >= dateadd(mi,-61,@now_date) and s.reg_date <= @now_date
and s.object_name= @object_name and P.line_start= @line_start and p.line_end = @line_end and s.set_options = @set_option
order by reg_date desc 

--Day
SELECT @object_name as [object_name], @day_date as base_date,dateadd(mi,-61,@day_date) as to_date--, dateadd(mi,61,@day_date) as from_date
SELECT distinct TOP (@rowcount) 
s.reg_date as reg_date, s.db_name as [db_name]
,cnt_min  as cnt_min   
,(cpu_min /1000) as cpu_min,  (duration_min/1000) as duration_min    
,reads_min, writes_min, cpu_cnt as cpu_cnt, reads_cnt as reads_cnt, writes_cnt, duration_cnt as duration_cnt
--,S.statement_start as statement_start, S.statement_end as statement_end
,S.set_options as set_option
,p.line_start, p.line_end as line_end
FROM DBMON.dbo.DB_MON_QUERY_STATS_V3 s WITH (NOLOCK)
left join  dbo.db_mon_query_plan_v3 p (nolock)      
on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date
WHERE s.reg_date >= dateadd(mi,-61,@day_date) and s.reg_date <= @day_date
and s.object_name= @object_name and P.line_start= @line_start and p.line_end = @line_end and s.set_options = @set_option
order by reg_date desc 


--Week
SELECT @object_name as [object_name], @week_date as base_date,dateadd(mi,-61,@week_date) as to_date--, dateadd(mi,61,@week_date) as from_date
SELECT distinct TOP (@rowcount) 
s.reg_date as reg_date, s.db_name as [db_name]
,cnt_min  as cnt_min   
,(cpu_min /1000) as cpu_min,  (duration_min/1000) as duration_min    
,reads_min, writes_min, cpu_cnt as cpu_cnt, reads_cnt as reads_cnt, writes_cnt, duration_cnt as duration_cnt
--,S.statement_start as statement_start, S.statement_end as statement_end
,S.set_options as set_option
,p.line_start, p.line_end as line_end
FROM DBMON.dbo.DB_MON_QUERY_STATS_V3 s WITH (NOLOCK)
left join  dbo.db_mon_query_plan_v3 p (nolock)      
on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date
WHERE s.reg_date >= dateadd(mi,-61,@week_date) and s.reg_date <= @week_date
and s.object_name= @object_name and P.line_start= @line_start and p.line_end = @line_end and s.set_options = @set_option
order by reg_date desc
END
go

drop proc Up_Mon_Query_Stats_Top_Cnt
go

create  Procedure Up_Mon_Query_Stats_Top_Cnt    
 @Date Datetime = Null,    
 @Rowcount Int = 20    
As    
Set Nocount On    
    
If @Date Is Null Set @Date =  Getdate()    

Select Top 1 @Date = Reg_Date From Db_Mon_Query_Stats_V3 (Nolock)
Where Reg_Date <= @Date Order By Reg_Date Desc
    
Select Top (@Rowcount)    
s.db_name,    
s.object_name,    
s.reg_date as to_date,  
s.type,
s.term,   
s.set_options,    
p.line_start,    
p.line_end,    
s.cnt_min,    
s.cpu_rate,    
s.cpu_min,    
s.reads_min,  
s.writes_min,  
s.duration_min,    
s.cpu_cnt,    
s.reads_cnt,  
s.writes_cnt , 
s.duration_cnt,    
s.statement_start,  
s.statement_end,  
s.create_date,
s.query_text,    
p.query_plan  
From Dbo.Db_Mon_Query_Stats_V3 S (Nolock)     
Left Join  Dbo.Db_Mon_Query_Plan_V3 P (Nolock)    
  On S.Plan_Handle = P.Plan_Handle And S.Statement_Start = P.Statement_Start And S.Statement_End = P.Statement_End And S.Create_Date = P.Create_Date    
--Outer Apply Dbo.Fn_Getobjectline(S.Plan_Handle, S.Statement_Start, S.Statement_End) F    
Where S.Reg_Date = @Date    
order by s.reg_date desc, s.cnt_min desc 
go


drop  proc up_mon_query_stats_top_cpu
go


/* 2010-08-25 10:52 
 2014-10-27 by choi bo ra   
*/
create PROCEDURE up_mon_query_stats_top_cpu  
 @date datetime = null,  
 @rowcount int = 20  
AS  
SET NOCOUNT ON  
  
  
if @date is null set @date =  getdate()

select top 1 @date = reg_date from db_mon_query_stats_v3 (nolock) 
where reg_date <= @date order by reg_date desc
  
select top (@rowcount)  
s.db_name,  
s.object_name,  
s.reg_date as to_date,   
s.type,
s.term, 
s.set_options,  
p.line_start,  
p.line_end,  
s.cnt_min,  
s.cpu_rate,  
s.cpu_min,  
s.reads_min,  
s.writes_min, 
s.duration_min,  
s.cpu_cnt,  
s.reads_cnt,
s.writes_cnt,  
s.duration_cnt,  
s.statement_start,
s.statement_end,
s.create_date, 
s.query_text,
p.query_plan
from dbo.db_mon_query_stats_v3 s (nolock)   
left join  dbo.db_mon_query_plan_v3 p (nolock)  
  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
where s.reg_date = @date
order by s.reg_date desc, s.cpu_min desc 
go

drop proc up_mon_query_stats_top_duration
go


CREATE PROCEDURE up_mon_query_stats_top_duration
 @date datetime = null,  
 @rowcount int = 20  
AS  

SET NOCOUNT ON  
  
if @date is null set @date =  getdate()

select top 1 @date = reg_date from db_mon_query_stats_v3 (nolock) 
where reg_date <= @date order by reg_date desc
  

select top (@rowcount)  
s.db_name,  
s.object_name,  
s.reg_date as to_date,  
s.type,    
s.term, 
s.set_options,  
p.line_start,  
p.line_end,  
s.cnt_min,  
s.cpu_rate,  
s.cpu_min,  
s.reads_min,  
s.writes_min,
s.duration_min,  
s.cpu_cnt,  
s.reads_cnt,  
s.writes_cnt,
s.duration_cnt,  
s.statement_start,
s.statement_end,
s.create_date, 
s.query_text,
p.query_plan
from dbo.db_mon_query_stats_v3 s (nolock)   
left join  dbo.db_mon_query_plan_v3 p (nolock)  
  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
--outer apply dbo.fn_getobjectline(s.plan_handle, s.statement_start, s.statement_end) f  
where s.reg_date = @date  
order by s.reg_date desc, s.duration_min desc 
go

drop proc up_mon_query_stats_top_writes
go
CREATE PROCEDURE up_mon_query_stats_top_writes
 @date datetime = null,  
 @rowcount int = 20  
AS  

SET NOCOUNT ON  
  
if @date is null set @date =  getdate()

select top 1 @date = reg_date from db_mon_query_stats_v3 (nolock) 
where reg_date <= @date order by reg_date desc
  

select top (@rowcount)  
s.db_name,  
s.object_name,  
s.reg_date as to_date,  
s.type,    
s.term, 
s.set_options,  
p.line_start,  
p.line_end,  
s.cnt_min,  
s.cpu_rate,  
s.cpu_min,  
s.reads_min,  
s.writes_min,
s.duration_min,  
s.cpu_cnt,  
s.reads_cnt,  
s.writes_cnt,
s.duration_cnt,  
s.statement_start,
s.statement_end,
s.create_date, 
s.query_text,
p.query_plan
from dbo.db_mon_query_stats_v3 s (nolock)   
left join  dbo.db_mon_query_plan_v3 p (nolock)  
  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
--outer apply dbo.fn_getobjectline(s.plan_handle, s.statement_start, s.statement_end) f  
where s.reg_date = @date  
order by s.reg_date desc, s.writes_min desc 
go

drop proc up_mon_query_stats_top_reads
go

CREATE PROCEDURE up_mon_query_stats_top_reads  
 @date datetime = null,  
 @rowcount int = 20  
AS  
SET NOCOUNT ON  
  
if @date is null set @date =  getdate()

select top 1 @date = reg_date from db_mon_query_stats_v3 (nolock) 
where reg_date <= @date order by reg_date desc
  
select top (@rowcount)  
s.db_name,  
s.object_name,  
s.reg_date as to_date,   
s.type,
s.term, 
s.set_options,  
p.line_start,  
p.line_end,  
s.cnt_min,  
s.cpu_rate,  
s.cpu_min,  
s.reads_min,  
s.writes_min,  
s.duration_min,  
s.cpu_cnt,  
s.reads_cnt,  
s.writes_cnt, 
s.duration_cnt,  
s.statement_start,
s.statement_end,
s.create_date,
s.query_text,   
p.query_plan
from dbo.db_mon_query_stats_v3 s (nolock)   
left join  dbo.db_mon_query_plan_v3 p (nolock)  
  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
--outer apply dbo.fn_getobjectline(s.plan_handle, s.statement_start, s.statement_end) f  
where s.reg_date = @date  
order by s.reg_date desc, s.reads_min desc 
go

drop proc up_mon_query_plan_change
go


/*************************************************************************  
* : dbo.up_mon_query_plan_change
* 	: 2013-07-19 by choi bo ra
* :  
* 		: exec dbo.up_mon_query_plan_change  '', ''-- 30
* 	:    query plan  
			  2014-10-28 by choi bo ra V3 
**************************************************************************/
CREATE PROCEDURE dbo.up_mon_query_plan_change
 	@reg_date 	datetime =null	, 
 	@duration 	int = 30	

AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */
declare @pre_reg_date datetime , @pre_pre_reg_date datetime

 
if @reg_date is null set @reg_date = getdate()

select @reg_date = max(reg_date) from dbmon.dbo.DB_MON_QUERY_PLAN_V3 with(nolock) where reg_date <= @reg_date
select @pre_reg_date = max(reg_date) from dbmon.dbo.DB_MON_QUERY_PLAN_V3 with(nolock) where reg_date < dateadd(mi, -1*@duration,@reg_date );

--select @reg_date, @pre_reg_date



WITH QUERY_PLAN ( rank, create_date, statement_start,statement_end
				,plan_handle,line_start, line_end ,query_plan, object_name,set_options)
AS 
(
	select  rank() over (partition by p1.object_name , p1.statement_start, p1.statement_end order by p1.create_date desc) as rank
		, p1.create_date,  p1.statement_start, p1.statement_end, p1.plan_handle , p1.line_start, p1.line_end, p1.query_plan
		, p1.object_name, p1.set_options
	from 
	(select  distinct db_name, object_name  from  DB_MON_QUERY_PLAN_V3 with(nolock)
		 where reg_date <= @reg_date and reg_date > @pre_reg_date ) as p 
		join  DB_MON_QUERY_PLAN_V3 as p1 with(nolock) on p1.object_name = p.object_name and p1.db_name = p.db_name 
	where p1.reg_date <= @reg_date and p1.reg_date >= dateadd(dd, -7, @reg_date)
)
SELECT  
		DB_NAME,
		object_name, 
		to_date,
		type,
		create_date,   	   
		set_options,  
		line_start,  
		line_end,  
		cnt_min,  
		cpu_rate,  
		cpu_min,  
		reads_min,
		writes_min,   
		duration_min,  
		cpu_cnt,  
		reads_cnt,  
		writes_cnt,
		duration_cnt,  
		plan_handle,
		query_text,
		query_plan,
		statement_start,
		statement_end		
FROM 
(
	select RANK () OVER( PARTITION BY S.DB_NAME, S.OBJECT_NAME, P.CREATE_DATE ORDER BY S.REG_DATE DESC) AS RANK,  s.db_name,  
		s.object_name, 
		s.reg_date as to_date,
		s.type,
		s.create_date,   	   
		s.set_options,  
		p.line_start,  
		p.line_end,  
		s.cnt_min,  
		s.cpu_rate,  
		s.cpu_min,  
		s.reads_min,  
		s.writes_min,
		s.duration_min,  
		s.cpu_cnt,  
		s.reads_cnt,  
		s.writes_cnt, 
		s.duration_cnt, 
		s.query_text,
		p.query_plan, 
		s.plan_handle,
		s.statement_start,
		s.statement_end		
	from QUERY_PLAN as p with(nolock) 
		join db_mon_query_stats_v3 as s with(nolock) 
			on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
	where p.rank <=2  
) AS M  WHERE RANK = 1
order by  M.object_name, M.LINE_START, M.LINE_END, M.CREATE_DATE DESC
go




/* 2010-08-26 09:53 */    
    
/* 2010-08-25 11:42 */      
--   seq       
-- plan         
-- date parameter       
--          
      
ALTER PROCEDURE [dbo].[up_mon_query_stats_top_cpu_excel]           
 @date datetime = null,      
 @is_plan tinyint = 1      
AS          
          
set nocount on          
          
declare @base_time datetime          
declare @before_10min datetime          
declare @before_1day datetime          
declare @before_1week datetime          
        
declare @base_time_from datetime          
declare @before_10min_from datetime          
declare @before_1day_from datetime          
declare @before_1week_from datetime          
          
declare @proc_info table (          
 seq int identity(1, 1) primary key,          
 db_name varchar(32),          
 object_name varchar(255),       
 plan_handle varbinary(64),          
 statement_start int,          
 statement_end int          
)          
          
declare @max int, @seq int          
declare @db_name varchar(32), @statement_start int, @statement_end int, @plan_handle varbinary(64)      
declare @object_name varchar(255)          
          
declare @proc table (          
 base_time_type int,          
 plan_handle varbinary(64),          
 create_date datetime,          
 cnt_min bigint,          
 cpu_min bigint,          
 reads_min bigint,          
 duration_min bigint,          
 cpu_cnt bigint,          
 reads_cnt bigint,          
 duration_cnt bigint          
)          
          
declare @proc_pivot table (          
 seq int identity(1, 1) primary key,          
 type varchar(20),          
 base_date bigint,          
 before_10min bigint,          
 gap_10min numeric(5, 2),          
 before_1day bigint,          
 gap_1day numeric(5, 2),          
 before_1week bigint,          
 gap_1week numeric(5, 2)          
)          
        
declare @excel table (        
 seq int identity(1, 1) primary key,         
 col1 varchar(1000) default '',        
 col2 varchar(1000) default '',        
 col3 varchar(1000) default '',        
 col4 varchar(1000) default '',        
 col5 varchar(1000) default '',        
 col6 varchar(1000) default '',        
 col7 varchar(1000) default '',        
 col8 varchar(1000) default '',        
 col9 varchar(1000) default '',        
 col10 varchar(1000) default '',        
 col11 varchar(1000) default '',        
 col12 varchar(1000) default '',        
 col13 varchar(1000) default '',        
 col14 varchar(1000) default '',    
 col15 varchar(1000) default ''  
)        
          
      
if @date is null set @base_time = getdate()          
else set @base_time = @date      
          
select @base_time = max(reg_date), @base_time_from = max(from_date) from dbo.db_mon_query_stats_v3 (nolock)           
where reg_date <= @base_time          
          
select @before_10min = max(reg_date), @before_10min_from = max(from_date) from dbo.db_mon_query_stats_v3 (nolock)          
where reg_date <= dateadd(minute, 2, dateadd(minute, -10, @base_time))          
          
select @before_1day = max(reg_date), @before_1day_from = max(from_date) from dbo.db_mon_query_stats_v3 (nolock)          
where reg_date <= dateadd(minute, 2, dateadd(day, -1, @base_time))          
          
select @before_1week = max(reg_date), @before_1week_from = max(from_date) from dbo.db_mon_query_stats_v3 (nolock)          
where reg_date <= dateadd(minute, 2, dateadd(day, -6, @base_time))          
        
insert @excel (col2, col3) values ('from date', 'to date')        
        
insert @excel (col1, col2, col3)        
select 'now ' as ' ', convert(char(16), @base_time_from, 121) as 'from date', convert(char(16),@base_time, 121) as 'to date'        
union all        
select 'before 10 min' as ' ', convert(char(16), @before_10min_from, 121) as 'from date', convert(char(16),@before_10min, 121) as 'to date'        
union all        
select 'before 1 day' as ' ', convert(char(16), @before_1day_from, 121) as 'from date', convert(char(16),@before_1day, 121) as 'to date'        
union all        
select 'before 1 week' as ' ', convert(char(16), @before_1week_from, 121) as 'from date', convert(char(16),@before_1week, 121) as 'to date'        
        
insert @excel (col1) values ('')        
          
insert @proc_info (db_name, object_name, statement_start, statement_end, plan_handle)          
select top 10 db_name, object_name, statement_start, statement_end, plan_handle          
from dbo.db_mon_query_stats_v3 (nolock)           
where reg_date = @base_time     
order by cpu_min desc      
          
select @max = @@rowcount, @seq = 1          
          
while @seq <= @max          
begin          
          
 select @db_name = db_name, @object_name = object_name, @statement_start = statement_start, @statement_end = statement_end, @plan_handle = plan_handle          
 from @proc_info a           
 where seq = @seq          
         
 insert @excel (col1, col4, col5, col6, col7, col8, col10, col12, col14)        
 values ('object name - ranking ' + convert(varchar(10), @seq), 'db name', 'line start', 'line end', 'statement start', 'statement end'  
  , 'cnt / min', 'cpu / min', 'reads / min')        
    
/*  recompile ?? ?? ??????? ?? ?????? ??\uCC21 ??? getobjectline ??????? ????    
 insert @excel (col1, col4, col5, col6, col7, col8)        
 select         
 @object_name as object_name,         
 @db_name as db_name,         
 convert(varchar(10), line_start),         
 convert(varchar(10), line_end),         
 convert(varchar(10), @statement_start),         
 convert(varchar(10), @statement_end)        
 from dbo.fn_getobjectline(@plan_handle, @statement_start, @statement_end)          
*/     
 insert @excel (col1, col4, col5, col6, col7, col8)    
 select top 1     
 @object_name as object_name,    
 @db_name as db_name,    
 convert(varchar(10), line_start),    
 convert(varchar(10), line_end),    
 convert(varchar(10), @statement_start),    
 convert(varchar(10), @statement_end)    
 from db_mon_query_plan_v3 (nolock)     
 where plan_handle = @plan_handle and statement_start = @statement_start and statement_end = @statement_end    
 order by create_date desc    
       
 insert @excel (col1)       
 select convert(varchar(140), dbo.fn_getquerytext(@plan_handle, @statement_start, @statement_end))      
         
 insert @excel (col1) values ('')        
           
          
 set @seq = @seq + 1          
          
 insert @proc (base_time_type, plan_handle, create_date, cnt_min, cpu_min, reads_min, duration_min, cpu_cnt, reads_cnt, duration_cnt)          
 select           
  case when reg_date = @base_time then 0           
    when reg_date = @before_10min then 1          
    when reg_date = @before_1day then 2          
    when reg_date = @before_1week then 3          
  end,
  plan_handle, create_date
   , cnt_min, cpu_min, reads_min, duration_min, cpu_cnt, reads_cnt, duration_cnt          
 from dbo.db_mon_query_stats_v3 (nolock)
 where object_name = @object_name and (reg_date in (@base_time, @before_10min, @before_1day, @before_1week))          
   and statement_start = @statement_start and statement_end = @statement_end
          
-- insert @proc_pivot (type, base_date, before_10min, gap_10min, before_1day, gap_1day, before_1week, gap_1week)          

 insert @excel (col2, col3, col4, col5, col6, col7, col8)        
 values ('now', 'before 10 min', '10 min gap (%)', 'before 1 day', '1 day gap (%)', 'before 1 week', '1 week gap (%)')        
         
 insert @excel (col1, col2, col3, col4, col5, col6, col7, col8)        
 select           
  case when cd = 0 then 'cnt / min'          
    when cd = 1 then 'cpu / min'          
    when cd = 2 then 'reads / min'          
    when cd = 3 then 'duration / min'    
    when cd = 4 then 'cpu / cnt'          
    when cd = 5 then 'reads / cnt'          
    when cd = 6 then 'duration / cnt'          
  end as ' ',          
  convert(varchar(20), base) as [now] ,          
  convert(varchar(20),m20) as 'before 10 min',  convert(varchar(20), case when m20 = 0 then 0 else convert(numeric(10, 2), (base - m20) * 100 / convert(numeric(18, 2), m20)) end) as 'gap (10 min)',          
--  dbo.fn_gaprate(base, m20),       
  convert(varchar(20),d1) as 'before 1 day' , convert(varchar(20), case when d1 = 0 then 0 else convert(numeric(10, 2), (base - d1) * 100 / convert(numeric(18, 2), d1)) end) as 'gap (1 day)',          
  convert(varchar(20),w1) as 'before 1 week', convert(varchar(20), case when w1 = 0 then 0 else convert(numeric(10, 2), (base - w1) * 100 / convert(numeric(18, 2), w1)) end) as 'gap (1 week)'          
 from (          
  select 0 as cd,           
   sum(case when base_time_type = 0 then cnt_min else 0 end) as base,          
   sum(case when base_time_type = 1 then cnt_min else 0 end) as m20,          
   sum(case when base_time_type = 2 then cnt_min else 0 end) as d1,          
   sum(case when base_time_type = 3 then cnt_min else 0 end) as w1          
  from @proc          
  union all          
  select 1 as cd,           
   sum(case when base_time_type = 0 then cpu_min else 0 end) as base,          
   sum(case when base_time_type = 1 then cpu_min else 0 end) as m20,          
   sum(case when base_time_type = 2 then cpu_min else 0 end) as d1,          
   sum(case when base_time_type = 3 then cpu_min else 0 end) as w1          
  from @proc          
  union all          
  select 2 as cd,           
   sum(case when base_time_type = 0 then reads_min else 0 end) as base,          
   sum(case when base_time_type = 1 then reads_min else 0 end) as m20,          
   sum(case when base_time_type = 2 then reads_min else 0 end) as d1,          
   sum(case when base_time_type = 3 then reads_min else 0 end) as w1          
  from @proc            
  union all          
  select 3 as cd,           
   sum(case when base_time_type = 0 then duration_min else 0 end) as base,          
   sum(case when base_time_type = 1 then duration_min else 0 end) as m20,          
   sum(case when base_time_type = 2 then duration_min else 0 end) as d1,          
   sum(case when base_time_type = 3 then duration_min else 0 end) as w1          
  from @proc            
  union all          
  select 4 as cd,           
   sum(case when base_time_type = 0 then cpu_cnt else 0 end) as base,          
   sum(case when base_time_type = 1 then cpu_cnt else 0 end) as m20,          
   sum(case when base_time_type = 2 then cpu_cnt else 0 end) as d1,          
   sum(case when base_time_type = 3 then cpu_cnt else 0 end) as w1          
  from @proc              
  union all          
  select 5 as cd,           
   sum(case when base_time_type = 0 then reads_cnt else 0 end) as base,          
   sum(case when base_time_type = 1 then reads_cnt else 0 end) as m20,          
   sum(case when base_time_type = 2 then reads_cnt else 0 end) as d1,          
   sum(case when base_time_type = 3 then reads_cnt else 0 end) as w1          
  from @proc             
  union all          
  select 6 as cd,           
   sum(case when base_time_type = 0 then duration_cnt else 0 end) as base,          
   sum(case when base_time_type = 1 then duration_cnt else 0 end) as m20,          
   sum(case when base_time_type = 2 then duration_cnt else 0 end) as d1,          
   sum(case when base_time_type = 3 then duration_cnt else 0 end) as w1          
  from @proc             
 ) a          
        
 insert @excel (col1) values ('')           
      
 if @is_plan = 1            
 begin      
         
  insert @excel (col2) values ('view plan info')          
      
  insert @excel (col1, col2)        
  select a.name,      
  isnull('exec dbmon.dbo.up_mon_query_plan_info @plan_handle = ' + dbo.fnc_hexa2decimal(plan_handle) + ', @create_date = ''' + convert(varchar(23), create_date, 121) + '''' + ', @statement_start = ' + convert(varchar(10), @statement_start)     
  + ', @statement_end = ' + convert(varchar(10), @statement_end), '')  as view_plan          
  from (      
   select 0 as type, 'now' as name      
   union all      
   select 1 as type, 'before 10 min' as name      
   union all      
   select 2 as type, 'before 1 day' as name    
   union all      
   select 3 as type, 'before 1 week' as name      
  ) a left join @proc b on a.type = b.base_time_type      
  order by a.type      
        
/*        
  select           
   case when base_time_type = 0 then 'now'          
     when base_time_type = 1 then 'before 10 min'          
     when base_time_type = 2 then 'before 1 day'          
     when base_time_type = 3 then 'before 1 week'          
   end base_time,            
   'exec up_mon_query_plan_info @plan_handle = ' + dbo.fnc_hexa2decimal(@plan_handle) + ', @create_date = ''' + convert(varchar(23), create_date, 121) + '''' + ', @statement_start = ' + convert(varchar(10), @statement_start) + ', @statement_end = '    
 + convert(varchar(10), @statement_end)  as view_plan          
  from @proc          
  order by base_time_type          
*/          
  insert @excel (col1) values ('')        
      
 end       
          
 delete  @proc        
        
end          
        
        
select col1, col2, col3, col4, col5, col6, col7, col8, col9, col10, col11, col12, col13, col14, col15 from @excel order by seq
GO


/* 2010-08-26 09:53 */    
ALTER PROCEDURE [dbo].[up_mon_query_stats_top_cnt_excel]         
 @date datetime = null,    
 @is_plan tinyint = 1    
AS        
        
set nocount on        
        
declare @base_time datetime        
declare @before_10min datetime        
declare @before_1day datetime        
declare @before_1week datetime        
      
declare @base_time_from datetime        
declare @before_10min_from datetime        
declare @before_1day_from datetime        
declare @before_1week_from datetime        
        
declare @proc_info table (        
 seq int identity(1, 1) primary key,        
 db_name varchar(32),        
 object_name varchar(255),     
 plan_handle varbinary(64),        
 statement_start int,        
 statement_end int        
)        
        
declare @max int, @seq int        
declare @db_name varchar(32), @statement_start int, @statement_end int, @plan_handle varbinary(64)    
declare @object_name varchar(255)        
        
declare @proc table (        
 base_time_type int,        
 plan_handle varbinary(64),        
 create_date datetime,        
 cnt_min bigint,        
 cpu_min bigint,        
 reads_min bigint,        
 duration_min bigint,        
 cpu_cnt bigint,        
 reads_cnt bigint,        
 duration_cnt bigint        
)        
        
declare @proc_pivot table (        
 seq int identity(1, 1) primary key,        
 type varchar(20),        
 base_date bigint,        
 before_10min bigint,        
 gap_10min numeric(5, 2),        
 before_1day bigint,        
 gap_1day numeric(5, 2),        
 before_1week bigint,        
 gap_1week numeric(5, 2)        
)        
      
declare @excel table (      
 seq int identity(1, 1) primary key,       
 col1 varchar(1000) default '',      
 col2 varchar(1000) default '',      
 col3 varchar(1000) default '',      
 col4 varchar(1000) default '',      
 col5 varchar(1000) default '',      
 col6 varchar(1000) default '',      
 col7 varchar(1000) default '',      
 col8 varchar(1000) default '',  
 col9 varchar(1000) default '',  
 col10 varchar(1000) default '',  
 col11 varchar(1000) default '',  
 col12 varchar(1000) default '',  
 col13 varchar(1000) default '',  
 col14 varchar(1000) default '',  
 col15 varchar(1000) default ''  
)      
        
    
if @date is null set @base_time = getdate()        
else set @base_time = @date    
        
select @base_time = max(reg_date), @base_time_from = max(from_date) from dbo.db_mon_query_stats_v3 (nolock)         
where reg_date <= @base_time        
        
select @before_10min = max(reg_date), @before_10min_from = max(from_date) from dbo.db_mon_query_stats_v3 (nolock)        
where reg_date <= dateadd(minute, 2, dateadd(minute, -10, @base_time))        
        
select @before_1day = max(reg_date), @before_1day_from = max(from_date) from dbo.db_mon_query_stats_v3 (nolock)        
where reg_date <= dateadd(minute, 2, dateadd(day, -1, @base_time))        
        
select @before_1week = max(reg_date), @before_1week_from = max(from_date) from dbo.db_mon_query_stats_v3 (nolock)        
where reg_date <= dateadd(minute, 2, dateadd(day, -6, @base_time))        
      
insert @excel (col2, col3) values ('from date', 'to date')      
      
insert @excel (col1, col2, col3)      
select 'now ' as ' ', convert(char(16), @base_time_from, 121) as 'from date', convert(char(16),@base_time, 121) as 'to date'      
union all      
select 'before 10 min' as ' ', convert(char(16), @before_10min_from, 121) as 'from date', convert(char(16),@before_10min, 121) as 'to date'      
union all      
select 'before 1 day' as ' ', convert(char(16), @before_1day_from, 121) as 'from date', convert(char(16),@before_1day, 121) as 'to date'      
union all      
select 'before 1 week' as ' ', convert(char(16), @before_1week_from, 121) as 'from date', convert(char(16),@before_1week, 121) as 'to date'      
 
insert @excel (col1) values ('')      
        
insert @proc_info (db_name, object_name, statement_start, statement_end, plan_handle)        
select top 10 db_name, object_name, statement_start, statement_end, plan_handle        
from dbo.db_mon_query_stats_v3 (nolock)         
where reg_date = @base_time -- and object_name = @object_name        
order by cnt_min desc    
        
select @max = @@rowcount, @seq = 1        
        
while @seq <= @max        
begin        
        
 select @db_name = db_name, @object_name = object_name, @statement_start = statement_start, @statement_end = statement_end, @plan_handle = plan_handle        
 from @proc_info a         
 where seq = @seq        
       
 insert @excel (col1, col4, col5, col6, col7, col8, col10, col12, col14)      
 values ('object name - ranking ' + convert(varchar(10), @seq), 'db name', 'line start', 'line end', 'statement start', 'statement end',  
   'cnt / min', 'cpu / min', 'reads / min')      
       
/*  recompile ?? ?? ??????? ?? ?????? ??\uCC21 ??? getobjectline ??????? ????  
 insert @excel (col1, col4, col5, col6, col7, col8)      
 select       
 @object_name as object_name,       
 @db_name as db_name,       
 convert(varchar(10), line_start),       
 convert(varchar(10), line_end),       
 convert(varchar(10), @statement_start),       
 convert(varchar(10), @statement_end)      
 from dbo.fn_getobjectline(@plan_handle, @statement_start, @statement_end)        
*/   
 insert @excel (col1, col4, col5, col6, col7, col8)  
 select top 1   
 @object_name as object_name,  
 @db_name as db_name,  
 convert(varchar(10), line_start),  
 convert(varchar(10), line_end),  
 convert(varchar(10), @statement_start),  
 convert(varchar(10), @statement_end)  
 from db_mon_query_plan_v3 (nolock)   
 where plan_handle = @plan_handle and statement_start = @statement_start and statement_end = @statement_end  
 order by create_date desc     
     
 insert @excel (col1)     
 select convert(varchar(140), dbo.fn_getquerytext(@plan_handle, @statement_start, @statement_end))    
       
 insert @excel (col1) values ('')      
         
        
 set @seq = @seq + 1        
        
 insert @proc (base_time_type, plan_handle, create_date, cnt_min, cpu_min, reads_min, duration_min, cpu_cnt, reads_cnt, duration_cnt)        
 select         
  case when reg_date = @base_time then 0         
    when reg_date = @before_10min then 1        
    when reg_date = @before_1day then 2        
    when reg_date = @before_1week then 3        
  end,        
  plan_handle, create_date        
   , cnt_min, cpu_min, reads_min, duration_min, cpu_cnt, reads_cnt, duration_cnt        
 from dbo.db_mon_query_stats_v3 (nolock)         
 where object_name = @object_name and (reg_date in (@base_time, @before_10min, @before_1day, @before_1week))        
   and statement_start = @statement_start and statement_end = @statement_end        
        
-- insert @proc_pivot (type, base_date, before_10min, gap_10min, before_1day, gap_1day, before_1week, gap_1week)        
      
 insert @excel (col2, col3, col4, col5, col6, col7, col8)      
 values ('now', 'before 10 min', '10 min gap (%)', 'before 1 day', '1 day gap (%)', 'before 1 week', '1 week gap (%)')      
       
 insert @excel (col1, col2, col3, col4, col5, col6, col7, col8)      
 select         
  case when cd = 0 then 'cnt / min'        
    when cd = 1 then 'cpu / min'        
    when cd = 2 then 'reads / min'        
    when cd = 3 then 'duration / min'        
    when cd = 4 then 'cpu / cnt'        
    when cd = 5 then 'reads / cnt'        
    when cd = 6 then 'duration / cnt'        
  end as ' ',        
  convert(varchar(20), base) as [now] ,        
  convert(varchar(20),m20) as 'before 10 min',  convert(varchar(20), case when m20 = 0 then 0 else convert(numeric(10, 2), (base - m20) * 100 / convert(numeric(18, 2), m20)) end) as 'gap (10 min)',      
--  dbo.fn_gaprate(base, m20),     
  convert(varchar(20),d1) as 'before 1 day' , convert(varchar(20), case when d1 = 0 then 0 else convert(numeric(10, 2), (base - d1) * 100 / convert(numeric(18, 2), d1)) end) as 'gap (1 day)',        
  convert(varchar(20),w1) as 'before 1 week', convert(varchar(20), case when w1 = 0 then 0 else convert(numeric(10, 2), (base - w1) * 100 / convert(numeric(18, 2), w1)) end) as 'gap (1 week)'        
 from (        
  select 0 as cd,         
   sum(case when base_time_type = 0 then cnt_min else 0 end) as base,        
   sum(case when base_time_type = 1 then cnt_min else 0 end) as m20,        
   sum(case when base_time_type = 2 then cnt_min else 0 end) as d1,        
   sum(case when base_time_type = 3 then cnt_min else 0 end) as w1        
  from @proc        
  union all        
  select 1 as cd,         
   sum(case when base_time_type = 0 then cpu_min else 0 end) as base,        
   sum(case when base_time_type = 1 then cpu_min else 0 end) as m20,        
   sum(case when base_time_type = 2 then cpu_min else 0 end) as d1,        
   sum(case when base_time_type = 3 then cpu_min else 0 end) as w1        
  from @proc        
  union all        
  select 2 as cd,         
   sum(case when base_time_type = 0 then reads_min else 0 end) as base,        
   sum(case when base_time_type = 1 then reads_min else 0 end) as m20,        
   sum(case when base_time_type = 2 then reads_min else 0 end) as d1,        
   sum(case when base_time_type = 3 then reads_min else 0 end) as w1        
  from @proc          
  union all        
  select 3 as cd,         
   sum(case when base_time_type = 0 then duration_min else 0 end) as base,        
   sum(case when base_time_type = 1 then duration_min else 0 end) as m20,        
   sum(case when base_time_type = 2 then duration_min else 0 end) as d1,        
   sum(case when base_time_type = 3 then duration_min else 0 end) as w1        
  from @proc          
  union all        
  select 4 as cd,         
   sum(case when base_time_type = 0 then cpu_cnt else 0 end) as base,        
   sum(case when base_time_type = 1 then cpu_cnt else 0 end) as m20,        
   sum(case when base_time_type = 2 then cpu_cnt else 0 end) as d1,        
   sum(case when base_time_type = 3 then cpu_cnt else 0 end) as w1        
  from @proc            
  union all        
  select 5 as cd,         
   sum(case when base_time_type = 0 then reads_cnt else 0 end) as base,        
   sum(case when base_time_type = 1 then reads_cnt else 0 end) as m20,        
   sum(case when base_time_type = 2 then reads_cnt else 0 end) as d1,        
   sum(case when base_time_type = 3 then reads_cnt else 0 end) as w1        
  from @proc           
  union all        
  select 6 as cd,         
   sum(case when base_time_type = 0 then duration_cnt else 0 end) as base,        
   sum(case when base_time_type = 1 then duration_cnt else 0 end) as m20,        
   sum(case when base_time_type = 2 then duration_cnt else 0 end) as d1,        
   sum(case when base_time_type = 3 then duration_cnt else 0 end) as w1        
  from @proc           
 ) a        
      
 insert @excel (col1) values ('')         
    
 if @is_plan = 1          
 begin    
       
  insert @excel (col2) values ('view plan info')        
    
  insert @excel (col1, col2)      
  select a.name,    
  isnull('exec dbmon.dbo.up_mon_query_plan_info @plan_handle = ' + dbo.fnc_hexa2decimal(plan_handle) + ', @create_date = ''' + convert(varchar(23), create_date, 121) + '''' + ', @statement_start = '   
  + convert(varchar(10), @statement_start) + ', @statement_end = ' + convert(varchar(10), @statement_end), '')  as view_plan        
  from (    
   select 0 as type, 'now' as name    
   union all    
   select 1 as type, 'before 10 min' as name    
   union all    
   select 2 as type, 'before 1 day' as name    
   union all    
   select 3 as type, 'before 1 week' as name    
  ) a left join @proc b on a.type = b.base_time_type    
  order by a.type    
      
/*      
  select         
   case when base_time_type = 0 then 'now'        
     when base_time_type = 1 then 'before 10 min'        
     when base_time_type = 2 then 'before 1 day'        
     when base_time_type = 3 then 'before 1 week'        
   end base_time,          
   'exec up_mon_query_plan_info @plan_handle = ' + dbo.fnc_hexa2decimal(@plan_handle) + ', @create_date = ''' + convert(varchar(23), create_date, 121) + '''' + ', @statement_start = ' + convert(varchar(10), @statement_start) + ', @statement_end = '  
 + convert(varchar(10), @statement_end)  as view_plan        
  from @proc        
  order by base_time_type        
*/        
  insert @excel (col1) values ('')      
    
 end     
        
 delete  @proc      
      
end        
      
      
select col1, col2, col3, col4, col5, col6, col7, col8, col9, col10, col11, col12, col13, col14, col15 from @excel order by seq
GO

drop proc [up_mon_query_stats_object]
go

CREATE PROCEDURE [dbo].[up_mon_query_stats_object]
 @object_name sysname = null,
 @date datetime = null,  
 @rowcount int = 20  
AS  
SET NOCOUNT ON  

declare @basedate datetime
declare @max int, @seq int
declare @statement_start int, @statement_end int, @set_options int

declare @object table (
	seq int identity(1, 1) primary key,
	statement_start int,
	statement_end int,
	set_options int
)

if @object_name is null
begin
	print '@object_name   !!!'
	return
end

if @date is null set @date =  getdate()  

select @basedate = max(reg_date) from db_mon_query_stats_v3 (nolock) 

insert @object (statement_start, statement_end, set_options)
select statement_start, statement_end, set_options
from db_mon_query_stats_v3 (nolock) 
where object_name = @object_name and reg_date = @basedate
order by statement_start

select @max = @@rowcount, @seq = 1

while @seq <= @max
begin
  
   select @statement_start = statement_start, @statement_end = statement_end, @set_options = set_options
   from @object
   where seq = @seq
   
   set @seq = @seq + 1
  
	select top (@rowcount)  
	s.db_name,  
	s.object_name,  
	s.reg_date as to_date,   
	s.type,
	s.term, 
	s.set_options,  
	p.line_start,  
	p.line_end,  
	s.cnt_min,  
	s.cpu_rate,  
	s.cpu_min,  
	s.reads_min,  
	s.writes_min,  
	s.duration_min,  
	s.cpu_cnt,  
	s.reads_cnt,  
	s.writes_cnt, 
	s.duration_cnt,  
	s.plan_handle,
	s.statement_start,
	s.statement_end,
	s.create_date,   	
	s.query_text,
	p.query_plan
	from dbo.db_mon_query_stats_v3 s (nolock)   
	left join  dbo.db_mon_query_plan_v3 p (nolock)  
	  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
--	outer apply dbo.fn_getobjectline(s.plan_handle, s.statement_start, s.statement_end) f  
	where s.reg_date <= @date and s.object_name = @object_name
	  and s.statement_start = @statement_start and s.statement_end = @statement_end and s.set_options = @set_options
	order by s.reg_date desc

end
go

drop proc up_mon_query_stats_sp_rate
go

/*************************************************************************  
* : dbo.up_mon_query_stats_sp_rate
* 	: 2013-07-16 by choi bo ra
* :  
* 		:    sp   
* 	:
**************************************************************************/
CREATE PROCEDURE dbo.up_mon_query_stats_sp_rate
	 @type   varchar(10) = 'cpu',  -- cnt, i/o, 
	 @from_date	datetime, 
	 @sp_name sysname

AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE*/  
declare @basedate datetime, @total bigint
select @basedate = max(reg_date) from db_mon_query_stats_v3 (nolock)  
where reg_date <= @from_date

if @type = 'cpu'
begin
	

	
	select s.rank,
		s.db_name,  
		s.object_name,  
		s.reg_date as to_date,   
		s.type,
		s.term, 
		s.set_options,  
		p.line_start,  
		p.line_end,  
		s.cnt_min,  
		s.cpu_rate,  
		s.cpu_min,  
		s.reads_min,  
		s.writes_min,
		s.duration_min,  
		s.cpu_cnt,  
		s.reads_cnt,  
		s.writes_cnt,
		s.duration_cnt,  
		s.plan_handle,
		s.statement_start,
		s.statement_end,
		s.create_date, 
		s.query_text,
		p.query_plan
	from
	(select rank() over (order by cpu_min desc) as rank 
		,s.*
	from dbo.db_mon_query_stats_v3 s (nolock)  
	where reg_date = @basedate
	) as s
	 left join  dbo.db_mon_query_plan_v3 p (nolock)  
		  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
	where s.object_name  = @sp_name
	
end
else if @type = 'cnt'
begin
	
		select @total = sum(cnt_min) from  db_mon_query_stats_v3 (nolock)  where reg_date = @basedate 
		
		select s.rank,  convert(decimal(5,1), s.cnt_min *1.0 /@total * 100 ) as cnt_rate,
		s.db_name,  
		s.object_name,  
		s.reg_date as to_date,   
		s.type,
		s.term, 
		s.set_options,  
		p.line_start,  
		p.line_end,  
		s.cnt_min,  
		s.cpu_rate,  
		s.cpu_min,  
		s.reads_min,  
		s.writes_min,
		s.duration_min,  
		s.cpu_cnt,  
		s.reads_cnt,  
		s.writes_cnt,
		s.duration_cnt,  
		s.plan_handle,
		s.statement_start,
		s.statement_end,
		s.create_date, 
		s.query_text,
		p.query_plan
	from
	(select rank() over (order by cnt_min desc) as rank 
		,s.*
	from dbo.db_mon_query_stats_v3 s (nolock)  
	where reg_date = @basedate
	) as s
	 left join  dbo.db_mon_query_plan_v3 p (nolock)  
		  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
	where s.object_name  = @sp_name
	
end
else if @type = 'i/o'
begin
	
		select @total = sum(reads_min) from  db_mon_query_stats_v3 (nolock)  where reg_date = @basedate 
		
		
		select s.rank,  convert(decimal(5,1), s.reads_min *1.0 /@total * 100.0 ) as reads_rate,
		s.db_name,  
		s.object_name,  
		s.reg_date as to_date,   
		s.type,
		s.term, 
		s.set_options,  
		p.line_start,  
		p.line_end,  
		s.cnt_min,  
		s.cpu_rate,  
		s.cpu_min,  
		s.reads_min,  
		s.writes_min,
		s.duration_min,  
		s.cpu_cnt,  
		s.reads_cnt,  
		s.writes_cnt,
		s.duration_cnt,  
		s.plan_handle,
		s.statement_start,
		s.statement_end,
		s.create_date, 
		s.query_text,
		p.query_plan
	from
	(select rank() over (order by reads_min  desc) as rank 
		,s.*
	from dbo.db_mon_query_stats_v3 s (nolock)  
	where reg_date = @basedate
	) as s
	 left join  dbo.db_mon_query_plan_v3 p (nolock)  
		  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
	where s.object_name  = @sp_name
	
end
go


/* 2010-08-25 11:42 */  
--   seq   
-- plan     
-- date parameter   
--      
  
ALTER PROCEDURE [dbo].[up_mon_query_stats_object_excel]       
 @object_name sysname = null,  
 @date datetime = null,  
 @is_plan tinyint = 1  
AS      
      
set nocount on      
      
declare @base_time datetime      
declare @before_10min datetime      
declare @before_1day datetime      
declare @before_1week datetime      
    
declare @base_time_from datetime      
declare @before_10min_from datetime      
declare @before_1day_from datetime      
declare @before_1week_from datetime      
      
declare @proc_info table (      
 seq int identity(1, 1) primary key,      
 db_name varchar(32),      
 plan_handle varbinary(64),      
 statement_start int,      
 statement_end int      
)      
      
declare @max int, @seq int      
declare @db_name varchar(32), @statement_start int, @statement_end int, @plan_handle varbinary(64)      
      
declare @proc table (      
 base_time_type int,      
 plan_handle varbinary(64),      
 create_date datetime,      
 cnt_min bigint,      
 cpu_min bigint,      
 reads_min bigint,      
 duration_min bigint,      
 cpu_cnt bigint,      
 reads_cnt bigint,      
 duration_cnt bigint      
)      
      
declare @proc_pivot table (      
 seq int identity(1, 1) primary key,      
 type varchar(20),      
 base_date bigint,      
 before_10min bigint,      
 gap_10min numeric(5, 2),      
 before_1day bigint,      
 gap_1day numeric(5, 2),      
 before_1week bigint,      
 gap_1week numeric(5, 2)      
)      
    
declare @excel table (    
 seq int identity(1, 1) primary key,     
 col1 varchar(1000) default '',    
 col2 varchar(1000) default '',    
 col3 varchar(1000) default '',    
 col4 varchar(1000) default '',    
 col5 varchar(1000) default '',    
 col6 varchar(1000) default '',    
 col7 varchar(1000) default '',    
 col8 varchar(1000) default '',    
 col9 varchar(1000) default '',     
 col10 varchar(1000) default '',     
 col11 varchar(1000) default '',     
 col12 varchar(1000) default '',     
 col13 varchar(1000) default '',     
 col14 varchar(1000) default '',     
 col15 varchar(1000) default ''     
)    
      
if @object_name is null       
begin      
 print '@object_name    !!!'      
 return      
end      
  
if @date is null set @base_time = getdate()      
else set @base_time = @date  
      
select @base_time = max(reg_date), @base_time_from = max(from_date) from dbo.db_mon_query_stats_v3 (nolock)       
where reg_date <= @base_time      
      
select @before_10min = max(reg_date), @before_10min_from = max(from_date) from dbo.db_mon_query_stats_v3 (nolock)      
where reg_date <= dateadd(minute, 2, dateadd(minute, -10, @base_time))      
      
select @before_1day = max(reg_date), @before_1day_from = max(from_date) from dbo.db_mon_query_stats_v3 (nolock)      
where reg_date <= dateadd(minute, 2, dateadd(day, -1, @base_time))      
      
select @before_1week = max(reg_date), @before_1week_from = max(from_date) from dbo.db_mon_query_stats_v3 (nolock)      
where reg_date <= dateadd(minute, 2, dateadd(day, -6, @base_time))      
    
insert @excel (col2, col3) values ('from date', 'to date')    
    
insert @excel (col1, col2, col3)    
select 'now ' as ' ', convert(char(16), @base_time_from, 121) as 'from date', convert(char(16),@base_time, 121) as 'to date'    
union all    
select 'before 10 min' as ' ', convert(char(16), @before_10min_from, 121) as 'from date', convert(char(16),@before_10min, 121) as 'to date'    
union all    
select 'before 1 day' as ' ', convert(char(16), @before_1day_from, 121) as 'from date', convert(char(16),@before_1day, 121) as 'to date'    
union all    
select 'before 1 week' as ' ', convert(char(16), @before_1week_from, 121) as 'from date', convert(char(16),@before_1week, 121) as 'to date'    
  
insert @excel (col1) values ('')    
      
insert @proc_info (db_name, statement_start, statement_end, plan_handle)      
select db_name, statement_start, statement_end, plan_handle      
from dbo.db_mon_query_stats_v3 (nolock)       
where reg_date = @base_time and object_name = @object_name      
order by statement_start      
      
select @max = @@rowcount, @seq = 1      
      
while @seq <= @max      
begin      
      
 select @db_name = db_name, @statement_start = statement_start, @statement_end = statement_end, @plan_handle = plan_handle      
 from @proc_info a       
 where seq = @seq      
     
 insert @excel (col1, col4, col5, col6, col7, col8, col10, col12, col14)    
 values ('object name', 'db name', 'line start', 'line end', 'statement start', 'statement end', 'cnt / min', 'cpu / min', 'reads / min')    
/*     
 insert @excel (col1, col4, col5, col6, col7, col8)    
 select     
 @object_name as object_name,     
 @db_name as db_name,     
 convert(varchar(10), line_start),     
 convert(varchar(10), line_end),     
 convert(varchar(10), @statement_start),     
 convert(varchar(10), @statement_end)    
 from dbo.fn_getobjectline(@plan_handle, @statement_start, @statement_end)      
*/   
 insert @excel (col1, col4, col5, col6, col7, col8)  
 select top 1   
 @object_name as object_name,  
 @db_name as db_name,  
 convert(varchar(10), line_start),  
 convert(varchar(10), line_end),  
 convert(varchar(10), @statement_start),  
 convert(varchar(10), @statement_end)  
 from db_mon_query_plan_v3 (nolock)   
 where plan_handle = @plan_handle and statement_start = @statement_start and statement_end = @statement_end  
 order by create_date desc   
   
 insert @excel (col1)   
 select convert(varchar(140), dbo.fn_getquerytext(@plan_handle, @statement_start, @statement_end))  
     
 insert @excel (col1) values ('')    
       
      
 set @seq = @seq + 1      
      
 insert @proc (base_time_type, plan_handle, create_date, cnt_min, cpu_min, reads_min, duration_min, cpu_cnt, reads_cnt, duration_cnt)      
 select       
  case when reg_date = @base_time then 0       
    when reg_date = @before_10min then 1      
    when reg_date = @before_1day then 2      
    when reg_date = @before_1week then 3      
  end,      
  plan_handle, create_date      
   , cnt_min, cpu_min, reads_min, duration_min, cpu_cnt, reads_cnt, duration_cnt      
 from dbo.db_mon_query_stats_v3 (nolock)       
 where object_name = @object_name and (reg_date in (@base_time, @before_10min, @before_1day, @before_1week))      
   and statement_start = @statement_start and statement_end = @statement_end      
      
-- insert @proc_pivot (type, base_date, before_10min, gap_10min, before_1day, gap_1day, before_1week, gap_1week)      
    
 insert @excel (col2, col3, col4, col5, col6, col7, col8)    
 values ('now', 'before 10 min', '10 min gap', 'before 1 day', '1 day gap', 'before 1 week', '1 week gap')    
     
 insert @excel (col1, col2, col3, col4, col5, col6, col7, col8)    
 select       
  case when cd = 0 then 'cnt / min'      
    when cd = 1 then 'cpu / min'      
    when cd = 2 then 'reads / min'      
    when cd = 3 then 'duration / min'      
    when cd = 4 then 'cpu / cnt'      
    when cd = 5 then 'reads / cnt'      
    when cd = 6 then 'duration / cnt'      
  end as ' ',      
  convert(varchar(20), base) as [now] ,      
  convert(varchar(20),m20) as 'before 10 min', convert(varchar(20), case when m20 = 0 then 0 else convert(numeric(10, 2), (base - m20) * 100 / convert(numeric(18, 2), m20)) end) as 'gap (10 min)',      
  convert(varchar(20),d1) as 'before 1 day' , convert(varchar(20), case when d1 = 0 then 0 else convert(numeric(10, 2), (base - d1) * 100 / convert(numeric(18, 2), d1)) end) as 'gap (1 day)',      
  convert(varchar(20),w1) as 'before 1 week', convert(varchar(20), case when w1 = 0 then 0 else convert(numeric(10, 2), (base - w1) * 100 / convert(numeric(18, 2), w1)) end) as 'gap (1 week)'      
 from (      
  select 0 as cd,       
   sum(case when base_time_type = 0 then cnt_min else 0 end) as base,      
   sum(case when base_time_type = 1 then cnt_min else 0 end) as m20,      
   sum(case when base_time_type = 2 then cnt_min else 0 end) as d1,      
   sum(case when base_time_type = 3 then cnt_min else 0 end) as w1      
  from @proc      
  union all      
  select 1 as cd,       
   sum(case when base_time_type = 0 then cpu_min else 0 end) as base,      
   sum(case when base_time_type = 1 then cpu_min else 0 end) as m20,      
   sum(case when base_time_type = 2 then cpu_min else 0 end) as d1,      
   sum(case when base_time_type = 3 then cpu_min else 0 end) as w1      
  from @proc      
  union all      
  select 2 as cd,       
   sum(case when base_time_type = 0 then reads_min else 0 end) as base,      
   sum(case when base_time_type = 1 then reads_min else 0 end) as m20,      
   sum(case when base_time_type = 2 then reads_min else 0 end) as d1,      
   sum(case when base_time_type = 3 then reads_min else 0 end) as w1      
  from @proc        
  union all      
  select 3 as cd,       
   sum(case when base_time_type = 0 then duration_min else 0 end) as base,      
   sum(case when base_time_type = 1 then duration_min else 0 end) as m20,      
   sum(case when base_time_type = 2 then duration_min else 0 end) as d1,      
   sum(case when base_time_type = 3 then duration_min else 0 end) as w1      
  from @proc        
  union all      
  select 4 as cd,       
   sum(case when base_time_type = 0 then cpu_cnt else 0 end) as base,      
   sum(case when base_time_type = 1 then cpu_cnt else 0 end) as m20,      
   sum(case when base_time_type = 2 then cpu_cnt else 0 end) as d1,      
   sum(case when base_time_type = 3 then cpu_cnt else 0 end) as w1      
  from @proc          
  union all      
  select 5 as cd,       
   sum(case when base_time_type = 0 then reads_cnt else 0 end) as base,      
   sum(case when base_time_type = 1 then reads_cnt else 0 end) as m20,      
   sum(case when base_time_type = 2 then reads_cnt else 0 end) as d1,      
   sum(case when base_time_type = 3 then reads_cnt else 0 end) as w1      
  from @proc         
  union all      
  select 6 as cd,       
   sum(case when base_time_type = 0 then duration_cnt else 0 end) as base,      
   sum(case when base_time_type = 1 then duration_cnt else 0 end) as m20,      
   sum(case when base_time_type = 2 then duration_cnt else 0 end) as d1,      
   sum(case when base_time_type = 3 then duration_cnt else 0 end) as w1      
  from @proc         
 ) a      
    
 insert @excel (col1) values ('')       
  
 if @is_plan = 1        
 begin  
     
  insert @excel (col2) values ('view plan info')      
  
  insert @excel (col1, col2)      
  select a.name,    
  isnull('exec dbmon.dbo.up_mon_query_plan_info @plan_handle = ' + dbo.fnc_hexa2decimal(plan_handle) + ', @create_date = ''' + convert(varchar(23), create_date, 121) + '''' + ', @statement_start = '   
  + convert(varchar(10), @statement_start) + ', @statement_end = ' + convert(varchar(10), @statement_end), '')  as view_plan        
  from (    
   select 0 as type, 'now' as name    
   union all    
   select 1 as type, 'before 10 min' as name    
   union all    
   select 2 as type, 'before 1 day' as name    
   union all    
   select 3 as type, 'before 1 week' as name    
  ) a left join @proc b on a.type = b.base_time_type    
  order by a.type    
      
  insert @excel (col1) values ('')    
  
 end   
      
 delete  @proc    
    
end      
    
    
select col1, col2, col3, col4, col5, col6, col7, col8, col9, col10, col11, col12, col13, col14, col15 from @excel order by seq
go

drop proc [up_mon_query_plan_info]
go

/* 2010-08-25 13:32 */
CREATE PROCEDURE [dbo].[up_mon_query_plan_info]
	@plan_handle varbinary(64),
	@statement_start int,
	@statement_end int,
	@create_date datetime
AS
set nocount on

	select db_name, object_name, f.line_start, f.line_end, 
		dbo.fn_getquerytext(plan_handle, statement_start, statement_end) as query, query_plan
	from dbo.db_mon_query_plan_v3 p (nolock) 
		cross apply dbo.fn_getobjectline(p.plan_handle, p.statement_start, p.statement_end) f
	where plan_handle = @plan_handle
	  and statement_start = @statement_start
	  and statement_end = @statement_end
	  and create_date = @create_date
	  
	exec up_mon_query_plan_scan_info @plan_handle = @plan_handle, @statement_start = @statement_start
	, @statement_end = @statement_end, @create_date = @create_date
go


CREATE PROCEDURE UP_MON_COLLECT_QUERY_PLAN_OBJECT
	@OBJECT_NAME SYSNAME             
AS              
set nocount on              
              
declare @reg_date datetime              
declare @seq int, @max int              
declare @plan_handle varbinary(64), @statement_start int, @statement_end int, @create_date datetime        
declare @db_id smallint              
              
declare @plan_info table (              
 seq int identity(1, 1) primary key,              
 plan_handle varbinary(64),              
 statement_start int,              
 statement_end int,              
 create_date datetime,        
 db_id smallint         
)        
              
select @reg_date = max(reg_date) from DB_MON_QUERY_STATS_V3 (nolock)              
              
if exists (select top 1 * from DB_MON_QUERY_PLAN_V3 (nolock) where reg_date = @reg_date and object_name=@OBJECT_NAME)              
begin              
 print '   plan  !'              
 return              
end              
              
insert @plan_info (plan_handle, statement_start, statement_end, create_date, db_id)              
select plan_handle, statement_start, statement_end, create_date, db_id         
from DB_MON_QUERY_STATS_V3 with (nolock)     
where reg_date = @reg_date  AND	object_name = @object_name           
--and  cpu_rate > 0.5             
              
select @seq = 1, @max = @@rowcount              
              
while @seq <= @max              
begin              
              
 select @plan_handle = plan_handle,              
     @statement_start = statement_start,              
     @statement_end = statement_end,              
     @create_date = create_date,        
     @db_id = db_id              
 from @plan_info              
 where seq = @seq              
               
 set @seq = @seq + 1              
         
 if @db_id < 5 continue        
               
 if not exists (              
  select top 1 * from DB_MON_QUERY_PLAN_V3 (nolock)               
  where plan_handle = @plan_handle and statement_start = @statement_start and statement_end = @statement_end and create_date = @create_date)              
 begin              
        
  begin try      
  insert DB_MON_QUERY_PLAN_V3               
   (plan_handle, statement_start, statement_end, create_date, set_options, db_name,       
   object_name, query_plan, reg_date, upd_date, line_start, line_end)              
  select               
      @plan_handle,              
      @statement_start,              
      @statement_end,              
      @create_date,              
      0,              
      db_name(dbid) as db_name,               
      object_name(objectid, dbid) as object_name,              
      query_plan,             
      @reg_date,        
      @reg_date,      
      f.line_start, f.line_end              
  from sys.dm_exec_text_query_plan(@plan_handle, @statement_start, @statement_end)      
 outer apply dbo.fn_getobjectline(@plan_handle, @statement_start, @statement_end) f          
  where dbid >= 5            
  end try      
  begin catch  -- xml   (depth  128   )      
   insert DB_MON_QUERY_PLAN_V3               
    (plan_handle, statement_start, statement_end, create_date, set_options, db_name,       
  object_name, query_plan, reg_date, upd_date, line_start, line_end)              
   select @plan_handle, @statement_start, @statement_end, @create_date, 0,       
    db_name(dbid) as db_name,      
    object_name(objectid, dbid) as object_name,      
    null,      
    @reg_date,      
    @reg_date,      
    f.line_start, f.line_end      
   from sys.dm_exec_text_query_plan(@plan_handle, @statement_start, @statement_end)            
    outer apply dbo.fn_getobjectline(@plan_handle, @statement_start, @statement_end) f          
  end catch      
              
 end              
 else         
 begin 
 update DB_MON_QUERY_PLAN_V3      
 set upd_date = @reg_date        
 where plan_handle = @plan_handle and statement_start = @statement_start and statement_end = @statement_end and create_date = @create_date        
 end        
            
end 
go

drop proc [UP_MON_COLLECT_QUERY_PLAN_DELETE_V3]
go


CREATE PROCEDURE [DBO].[UP_MON_COLLECT_QUERY_PLAN_DELETE_V3]
AS
SET NOCOUNT ON

DECLARE @DATE DATETIME

SET @DATE = DATEADD(HOUR, -12, DATEADD(DAY, -8, GETDATE()))

DELETE DBMON.DBO.DB_MON_QUERY_PLAN_V3 WHERE UPD_DATE <= @DATE
go



drop proc [up_mon_collect_procedure_stats_total]
go


create PROCEDURE [dbo].[up_mon_collect_procedure_stats_total]    
AS    
set nocount on    
    
exec up_switch_partition @table_name = 'DB_MON_PROCEDURE_STATS_TOTAL', @column_name = 'REG_DATE'       
    
declare @reg_date datetime    
  
declare @procedure_stats table (  
 db_id int not null,   
 object_id int not null,   
 sql_handle varbinary(64),   
 cached_time datetime not null,  
 plan_handle varbinary(64),   
 execution_count bigint,  
 worker_time bigint,  
 physical_reads bigint,  
 logical_reads bigint,  
 logical_writes bigint,  
 elapsed_time bigint  
)  
    
set @reg_date = GETDATE()    
  
insert @procedure_stats (    
 db_id, object_id, sql_handle, plan_handle, cached_time,    
 execution_count, worker_time, physical_reads, logical_reads, logical_writes, elapsed_time )    
select     
 database_id,    
 object_id,    
 sql_handle,    
 plan_handle,    
 cached_time,    
 execution_count,    
 total_worker_time,    
 total_physical_reads,    
 total_logical_reads,    
 total_logical_writes,    
 total_elapsed_time    
from sys.dm_exec_procedure_stats with (nolock)  
where database_id<>32767  
  
insert dbo.DB_MON_PROCEDURE_STATS_TOTAL (    
 reg_date, db_id, object_id, sql_handle, plan_handle, cached_time,    
 execution_count, worker_time, physical_reads, logical_reads, logical_writes, elapsed_time )    
select getdate(),   
 db_id,    
 object_id,    
 sql_handle,    
 plan_handle,    
 cached_time,    
 execution_count,    
 worker_time,    
 physical_reads,    
 logical_reads,    
 logical_writes,    
 elapsed_time    
from @procedure_stats a  
where cached_time = (select top 1 cached_time from @procedure_stats where db_id = a.db_id and object_id = a.object_id and sql_handle = a.sql_handle order by cached_time desc)  
go


drop proc up_mon_collect_procedure_stats
go

CREATE PROCEDURE [dbo].[up_mon_collect_procedure_stats]  
AS    
    
set nocount on    
    
exec up_switch_partition @table_name = 'DB_MON_PROCEDURE_STATS', @column_name = 'REG_DATE'       
    
declare @from_date datetime, @to_date datetime, @reg_date datetime    
declare @to_worker_time bigint, @from_worker_time bigint, @worker_time_min money  
declare @term int  
    
select @to_date = max(reg_date) from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)    

if exists (select top 1 * from DB_MON_PROCEDURE_STATS (nolock) where reg_date >= @to_date) 
begin
	print '이미 해당 데이터가 존재합니다.'
	return
end
    
select @to_worker_time = SUM(worker_time)   
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)   
where reg_date = @to_date
    
select sql_handle, plan_handle, db_id, object_id, cached_time, execution_count as count, worker_time, logical_reads, elapsed_time, logical_writes    
into #resource_to  
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)    
where reg_date = @to_date  
    
select @from_date = max(reg_date) from DB_MON_PROCEDURE_STATS_TOTAL with (nolock) where reg_date < @to_date    
  
select @from_worker_time = SUM(worker_time)   
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)   
where reg_date = @from_date   
  and sql_handle in (select sql_handle from #resource_to )  
  
select sql_handle, plan_handle, db_id, object_id, cached_time, execution_count as count, worker_time, logical_reads, elapsed_time , logical_writes
into #resource_from    
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)    
where reg_date = @from_date  
  
set @term = DATEDIFF(second, @from_date, @to_date)
set @worker_time_min = @to_worker_time - @from_worker_time

select @from_date, @to_date, @term, @worker_time_min
  
set @reg_date = GETDATE()    
 
  
insert DB_MON_PROCEDURE_STATS (  
 reg_date, db_id, object_id, db_name, object_name, cached_time, from_date, to_date,   
 cnt_min, cpu_rate, cpu_min, reads_min, writes_min,duration_min, cpu_cnt, reads_cnt, writes_cnt, duration_cnt, sql_handle, term)  
select @reg_date as reg_date  
     , a.DB_ID as db_id
     , a.OBJECT_ID as object_id  
     , DB_NAME(a.db_id) as db_name  
  , OBJECT_NAME(a.object_id, a.db_id) as object_name  
  , a.cached_time  
  , @from_date as from_date  
  , @to_date as to_date  
  , (a.count - isnull(b.count, 0)) * 60 / @term as cnt_min
  , case when @worker_time_min > 0 then convert(money, (a.worker_time - ISNULL(b.worker_time, 0))) * 100 / @worker_time_min else 0 end as cpu_rate  
  , (a.worker_time - ISNULL(b.worker_time, 0)) * 60 / @term as cpu_min  
  , (a.logical_reads - ISNULL(b.logical_reads, 0)) * 60 / @term as reads_min  
  , (a.logical_writes - ISNULL(b.logical_writes, 0)) * 60 / @term as writes_min 
  , (a.elapsed_time - ISNULL(b.elapsed_time, 0)) * 60 / @term as duration_min  
  , (a.worker_time - ISNULL(b.worker_time, 0)) / (a.count - ISNULL(b.count, 0)) as cpu_cnt  
  , (a.logical_reads - ISNULL(b.logical_reads, 0)) / (a.count - ISNULL(b.count, 0)) as reads_cnt  
  , (a.logical_writes - ISNULL(b.logical_writes, 0)) / (a.count - ISNULL(b.count, 0)) as writes_cnt  
  , (a.elapsed_time - ISNULL(b.elapsed_time, 0)) / (a.count - ISNULL(b.count, 0)) as duration_cnt  
  , a.sql_handle  
  , @term as term  
from #resource_to A with (nolock)                 
 left join #resource_from b with (nolock) on a.sql_handle  = b.sql_handle and a.plan_handle = b.plan_handle  
where (a.count - b.count) > 0    
order by cpu_rate desc  
  
    
drop table #resource_from  
drop table #resource_to  
go



drop proc [up_mon_collect_procedure_stats_hour]
go

/*************************************************************************  
* 프로시저명  : dbo.up_mon_collect_procedure_stats_hour
* 작성정보    : 2011-01-14 수정 top 1로 변경
* 관련페이지  : 
* 내용        : 
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_collect_procedure_stats_hour]      
AS        
        
set nocount on        
        
exec up_switch_partition @table_name = 'DB_MON_PROCEDURE_STATS_HOUR', @column_name = 'REG_DATE'           
        
declare @from_date datetime, @to_date datetime, @reg_date datetime        
declare @to_worker_time bigint, @from_worker_time bigint, @worker_time_min money    
declare @term int      
        
select top 1 @to_date = reg_date 
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock) 
order by  reg_date desc
    
if exists (select top 1 * from DB_MON_PROCEDURE_STATS_HOUR (nolock) 
    where reg_date >= dateadd(hour, -2, @to_date))    
begin    
 print '이미 해당 데이터가 존재합니다.'    
 return    
end    
    
select top 1 @to_date = reg_date
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock) 
where reg_date < convert(datetime, convert(char(13), @to_date, 121) + ':00') 
order by reg_date desc

   
    
select @to_worker_time = SUM(worker_time)       
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)       
where reg_date = @to_date    
        
select sql_handle, plan_handle, db_id, object_id, cached_time, execution_count as count, worker_time, logical_reads, logical_writes, elapsed_time        
into #resource_to      
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)        
where reg_date = @to_date      
        
select  top  1 @from_date = reg_date
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock) 
where reg_date < convert(datetime, convert(char(13), @to_date, 121) + ':00')   
order by reg_date desc 
      
select @from_worker_time = SUM(worker_time)       
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)       
where reg_date = @from_date       
  and sql_handle in (select sql_handle from #resource_to )      
      
select sql_handle, plan_handle, db_id, object_id, cached_time, execution_count as count, worker_time, logical_reads, logical_writes, elapsed_time        
into #resource_from        
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)        
where reg_date = @from_date      
      
set @term = DATEDIFF(second, @from_date, @to_date)    
set @worker_time_min = @to_worker_time - @from_worker_time    
    
--select @from_date, @to_date, @term, @worker_time_min    
      
set @reg_date = convert(datetime, convert(char(13), @to_date, 121) + ':00')    

      
insert DB_MON_PROCEDURE_STATS_HOUR (      
 reg_date, db_id, object_id, db_name, object_name, cached_time, from_date, to_date,       
 cnt_min, cpu_rate, cpu_min, reads_min, writes_min, duration_min, cpu_cnt, reads_cnt, writes_cnt, duration_cnt, sql_handle, term)      
select @reg_date as reg_date      
     , a.DB_ID as db_id    
     , a.OBJECT_ID as object_id      
     , DB_NAME(a.db_id) as db_name      
  , OBJECT_NAME(a.object_id, a.db_id) as object_name      
  , a.cached_time      
  , @from_date as from_date      
  , @to_date as to_date      
  , (a.count - isnull(b.count, 0)) * 60 / @term as cnt_min    
  , case when @worker_time_min > 0 
    then convert(money, (a.worker_time - ISNULL(b.worker_time, 0))) * 100 / @worker_time_min else 0
     end as cpu_rate      
  , (a.worker_time - ISNULL(b.worker_time, 0)) * 60 / @term as cpu_min      
  , (a.logical_reads - ISNULL(b.logical_reads, 0)) * 60 / @term as reads_min   
  , (a.logical_writes - ISNULL(b.logical_writes, 0)) * 60 / @term as writes_min      
  , (a.elapsed_time - ISNULL(b.elapsed_time, 0)) * 60 / @term as duration_min      
  , (a.worker_time - ISNULL(b.worker_time, 0)) / (a.count - ISNULL(b.count, 0)) as cpu_cnt      
  , (a.logical_reads - ISNULL(b.logical_reads, 0)) / (a.count - ISNULL(b.count, 0)) as reads_cnt   
  , (a.logical_writes - ISNULL(b.logical_writes, 0)) / (a.count - ISNULL(b.count, 0)) as wriates_cnt      
  , (a.elapsed_time - ISNULL(b.elapsed_time, 0)) / (a.count - ISNULL(b.count, 0)) as duration_cnt      
  , a.sql_handle      
  , @term as term      
from #resource_to A with (nolock)                     
 left join #resource_from b with (nolock) on a.sql_handle  = b.sql_handle and a.plan_handle = b.plan_handle      
where (a.count - b.count) > 0        
order by cpu_rate desc   
option (maxdop 1)   
   
        
drop table #resource_from 
drop table #resource_TO
GO




drop proc [up_mon_collect_procedure_stats]
go


CREATE PROCEDURE [dbo].[up_mon_collect_procedure_stats]  
AS    
    
set nocount on    
    
exec up_switch_partition @table_name = 'DB_MON_PROCEDURE_STATS', @column_name = 'REG_DATE'       
    
declare @from_date datetime, @to_date datetime, @reg_date datetime    
declare @to_worker_time bigint, @from_worker_time bigint, @worker_time_min money  
declare @term int  
    
select @to_date = max(reg_date) from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)    

if exists (select top 1 * from DB_MON_PROCEDURE_STATS (nolock) where reg_date >= @to_date) 
begin
	print '이미 해당 데이터가 존재합니다.'
	return
end
    
select @to_worker_time = SUM(worker_time)   
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)   
where reg_date = @to_date
    
select sql_handle, plan_handle, db_id, object_id, cached_time, execution_count as count, worker_time, logical_reads, elapsed_time, logical_writes   
into #resource_to  
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)    
where reg_date = @to_date  
    
select @from_date = max(reg_date) from DB_MON_PROCEDURE_STATS_TOTAL with (nolock) where reg_date < @to_date    
  
select @from_worker_time = SUM(worker_time)   
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)   
where reg_date = @from_date   
  and sql_handle in (select sql_handle from #resource_to )  
  
select sql_handle, plan_handle, db_id, object_id, cached_time, execution_count as count, worker_time, logical_reads, elapsed_time, logical_writes
into #resource_from    
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)    
where reg_date = @from_date  
  
set @term = DATEDIFF(second, @from_date, @to_date)
set @worker_time_min = @to_worker_time - @from_worker_time

select @from_date, @to_date, @term, @worker_time_min
  
set @reg_date = GETDATE()    
 
  
insert DB_MON_PROCEDURE_STATS (  
 reg_date, db_id, object_id, db_name, object_name, cached_time, from_date, to_date,   
 cnt_min, cpu_rate, cpu_min, reads_min, writes_min,duration_min, cpu_cnt, reads_cnt, writes_cnt, duration_cnt, sql_handle, term, plan_handle)  
select @reg_date as reg_date  
     , a.DB_ID as db_id
     , a.OBJECT_ID as object_id  
     , DB_NAME(a.db_id) as db_name  
  , OBJECT_NAME(a.object_id, a.db_id) as object_name  
  , a.cached_time  
  , @from_date as from_date  
  , @to_date as to_date  
  , (a.count - isnull(b.count, 0)) * 60 / @term as cnt_min
  , round(case when @worker_time_min > 0 then convert(money, (a.worker_time - ISNULL(b.worker_time, 0))) * 100 / @worker_time_min else 0 end,2) as cpu_rate  
  , (a.worker_time - ISNULL(b.worker_time, 0)) * 60 / @term as cpu_min  
  , (a.logical_reads - ISNULL(b.logical_reads, 0)) * 60 / @term as reads_min  
  , (a.logical_writes - ISNULL(b.logical_writes, 0)) * 60 / @term as writes_min 
  , (a.elapsed_time - ISNULL(b.elapsed_time, 0)) * 60 / @term as duration_min  
  , (a.worker_time - ISNULL(b.worker_time, 0)) / (a.count - ISNULL(b.count, 0)) as cpu_cnt  
  , (a.logical_reads - ISNULL(b.logical_reads, 0)) / (a.count - ISNULL(b.count, 0)) as reads_cnt  
  , (a.logical_writes - ISNULL(b.logical_writes, 0)) / (a.count - ISNULL(b.count, 0)) as writes_cnt  
  , (a.elapsed_time - ISNULL(b.elapsed_time, 0)) / (a.count - ISNULL(b.count, 0)) as duration_cnt  
  , a.sql_handle  
  , @term as term  
  , a.plan_handle
from #resource_to A with (nolock)                 
 left join #resource_from b with (nolock) on a.sql_handle  = b.sql_handle and a.plan_handle = b.plan_handle  
where (a.count - b.count) > 0    
order by cpu_rate desc  
  
    
drop table #resource_from   
drop table #resource_to 
go


drop proc [up_mon_procedure_object]
go

/*************************************************************************    
* 프로시저명  : dbo.[up_mon_procedure_object]  
* 작성정보    : 2014-10-29 by choi bo ra
* 관련페이지  :   
* 내용        : 프로시저 정보 
* 수정정보    : [up_mon_procedure_object] 
**************************************************************************/  
CREATE PROCEDURE [dbo].[up_mon_procedure_object]
 @object_name sysname = null,
 @date datetime = null,  
 @rowcount int = 10  
AS  
SET NOCOUNT ON  

declare @basedate datetime, @query_basedate datetime
declare @max int, @seq int
declare @statement_start int, @statement_end int, @set_options int



if @object_name is null
begin
	print '@object_name 이 입력되어야 합니다!!!'
	return
end

if @date is null set @date =  getdate()  

select @basedate = max(reg_date) from DB_MON_PROCEDURE_STATS (nolock) 

-- 프로시저 내역
select top ( @rowcount)  reg_date,  from_date, to_date,term, db_name, object_name, cached_time, cpu_rate
	, cnt_min,cpu_min, reads_min, writes_min,duration_min
	, cpu_cnt, reads_cnt, writes_cnt, duration_cnt
	--, CONVERT(XML, P.query_plan) AS query_plan
	, sql_handle,plan_handle
from DBMON.DBO.DB_MON_PROCEDURE_STATS AS S WITH(NOLOCK) 
--	cross apply sys.dm_exec_query_plan  (s.plan_handle) as p
where s.reg_date <= @basedate
 and s.object_name = @object_name
order by s.reg_date desc

go

/*************************************************************************    
* 프로시저명  : dbo.up_mon_procedure_top_cpu 
* 작성정보    : 2014-10-29 by choi bo ra
* 관련페이지  :   
* 내용        : 프로시저 정보 
* 수정정보    : up_mon_query_procedure_top_cpu
**************************************************************************/  
CREATE PROCEDURE [dbo].up_mon_procedure_top_cpu
 @date datetime = null,  
 @rowcount int = 20  
AS  
SET NOCOUNT ON  

if @date is null set @date =  getdate()

select top 1 @date = reg_date from DB_MON_PROCEDURE_STATS (nolock) 
where reg_date <= @date order by reg_date desc
  
select top (@rowcount)  
	s.db_name,  
	s.object_name,  
	s.reg_date as to_date,   
	s.term, 
	s.cnt_min,  
	s.cpu_rate,  
	s.cpu_min,  
	s.reads_min, 
	s.writes_min ,
	s.duration_min,  
	s.cpu_cnt,  
	s.reads_cnt, 
	s.writes_cnt, 
	s.duration_cnt,  
	s.cached_time,   
	--p.query_plan,
	s.sql_handle
	from dbo.DB_MON_PROCEDURE_STATS s (nolock)   
	--	cross apply sys.dm_exec_query_plan (s.plan_handle) as p
	where s.reg_date = @date  
	order by  s.cpu_min desc , s.cpu_rate desc
go

/*************************************************************************    
* 프로시저명  : dbo.up_mon_procedure_top_reads 
* 작성정보    : 2014-10-29 by choi bo ra
* 관련페이지  :   
* 내용        : 프로시저 정보 
* 수정정보    : up_mon_procedure_top_reads
**************************************************************************/  
CREATE PROCEDURE [dbo].up_mon_procedure_top_reads
 @date datetime = null,  
 @rowcount int = 20  
AS  
SET NOCOUNT ON  

if @date is null set @date =  getdate()

select top 1 @date = reg_date from DB_MON_PROCEDURE_STATS (nolock) 
where reg_date <= @date order by reg_date desc
  
select top (@rowcount)  
	s.db_name,  
	s.object_name,  
	s.reg_date as to_date,   
	s.term, 
	s.cnt_min,  
	s.cpu_rate,  
	s.cpu_min,  
	s.reads_min, 
	s.writes_min ,
	s.duration_min,  
	s.cpu_cnt,  
	s.reads_cnt, 
	s.writes_cnt, 
	s.duration_cnt,  
	s.cached_time,   
	--p.query_plan,
	s.sql_handle
	from dbo.DB_MON_PROCEDURE_STATS s (nolock)   
	--	cross apply sys.dm_exec_query_plan (s.plan_handle) as p
	where s.reg_date = @date  
	order by  s.reads_min desc , s.cpu_rate desc
go

/*************************************************************************    
* 프로시저명  : dbo.up_mon_procedure_top_writes 
* 작성정보    : 2014-10-29 by choi bo ra
* 관련페이지  :   
* 내용        : 프로시저 정보 
* 수정정보    : up_mon_procedure_top_writes
**************************************************************************/  
CREATE PROCEDURE [dbo].up_mon_procedure_top_writes
 @date datetime = null,  
 @rowcount int = 20  
AS  
SET NOCOUNT ON  

if @date is null set @date =  getdate()

select top 1 @date = reg_date from DB_MON_PROCEDURE_STATS (nolock) 
where reg_date <= @date order by reg_date desc
  
select top (@rowcount)  
	s.db_name,  
	s.object_name,  
	s.reg_date as to_date,   
	s.term, 
	s.cnt_min,  
	s.cpu_rate,  
	s.cpu_min,  
	s.reads_min, 
	s.writes_min ,
	s.duration_min,  
	s.cpu_cnt,  
	s.reads_cnt, 
	s.writes_cnt, 
	s.duration_cnt,  
	s.cached_time,   
--	p.query_plan,
	s.sql_handle
	from dbo.DB_MON_PROCEDURE_STATS s (nolock)   
--		cross apply sys.dm_exec_query_plan (s.plan_handle) as p
	where s.reg_date = @date  
	order by  s.writes_min desc , s.cpu_rate desc

go

/*************************************************************************    
* 프로시저명  : dbo.up_mon_procedure_top_cnt 
* 작성정보    : 2014-10-29 by choi bo ra
* 관련페이지  :   
* 내용        : 프로시저 정보 
* 수정정보    : up_mon_procedure_top_cnt
**************************************************************************/  
CREATE PROCEDURE [dbo].up_mon_procedure_top_cnt
 @date datetime = null,  
 @rowcount int = 20  
AS  
SET NOCOUNT ON  

if @date is null set @date =  getdate()

select top 1 @date = reg_date from DB_MON_PROCEDURE_STATS (nolock) 
where reg_date <= @date order by reg_date desc
  
select top (@rowcount)  
	s.db_name,  
	s.object_name,  
	s.reg_date as to_date,   
	s.term, 
	s.cnt_min,  
	s.cpu_rate,  
	s.cpu_min,  
	s.reads_min, 
	s.writes_min ,
	s.duration_min,  
	s.cpu_cnt,  
	s.reads_cnt, 
	s.writes_cnt, 
	s.duration_cnt,  
	s.cached_time,   
--	p.query_plan,
	s.sql_handle
	from dbo.DB_MON_PROCEDURE_STATS s (nolock)   
--		cross apply sys.dm_exec_query_plan (s.plan_handle) as p
	where s.reg_date = @date  
	order by  s.cnt_min desc , s.cpu_rate desc
go
/*************************************************************************    
* 프로시저명  : dbo.up_mon_procedure_top_duration 
* 작성정보    : 2014-10-29 by choi bo ra
* 관련페이지  :   
* 내용        : 프로시저 정보 
* 수정정보    : up_mon_procedure_top_duration
**************************************************************************/  
CREATE PROCEDURE [dbo].up_mon_procedure_top_duration
 @date datetime = null,  
 @rowcount int = 20  
AS  
SET NOCOUNT ON  

if @date is null set @date =  getdate()

select top 1 @date = reg_date from DB_MON_PROCEDURE_STATS (nolock) 
where reg_date <= @date order by reg_date desc
  
select top (@rowcount)  
	s.db_name,  
	s.object_name,  
	s.reg_date as to_date,   
	s.term, 
	s.cnt_min,  
	s.cpu_rate,  
	s.cpu_min,  
	s.reads_min, 
	s.writes_min ,
	s.duration_min,  
	s.cpu_cnt,  
	s.reads_cnt, 
	s.writes_cnt, 
	s.duration_cnt,  
	s.cached_time,   
--	p.query_plan,
	s.sql_handle
	from dbo.DB_MON_PROCEDURE_STATS s (nolock)   
		--cross apply sys.dm_exec_query_plan (s.plan_handle) as p
	where s.reg_date = @date  
	order by  s.duration_cnt desc , s.cpu_rate desc
go
/*************************************************************************    
* 프로시저명  : dbo.up_mon_procedure_top_1sp 
* 작성정보    : 2014-10-29 by choi bo ra
* 관련페이지  :   
* 내용        : 프로시저 정보 
* 수정정보    : up_mon_procedure_top_1sp
**************************************************************************/  
CREATE PROCEDURE [dbo].up_mon_procedure_top_1sp
 @type nvarchar(10)  = 'cpu',
 @date datetime = null,  
 @rowcount int = 20  
AS  
SET NOCOUNT ON  

if @date is null set @date =  getdate()

select top 1 @date = reg_date from DB_MON_PROCEDURE_STATS (nolock) 
where reg_date <= @date order by reg_date desc

if @type = 'cpu'
begin

  
	select top (@rowcount)  
		s.db_name,  
		s.object_name,  
		s.reg_date as to_date,   
		s.term, 
		s.cnt_min,  
		s.cpu_rate,  
		s.cpu_min,  
		s.reads_min, 
		s.writes_min ,
		s.duration_min,  
		s.cpu_cnt,  
		s.reads_cnt, 
		s.writes_cnt, 
		s.duration_cnt,  
		s.cached_time,   
	--	p.query_plan,
		s.sql_handle
		from dbo.DB_MON_PROCEDURE_STATS s (nolock)   
	--		cross apply sys.dm_exec_query_plan (s.plan_handle) as p
		where s.reg_date = @date  
		order by  s.cpu_cnt desc , s.cpu_rate desc
end
else if @type = 'reads'
begin
	  
	select top (@rowcount)  
		s.db_name,  
		s.object_name,  
		s.reg_date as to_date,   
		s.term, 
		s.cnt_min,  
		s.cpu_rate,  
		s.cpu_min,  
		s.reads_min, 
		s.writes_min ,
		s.duration_min,  
		s.cpu_cnt,  
		s.reads_cnt, 
		s.writes_cnt, 
		s.duration_cnt,  
		s.cached_time,   
	--	p.query_plan,
		s.sql_handle
		from dbo.DB_MON_PROCEDURE_STATS s (nolock)   
	--		cross apply sys.dm_exec_query_plan (s.plan_handle) as p
		where s.reg_date = @date  
		order by  s.reads_cnt desc , s.cpu_rate desc
end
else if @type = 'writes'
begin
	  
	select top (@rowcount)  
		s.db_name,  
		s.object_name,  
		s.reg_date as to_date,   
		s.term, 
		s.cnt_min,  
		s.cpu_rate,  
		s.cpu_min,  
		s.reads_min, 
		s.writes_min ,
		s.duration_min,  
		s.cpu_cnt,  
		s.reads_cnt, 
		s.writes_cnt, 
		s.duration_cnt,  
		s.cached_time,   
--		p.query_plan,
		s.sql_handle
		from dbo.DB_MON_PROCEDURE_STATS s (nolock)   
--			cross apply sys.dm_exec_query_plan (s.plan_handle) as p
		where s.reg_date = @date  
		order by  s.writes_cnt desc , s.cpu_rate desc
end
else if @type = 'duration'
begin
	  
	select top (@rowcount)  
		s.db_name,  
		s.object_name,  
		s.reg_date as to_date,   
		s.term, 
		s.cnt_min,  
		s.cpu_rate,  
		s.cpu_min,  
		s.reads_min, 
		s.writes_min ,
		s.duration_min,  
		s.cpu_cnt,  
		s.reads_cnt, 
		s.writes_cnt, 
		s.duration_cnt,  
		s.cached_time,   
	--	p.query_plan,
		s.sql_handle
		from dbo.DB_MON_PROCEDURE_STATS s (nolock)   
	--		cross apply sys.dm_exec_query_plan (s.plan_handle) as p
		where s.reg_date = @date  
		order by  s.duration_cnt desc , s.cpu_rate desc
end
go

drop proc [up_mon_procedure_object]
go

/*************************************************************************    
* 프로시저명  : dbo.[up_mon_procedure_object]  
* 작성정보    : 2014-10-29 by choi bo ra
* 관련페이지  :   
* 내용        : 프로시저 정보 
* 수정정보    : [up_mon_procedure_object] 
**************************************************************************/  
CREATE PROCEDURE [dbo].[up_mon_procedure_object]
 @object_name sysname = null,
 @date datetime = null,  
 @rowcount int = 10  
AS  
SET NOCOUNT ON  

declare @basedate datetime, @query_basedate datetime
declare @max int, @seq int
declare @statement_start int, @statement_end int, @set_options int



if @object_name is null
begin
	print '@object_name 이 입력되어야 합니다!!!'
	return
end

if @date is null set @date =  getdate()  

select @basedate = max(reg_date) from DB_MON_PROCEDURE_STATS (nolock) 

-- 프로시저 내역
select top ( @rowcount)  reg_date,  from_date, to_date,term, db_name, object_name, cached_time, cpu_rate
	, cnt_min,cpu_min, reads_min, writes_min,duration_min
	, cpu_cnt, reads_cnt, writes_cnt, duration_cnt
	--, CONVERT(XML, P.query_plan) AS query_plan
	, sql_handle,plan_handle
from DBMON.DBO.DB_MON_PROCEDURE_STATS AS S WITH(NOLOCK) 
--	cross apply sys.dm_exec_query_plan  (s.plan_handle) as p
where s.reg_date <= @basedate
 and s.object_name = @object_name
order by s.reg_date desc

go

/*************************************************************************    
* 프로시저명  : dbo.[[up_mon_procedure_object_detail]]
* 작성정보    : 2014-10-29 by choi bo ra
* 관련페이지  :   
* 내용        : 프로시저 정보 
* 수정정보    : [up_mon_procedure_object] 
**************************************************************************/  
CREATE PROCEDURE [dbo].[up_mon_procedure_object_detail]
 @object_name sysname = null,
 @date datetime = null
AS  
SET NOCOUNT ON  

declare @basedate datetime, @query_basedate datetime
declare @max int, @seq int
declare @statement_start int, @statement_end int, @set_options int


if @object_name is null
begin
	print '@object_name 이 입력되어야 합니다!!!'
	return
end

if @date is null set @date =  getdate()  

select @basedate = max(reg_date) from DB_MON_PROCEDURE_STATS (nolock) 


-- 프로시저 내역
select reg_date,  from_date, to_date,term, db_name, object_name, cached_time, cpu_rate
	, cnt_min,cpu_min, reads_min, writes_min,duration_min, sql_handle,plan_handle
	, cpu_cnt, reads_cnt, writes_cnt, duration_cnt
from DBMON.DBO.DB_MON_PROCEDURE_STATS  WITH(NOLOCK)
where reg_date = @basedate
 and object_name = @object_name

-- 상세 쿼리 내역

select @query_basedate = max(reg_date) from dbmon.dbo.DB_MON_QUERY_STATS_V3 with(nolock) 
where reg_date <= @date
	and object_name = @object_name

--select @query_basedate

select qs.db_name,  
	qs.object_name,  
	qs.reg_date as to_date,   
	qs.type,
	qs.term, 
	qs.set_options,  
	p.line_start,  
	p.line_end,  
	qs.cnt_min,  
	qs.cpu_rate,  
	qs.cpu_min,  
	qs.reads_min,  
	qs.writes_min,  
	qs.duration_min,  
	qs.cpu_cnt,  
	qs.reads_cnt,  
	qs.writes_cnt, 
	qs.duration_cnt, 
	convert(xml,p.query_plan) as query_plan, 
	qs.query_text,
	qs.sql_handle,
	qs.plan_handle,
	qs.statement_start,
	qs.statement_end,
	qs.create_date	
from dbmon.dbo.DB_MON_query_STATS_v3 as qs with(nolock)  
	left join  dbo.db_mon_query_plan_v3 p (nolock)  
	  on qs.plan_handle = p.plan_handle and qs.statement_start = p.statement_start and qs.statement_end = p.statement_end and qs.create_date = p.create_date  
where qs.reg_date = @query_basedate
 and qs.object_name = @object_name
order by qs.cpu_min desc
go

/*************************************************************************    
* 프로시저명  : dbo.up_mon_procedure_cache_info 
* 작성정보    : 2014-10-29 by choi bo ra
* 관련페이지  :   
* 내용        : 프로시저 정보 
* 수정정보    : up_mon_procedure_cache_info
**************************************************************************/  
CREATE PROCEDURE [dbo].up_mon_procedure_cache_info
	@type		nvarchar(10) = 'reuse'
AS  
SET NOCOUNT ON 


-- compiled plan 갯수
SELECT 'compiled plan'  as type , T.OBJTYPE , T.TOTAL_COUNT, NOT_RE.NOT_RE_COUNT, T.TOTAL_COUNT -NOT_RE.NOT_RE_COUNT AS REUSE
	, (T.TOTAL_COUNT -NOT_RE.NOT_RE_COUNT ) / CONVERT(MONEY,T.TOTAL_COUNT ) AS REUSE_RATE
FROM 
(SELECT OBJTYPE, COUNT(*) AS TOTAL_COUNT
FROM SYS.DM_EXEC_CACHED_PLANS  WITH(NOLOCK)
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(PLAN_HANDLE)
WHERE CACHEOBJTYPE = 'COMPILED PLAN'
GROUP BY OBJTYPE ) AS T
LEFT JOIN 
(SELECT OBJTYPE, COUNT(*) AS NOT_RE_COUNT
FROM SYS.DM_EXEC_CACHED_PLANS  WITH(NOLOCK)
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(PLAN_HANDLE)
WHERE CACHEOBJTYPE = 'COMPILED PLAN' AND USECOUNTS =1
GROUP BY OBJTYPE ) AS NOT_RE ON T.OBJTYPE = NOT_RE.OBJTYPE

if @type ='reuse'
begin

select top 1000 'resue' as type, st.text, db_name(st.dbid) as db_name
	,case when CHARINDEX('::SP', st.text) > 0   and st.text not like '%query_text%' then
			SUBSTRING(st.text, CHARINDEX('--SP::',st.text)+6, CHARINDEX('::SP', st.text)-6-CHARINDEX('--SP::',st.text))
		else st.text end as object_name
	,cp.cacheobjtype, cp.objtype, cp.refcounts
	,cp.usecounts, cp.size_in_bytes / 1024 as size_in_kb, cp.bucketid
	,ce.disk_ios_count, ce.context_switches_count
	,ce.pages_allocated_count, ce.original_cost, ce.current_cost
	,cp.plan_handle

from  
	sys.dm_exec_cached_plans cp
	cross apply sys.dm_exec_sql_text(cp.plan_handle) st
	join sys.dm_os_memory_cache_entries ce on cp.memory_object_address = ce.memory_object_address
where cp.cacheobjtype = 'Compiled Plan'
	and (cp.objtype = 'Adhoc' or cp.objtype = 'Prepared')
order by cp.objtype desc, cp.usecounts desc

end
else if @type ='no reuse'
begin
	
	select top 1000 'no resue' as type, st.text, db_name(st.dbid) as db_name
		,case when CHARINDEX('::SP', st.text) > 0   and st.text not like '%query_text%' then
				SUBSTRING(st.text, CHARINDEX('--SP::',st.text)+6, CHARINDEX('::SP', st.text)-6-CHARINDEX('--SP::',st.text))
			else st.text end as object_name
		,cp.cacheobjtype, cp.objtype, cp.refcounts
		,cp.usecounts, cp.size_in_bytes / 1024 as size_in_kb, cp.bucketid
		,ce.disk_ios_count, ce.context_switches_count
		,ce.pages_allocated_count, ce.original_cost, ce.current_cost
		,cp.plan_handle
	from  
		sys.dm_exec_cached_plans cp
		cross apply sys.dm_exec_sql_text(cp.plan_handle) st
		join sys.dm_os_memory_cache_entries ce on cp.memory_object_address = ce.memory_object_address
	where cp.cacheobjtype = 'Compiled Plan'
		and (cp.objtype = 'Adhoc' or cp.objtype = 'Prepared')
		and cp.usecounts =1
	

end
go

/*************************************************************************  
* 프로시저명	: dbo.[UP_MON_COLLECT_QUERY_PLAN_V3]
* 작성정보	: 2012-08-02 BY CHOI BO RA
* 관련페이지:  
* 내용		:  
* 수정정보	: PREPARED SQL을 수집하기 위해 생성. DB_ID조건을 제거 해야함.
**************************************************************************/
CREATE PROCEDURE [DBO].[UP_MON_COLLECT_QUERY_PLAN_V3]        
AS        
SET NOCOUNT ON        
        
DECLARE @REG_DATE DATETIME        
DECLARE @SEQ INT, @MAX INT        
DECLARE @PLAN_HANDLE VARBINARY(64), @STATEMENT_START INT, @STATEMENT_END INT, @CREATE_DATE DATETIME  
DECLARE @DB_ID SMALLINT     
DECLARE @OBJECT_NAME VARCHAR(255)   
        
DECLARE @PLAN_INFO TABLE (        
 SEQ INT IDENTITY(1, 1) PRIMARY KEY,        
 PLAN_HANDLE VARBINARY(64),        
 STATEMENT_START INT,        
 STATEMENT_END INT,        
 CREATE_DATE DATETIME,  
 DB_ID SMALLINT,
 OBJECT_NAME VARCHAR(255)   
)  
        
SELECT @REG_DATE = MAX(REG_DATE) FROM DB_MON_QUERY_STATS_V3 (NOLOCK)        
        
IF EXISTS (SELECT TOP 1 * FROM DB_MON_QUERY_PLAN_V3 (NOLOCK) WHERE REG_DATE = @REG_DATE)        
BEGIN        
 PRINT '이미 해당 시간의 PLAN 정보가 저장되었습니다!'        
 RETURN        
END        
        
INSERT @PLAN_INFO (PLAN_HANDLE, STATEMENT_START, STATEMENT_END, CREATE_DATE, DB_ID, OBJECT_NAME)        
SELECT PLAN_HANDLE, STATEMENT_START, STATEMENT_END, CREATE_DATE, DB_ID , OBJECT_NAME  
FROM DB_MON_QUERY_STATS_V3 WITH (NOLOCK)         
WHERE REG_DATE = @REG_DATE         
        
SELECT @SEQ = 1, @MAX = @@ROWCOUNT        
        
WHILE @SEQ <= @MAX        
BEGIN        
        
 SELECT @PLAN_HANDLE = PLAN_HANDLE,        
     @STATEMENT_START = STATEMENT_START,        
     @STATEMENT_END = STATEMENT_END,        
     @CREATE_DATE = CREATE_DATE,  
     @DB_ID = DB_ID,        
	 @OBJECT_NAME = OBJECT_NAME
 FROM @PLAN_INFO        
 WHERE SEQ = @SEQ        
         
 SET @SEQ = @SEQ + 1        
   
 IF @DB_ID < 5 CONTINUE  
         
 IF NOT EXISTS (        
  SELECT TOP 1 * FROM DBO.DB_MON_QUERY_PLAN_V3 (NOLOCK)         
  WHERE PLAN_HANDLE = @PLAN_HANDLE AND STATEMENT_START = @STATEMENT_START 
	AND STATEMENT_END = @STATEMENT_END AND CREATE_DATE = @CREATE_DATE)        
 BEGIN        
  
  BEGIN TRY
	  INSERT DB_MON_QUERY_PLAN_V3         
	   (PLAN_HANDLE, STATEMENT_START, STATEMENT_END, CREATE_DATE, SET_OPTIONS, DB_NAME, 
	   OBJECT_NAME, QUERY_PLAN, REG_DATE, UPD_DATE, LINE_START, LINE_END)        
	  SELECT         
		  @PLAN_HANDLE,        
		  @STATEMENT_START,        
		  @STATEMENT_END,        
		  @CREATE_DATE,        
		  0,        
		  DB_NAME(DBID) AS DB_NAME,         
		  OBJECT_NAME(OBJECTID, DBID) AS OBJECT_NAME,        
		  QUERY_PLAN,       
		  @REG_DATE,  
		  @REG_DATE,
		  F.LINE_START, F.LINE_END        
	  FROM SYS.DM_EXEC_TEXT_QUERY_PLAN(@PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END)
		OUTER APPLY DBO.FN_GETOBJECTLINE(@PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END) F    
	  WHERE (DBID >= 5  OR DBID IS NULL )
	       
  END TRY
  BEGIN CATCH		-- XML 이 너무 길어지면(DEPTH 가 128 이상이면 저장 못함)
	  INSERT DB_MON_QUERY_PLAN_V3         
	   (PLAN_HANDLE, STATEMENT_START, STATEMENT_END, CREATE_DATE, SET_OPTIONS, DB_NAME, 
		OBJECT_NAME, QUERY_PLAN, REG_DATE, UPD_DATE, LINE_START, LINE_END)        
	  SELECT @PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END, @CREATE_DATE, 0, 
			 DB_NAME(DBID) AS DB_NAME,
			 @OBJECT_NAME,
			 NULL,
			 @REG_DATE,
			 @REG_DATE,
			 F.LINE_START, F.LINE_END
	  FROM SYS.DM_EXEC_TEXT_QUERY_PLAN(@PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END)      
	  	OUTER APPLY DBO.FN_GETOBJECTLINE(@PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END) F    
  END CATCH
        
 END        
 ELSE   
 BEGIN  
	 UPDATE DB_MON_QUERY_PLAN_V3  
	 SET UPD_DATE = @REG_DATE  
	 WHERE PLAN_HANDLE = @PLAN_HANDLE AND STATEMENT_START = @STATEMENT_START AND STATEMENT_END = @STATEMENT_END AND CREATE_DATE = @CREATE_DATE  
 END  
      
END 
go


CREATE PROCEDURE [DBO].[UP_MON_COLLECT_QUERY_PLAN_DELETE_V3]
AS
SET NOCOUNT ON

DECLARE @DATE DATETIME

SET @DATE = DATEADD(HOUR, -12, DATEADD(DAY, -8, GETDATE()))

DELETE DBMON.DBO.DB_MON_QUERY_PLAN_V3 WHERE UPD_DATE <= @DATE
go