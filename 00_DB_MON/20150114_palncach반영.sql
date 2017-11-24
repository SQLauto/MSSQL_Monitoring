use dbmon
go

use dbmon
go

ALTER TABLE DB_MON_QUERY_STATS_DAILY_V2 ADD query_text varchar(max)
ALTER TABLE SwITCH_DB_MON_QUERY_STATS_DAILY_V2 ADD query_text varchar(max)
go
ALTER TABLE DB_MON_QUERY_PLAN_V3 add sql_handle varbinary(64)
go


CREATE INDEX IDX__DB_MON_QUERY_PLAN_V3__UPD_DATE ON DB_MON_QUERY_PLAN_V3 ( UPD_DATE)
go
CREATE INDEX IDX__DB_MON_QUERY_PLAN_V3__REG_DATE ON DB_MON_QUERY_PLAN_V3 ( REG_DATE)
go



ALTER TABLE DB_MON_QUERY_STATS_TOTAL_V3 add query_hash binary(8)
ALTER TABLE DB_MON_QUERY_STATS_TOTAL_V3 add query_plan_hash  binary(8)
go
ALTER TABLE SWITCH_DB_MON_QUERY_STATS_TOTAL_V3 add query_hash binary(8)
ALTER TABLE SWITCH_DB_MON_QUERY_STATS_TOTAL_V3 add query_plan_hash  binary(8)
go
ALTER TABLE DB_MON_QUERY_STATS_V3 add query_hash binary(8)
ALTER TABLE DB_MON_QUERY_STATS_V3 add query_plan_hash  binary(8)
ALTER TABLE DB_MON_QUERY_PLAN_V3 add warnings  VARCHAR(MAX)
ALTER TABLE DB_MON_QUERY_PLAN_V3 add query_cost money
go
ALTER TABLE SWITCH_DB_MON_QUERY_STATS_V3 add query_hash binary(8)
ALTER TABLE SWITCH_DB_MON_QUERY_STATS_V3 add query_plan_hash  binary(8)
go

-- configuration table 
CREATE TABLE DB_MON_QUERY_STATS_CONFIGURATION
(	 parameter_name	varchar(100),
	value 				decimal(38,0)
)

INSERT INTO DB_MON_QUERY_STATS_CONFIGURATION
SELECT 'frequent execution threshold', 1000
UNION ALL 
SELECT 'parameter sniffing variance percent', 30
UNION ALL 
SELECT 'parameter sniffing io threshold', 100000
UNION ALL 
SELECT 'cost threshold for parallelism warning', 100
UNION ALL 
SELECT 'long running query warning (seconds)', 300
GO




ALTER PROCEDURE [dbo].[up_mon_collect_query_stats_daily_v3]  
 @date datetime = null  
AS  
SET NOCOUNT ON  

SET QUERY_GOVERNOR_COST_LIMIT 0
  
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
	,query_text
	
)
select convert(nvarchar(10), max(reg_date), 121) , 'A'
	,  convert(numeric(4,2), ( SUM(cpu_min) * 1.00/ @total_cpu) *100) as cpu_rate
	,  DB_NAME, OBJECT_NAME, DB_ID, OBJECT_ID, statement_start, statement_end, set_options
	,  SUM(cnt_min) , SUM(cpu_min) , SUM(reads_min) , SUM(writes_min) ,SUM(duration_min) 
	,  AVG(cpu_cnt) , AVG(reads_cnt) , AVG(writes_cnt), AVG(duration_cnt) 
	,  query_text
from db_mon_query_stats_V3 with(nolock) where reg_date >= @from_date and reg_date < @to_date
GROUP BY DB_NAME, OBJECT_NAME, DB_ID, OBJECT_ID, statement_start, statement_end, set_options, query_text
ORDER BY  SUM(cpu_min)  desc




select  @total_cpu=SUM(cpu_min) from db_mon_query_stats_V3 with(nolock) 
where reg_date >= @wk_from_date and reg_date < @wk_to_date



insert into  DB_MON_QUERY_STATS_DAILY_V2 
(
	reg_date, type, cpu_rate, db_name, object_name, db_id, object_id, statement_start, statement_end,set_options
	,cnt_day, cpu_day, reads_day, writes_day,duration_day, cpu_cnt, reads_cnt,  writes_cnt,duration_cnt
	,query_text
	
)
select convert(nvarchar(10), max(reg_date), 121) , 'W'
	,  convert(numeric(4,2), ( SUM(cpu_min) * 1.00/ @total_cpu  ) *100.0) as cpu_rate
	,  DB_NAME, OBJECT_NAME, DB_ID, OBJECT_ID, statement_start, statement_end, set_options
	,  SUM(cnt_min) , SUM(cpu_min) , SUM(reads_min) , SUM(writes_min) ,SUM(duration_min) 
	,  AVG(cpu_cnt) , AVG(reads_cnt) , AVG(writes_cnt), AVG(duration_cnt) 
	,  query_text
from db_mon_query_stats_V3 with(nolock) where reg_date >= @wk_from_date and reg_date < @wk_to_date
GROUP BY DB_NAME, OBJECT_NAME, DB_ID, OBJECT_ID, statement_start, statement_end, set_options, query_text
ORDER BY  SUM(cpu_min) desc
go


/*********************************  *****************************************************/
/* 2010-08-25 10:52 
 2014-10-27 BY CHOI BO RA  TOTAL_SUM  
 2014-11-24 BY CHOI BO RA  query_hash,query_plan_hash 추가 
*/
ALTER PROCEDURE [DBO].[UP_MON_COLLECT_QUERY_STATS_TOTAL_V3]  
AS  
SET NOCOUNT ON  
  
EXEC UP_SWITCH_PARTITION @TABLE_NAME = 'DB_MON_QUERY_STATS_TOTAL_V3', @COLUMN_NAME = 'REG_DATE'   
   
  
DECLARE @REG_DATE DATETIME  
DECLARE @ERROR_NUM INT, @ERROR_MESSAGE SYSNAME  
SET @REG_DATE = GETDATE() 

BEGIN TRY

 
--  
INSERT DB_MON_QUERY_STATS_TOTAL_V3  
 (REG_DATE, TYPE,PLAN_HANDLE, STATEMENT_START, STATEMENT_END, DB_ID, OBJECT_ID, SET_OPTIONS, CREATE_DATE,  
  CNT, CPU, WRITES, READS, DURATION, OBJECT_NAME, QUERY_TEXT,sql_handle, query_hash,query_plan_hash)   
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
		QS.SQL_HANDLE, 
		QS.query_hash,
		QS.query_plan_hash
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
GO

/*************************************************************************  
* 프로시저명	: dbo.[UP_MON_COLLECT_QUERY_PLAN_V3]
* 작성정보	: 2012-08-02 BY CHOI BO RA
* 관련페이지:  
* 내용		:  
* 수정정보	: PREPARED SQL을 수집하기 위해 생성. DB_ID조건을 제거 해야함.
						 2014-11-17 by choi bo ra sql_handel 값 입력
**************************************************************************/
ALTER PROCEDURE [DBO].[UP_MON_COLLECT_QUERY_PLAN_V3]        
AS        
SET NOCOUNT ON        
        
DECLARE @REG_DATE DATETIME        
DECLARE @SEQ INT, @MAX INT        
DECLARE @PLAN_HANDLE VARBINARY(64), @STATEMENT_START INT, @STATEMENT_END INT, @CREATE_DATE DATETIME  
DECLARE @DB_ID SMALLINT    , @SQL_HANDLE VARBINARY(64) , @SET_OPTIONS INT
DECLARE @OBJECT_NAME VARCHAR(255) 

DECLARE @PLAN_INFO TABLE (        
 SEQ INT IDENTITY(1, 1) PRIMARY KEY,        
 PLAN_HANDLE VARBINARY(64),        
 STATEMENT_START INT,        
 STATEMENT_END INT, 
 SET_OPTIONS INT,       
 CREATE_DATE DATETIME,  
 DB_ID SMALLINT,
 OBJECT_NAME VARCHAR(255), 
 SQL_HANDLE VARBINARY(64)   
)  
  
 
IF OBJECT_ID('tempdb..##CacheProcs') IS NOT NULL
    DROP TABLE ##CacheProcs;

CREATE TABLE ##CacheProcs  (  
	query_plan   xml,     
	plan_handle varbinary(64),        
	statement_start int,        
	statement_end int,    
	set_options  int,    
	create_date datetime,  
	sql_handle varbinary(64) ,
	is_forced_plan bit,
	is_forced_parameterized bit,
	is_cursor bit,
	is_parallel bit,
	frequent_execution bit,
	parameter_sniffing bit,
	unparameterized_query bit,
	near_parallel bit,
	plan_warnings bit,
	plan_multiple_plans bit,
	long_running bit,
	--downlevel_estimator bit,
	implicit_conversions bit,
	tempdb_spill bit,
	busy_loops bit,
	tvf_join bit,
	tvf_estimate bit,
	compile_timeout bit,
	compile_memory_limit_exceeded bit,
	warning_no_join_predicate bit,
	queryplancost float,
	missing_index_count int,
	unmatched_index_count int,
	min_elapsed_time bigint,
	max_elapsed_time bigint,
	age_minutes money,
	age_minutes_lifetime money,
	is_trivial bit,
	warnings varchar(max), 
	query_cost float, 
	query_hash binary(8),
	query_plan_hash binary(8), 
	cnt_min		int, 
	duration_cnt int) 

         
SELECT @REG_DATE = MAX(REG_DATE) FROM DB_MON_QUERY_STATS_V3 (NOLOCK)    

select @reg_date    
        
IF EXISTS (SELECT TOP 1 * FROM DB_MON_QUERY_PLAN_V3 (NOLOCK) WHERE REG_DATE = @REG_DATE)        
BEGIN        
 PRINT '   PLAN  !'        
 RETURN        
END        
        
INSERT @PLAN_INFO (PLAN_HANDLE, STATEMENT_START, STATEMENT_END, SET_OPTIONS, CREATE_DATE, DB_ID, OBJECT_NAME, SQL_HANDLE)        
SELECT PLAN_HANDLE, STATEMENT_START, STATEMENT_END, SET_OPTIONS, CREATE_DATE, DB_ID , OBJECT_NAME  ,SQL_HANDLE
FROM DB_MON_QUERY_STATS_V3 WITH (NOLOCK)         
WHERE REG_DATE = @REG_DATE          
        
