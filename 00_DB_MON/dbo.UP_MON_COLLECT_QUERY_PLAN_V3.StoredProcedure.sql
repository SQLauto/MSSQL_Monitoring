
/*************************************************************************  
* 프로시저명	: dbo.[UP_MON_COLLECT_QUERY_PLAN_V3]
* 작성정보	: 2012-08-02 BY CHOI BO RA
* 관련페이지:  
* 내용		:  
* 수정정보	: PREPARED SQL을 수집하기 위해 생성. DB_ID조건을 제거 해야함.
						 2014-11-17 by choi bo ra sql_handel 값 입력
						 2015-01-14 by choi bo ra object_name 입력 수정.
**************************************************************************/
CREATE PROCEDURE [DBO].[UP_MON_COLLECT_QUERY_PLAN_V3]        
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
		  @OBJECT_NAME AS OBJECT_NAME,
		  --OBJECT_NAME(OBJECTID, DBID) AS OBJECT_NAME,        
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


		  --is_forced_plan, is_forced_ameterized
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