SELECT @SEQ = 1, @MAX = @@ROWCOUNT ;


        
WHILE @SEQ <= @MAX        
BEGIN        
        
 SELECT @PLAN_HANDLE = PLAN_HANDLE,        
     @STATEMENT_START = STATEMENT_START,        
     @STATEMENT_END = STATEMENT_END,
	 @SET_OPTIONS = SET_OPTIONS,       
     @CREATE_DATE = CREATE_DATE,  
     @DB_ID = DB_ID,        
	 @OBJECT_NAME = OBJECT_NAME,
	 @SQL_HANDLE = SQL_HANDLE
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
	   OBJECT_NAME, QUERY_PLAN, REG_DATE, UPD_DATE, LINE_START, LINE_END, SQL_HANDLE)        
	  SELECT         
		  @PLAN_HANDLE,        
		  @STATEMENT_START,        
		  @STATEMENT_END,        
		  @CREATE_DATE,        
		  @SET_OPTIONS, --0,        
		  DB_NAME(DBID) AS DB_NAME,         
		  OBJECT_NAME(OBJECTID, DBID) AS OBJECT_NAME,        
		  QUERY_PLAN,       
		  @REG_DATE,  
		  @REG_DATE,
		  F.LINE_START, F.LINE_END , 
		  @SQL_HANDLE      
	  FROM SYS.DM_EXEC_TEXT_QUERY_PLAN(@PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END)
		OUTER APPLY DBO.FN_GETOBJECTLINE(@PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END) F    
	  WHERE (DBID >= 5  OR DBID IS NULL )
	       
  END TRY
  BEGIN CATCH		-- XML   (DEPTH  128   )
	  INSERT DB_MON_QUERY_PLAN_V3         
	   (PLAN_HANDLE, STATEMENT_START, STATEMENT_END, CREATE_DATE, SET_OPTIONS, DB_NAME, 
		OBJECT_NAME, QUERY_PLAN, REG_DATE, UPD_DATE, LINE_START, LINE_END, SQL_HANDLE)        
	  SELECT @PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END, @CREATE_DATE, 
			 @SET_OPTIONS ,--	0, 
			 DB_NAME(DBID) AS DB_NAME,
			 @OBJECT_NAME,
			 NULL,
			 @REG_DATE,
			 @REG_DATE,
			 F.LINE_START, F.LINE_END, 
			 @SQL_HANDLE
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


-- Cache Check
insert into ##CacheProcs
(
	plan_handle ,        
	statement_start,        
	statement_end ,    
	set_options  ,    
	create_date,  
	sql_handle ,
	query_plan , 
	query_hash,
	query_plan_hash, 
	cnt_min, 
	duration_cnt
)
select 	p.plan_handle ,   p.statement_start,   p.statement_end ,    p.set_options  ,    p.create_date,  p.sql_handle , p.query_plan
	, q.query_hash, q.query_plan_hash, q.cnt_min, q.duration_min
from DB_MON_QUERY_PLAN_V3 as p with(nolock)  
	join DB_MON_QUERY_STATS_V3 as q with(nolock)  
		ON p.sql_handle = q.sql_handle and p.statement_start = q.statement_start and p.statement_end = q.statement_end and p.set_options = q.set_options
where p.reg_date = @reg_date and q.reg_date = @reg_date




IF @@rowcount > 0 
BEGIN

	-- QueryPlan Cost
	WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
		UPDATE ##CacheProcs
			SET query_cost = 
				CASE WHEN query_plan.exist('sum(//p:StmtSimple/@StatementSubTreeCost)') = 1 THEN query_plan.value('sum(//p:StmtSimple/@StatementSubTreeCost)', 'float')
				ELSE
					query_plan.value('sum(//p:StmtSimple[xs:hexBinary(substring(@QueryPlanHash, 3)) = xs:hexBinary(sql:column("query_plan_hash"))]/@StatementSubTreeCost)', 'float')
				END	, 
			  missing_index_count = query_plan.value('count(//p:MissingIndexGroup)', 'int') ,
			  unmatched_index_count = query_plan.value('count(//p:UnmatchedIndexes/p:Parameterization/p:Object)', 'int') ,
			  plan_multiple_plans = CASE WHEN distinct_plan_count < number_of_plans THEN 1 END ,				
			  is_trivial = CASE WHEN query_plan.exist('//p:StmtSimple[@StatementOptmLevel[.="TRIVIAL"]]/p:QueryPlan/p:ParameterList') = 1 THEN 1 END,
			  is_parallel = CASE WHEN query_plan.value('max(//p:RelOp/@Parallel)', 'float') >0  THEN 1 END
	FROM (
				SELECT COUNT(DISTINCT query_hash) AS distinct_plan_count,
				       COUNT(query_hash) AS number_of_plans,
				       query_hash
				FROM   ##CacheProcs
				GROUP BY query_hash
			) AS x
	WHERE ##CacheProcs.query_hash = x.query_hash
	OPTION (RECOMPILE) ;
	

	
	--	Busy Loops, No Join Predicate, tvf_join, no_join_warning
	WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
		UPDATE P
		SET 
			busy_loops = CASE WHEN (x.estimated_executions / 100.0) > x.estimated_rows THEN 1 END ,
			tvf_join = CASE WHEN x.tvf_join = 1 THEN 1 END ,
			warning_no_join_predicate = CASE WHEN x.no_join_warning = 1 THEN 1 END
	FROM
		##CacheProcs   AS P
		JOIN (
					SELECT 
							qp.sql_handle, statement_start, statement_end,create_date,set_options,  qp.query_plan, qp.plan_handle
						, n.value('@NodeId', 'int') AS node_id
						, n.value('@EstimateRows', 'float') AS estimated_rows 
						, n.value('@EstimateRewinds', 'float') + n.value('@EstimateRebinds', 'float') + 1.0 AS estimated_executions
						, n.query('.').exist('/p:RelOp[contains(@LogicalOp, "Join")]/*/p:RelOp[(@LogicalOp[.="Table-valued function"])]') AS tvf_join
						, n.query('.').exist('//p:RelOp/p:Warnings[(@NoJoinPredicate[.="1"])]') AS no_join_warning
					FROM ##CacheProcs as qp WITH(NOLOCK)
						OUTER APPLY qp.query_plan.nodes('//*') AS q(n)
					WHERE  n.value('local-name(.)', 'nvarchar(100)') = N'RelOp'
				) AS X  ON P.plan_handle = X.plan_handle AND P.statement_start = X.statement_start AND P.statement_end = X.statement_end AND P.set_options = X.set_options
						AND P.create_date  = X.create_date;


		 -- Compilation Timeout , Compile Memory Limit Exceeded
		  WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
			UPDATE P
			SET 
				compile_timeout = CASE WHEN n.query('.').exist('/p:StmtSimple/@StatementOptmEarlyAbortReason[.="TimeOut"]') = 1 THEN 1 END ,
				compile_memory_limit_exceeded = CASE WHEN n.query('.').exist('/p:StmtSimple/@StatementOptmEarlyAbortReason[.="MemoryLimitExceeded"]') = 1 THEN 1 END
		   FROM ##CacheProcs   AS P
			CROSS APPLY p.query_plan.nodes('//p:StmtSimple') AS q(n) 


		  --is_forced_plan, is_forced_parameterized
		  UPDATE p
			SET    is_forced_parameterized = CASE WHEN (CAST(pa.value AS INT) & 131072 = 131072) THEN 1
												  END ,
				   is_forced_plan = CASE WHEN (CAST(pa.value AS INT) & 131072 = 131072) THEN 1
										 WHEN (CAST(pa.value AS INT) & 4 = 4) THEN 1 
										 END 
			FROM   ##CacheProcs p
				   CROSS APPLY sys.dm_exec_plan_attributes(p.plan_handle) pa
			WHERE  pa.attribute = 'set_options' ;

		 -- unparameterized_query,implicit_conversions,long_running,tempdb_spill,near_parallel,plan_warnings,frequent_execution
		 /* coifiguration table create 필요 */
			
		DECLARE @execution_threshold INT = 1000 ,
				@parameter_sniffing_warning_pct TINYINT = 30,
				/* This is in average reads */
				@parameter_sniffing_io_threshold BIGINT = 100000 ,
				@ctp_threshold_pct TINYINT = 10,
				@long_running_query_warning_seconds BIGINT = 300 * 1000 ;

				SELECT @execution_threshold = CAST(value AS INT)
				FROM   DB_MON_QUERY_STATS_CONFIGURATION WITH(NOLOCK)
				WHERE  'frequent execution threshold' = LOWER(parameter_name) ;


				SELECT @parameter_sniffing_warning_pct = CAST(value AS TINYINT)
				FROM   DB_MON_QUERY_STATS_CONFIGURATION WITH(NOLOCK)
				WHERE  'parameter sniffing variance percent' = LOWER(parameter_name) ;

	
				SELECT @parameter_sniffing_io_threshold = CAST(value AS BIGINT)
				FROM   DB_MON_QUERY_STATS_CONFIGURATION WITH(NOLOCK)
				WHERE 'parameter sniffing io threshold' = LOWER(parameter_name) ;

	
				SELECT @ctp_threshold_pct = CAST(value AS TINYINT)
				FROM   DB_MON_QUERY_STATS_CONFIGURATION WITH(NOLOCK)
				WHERE 'cost threshold for parallelism warning' = LOWER(parameter_name) ;

				SELECT @long_running_query_warning_seconds = CAST(value * 1000 AS BIGINT)
					FROM   DB_MON_QUERY_STATS_CONFIGURATION WITH(NOLOCK)
				WHERE 'long running query warning (seconds)' = LOWER(parameter_name) ;



				DECLARE @ctp INT ;

				SELECT  @ctp = CAST(value AS INT)
				FROM    sys.configurations
				WHERE   name = 'cost threshold for parallelism'
				OPTION (RECOMPILE);


	

			WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
			UPDATE ##CacheProcs
				SET    frequent_execution = CASE WHEN p.cnt_min > @execution_threshold THEN 1 END ,
						-- 2012 버전 이상 이여야  sys.dm_exec_query_stats  row 값을 알 수 있음
					   --parameter_sniffing = CASE WHEN AverageReads > @parameter_sniffing_io_threshold
								--					  AND min_worker_time < ((1.0 - (@parameter_sniffing_warning_pct / 100.0)) * AverageCPU) THEN 1
								--				 WHEN AverageReads > @parameter_sniffing_io_threshold
								--					  AND max_worker_time > ((1.0 + (@parameter_sniffing_warning_pct / 100.0)) * AverageCPU) THEN 1
								--				 WHEN AverageReads > @parameter_sniffing_io_threshold
								--					  AND MinReturnedRows < ((1.0 - (@parameter_sniffing_warning_pct / 100.0)) * AverageReturnedRows) THEN 1
								--				 WHEN AverageReads > @parameter_sniffing_io_threshold
								--					  AND MaxReturnedRows > ((1.0 + (@parameter_sniffing_warning_pct / 100.0)) * AverageReturnedRows) THEN 1 END ,
					  -- near_parallel = CASE WHEN QueryPlanCost BETWEEN @ctp * (1 - (@ctp_threshold_pct / 100.0)) AND @ctp THEN 1 END,
					   plan_warnings = CASE WHEN p.query_plan.value('count(//p:Warnings)', 'int') > 0 THEN 1 END,
					   long_running = CASE WHEN p.duration_cnt /1000000 > @long_running_query_warning_seconds THEN 1 END,  -- 마이크로 초
										   --WHEN max_worker_time > @long_running_query_warning_seconds THEN 1
										   --WHEN max_elapsed_time > @long_running_query_warning_seconds THEN 1 END ,
					   implicit_conversions = CASE WHEN p.query_plan.exist('//p:RelOp//p:ScalarOperator/@ScalarString
														[contains(., "CONVERT_IMPLICIT")]') = 1 THEN 1
												   WHEN p.query_plan.exist('
														//p:PlanAffectingConvert/@Expression
														[contains(., "CONVERT_IMPLICIT")]') = 1 THEN 1
												   END ,
					   tempdb_spill = CASE WHEN p.query_plan.value('max(//p:SpillToTempDb/@SpillLevel)', 'int') > 0 THEN 1 END ,
					   unparameterized_query 
					   = CASE WHEN p.query_plan.exist('//p:StmtSimple[@StatementOptmLevel[.="FULL"]]/p:QueryPlan/p:ParameterList') = 1 AND
										p.query_plan.exist('//p:StmtSimple[@StatementOptmLevel[.="FULL"]]/p:QueryPlan/p:ParameterList/p:ColumnReference') = 0 THEN 1
								WHEN p.query_plan.exist('//p:StmtSimple[@StatementOptmLevel[.="FULL"]]/p:QueryPlan/p:ParameterList') = 0 AND
										p.query_plan.exist('//p:StmtSimple[@StatementOptmLevel[.="FULL"]]/*/p:RelOp/descendant::p:ScalarOperator/p:Identifier/p:ColumnReference[contains(@Column, "@")]')
														 = 1 THEN 1 END 
				FROM ##CacheProcs as p

		-- Cursor checks 
		UPDATE p
		SET    is_cursor = CASE WHEN CAST(pa.value AS INT) <> 0 THEN 1 END
		FROM   ##CacheProcs p
			   CROSS APPLY sys.dm_exec_plan_attributes(p.plan_handle) pa
		WHERE  pa.attribute LIKE '%cursor%' ;
		
		--WARING UPDATE
		UPDATE  Q
			SET warnings = 
					SUBSTRING(
                  CASE WHEN warning_no_join_predicate = 1 THEN ', No Join Predicate' ELSE '' END +
                  CASE WHEN compile_timeout = 1 THEN ', Compilation Timeout' ELSE '' END +
                  CASE WHEN compile_memory_limit_exceeded = 1 THEN ', Compile Memory Limit Exceeded' ELSE '' END +
                  CASE WHEN busy_loops = 1 THEN ', Busy Loops' ELSE '' END +
                  CASE WHEN is_forced_plan = 1 THEN ', Forced Plan' ELSE '' END +
                  CASE WHEN is_forced_parameterized = 1 THEN ', Forced Parameterization' ELSE '' END +
                  CASE WHEN unparameterized_query = 1 THEN ', Unparameterized Query' ELSE '' END +
                  CASE WHEN missing_index_count > 0 THEN ', Missing Indexes (' + CAST(missing_index_count AS VARCHAR(3)) + ')' ELSE '' END +
                  CASE WHEN unmatched_index_count > 0 THEN ', Unmatched Indexes (' + CAST(unmatched_index_count AS VARCHAR(3)) + ')' ELSE '' END +                  
                  CASE WHEN is_cursor = 1 THEN ', Cursor' ELSE '' END +
                  CASE WHEN is_parallel = 1 THEN ', Parallel' ELSE '' END +
                  CASE WHEN near_parallel = 1 THEN ', Nearly Parallel' ELSE '' END +
                  CASE WHEN frequent_execution = 1 THEN ', Frequent Execution' ELSE '' END +
                  CASE WHEN plan_warnings = 1 THEN ', Plan Warnings' ELSE '' END +
                  --CASE WHEN parameter_sniffing = 1 THEN ', Parameter Sniffing' ELSE '' END +
                  CASE WHEN long_running = 1 THEN ', Long Running Query' ELSE '' END +
                  --CASE WHEN downlevel_estimator = 1 THEN ', Downlevel CE' ELSE '' END +
                  CASE WHEN implicit_conversions = 1 THEN ', Implicit Conversions' ELSE '' END +
                  CASE WHEN tempdb_spill = 1 THEN ', TempDB Spills' ELSE '' END +
                  CASE WHEN tvf_join = 1 THEN ', Function Join' ELSE '' END +
                  CASE WHEN plan_multiple_plans = 1 THEN ', Multiple Plans' ELSE '' END +
                  CASE WHEN is_trivial = 1 THEN ', Trivial Plans' ELSE '' END 
                  , 2, 200000), 
				query_cost = convert(money,p.query_cost)
		FROM DB_MON_QUERY_PLAN_V3 AS Q
			JOIN ##CacheProcs AS P ON p.sql_handle = q.sql_handle and p.statement_start = q.statement_start and p.statement_end = q.statement_end and p.set_options = q.set_options
		where q.reg_date = @reg_date	

		--select is_forced_parameterized,is_forced_plan,  compile_timeout,compile_memory_limit_exceeded, * from ##CacheProcs


END
GO


/* 2014-10-28 최보라 total_sum_cpu 변경 , wirte 값 추가 
	 2014-11-24 BY CHOI BO RA  query_hash,query_plan_hash 추가 
*/
ALTER PROCEDURE [dbo].[UP_MON_COLLECT_QUERY_STATS_V3]          
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
 print '이미 저장된 시간대 입니다.!!!'        
 return        
end        
        
--select @TO_CPU = CPU_TOTAL               
--from DB_MON_QUERY_STATS_TOTAL_CPU with (nolock)               
--where reg_date = @TO_DATE               
                
select db_id, object_name, object_id, plan_handle, statement_start, statement_end, set_options, create_date
, cnt, cpu, writes, reads, duration, query_text,type , sql_handle,query_hash,query_plan_hash      
into #query_stats_to          
from DB_MON_QUERY_STATS_TOTAL_V3 with (nolock)          
where reg_date = @to_date  

          
select @from_date = max(reg_date) from DB_MON_QUERY_STATS_TOTAL_V3 with (nolock) where reg_date < @to_date                


--select @from_cpu = CPU_TOTAL               
--from DB_MON_QUERY_STATS_TOTAL_CPU with (nolock)               
--where reg_date = @from_date   

           
          
select plan_handle, statement_start, statement_end, set_options, create_date, cnt, cpu, writes, reads, duration    
into #query_stats_from          
from DB_MON_QUERY_STATS_TOTAL_V3 with (nolock)          
where reg_date = @from_date          
          
set @term = datediff(second, @from_date, @to_date)          
    

select  @cpu_term= sum(case when term > 30 then sum_cpu_gap * 60 / term else -1 end ) 
from 
	(
	select  sum(a.cpu - isnull(b.cpu, 0))  as sum_cpu_gap
		, case when datediff(second, @from_date, a.create_date) <= 0 then @term else datediff(second, a.create_date, @to_date) end as term         
	from #query_stats_to a with (nolock)           
	 left join #query_stats_from b with (nolock)           
	  on a.plan_handle = b.plan_handle and a.statement_start = b.statement_start and a.statement_end = b.statement_end and a.create_date = b.create_date
	group by a.cpu, b.cpu, a.create_date
	) AS T



       
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
 sql_handle, 
 query_hash,
 query_plan_hash
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
 convert(numeric(6,2),  (case when term > 30 then cpu_gap * 60 / term else -1  end ) / @cpu_term * 100 )   as cpu_rate,
 --convert(numeric(6, 2), cpu_gap* 1.0 /@cpu_term * 100) as cpu_rate,        
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
 sql_handle ,
 query_hash,
 query_plan_hash  
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
  A.sql_handle,
  a.query_hash,
  a.query_plan_hash
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

use msdb
go

declare @job_id uniqueidentifier, @schedule_id int
select @job_id = job_id from sysjobs with(nolock) where name = '[DB_COLLECT] DB_MON_OS_WAIT'
select @schedule_id = schedule_id from sysjobschedules where job_id =@job_id
EXEC msdb.dbo.sp_attach_schedule @job_id=@job_id,@schedule_id=@schedule_id
EXEC msdb.dbo.sp_update_schedule @schedule_id=@schedule_id, @new_name=N'10min', 
	@freq_subday_type=4, 
	@freq_subday_interval=10,
	@active_start_time=11
GO

USE DBMON
GO
CREATE INDEX IDX__DB_MON_QUERY_PLAN_V3__UPD_DATE ON DB_MON_QUERY_PLAN_V3 ( UPD_DATE)
go








/

/*********************************  *****************************************************/
/* 2010-08-25 10:52 
 2014-10-27 BY CHOI BO RA  TOTAL_SUM  
 2014-11-24 BY CHOI BO RA  query_hash,query_plan_hash 추가 
 2014-12-01 BY CHOI BO RA  PREAPARE, ADHOC과 구분 
*/
ALTER PROCEDURE [DBO].[UP_MON_COLLECT_QUERY_STATS_TOTAL_V3]  
AS  
SET NOCOUNT ON  
SET QUERY_GOVERNOR_COST_LIMIT 0  
EXEC UP_SWITCH_PARTITION @TABLE_NAME = 'DB_MON_QUERY_STATS_TOTAL_V3', @COLUMN_NAME = 'REG_DATE'   
   
  
DECLARE @REG_DATE DATETIME  
DECLARE @ERROR_NUM INT, @ERROR_MESSAGE SYSNAME  
SET @REG_DATE = GETDATE() 

BEGIN TRY

 
--  
INSERT DB_MON_QUERY_STATS_TOTAL_V3  
 (REG_DATE, PLAN_HANDLE, STATEMENT_START, STATEMENT_END, DB_ID, OBJECT_ID, SET_OPTIONS, CREATE_DATE,  
  CNT, CPU, WRITES, READS, DURATION, OBJECT_NAME, QUERY_TEXT,sql_handle, query_hash,query_plan_hash)   
SELECT 
	 @reg_date, 
	 --CASE WHEN cp.objtype = 'Prepared' THEN 'P'
		--  WHEN cp.objtype = 'Adhoc' THEN 'A'
		--  WHEN cp.objtype = 'Trigger' THEN 'T'
		--  ELSE 'S' END TYPE,
	 --CASE WHEN CONVERT(VARBINARY, LEFT(SQL_HANDLE, 1)) = 0X02 THEN 'P' ELSE 'S' END TYPE,
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
		QS.SQL_HANDLE, 
		QS.query_hash,
		QS.query_plan_hash
FROM SYS.DM_EXEC_QUERY_STATS   AS QS 
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(QS.PLAN_HANDLE)  AS QT 
WHERE SUBSTRING(QS.SQL_HANDLE, 3, 1) <> 0XFF


-- DELETE Adhoc 삭제 
DELETE DB_MON_QUERY_STATS_TOTAL_V3
FROM DB_MON_QUERY_STATS_TOTAL_V3 AS QS
	INNER JOIN SYS.DM_EXEC_CACHED_PLANS AS CP ON QS.PLAN_HANDLE=CP.PLAN_HANDLE
WHERE REG_DATE = @REG_DATE
	AND CP.objtype = 'A'

--   UPDATE
UPDATE QS
	SET TYPE = 
		CASE WHEN cp.objtype = 'Prepared' THEN 'P'
			  WHEN cp.objtype = 'Trigger' THEN 'T'
			  ELSE 'S' END 
FROM DB_MON_QUERY_STATS_TOTAL_V3 AS QS
	INNER JOIN SYS.DM_EXEC_CACHED_PLANS AS CP ON QS.PLAN_HANDLE=CP.PLAN_HANDLE
WHERE REG_DATE = @REG_DATE



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



GO

ALTER PROCEDURE up_mon_query_stats_top_cpu  
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
p.query_cost,
p.warnings,
s.query_text,
p.query_plan
from dbo.db_mon_query_stats_v3 s (nolock)   
left join  dbo.db_mon_query_plan_v3 p (nolock)  
  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
where s.reg_date = @date
order by s.reg_date desc, s.cpu_min desc 

go

ALTER PROCEDURE up_mon_query_stats_top_cnt    
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
s.statement_start,  
s.statement_end,  
s.create_date,
p.query_cost,
p.warnings,  
s.query_text, 
p.query_plan  
from dbo.db_mon_query_stats_v3 s (nolock)     
left join  dbo.db_mon_query_plan_v3 p (nolock)    
  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date    
--outer apply dbo.fn_getobjectline(s.plan_handle, s.statement_start, s.statement_end) f    
where s.reg_date = @date    
order by s.reg_date desc, s.cnt_min desc 
go

ALTER PROCEDURE up_mon_query_stats_top_duration
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
p.query_cost,
p.warnings,  
s.query_text, 
p.query_plan  
from dbo.db_mon_query_stats_v3 s (nolock)   
left join  dbo.db_mon_query_plan_v3 p (nolock)  
  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
--outer apply dbo.fn_getobjectline(s.plan_handle, s.statement_start, s.statement_end) f  
where s.reg_date = @date  
order by s.reg_date desc, s.duration_min desc 
go

ALTER PROCEDURE up_mon_query_stats_top_reads  
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
p.query_cost,
p.warnings,  
s.query_text, 
p.query_plan  
from dbo.db_mon_query_stats_v3 s (nolock)   
left join  dbo.db_mon_query_plan_v3 p (nolock)  
  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
--outer apply dbo.fn_getobjectline(s.plan_handle, s.statement_start, s.statement_end) f  
where s.reg_date = @date  
order by s.reg_date desc, s.reads_min desc 
go


ALTER PROCEDURE up_mon_query_stats_top_writes
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
p.query_cost,
p.warnings,  
s.query_text, 
p.query_plan 
from dbo.db_mon_query_stats_v3 s (nolock)   
left join  dbo.db_mon_query_plan_v3 p (nolock)  
  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
--outer apply dbo.fn_getobjectline(s.plan_handle, s.statement_start, s.statement_end) f  
where s.reg_date = @date  
order by s.reg_date desc, s.writes_min desc 
go

ALTER PROCEDURE [dbo].[up_mon_query_stats_object]
@object_name sysname = null,
@date datetime = null,  
 @rowcount int = 5  
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

--select @basedate = max(reg_date) from db_mon_query_stats_v3 (nolock)   where reg_date <= @date
select top 1 @basedate = reg_date from db_mon_query_stats_v3 (nolock)   where reg_date <= @date order by reg_Date desc


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
	     p.query_cost,
		   p.warnings,  
		   s.query_text, 
		   p.query_plan 
       from dbo.db_mon_query_stats_v3 s (nolock)   
       left join  dbo.db_mon_query_plan_v3 p (nolock)  
         on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
--     outer apply dbo.fn_getobjectline(s.plan_handle, s.statement_start, s.statement_end) f  
       where s.reg_date <= @date and s.object_name = @object_name
         and s.statement_start = @statement_start and s.statement_end = @statement_end and s.set_options = @set_options       
       order by s.reg_date desc

end
go

/*************************************************************************  
* : dbo.up_mon_query_stats_sp_rate
* 	: 2013-07-16 by choi bo ra
* :  
* 		:    sp   
* 	:
**************************************************************************/
ALTER PROCEDURE dbo.up_mon_query_stats_sp_rate
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
	    p.query_cost,
		p.warnings,  
		s.query_text, 
		p.query_plan,  
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
	    p.query_cost,
		p.warnings,  
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

--up_mon_query_stats_log_object_V2

ALTER PROC dbo.up_mon_query_stats_log_object_V2
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
,reads_min, cpu_cnt as cpu_cnt, reads_cnt as reads_cnt, duration_cnt as duration_cnt
,S.set_options as set_option
,p.line_start, p.line_end as line_end
,p.query_cost,
p.warnings,  
s.query_text 
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
,reads_min, cpu_cnt as cpu_cnt, reads_cnt as reads_cnt, duration_cnt as duration_cnt
--,S.statement_start as statement_start, S.statement_end as statement_end
,S.set_options as set_option
,p.line_start, p.line_end as line_end
,p.query_cost,
p.warnings,  
s.query_text 
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
,reads_min, cpu_cnt as cpu_cnt, reads_cnt as reads_cnt, duration_cnt as duration_cnt
--,S.statement_start as statement_start, S.statement_end as statement_end
,S.set_options as set_option
,p.line_start, p.line_end as line_end
,p.query_cost,
p.warnings,  
s.query_text 
FROM DBMON.dbo.DB_MON_QUERY_STATS_V3 s WITH (NOLOCK)
left join  dbo.db_mon_query_plan_v3 p (nolock)      
on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date
WHERE s.reg_date >= dateadd(mi,-61,@week_date) and s.reg_date <= @week_date
and s.object_name= @object_name and P.line_start= @line_start and p.line_end = @line_end and s.set_options = @set_option
order by reg_date desc
END
go

/*************************************************************************  
* 프로시저명	: dbo.[UP_MON_COLLECT_QUERY_PLAN_V3]
* 작성정보	: 2012-08-02 BY CHOI BO RA
* 관련페이지:  
* 내용		:  
* 수정정보	: PREPARED SQL을 수집하기 위해 생성. DB_ID조건을 제거 해야함.
						 2014-11-17 by choi bo ra sql_handel 값 입력
**************************************************************************/
ALTER PROCEDURE [DBO].[UP_MON_COLLECT_QUERY_PLAN_V3]        
AS        
SET NOCOUNT ON        
SET QUERY_GOVERNOR_COST_LIMIT 0   
        
DECLARE @REG_DATE DATETIME        
DECLARE @SEQ INT, @MAX INT        
DECLARE @PLAN_HANDLE VARBINARY(64), @STATEMENT_START INT, @STATEMENT_END INT, @CREATE_DATE DATETIME  
DECLARE @DB_ID SMALLINT    , @SQL_HANDLE VARBINARY(64) , @SET_OPTIONS INT
DECLARE @OBJECT_NAME VARCHAR(255) 

DECLARE @PLAN_INFO TABLE (        
 SEQ INT IDENTITY(1, 1) PRIMARY KEY,        
 PLAN_HANDLE VARBINARY(64),        
 STATEMENT_START INT,        
 STATEMENT_END INT, 
 SET_OPTIONS INT,       
 CREATE_DATE DATETIME,  
 DB_ID SMALLINT,
 OBJECT_NAME VARCHAR(255), 
 SQL_HANDLE VARBINARY(64)   
)  
  
 
IF OBJECT_ID('tempdb..##CacheProcs') IS NOT NULL
    DROP TABLE ##CacheProcs;

CREATE TABLE ##CacheProcs  (  
	query_plan   xml,     
	plan_handle varbinary(64),        
	statement_start int,        
	statement_end int,    
	set_options  int,    
	create_date datetime,  
	sql_handle varbinary(64) ,
	is_forced_plan bit,
	is_forced_parameterized bit,
	is_cursor bit,
	is_parallel bit,
	frequent_execution bit,
	parameter_sniffing bit,
	unparameterized_query bit,
	near_parallel bit,
	plan_warnings bit,
	plan_multiple_plans bit,
	long_running bit,
	--downlevel_estimator bit,
	implicit_conversions bit,
	tempdb_spill bit,
	busy_loops bit,
	tvf_join bit,
	tvf_estimate bit,
	compile_timeout bit,
	compile_memory_limit_exceeded bit,
	warning_no_join_predicate bit,
	queryplancost float,
	missing_index_count int,
	unmatched_index_count int,
	min_elapsed_time bigint,
	max_elapsed_time bigint,
	age_minutes money,
	age_minutes_lifetime money,
	is_trivial bit,
	warnings varchar(max), 
	query_cost float, 
	query_hash binary(8),
	query_plan_hash binary(8), 
	cnt_min		int, 
	duration_cnt int) 

         
SELECT @REG_DATE = MAX(REG_DATE) FROM DB_MON_QUERY_STATS_V3 (NOLOCK)    

select @reg_date    
        
IF EXISTS (SELECT TOP 1 * FROM DB_MON_QUERY_PLAN_V3 (NOLOCK) WHERE REG_DATE = @REG_DATE)        
BEGIN        
 PRINT '   PLAN  !'        
 RETURN        
END        
        
INSERT @PLAN_INFO (PLAN_HANDLE, STATEMENT_START, STATEMENT_END, SET_OPTIONS, CREATE_DATE, DB_ID, OBJECT_NAME, SQL_HANDLE)        
SELECT PLAN_HANDLE, STATEMENT_START, STATEMENT_END, SET_OPTIONS, CREATE_DATE, DB_ID , OBJECT_NAME  ,SQL_HANDLE
FROM DB_MON_QUERY_STATS_V3 WITH (NOLOCK)         
WHERE REG_DATE = @REG_DATE          
        
SELECT @SEQ = 1, @MAX = @@ROWCOUNT ;


        
WHILE @SEQ <= @MAX        
BEGIN        
        
 SELECT @PLAN_HANDLE = PLAN_HANDLE,        
     @STATEMENT_START = STATEMENT_START,        
     @STATEMENT_END = STATEMENT_END,
	 @SET_OPTIONS = SET_OPTIONS,       
     @CREATE_DATE = CREATE_DATE,  
     @DB_ID = DB_ID,        
	 @OBJECT_NAME = OBJECT_NAME,
	 @SQL_HANDLE = SQL_HANDLE
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
	   OBJECT_NAME, QUERY_PLAN, REG_DATE, UPD_DATE, LINE_START, LINE_END, SQL_HANDLE)        
	  SELECT         
		  @PLAN_HANDLE,        
		  @STATEMENT_START,        
		  @STATEMENT_END,        
		  @CREATE_DATE,        
		  @SET_OPTIONS, --0,        
		  DB_NAME(DBID) AS DB_NAME,         
		  OBJECT_NAME(OBJECTID, DBID) AS OBJECT_NAME,        
		  QUERY_PLAN,       
		  @REG_DATE,  
		  @REG_DATE,
		  F.LINE_START, F.LINE_END , 
		  @SQL_HANDLE      
	  FROM SYS.DM_EXEC_TEXT_QUERY_PLAN(@PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END)
		OUTER APPLY DBO.FN_GETOBJECTLINE(@PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END) F    
	  WHERE (DBID >= 5  OR DBID IS NULL )
	       
  END TRY
  BEGIN CATCH		-- XML   (DEPTH  128   )
	  INSERT DB_MON_QUERY_PLAN_V3         
	   (PLAN_HANDLE, STATEMENT_START, STATEMENT_END, CREATE_DATE, SET_OPTIONS, DB_NAME, 
		OBJECT_NAME, QUERY_PLAN, REG_DATE, UPD_DATE, LINE_START, LINE_END, SQL_HANDLE)        
	  SELECT @PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END, @CREATE_DATE, 
			 @SET_OPTIONS ,--	0, 
			 DB_NAME(DBID) AS DB_NAME,
			 @OBJECT_NAME,
			 NULL,
			 @REG_DATE,
			 @REG_DATE,
			 F.LINE_START, F.LINE_END, 
			 @SQL_HANDLE
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


-- Cache Check
insert into ##CacheProcs
(
	plan_handle ,        
	statement_start,        
	statement_end ,    
	set_options  ,    
	create_date,  
	sql_handle ,
	query_plan , 
	query_hash,
	query_plan_hash, 
	cnt_min, 
	duration_cnt
)
select 	p.plan_handle ,   p.statement_start,   p.statement_end ,    p.set_options  ,    p.create_date,  p.sql_handle , p.query_plan
	, q.query_hash, q.query_plan_hash, q.cnt_min, q.duration_min
from DB_MON_QUERY_PLAN_V3 as p with(nolock)  
	join DB_MON_QUERY_STATS_V3 as q with(nolock)  
		ON p.sql_handle = q.sql_handle and p.statement_start = q.statement_start and p.statement_end = q.statement_end and p.set_options = q.set_options
where p.reg_date = @reg_date and q.reg_date = @reg_date




IF @@rowcount > 0 
BEGIN

	-- QueryPlan Cost
	WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
		UPDATE ##CacheProcs
			SET query_cost = 
				CASE WHEN query_plan.exist('sum(//p:StmtSimple/@StatementSubTreeCost)') = 1 THEN query_plan.value('sum(//p:StmtSimple/@StatementSubTreeCost)', 'float')
				ELSE
					query_plan.value('sum(//p:StmtSimple[xs:hexBinary(substring(@QueryPlanHash, 3)) = xs:hexBinary(sql:column("query_plan_hash"))]/@StatementSubTreeCost)', 'float')
				END	, 
			  missing_index_count = query_plan.value('count(//p:MissingIndexGroup)', 'int') ,
			  unmatched_index_count = query_plan.value('count(//p:UnmatchedIndexes/p:Parameterization/p:Object)', 'int') ,
			  plan_multiple_plans = CASE WHEN distinct_plan_count < number_of_plans THEN 1 END ,				
			  is_trivial = CASE WHEN query_plan.exist('//p:StmtSimple[@StatementOptmLevel[.="TRIVIAL"]]/p:QueryPlan/p:ParameterList') = 1 THEN 1 END,
			  is_parallel = CASE WHEN query_plan.value('max(//p:RelOp/@Parallel)', 'float') >0  THEN 1 END
	FROM (
				SELECT COUNT(DISTINCT query_hash) AS distinct_plan_count,
				       COUNT(query_hash) AS number_of_plans,
				       query_hash
				FROM   ##CacheProcs
				GROUP BY query_hash
			) AS x
	WHERE ##CacheProcs.query_hash = x.query_hash
	OPTION (RECOMPILE) ;
	

	
	--	Busy Loops, No Join Predicate, tvf_join, no_join_warning
	WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
		UPDATE P
		SET 
			busy_loops = CASE WHEN (x.estimated_executions / 100.0) > x.estimated_rows THEN 1 ELSE 0 END ,
			tvf_join = CASE WHEN x.tvf_join = 1 THEN 1  ELSE 0 END ,
			warning_no_join_predicate = CASE WHEN x.no_join_warning = 1 THEN 1  ELSE 0 END
	FROM
		##CacheProcs   AS P
		JOIN (
					SELECT 
							qp.sql_handle, statement_start, statement_end,create_date,set_options,  qp.query_plan, qp.plan_handle
						, n.value('@NodeId', 'int') AS node_id
						, n.value('@EstimateRows', 'float') AS estimated_rows 
						, n.value('@EstimateRewinds', 'float') + n.value('@EstimateRebinds', 'float') + 1.0 AS estimated_executions
						, n.query('.').exist('/p:RelOp[contains(@LogicalOp, "Join")]/*/p:RelOp[(@LogicalOp[.="Table-valued function"])]') AS tvf_join
						, n.query('.').exist('//p:RelOp/p:Warnings[(@NoJoinPredicate[.="1"])]') AS no_join_warning
					FROM ##CacheProcs as qp WITH(NOLOCK)
						OUTER APPLY qp.query_plan.nodes('//*') AS q(n)
					WHERE  n.value('local-name(.)', 'nvarchar(100)') = N'RelOp'
				) AS X  ON P.plan_handle = X.plan_handle AND P.statement_start = X.statement_start AND P.statement_end = X.statement_end AND P.set_options = X.set_options
						AND P.create_date  = X.create_date;


		 -- Compilation Timeout , Compile Memory Limit Exceeded
		  WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
			UPDATE P
			SET 
				compile_timeout = CASE WHEN n.query('.').exist('/p:StmtSimple/@StatementOptmEarlyAbortReason[.="TimeOut"]') = 1 THEN 1 END ,
				compile_memory_limit_exceeded = CASE WHEN n.query('.').exist('/p:StmtSimple/@StatementOptmEarlyAbortReason[.="MemoryLimitExceeded"]') = 1 THEN 1 END
		   FROM ##CacheProcs   AS P
			CROSS APPLY p.query_plan.nodes('//p:StmtSimple') AS q(n) 


		  --is_forced_plan, is_forced_parameterized
		  UPDATE p
			SET    is_forced_parameterized = CASE WHEN (CAST(pa.value AS INT) & 131072 = 131072) THEN 1
												  END ,
				   is_forced_plan = CASE WHEN (CAST(pa.value AS INT) & 131072 = 131072) THEN 1
										 WHEN (CAST(pa.value AS INT) & 4 = 4) THEN 1 
										 END 
			FROM   ##CacheProcs p
				   CROSS APPLY sys.dm_exec_plan_attributes(p.plan_handle) pa
			WHERE  pa.attribute = 'set_options' ;

		 -- unparameterized_query,implicit_conversions,long_running,tempdb_spill,near_parallel,plan_warnings,frequent_execution
		 /* coifiguration table create 필요 */
			
		DECLARE @execution_threshold INT = 1000 ,
				@parameter_sniffing_warning_pct TINYINT = 30,
				/* This is in average reads */
				@parameter_sniffing_io_threshold BIGINT = 100000 ,
				@ctp_threshold_pct TINYINT = 10,
				@long_running_query_warning_seconds BIGINT = 300 * 1000 ;

				SELECT @execution_threshold = CAST(value AS INT)
				FROM   DB_MON_QUERY_STATS_CONFIGURATION WITH(NOLOCK)
				WHERE  'frequent execution threshold' = LOWER(parameter_name) ;


				SELECT @parameter_sniffing_warning_pct = CAST(value AS TINYINT)
				FROM   DB_MON_QUERY_STATS_CONFIGURATION WITH(NOLOCK)
				WHERE  'parameter sniffing variance percent' = LOWER(parameter_name) ;

	
				SELECT @parameter_sniffing_io_threshold = CAST(value AS BIGINT)
				FROM   DB_MON_QUERY_STATS_CONFIGURATION WITH(NOLOCK)
				WHERE 'parameter sniffing io threshold' = LOWER(parameter_name) ;

	
				SELECT @ctp_threshold_pct = CAST(value AS TINYINT)
				FROM   DB_MON_QUERY_STATS_CONFIGURATION WITH(NOLOCK)
				WHERE 'cost threshold for parallelism warning' = LOWER(parameter_name) ;

				SELECT @long_running_query_warning_seconds = CAST(value * 1000 AS BIGINT)
					FROM   DB_MON_QUERY_STATS_CONFIGURATION WITH(NOLOCK)
				WHERE 'long running query warning (seconds)' = LOWER(parameter_name) ;



				DECLARE @ctp INT ;

				SELECT  @ctp = CAST(value AS INT)
				FROM    sys.configurations
				WHERE   name = 'cost threshold for parallelism'
				OPTION (RECOMPILE);


	

			WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
			UPDATE ##CacheProcs
				SET    frequent_execution = CASE WHEN p.cnt_min > @execution_threshold THEN 1 END ,
						-- 2012 버전 이상 이여야  sys.dm_exec_query_stats  row 값을 알 수 있음
					   --parameter_sniffing = CASE WHEN AverageReads > @parameter_sniffing_io_threshold
								--					  AND min_worker_time < ((1.0 - (@parameter_sniffing_warning_pct / 100.0)) * AverageCPU) THEN 1
								--				 WHEN AverageReads > @parameter_sniffing_io_threshold
								--					  AND max_worker_time > ((1.0 + (@parameter_sniffing_warning_pct / 100.0)) * AverageCPU) THEN 1
								--				 WHEN AverageReads > @parameter_sniffing_io_threshold
								--					  AND MinReturnedRows < ((1.0 - (@parameter_sniffing_warning_pct / 100.0)) * AverageReturnedRows) THEN 1
								--				 WHEN AverageReads > @parameter_sniffing_io_threshold
								--					  AND MaxReturnedRows > ((1.0 + (@parameter_sniffing_warning_pct / 100.0)) * AverageReturnedRows) THEN 1 END ,
					  -- near_parallel = CASE WHEN QueryPlanCost BETWEEN @ctp * (1 - (@ctp_threshold_pct / 100.0)) AND @ctp THEN 1 END,
					   plan_warnings = CASE WHEN p.query_plan.value('count(//p:Warnings)', 'int') > 0 THEN 1 END,
					   long_running = CASE WHEN p.duration_cnt /1000000 > @long_running_query_warning_seconds THEN 1 END,  -- 마이크로 초
										   --WHEN max_worker_time > @long_running_query_warning_seconds THEN 1
										   --WHEN max_elapsed_time > @long_running_query_warning_seconds THEN 1 END ,
					   implicit_conversions = CASE WHEN p.query_plan.exist('//p:RelOp//p:ScalarOperator/@ScalarString
														[contains(., "CONVERT_IMPLICIT")]') = 1 THEN 1
												   WHEN p.query_plan.exist('
														//p:PlanAffectingConvert/@Expression
														[contains(., "CONVERT_IMPLICIT")]') = 1 THEN 1
												   END ,
					   tempdb_spill = CASE WHEN p.query_plan.value('max(//p:SpillToTempDb/@SpillLevel)', 'int') > 0 THEN 1 END ,
					   unparameterized_query 
					   = CASE WHEN p.query_plan.exist('//p:StmtSimple[@StatementOptmLevel[.="FULL"]]/p:QueryPlan/p:ParameterList') = 1 AND
										p.query_plan.exist('//p:StmtSimple[@StatementOptmLevel[.="FULL"]]/p:QueryPlan/p:ParameterList/p:ColumnReference') = 0 THEN 1
								WHEN p.query_plan.exist('//p:StmtSimple[@StatementOptmLevel[.="FULL"]]/p:QueryPlan/p:ParameterList') = 0 AND
										p.query_plan.exist('//p:StmtSimple[@StatementOptmLevel[.="FULL"]]/*/p:RelOp/descendant::p:ScalarOperator/p:Identifier/p:ColumnReference[contains(@Column, "@")]')
														 = 1 THEN 1 END 
				FROM ##CacheProcs as p

		-- Cursor checks 
		UPDATE p
		SET    is_cursor = CASE WHEN CAST(pa.value AS INT) <> 0 THEN 1 END
		FROM   ##CacheProcs p
			   CROSS APPLY sys.dm_exec_plan_attributes(p.plan_handle) pa
		WHERE  pa.attribute LIKE '%cursor%' ;
		
		--WARING UPDATE
		UPDATE  Q
			SET warnings = 
					SUBSTRING(
                  CASE WHEN warning_no_join_predicate = 1 THEN ', No Join Predicate' ELSE '' END +
                  CASE WHEN compile_timeout = 1 THEN ', Compilation Timeout' ELSE '' END +
                  CASE WHEN compile_memory_limit_exceeded = 1 THEN ', Compile Memory Limit Exceeded' ELSE '' END +
                  CASE WHEN busy_loops = 1 THEN ', Busy Loops' ELSE '' END +
                  CASE WHEN is_forced_plan = 1 THEN ', Forced Plan' ELSE '' END +
                  CASE WHEN is_forced_parameterized = 1 THEN ', Forced Parameterization' ELSE '' END +
                  CASE WHEN unparameterized_query = 1 THEN ', Unparameterized Query' ELSE '' END +
                  CASE WHEN missing_index_count > 0 THEN ', Missing Indexes (' + CAST(missing_index_count AS VARCHAR(3)) + ')' ELSE '' END +
                  CASE WHEN unmatched_index_count > 0 THEN ', Unmatched Indexes (' + CAST(unmatched_index_count AS VARCHAR(3)) + ')' ELSE '' END +                  
                  CASE WHEN is_cursor = 1 THEN ', Cursor' ELSE '' END +
                  CASE WHEN is_parallel = 1 THEN ', Parallel' ELSE '' END +
                  CASE WHEN near_parallel = 1 THEN ', Nearly Parallel' ELSE '' END +
                  CASE WHEN frequent_execution = 1 THEN ', Frequent Execution' ELSE '' END +
                  CASE WHEN plan_warnings = 1 THEN ', Plan Warnings' ELSE '' END +
                  --CASE WHEN parameter_sniffing = 1 THEN ', Parameter Sniffing' ELSE '' END +
                  CASE WHEN long_running = 1 THEN ', Long Running Query' ELSE '' END +
                  --CASE WHEN downlevel_estimator = 1 THEN ', Downlevel CE' ELSE '' END +
                  CASE WHEN implicit_conversions = 1 THEN ', Implicit Conversions' ELSE '' END +
                  CASE WHEN tempdb_spill = 1 THEN ', TempDB Spills' ELSE '' END +
                  CASE WHEN tvf_join = 1 THEN ', Function Join' ELSE '' END +
                  CASE WHEN plan_multiple_plans = 1 THEN ', Multiple Plans' ELSE '' END +
                  CASE WHEN is_trivial = 1 THEN ', Trivial Plans' ELSE '' END 
                  , 2, 200000), 
				query_cost = convert(money,p.query_cost)
		FROM DB_MON_QUERY_PLAN_V3 AS Q
			JOIN ##CacheProcs AS P ON p.sql_handle = q.sql_handle and p.statement_start = q.statement_start and p.statement_end = q.statement_end and p.set_options = q.set_options
		where q.reg_date = @reg_date	

		--select is_forced_parameterized,is_forced_plan,  compile_timeout,compile_memory_limit_exceeded, * from ##CacheProcs


END
GO

use msdb
go

declare @job_id uniqueidentifier, @schedule_id int
select @job_id = job_id from sysjobs with(nolock) where name = '[DB_COLLECT] DB_MON_OS_WAIT'
if @job_id is not null 
begin
	select @schedule_id = schedule_id from sysjobschedules where job_id =@job_id
	EXEC msdb.dbo.sp_attach_schedule @job_id=@job_id,@schedule_id=@schedule_id
	EXEC msdb.dbo.sp_update_schedule @schedule_id=@schedule_id, @new_name=N'10min', 
		@freq_subday_type=4, 
		@freq_subday_interval=10,
		@active_start_time=11

end
go

USE DBMON
GO
CREATE INDEX IDX__DB_MON_QUERY_PLAN_V3__UPD_DATE ON DB_MON_QUERY_PLAN_V3 ( UPD_DATE)
go

CREATE INDEX IDX__DB_MON_QUERY_PLAN_V3__REG_DATE ON DB_MON_QUERY_PLAN_V3 ( REG_DATE)
go

/*********************************  *****************************************************/
/* 2010-08-25 10:52 
 2014-10-27 BY CHOI BO RA  TOTAL_SUM  
 2014-11-24 BY CHOI BO RA  query_hash,query_plan_hash 추가 
 2014-12-01 BY CHOI BO RA  PREAPARE, ADHOC과 구분 
*/
ALTER PROCEDURE [DBO].[UP_MON_COLLECT_QUERY_STATS_TOTAL_V3]  
AS  
SET NOCOUNT ON  
SET QUERY_GOVERNOR_COST_LIMIT 0  
EXEC UP_SWITCH_PARTITION @TABLE_NAME = 'DB_MON_QUERY_STATS_TOTAL_V3', @COLUMN_NAME = 'REG_DATE'   
   
  
DECLARE @REG_DATE DATETIME  
DECLARE @ERROR_NUM INT, @ERROR_MESSAGE SYSNAME  
SET @REG_DATE = GETDATE() 

BEGIN TRY

 
--  
INSERT DB_MON_QUERY_STATS_TOTAL_V3  
 (REG_DATE, PLAN_HANDLE, STATEMENT_START, STATEMENT_END, DB_ID, OBJECT_ID, SET_OPTIONS, CREATE_DATE,  
  CNT, CPU, WRITES, READS, DURATION, OBJECT_NAME, QUERY_TEXT,sql_handle, query_hash,query_plan_hash)   
SELECT 
	 @reg_date, 
	 --CASE WHEN cp.objtype = 'Prepared' THEN 'P'
		--  WHEN cp.objtype = 'Adhoc' THEN 'A'
		--  WHEN cp.objtype = 'Trigger' THEN 'T'
		--  ELSE 'S' END TYPE,
	 --CASE WHEN CONVERT(VARBINARY, LEFT(SQL_HANDLE, 1)) = 0X02 THEN 'P' ELSE 'S' END TYPE,
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
		QS.SQL_HANDLE, 
		QS.query_hash,
		QS.query_plan_hash
FROM SYS.DM_EXEC_QUERY_STATS   AS QS 
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(QS.PLAN_HANDLE)  AS QT 
WHERE SUBSTRING(QS.SQL_HANDLE, 3, 1) <> 0XFF


-- DELETE Adhoc 삭제 
DELETE DB_MON_QUERY_STATS_TOTAL_V3
FROM DB_MON_QUERY_STATS_TOTAL_V3 AS QS
	INNER JOIN SYS.DM_EXEC_CACHED_PLANS AS CP ON QS.PLAN_HANDLE=CP.PLAN_HANDLE
WHERE REG_DATE = @REG_DATE
	AND CP.objtype = 'A'

--   UPDATE
UPDATE QS
	SET TYPE = 
		CASE WHEN cp.objtype = 'Prepared' THEN 'P'
			  WHEN cp.objtype = 'Trigger' THEN 'T'
			  ELSE 'S' END 
FROM DB_MON_QUERY_STATS_TOTAL_V3 AS QS
	INNER JOIN SYS.DM_EXEC_CACHED_PLANS AS CP ON QS.PLAN_HANDLE=CP.PLAN_HANDLE
WHERE REG_DATE = @REG_DATE



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



GO

ALTER PROCEDURE up_mon_query_stats_top_cpu  
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
p.query_cost,
p.warnings,
s.query_text,
p.query_plan
from dbo.db_mon_query_stats_v3 s (nolock)   
left join  dbo.db_mon_query_plan_v3 p (nolock)  
  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
where s.reg_date = @date
order by s.reg_date desc, s.cpu_min desc 

go

ALTER PROCEDURE up_mon_query_stats_top_cnt    
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
s.statement_start,  
s.statement_end,  
s.create_date,
p.query_cost,
p.warnings,  
s.query_text, 
p.query_plan  
from dbo.db_mon_query_stats_v3 s (nolock)     
left join  dbo.db_mon_query_plan_v3 p (nolock)    
  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date    
--outer apply dbo.fn_getobjectline(s.plan_handle, s.statement_start, s.statement_end) f    
where s.reg_date = @date    
order by s.reg_date desc, s.cnt_min desc 
go

ALTER PROCEDURE up_mon_query_stats_top_duration
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
p.query_cost,
p.warnings,  
s.query_text, 
p.query_plan  
from dbo.db_mon_query_stats_v3 s (nolock)   
left join  dbo.db_mon_query_plan_v3 p (nolock)  
  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
--outer apply dbo.fn_getobjectline(s.plan_handle, s.statement_start, s.statement_end) f  
where s.reg_date = @date  
order by s.reg_date desc, s.duration_min desc 
go

ALTER PROCEDURE up_mon_query_stats_top_reads  
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
p.query_cost,
p.warnings,  
s.query_text, 
p.query_plan  
from dbo.db_mon_query_stats_v3 s (nolock)   
left join  dbo.db_mon_query_plan_v3 p (nolock)  
  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
--outer apply dbo.fn_getobjectline(s.plan_handle, s.statement_start, s.statement_end) f  
where s.reg_date = @date  
order by s.reg_date desc, s.reads_min desc 
go


ALTER PROCEDURE up_mon_query_stats_top_writes
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
p.query_cost,
p.warnings,  
s.query_text, 
p.query_plan 
from dbo.db_mon_query_stats_v3 s (nolock)   
left join  dbo.db_mon_query_plan_v3 p (nolock)  
  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
--outer apply dbo.fn_getobjectline(s.plan_handle, s.statement_start, s.statement_end) f  
where s.reg_date = @date  
order by s.reg_date desc, s.writes_min desc 
go

ALTER PROCEDURE [dbo].[up_mon_query_stats_object]
@object_name sysname = null,
@date datetime = null,  
 @rowcount int = 5  
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

--select @basedate = max(reg_date) from db_mon_query_stats_v3 (nolock)   where reg_date <= @date
select top 1 @basedate = reg_date from db_mon_query_stats_v3 (nolock)   where reg_date <= @date order by reg_Date desc


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
	     p.query_cost,
		   p.warnings,  
		   s.query_text, 
		   p.query_plan 
       from dbo.db_mon_query_stats_v3 s (nolock)   
       left join  dbo.db_mon_query_plan_v3 p (nolock)  
         on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
--     outer apply dbo.fn_getobjectline(s.plan_handle, s.statement_start, s.statement_end) f  
       where s.reg_date <= @date and s.object_name = @object_name
         and s.statement_start = @statement_start and s.statement_end = @statement_end and s.set_options = @set_options       
       order by s.reg_date desc

end
go

/*************************************************************************  
* : dbo.up_mon_query_stats_sp_rate
* 	: 2013-07-16 by choi bo ra
* :  
* 		:    sp   
* 	:
**************************************************************************/
ALTER PROCEDURE dbo.up_mon_query_stats_sp_rate
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
	    p.query_cost,
		p.warnings,  
		s.query_text, 
		p.query_plan,  
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
	    p.query_cost,
		p.warnings,  
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

--up_mon_query_stats_log_object_V2

ALTER PROC dbo.up_mon_query_stats_log_object_V2
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
,reads_min, cpu_cnt as cpu_cnt, reads_cnt as reads_cnt, duration_cnt as duration_cnt
,S.set_options as set_option
,p.line_start, p.line_end as line_end
,p.query_cost,
p.warnings,  
s.query_text 
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
,reads_min, cpu_cnt as cpu_cnt, reads_cnt as reads_cnt, duration_cnt as duration_cnt
--,S.statement_start as statement_start, S.statement_end as statement_end
,S.set_options as set_option
,p.line_start, p.line_end as line_end
,p.query_cost,
p.warnings,  
s.query_text 
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
,reads_min, cpu_cnt as cpu_cnt, reads_cnt as reads_cnt, duration_cnt as duration_cnt
--,S.statement_start as statement_start, S.statement_end as statement_end
,S.set_options as set_option
,p.line_start, p.line_end as line_end
,p.query_cost,
p.warnings,  
s.query_text 
FROM DBMON.dbo.DB_MON_QUERY_STATS_V3 s WITH (NOLOCK)
left join  dbo.db_mon_query_plan_v3 p (nolock)      
on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date
WHERE s.reg_date >= dateadd(mi,-61,@week_date) and s.reg_date <= @week_date
and s.object_name= @object_name and P.line_start= @line_start and p.line_end = @line_end and s.set_options = @set_option
order by reg_date desc
END
go

/*************************************************************************  
* 프로시저명	: dbo.[UP_MON_COLLECT_QUERY_PLAN_V3]
* 작성정보	: 2012-08-02 BY CHOI BO RA
* 관련페이지:  
* 내용		:  
* 수정정보	: PREPARED SQL을 수집하기 위해 생성. DB_ID조건을 제거 해야함.
						 2014-11-17 by choi bo ra sql_handel 값 입력
**************************************************************************/
ALTER PROCEDURE [DBO].[UP_MON_COLLECT_QUERY_PLAN_V3]        
AS        
SET NOCOUNT ON        
        
DECLARE @REG_DATE DATETIME        
DECLARE @SEQ INT, @MAX INT        
DECLARE @PLAN_HANDLE VARBINARY(64), @STATEMENT_START INT, @STATEMENT_END INT, @CREATE_DATE DATETIME  
DECLARE @DB_ID SMALLINT    , @SQL_HANDLE VARBINARY(64) , @SET_OPTIONS INT
DECLARE @OBJECT_NAME VARCHAR(255) 

DECLARE @PLAN_INFO TABLE (        
 SEQ INT IDENTITY(1, 1) PRIMARY KEY,        
 PLAN_HANDLE VARBINARY(64),        
 STATEMENT_START INT,        
 STATEMENT_END INT, 
 SET_OPTIONS INT,       
 CREATE_DATE DATETIME,  
 DB_ID SMALLINT,
 OBJECT_NAME VARCHAR(255), 
 SQL_HANDLE VARBINARY(64)   
)  
  
 
IF OBJECT_ID('tempdb..##CacheProcs') IS NOT NULL
    DROP TABLE ##CacheProcs;

CREATE TABLE ##CacheProcs  (  
	query_plan   xml,     
	plan_handle varbinary(64),        
	statement_start int,        
	statement_end int,    
	set_options  int,    
	create_date datetime,  
	sql_handle varbinary(64) ,
	is_forced_plan bit,
	is_forced_parameterized bit,
	is_cursor bit,
	is_parallel bit,
	frequent_execution bit,
	parameter_sniffing bit,
	unparameterized_query bit,
	near_parallel bit,
	plan_warnings bit,
	plan_multiple_plans bit,
	long_running bit,
	--downlevel_estimator bit,
	implicit_conversions bit,
	tempdb_spill bit,
	busy_loops bit,
	tvf_join bit,
	tvf_estimate bit,
	compile_timeout bit,
	compile_memory_limit_exceeded bit,
	warning_no_join_predicate bit,
	queryplancost float,
	missing_index_count int,
	unmatched_index_count int,
	min_elapsed_time bigint,
	max_elapsed_time bigint,
	age_minutes money,
	age_minutes_lifetime money,
	is_trivial bit,
	warnings varchar(max), 
	query_cost float, 
	query_hash binary(8),
	query_plan_hash binary(8), 
	cnt_min		int, 
	duration_cnt int) 

         
SELECT @REG_DATE = MAX(REG_DATE) FROM DB_MON_QUERY_STATS_V3 (NOLOCK)    

select @reg_date    
        
IF EXISTS (SELECT TOP 1 * FROM DB_MON_QUERY_PLAN_V3 (NOLOCK) WHERE REG_DATE = @REG_DATE)        
BEGIN        
 PRINT '   PLAN  !'        
 RETURN        
END        
        
INSERT @PLAN_INFO (PLAN_HANDLE, STATEMENT_START, STATEMENT_END, SET_OPTIONS, CREATE_DATE, DB_ID, OBJECT_NAME, SQL_HANDLE)        
SELECT PLAN_HANDLE, STATEMENT_START, STATEMENT_END, SET_OPTIONS, CREATE_DATE, DB_ID , OBJECT_NAME  ,SQL_HANDLE
FROM DB_MON_QUERY_STATS_V3 WITH (NOLOCK)         
WHERE REG_DATE = @REG_DATE          
        
SELECT @SEQ = 1, @MAX = @@ROWCOUNT ;


        
WHILE @SEQ <= @MAX        
BEGIN        
        
 SELECT @PLAN_HANDLE = PLAN_HANDLE,        
     @STATEMENT_START = STATEMENT_START,        
     @STATEMENT_END = STATEMENT_END,
	 @SET_OPTIONS = SET_OPTIONS,       
     @CREATE_DATE = CREATE_DATE,  
     @DB_ID = DB_ID,        
	 @OBJECT_NAME = OBJECT_NAME,
	 @SQL_HANDLE = SQL_HANDLE
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
	   OBJECT_NAME, QUERY_PLAN, REG_DATE, UPD_DATE, LINE_START, LINE_END, SQL_HANDLE)        
	  SELECT         
		  @PLAN_HANDLE,        
		  @STATEMENT_START,        
		  @STATEMENT_END,        
		  @CREATE_DATE,        
		  @SET_OPTIONS, --0,        
		  DB_NAME(DBID) AS DB_NAME,         
		  OBJECT_NAME(OBJECTID, DBID) AS OBJECT_NAME,        
		  QUERY_PLAN,       
		  @REG_DATE,  
		  @REG_DATE,
		  F.LINE_START, F.LINE_END , 
		  @SQL_HANDLE      
	  FROM SYS.DM_EXEC_TEXT_QUERY_PLAN(@PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END)
		OUTER APPLY DBO.FN_GETOBJECTLINE(@PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END) F    
	  WHERE (DBID >= 5  OR DBID IS NULL )
	       
  END TRY
  BEGIN CATCH		-- XML   (DEPTH  128   )
	  INSERT DB_MON_QUERY_PLAN_V3         
	   (PLAN_HANDLE, STATEMENT_START, STATEMENT_END, CREATE_DATE, SET_OPTIONS, DB_NAME, 
		OBJECT_NAME, QUERY_PLAN, REG_DATE, UPD_DATE, LINE_START, LINE_END, SQL_HANDLE)        
	  SELECT @PLAN_HANDLE, @STATEMENT_START, @STATEMENT_END, @CREATE_DATE, 
			 @SET_OPTIONS ,--	0, 
			 DB_NAME(DBID) AS DB_NAME,
			 @OBJECT_NAME,
			 NULL,
			 @REG_DATE,
			 @REG_DATE,
			 F.LINE_START, F.LINE_END, 
			 @SQL_HANDLE
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


-- Cache Check
insert into ##CacheProcs
(
	plan_handle ,        
	statement_start,        
	statement_end ,    
	set_options  ,    
	create_date,  
	sql_handle ,
	query_plan , 
	query_hash,
	query_plan_hash, 
	cnt_min, 
	duration_cnt
)
select 	p.plan_handle ,   p.statement_start,   p.statement_end ,    p.set_options  ,    p.create_date,  p.sql_handle , p.query_plan
	, q.query_hash, q.query_plan_hash, q.cnt_min, q.duration_min
from DB_MON_QUERY_PLAN_V3 as p with(nolock)  
	join DB_MON_QUERY_STATS_V3 as q with(nolock)  
		ON p.sql_handle = q.sql_handle and p.statement_start = q.statement_start and p.statement_end = q.statement_end and p.set_options = q.set_options
where p.reg_date = @reg_date and q.reg_date = @reg_date




IF @@rowcount > 0 
BEGIN

	-- QueryPlan Cost
	WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
		UPDATE ##CacheProcs
			SET query_cost = 
				CASE WHEN query_plan.exist('sum(//p:StmtSimple/@StatementSubTreeCost)') = 1 THEN query_plan.value('sum(//p:StmtSimple/@StatementSubTreeCost)', 'float')
				ELSE
					query_plan.value('sum(//p:StmtSimple[xs:hexBinary(substring(@QueryPlanHash, 3)) = xs:hexBinary(sql:column("query_plan_hash"))]/@StatementSubTreeCost)', 'float')
				END	, 
			  missing_index_count = query_plan.value('count(//p:MissingIndexGroup)', 'int') ,
			  unmatched_index_count = query_plan.value('count(//p:UnmatchedIndexes/p:Parameterization/p:Object)', 'int') ,
			  plan_multiple_plans = CASE WHEN distinct_plan_count < number_of_plans THEN 1 END ,				
			  is_trivial = CASE WHEN query_plan.exist('//p:StmtSimple[@StatementOptmLevel[.="TRIVIAL"]]/p:QueryPlan/p:ParameterList') = 1 THEN 1 END,
			  is_parallel = CASE WHEN query_plan.value('max(//p:RelOp/@Parallel)', 'float') >0  THEN 1 END
	FROM (
				SELECT COUNT(DISTINCT query_hash) AS distinct_plan_count,
				       COUNT(query_hash) AS number_of_plans,
				       query_hash
				FROM   ##CacheProcs
				GROUP BY query_hash
			) AS x
	WHERE ##CacheProcs.query_hash = x.query_hash
	OPTION (RECOMPILE) ;
	

	
	--	Busy Loops, No Join Predicate, tvf_join, no_join_warning
	WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
		UPDATE P
		SET 
			busy_loops = CASE WHEN (x.estimated_executions / 100.0) > x.estimated_rows THEN 1 ELSE 0 END ,
			tvf_join = CASE WHEN x.tvf_join = 1 THEN 1  ELSE 0 END ,
			warning_no_join_predicate = CASE WHEN x.no_join_warning = 1 THEN 1  ELSE 0 END
	FROM
		##CacheProcs   AS P
		JOIN (
					SELECT 
							qp.sql_handle, statement_start, statement_end,create_date,set_options,  qp.query_plan, qp.plan_handle
						, n.value('@NodeId', 'int') AS node_id
						, n.value('@EstimateRows', 'float') AS estimated_rows 
						, n.value('@EstimateRewinds', 'float') + n.value('@EstimateRebinds', 'float') + 1.0 AS estimated_executions
						, n.query('.').exist('/p:RelOp[contains(@LogicalOp, "Join")]/*/p:RelOp[(@LogicalOp[.="Table-valued function"])]') AS tvf_join
						, n.query('.').exist('//p:RelOp/p:Warnings[(@NoJoinPredicate[.="1"])]') AS no_join_warning
					FROM ##CacheProcs as qp WITH(NOLOCK)
						OUTER APPLY qp.query_plan.nodes('//*') AS q(n)
					WHERE  n.value('local-name(.)', 'nvarchar(100)') = N'RelOp'
				) AS X  ON P.plan_handle = X.plan_handle AND P.statement_start = X.statement_start AND P.statement_end = X.statement_end AND P.set_options = X.set_options
						AND P.create_date  = X.create_date;


		 -- Compilation Timeout , Compile Memory Limit Exceeded
		  WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
			UPDATE P
			SET 
				compile_timeout = CASE WHEN n.query('.').exist('/p:StmtSimple/@StatementOptmEarlyAbortReason[.="TimeOut"]') = 1 THEN 1 END ,
				compile_memory_limit_exceeded = CASE WHEN n.query('.').exist('/p:StmtSimple/@StatementOptmEarlyAbortReason[.="MemoryLimitExceeded"]') = 1 THEN 1 END
		   FROM ##CacheProcs   AS P
			CROSS APPLY p.query_plan.nodes('//p:StmtSimple') AS q(n) 


		  --is_forced_plan, is_forced_parameterized
		  UPDATE p
			SET    is_forced_parameterized = CASE WHEN (CAST(pa.value AS INT) & 131072 = 131072) THEN 1
												  END ,
				   is_forced_plan = CASE WHEN (CAST(pa.value AS INT) & 131072 = 131072) THEN 1
										 WHEN (CAST(pa.value AS INT) & 4 = 4) THEN 1 
										 END 
			FROM   ##CacheProcs p
				   CROSS APPLY sys.dm_exec_plan_attributes(p.plan_handle) pa
			WHERE  pa.attribute = 'set_options' ;

		 -- unparameterized_query,implicit_conversions,long_running,tempdb_spill,near_parallel,plan_warnings,frequent_execution
		 /* coifiguration table create 필요 */
			
		DECLARE @execution_threshold INT = 1000 ,
				@parameter_sniffing_warning_pct TINYINT = 30,
				/* This is in average reads */
				@parameter_sniffing_io_threshold BIGINT = 100000 ,
				@ctp_threshold_pct TINYINT = 10,
				@long_running_query_warning_seconds BIGINT = 300 * 1000 ;

				SELECT @execution_threshold = CAST(value AS INT)
				FROM   DB_MON_QUERY_STATS_CONFIGURATION WITH(NOLOCK)
				WHERE  'frequent execution threshold' = LOWER(parameter_name) ;


				SELECT @parameter_sniffing_warning_pct = CAST(value AS TINYINT)
				FROM   DB_MON_QUERY_STATS_CONFIGURATION WITH(NOLOCK)
				WHERE  'parameter sniffing variance percent' = LOWER(parameter_name) ;

	
				SELECT @parameter_sniffing_io_threshold = CAST(value AS BIGINT)
				FROM   DB_MON_QUERY_STATS_CONFIGURATION WITH(NOLOCK)
				WHERE 'parameter sniffing io threshold' = LOWER(parameter_name) ;

	
				SELECT @ctp_threshold_pct = CAST(value AS TINYINT)
				FROM   DB_MON_QUERY_STATS_CONFIGURATION WITH(NOLOCK)
				WHERE 'cost threshold for parallelism warning' = LOWER(parameter_name) ;

				SELECT @long_running_query_warning_seconds = CAST(value * 1000 AS BIGINT)
					FROM   DB_MON_QUERY_STATS_CONFIGURATION WITH(NOLOCK)
				WHERE 'long running query warning (seconds)' = LOWER(parameter_name) ;



				DECLARE @ctp INT ;

				SELECT  @ctp = CAST(value AS INT)
				FROM    sys.configurations
				WHERE   name = 'cost threshold for parallelism'
				OPTION (RECOMPILE);


	

			WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
			UPDATE ##CacheProcs
				SET    frequent_execution = CASE WHEN p.cnt_min > @execution_threshold THEN 1 END ,
						-- 2012 버전 이상 이여야  sys.dm_exec_query_stats  row 값을 알 수 있음
					   --parameter_sniffing = CASE WHEN AverageReads > @parameter_sniffing_io_threshold
								--					  AND min_worker_time < ((1.0 - (@parameter_sniffing_warning_pct / 100.0)) * AverageCPU) THEN 1
								--				 WHEN AverageReads > @parameter_sniffing_io_threshold
								--					  AND max_worker_time > ((1.0 + (@parameter_sniffing_warning_pct / 100.0)) * AverageCPU) THEN 1
								--				 WHEN AverageReads > @parameter_sniffing_io_threshold
								--					  AND MinReturnedRows < ((1.0 - (@parameter_sniffing_warning_pct / 100.0)) * AverageReturnedRows) THEN 1
								--				 WHEN AverageReads > @parameter_sniffing_io_threshold
								--					  AND MaxReturnedRows > ((1.0 + (@parameter_sniffing_warning_pct / 100.0)) * AverageReturnedRows) THEN 1 END ,
					  -- near_parallel = CASE WHEN QueryPlanCost BETWEEN @ctp * (1 - (@ctp_threshold_pct / 100.0)) AND @ctp THEN 1 END,
					   plan_warnings = CASE WHEN p.query_plan.value('count(//p:Warnings)', 'int') > 0 THEN 1 END,
					   long_running = CASE WHEN p.duration_cnt /1000000 > @long_running_query_warning_seconds THEN 1 END,  -- 마이크로 초
										   --WHEN max_worker_time > @long_running_query_warning_seconds THEN 1
										   --WHEN max_elapsed_time > @long_running_query_warning_seconds THEN 1 END ,
					   implicit_conversions = CASE WHEN p.query_plan.exist('//p:RelOp//p:ScalarOperator/@ScalarString
														[contains(., "CONVERT_IMPLICIT")]') = 1 THEN 1
												   WHEN p.query_plan.exist('
														//p:PlanAffectingConvert/@Expression
														[contains(., "CONVERT_IMPLICIT")]') = 1 THEN 1
												   END ,
					   tempdb_spill = CASE WHEN p.query_plan.value('max(//p:SpillToTempDb/@SpillLevel)', 'int') > 0 THEN 1 END ,
					   unparameterized_query 
					   = CASE WHEN p.query_plan.exist('//p:StmtSimple[@StatementOptmLevel[.="FULL"]]/p:QueryPlan/p:ParameterList') = 1 AND
										p.query_plan.exist('//p:StmtSimple[@StatementOptmLevel[.="FULL"]]/p:QueryPlan/p:ParameterList/p:ColumnReference') = 0 THEN 1
								WHEN p.query_plan.exist('//p:StmtSimple[@StatementOptmLevel[.="FULL"]]/p:QueryPlan/p:ParameterList') = 0 AND
										p.query_plan.exist('//p:StmtSimple[@StatementOptmLevel[.="FULL"]]/*/p:RelOp/descendant::p:ScalarOperator/p:Identifier/p:ColumnReference[contains(@Column, "@")]')
														 = 1 THEN 1 END 
				FROM ##CacheProcs as p

		-- Cursor checks 
		UPDATE p
		SET    is_cursor = CASE WHEN CAST(pa.value AS INT) <> 0 THEN 1 END
		FROM   ##CacheProcs p
			   CROSS APPLY sys.dm_exec_plan_attributes(p.plan_handle) pa
		WHERE  pa.attribute LIKE '%cursor%' ;
		
		--WARING UPDATE
		UPDATE  Q
			SET warnings = 
					SUBSTRING(
                  CASE WHEN warning_no_join_predicate = 1 THEN ', No Join Predicate' ELSE '' END +
                  CASE WHEN compile_timeout = 1 THEN ', Compilation Timeout' ELSE '' END +
                  CASE WHEN compile_memory_limit_exceeded = 1 THEN ', Compile Memory Limit Exceeded' ELSE '' END +
                  CASE WHEN busy_loops = 1 THEN ', Busy Loops' ELSE '' END +
                  CASE WHEN is_forced_plan = 1 THEN ', Forced Plan' ELSE '' END +
                  CASE WHEN is_forced_parameterized = 1 THEN ', Forced Parameterization' ELSE '' END +
                  CASE WHEN unparameterized_query = 1 THEN ', Unparameterized Query' ELSE '' END +
                  CASE WHEN missing_index_count > 0 THEN ', Missing Indexes (' + CAST(missing_index_count AS VARCHAR(3)) + ')' ELSE '' END +
                  CASE WHEN unmatched_index_count > 0 THEN ', Unmatched Indexes (' + CAST(unmatched_index_count AS VARCHAR(3)) + ')' ELSE '' END +                  
                  CASE WHEN is_cursor = 1 THEN ', Cursor' ELSE '' END +
                  CASE WHEN is_parallel = 1 THEN ', Parallel' ELSE '' END +
                  CASE WHEN near_parallel = 1 THEN ', Nearly Parallel' ELSE '' END +
                  CASE WHEN frequent_execution = 1 THEN ', Frequent Execution' ELSE '' END +
                  CASE WHEN plan_warnings = 1 THEN ', Plan Warnings' ELSE '' END +
                  --CASE WHEN parameter_sniffing = 1 THEN ', Parameter Sniffing' ELSE '' END +
                  CASE WHEN long_running = 1 THEN ', Long Running Query' ELSE '' END +
                  --CASE WHEN downlevel_estimator = 1 THEN ', Downlevel CE' ELSE '' END +
                  CASE WHEN implicit_conversions = 1 THEN ', Implicit Conversions' ELSE '' END +
                  CASE WHEN tempdb_spill = 1 THEN ', TempDB Spills' ELSE '' END +
                  CASE WHEN tvf_join = 1 THEN ', Function Join' ELSE '' END +
                  CASE WHEN plan_multiple_plans = 1 THEN ', Multiple Plans' ELSE '' END +
                  CASE WHEN is_trivial = 1 THEN ', Trivial Plans' ELSE '' END 
                  , 2, 200000), 
				query_cost = convert(money,p.query_cost)
		FROM DB_MON_QUERY_PLAN_V3 AS Q
			JOIN ##CacheProcs AS P ON p.sql_handle = q.sql_handle and p.statement_start = q.statement_start and p.statement_end = q.statement_end and p.set_options = q.set_options
		where q.reg_date = @reg_date	

		--select is_forced_parameterized,is_forced_plan,  compile_timeout,compile_memory_limit_exceeded, * from ##CacheProcs


END
GO

/*************************************************************************  
* 프로시저명: dbo.UP_MON_QUERY_PLAN_WARNINGS
* 작성정보	: 2014-12-15 BY CHOI BO RA
* 관련페이지:  
* 내용		:  쿼리 PLAN WARINGS 정보

* 수정정보	: 
**************************************************************************/
CREATE PROCEDURE dbo.UP_MON_QUERY_PLAN_WARNINGS
	@date			datetime = null
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
if @date is null set @date =  getdate()

select top 1 @date = reg_date from db_mon_query_stats_v3 (nolock) 
where reg_date <= @date order by reg_date desc


select 
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
p.query_cost,
p.warnings,
s.query_text,
p.query_plan
from dbo.db_mon_query_stats_v3 s (nolock)   
 join  dbo.db_mon_query_plan_v3 p (nolock)  
  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
where s.reg_date = @date
	AND P.WARNINGS <> ''
order by s.reg_date desc, s.cpu_min desc 
go