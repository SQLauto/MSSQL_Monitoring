/*************************************************************************  
* 프로시저명  : dbo.up_mon_sp_index_usage
* 작성정보    : 2014-04-01 by sewkim
* 관련페이지  :  
* 내용        : SP index 사용현황
* 수정정보    : 'TIGER','up_sttl_vaccount_confirm_not_single_running'
* select plan_handle, count(*) from sys.dm_exec_query_stats group by plan_handle
* select * from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
* select db_name(database_id), object_name(object_id,database_id) from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
*************************************************************************/
CREATE proc up_mon_sp_index_update
	@db_name sysname, 
	@sp_name sysname,
	@plan tinyint = 0, 
    @table_name sysname = '',
    @index_name sysname = ''
as
declare @db_id int, @object_id int
declare @param nvarchar(100)  = N'@object_id int OUTPUT'
declare @query nvarchar(500)
declare @sql_handle  varbinary(64) 

if not @table_name = ''
	SET @table_name=QUOTENAME(@table_name,'[');

if not @index_name = ''
	SET @index_name=QUOTENAME(@index_name,'[');

set @db_id = db_id(@db_name);
set @query =N'select @object_id = object_id from ' + @db_name + '.sys.objects where name = ''' + @sp_name + ''''

execute sp_executesql @query, @param, @object_id = @object_id OUTPUT;

if @object_id is null 
  begin 
    select 'object not founded' 	
	return 
  end

select @sql_handle = sql_handle  from sys.dm_exec_procedure_stats  a where a.database_id = @db_id and a.object_id = @object_id;
if @sql_handle is null 
  begin 
    select 'sql_handle not founded'; 	
	return 
  end;
  
WITH XMLNAMESPACES(DEFAULT 
        'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
        INDEXSEARCH
AS (
		select convert(xml,a.query_plan) query_plan
			   ,convert(xml,b.query_plan) b_query_plan
			   ,plan_handle
			   ,statement_start_offset
			   ,statement_end_offset
			   ,a.dbid
			   ,a.objectid
			   ,M.creation_time	
			   ,M.last_execution_time
			   ,M.execution_count	
			   ,M.total_worker_time
			   ,M.total_physical_reads	
			   ,M.total_logical_writes	
			   ,M.total_logical_reads	
			   ,M.total_clr_time	
			   ,M.total_elapsed_time
		  from sys.dm_exec_query_stats M
		 outer apply sys.dm_exec_text_query_plan (plan_handle,statement_start_offset,statement_end_offset) A
		 outer apply sys.dm_exec_query_plan (plan_handle) B 
		 where sql_handle = @sql_handle
)
SELECT 
		 db_name(IXS.dbid) dbname
		,object_name(IXS.objectid,IXS.dbid) objectname
--		,statement_start_offset
--		,statement_end_offset

		,F.LINE_START
		,F.LINE_END 

		,SUBSTRING(TEXT, statement_start_offset/2, case when statement_end_offset > 0 then (statement_end_offset - statement_start_offset)/2 else (len(TEXT) - statement_end_offset)/2 end )  string

        ,c2.value('@Database','sysname') AS DATABASE_NAME
        ,c2.value('@Schema','sysname') AS SCHEMA_NAME
        ,c2.value('@Table','sysname') AS TABLE_NAME
        ,c2.value('@Index','sysname') AS INDEX_NAME
        ,c2.value('@IndexKind','sysname') AS INDEX_KIND

	    ,c1.value('@NodeId','int')  NodeId
	    ,c1.value('@PhysicalOp','nvarchar(50)')  PhysicalOp 
		,c1.value('@LogicalOp','nvarchar(50)')  LogicalOp
	    ,c1.value('@EstimateRows', 'nvarchar(50)') EstimateRows

		,IXS.creation_time	
		,IXS.last_execution_time
		,IXS.execution_count	
		,IXS.total_worker_time
		,IXS.total_physical_reads	
		,IXS.total_logical_writes	
		,IXS.total_logical_reads	
		,IXS.total_clr_time	
		,IXS.total_elapsed_time

	    ,c1.value('@EstimateIO', 'nvarchar(50)') EstimateIO      
	    ,c1.value('@EstimateCPU', 'nvarchar(50)') EstimateCPU
	    ,c1.value('@AvgRowSize', 'nvarchar(50)') AvgRowSize
	    ,c1.value('@EstimatedTotalSubtreeCost', 'nvarchar(50)')  EstimatedTotalSubtreeCost
	    ,c1.value('@Parallel','nvarchar(50)') Parallel
	    ,c1.value('@EstimateRebinds','nvarchar(50)') EstimateRebinds
	    ,c1.value('@EstimateRewinds','nvarchar(50)') EstimateRewinds
	    ,c1.value('@TableCardinality','nvarchar(50)') TableCardinality

	    ,case when @plan = 0 then null else IXS.query_plan		 end query_stats_plan
	    ,case when @plan = 0 then null else IXS.b_query_plan     end sp_plan

FROM INDEXSEARCH IXS
OUTER APPLY DBMON.DBO.FN_GETOBJECTLINE(plan_handle, statement_start_offset, statement_end_offset) F  
OUTER APPLY sys.dm_exec_sql_text(plan_handle)
CROSS APPLY QUERY_PLAN.nodes('//RelOp') as r(c1)
CROSS APPLY c1.nodes('Update/Object') as o(c2)
WHERE @table_name = case when @table_name = '' then @table_name ELSE c2.value('@Table','sysname') end
  AND @index_name = case when @index_name = '' then @index_name ELSE c2.value('@Index','sysname') end

go

/*************************************************************************  
* 프로시저명  : dbo.up_mon_sp_index_update_light
* 작성정보    : 2014-04-01 by sewkim
* 관련페이지  :  
* 내용        : SP index 사용현황
* 수정정보    : 'TIGER','up_sttl_vaccount_confirm_not_single_running'
* select plan_handle, count(*) from sys.dm_exec_query_stats group by plan_handle
* select * from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
* select db_name(database_id), object_name(object_id,database_id) from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
*************************************************************************/
CREATE proc up_mon_sp_index_update_light
	@db_name sysname, 
	@sp_name sysname,
	@plan tinyint = 0, 
	@text tinyint = 0, 
    @table_name sysname = '',
    @index_name sysname = ''
as

set nocount on 

declare @db_id int, @object_id int
declare @param nvarchar(100)  = N'@object_id int OUTPUT'
declare @query nvarchar(500)
declare @sql_handle varbinary(64)
declare @id int, @maxid int

if not @table_name = ''
	SET @table_name=QUOTENAME(@table_name,'[');

if not @index_name = ''
	SET @index_name=QUOTENAME(@index_name,'[');

set @db_id = db_id(@db_name);
set @query =N'select @object_id = object_id from ' + @db_name + '.sys.objects where name = ''' + @sp_name + ''''

execute sp_executesql @query, @param, @object_id = @object_id OUTPUT;

if @object_id is null 
  begin 
    select 'object not founded' 	
	return 
  end

select @sql_handle = sql_handle  from sys.dm_exec_procedure_stats  a where a.database_id = @db_id and a.object_id = @object_id;
if @sql_handle is null 
  begin 
    select 'sql_handle not founded'; 	
	return 
  end;
    
  CREATE TABLE #T1 
  ( 
	 id						int identity
	,query_plan				xml	
	,plan_handle			varbinary(64)
	,statement_start_offset	int
	,statement_end_offset	int
	,dbid					smallint
	,objectid				int
	,creation_time			datetime
	,last_execution_time	datetime
	,execution_count		bigint
	,total_worker_time		bigint
	,total_physical_reads	bigint
	,total_logical_writes	bigint
	,total_logical_reads	bigint
	,total_clr_time			bigint
	,total_elapsed_time		bigint
  )
  
  CREATE TABLE #T2
  (
	 id int identity
	,gn			char(1)
	,dbname		varchar(256) null
	,objectname	varchar(256) null
	,LINE_START	int null
	,LINE_END	int null
	,DATABASE_NAME	sysname null
	,SCHEMA_NAME	sysname null
	,TABLE_NAME		sysname null
	,INDEX_NAME		sysname null
	,INDEX_KIND		sysname null
	,NodeId			int null
	,PhysicalOp		varchar(100) null
	,LogicalOp		varchar(100) null
	,EstimateRows	nvarchar(100) null
	,creation_time	datetime null
	,last_execution_time	datetime null
	,min_worker_time		bigint null
	,unit_worker_time		bigint null
	,execution_count		bigint null
	,total_worker_time		bigint null
	,total_physical_reads	bigint null
	,total_logical_writes	bigint null
	,total_logical_reads	bigint null
	,total_clr_time			bigint null
	,total_elapsed_time		bigint null
	,EstimateIO				varchar(100) null
	,EstimateCPU			varchar(100) null
	,AvgRowSize				varchar(100) null
	,EstimatedTotalSubtreeCost	varchar(100) null
	,Parallel				varchar(100) null
	,EstimateRebinds		varchar(100) null
	,EstimateRewinds		varchar(100) null
	,TableCardinality		varchar(100) null
	,query_stats_plan		xml  null
	,string					varchar(max)  null
  )

set @id = 1

insert #t1
select  convert(xml,a.query_plan) query_plan
		,plan_handle
		,statement_start_offset
		,statement_end_offset
		,a.dbid
		,a.objectid
		,M.creation_time	
		,M.last_execution_time
		,M.execution_count	
		,M.total_worker_time
		,M.total_physical_reads	
		,M.total_logical_writes	
		,M.total_logical_reads	
		,M.total_clr_time	
		,M.total_elapsed_time
	from sys.dm_exec_query_stats M
	outer apply sys.dm_exec_text_query_plan (plan_handle,statement_start_offset,statement_end_offset) A
	outer apply sys.dm_exec_query_plan (plan_handle) B 
	where sql_handle = @sql_handle;

set @maxid = @@identity;

WHILE (@id <= @maxid)	   
BEGIN
	WITH XMLNAMESPACES(DEFAULT 
			'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
			INDEXSEARCH
	AS (
			select * from #t1 where id = @id 
	)
	INSERT #T2
	SELECT 
			 '2' gn
			,db_name(IXS.dbid) dbname
			,object_name(IXS.objectid,IXS.dbid) objectname
			,statement_start_offset
			,statement_end_offset

	--		,F.LINE_START
	--		,F.LINE_END 

			,c2.value('@Database','sysname') AS DATABASE_NAME
			,c2.value('@Schema','sysname') AS SCHEMA_NAME
			,c2.value('@Table','sysname') AS TABLE_NAME
			,c2.value('@Index','sysname') AS INDEX_NAME
			,c2.value('@IndexKind','sysname') AS INDEX_KIND

			,c1.value('@NodeId','int')  NodeId
			,c1.value('@PhysicalOp','nvarchar(50)')  PhysicalOp 
			,c1.value('@LogicalOp','nvarchar(50)')  LogicalOp
			,c1.value('@EstimateRows', 'nvarchar(50)') EstimateRows

			,IXS.creation_time	
			,IXS.last_execution_time

			,IXS.total_worker_time / (datediff(minute,IXS.creation_time,getdate()) + 1) hour_worker_time 
			,IXS.total_worker_time / IXS.execution_count unit_worker_time 

			,IXS.execution_count	
			,IXS.total_worker_time
			,IXS.total_physical_reads	
			,IXS.total_logical_writes	
			,IXS.total_logical_reads	
			,IXS.total_clr_time	
			,IXS.total_elapsed_time

			,c1.value('@EstimateIO', 'nvarchar(50)') EstimateIO      
			,c1.value('@EstimateCPU', 'nvarchar(50)') EstimateCPU
			,c1.value('@AvgRowSize', 'nvarchar(50)') AvgRowSize
			,c1.value('@EstimatedTotalSubtreeCost', 'nvarchar(50)')  EstimatedTotalSubtreeCost
			,c1.value('@Parallel','nvarchar(50)') Parallel
			,c1.value('@EstimateRebinds','nvarchar(50)') EstimateRebinds
			,c1.value('@EstimateRewinds','nvarchar(50)') EstimateRewinds
			,c1.value('@TableCardinality','nvarchar(50)') TableCardinality

			,case when @plan = 0 then null else IXS.query_plan		 end query_stats_plan
	--	    ,case when @plan = 0 then null else IXS.b_query_plan     end sp_plan
			,''
	--		,case when @text = 0 then '' else 
	--		 REPLACE(REPLACE(REPLACE(SUBSTRING(TEXT, statement_start_offset/2, case when statement_end_offset > 0 then (statement_end_offset - statement_start_offset)/2 
	--		 else (len(TEXT) - statement_end_offset)/2 end ),CHAR(13), ' '),CHAR(10), ' '),CHAR(09), ' ') end string
	FROM INDEXSEARCH IXS
	-- OUTER APPLY DBMON.DBO.FN_GETOBJECTLINE(plan_handle, statement_start_offset, statement_end_offset) F  
	OUTER APPLY sys.dm_exec_sql_text(plan_handle)
	CROSS APPLY query_plan.nodes('//RelOp') as r(c1)
	CROSS APPLY c1.nodes('Update/Object') as o(c2)
	WHERE @table_name = case when @table_name = '' then @table_name ELSE c2.value('@Table','sysname') end
	  AND @index_name = case when @index_name = '' then @index_name ELSE c2.value('@Index','sysname') end;
	
	set @id = @id + 1; 
 
END

SELECT * FROM #t2 order by id;
go


/*************************************************************************  
* 프로시저명  : dbo.up_mon_sp_index_usage
* 작성정보    : 2014-04-01 by sewkim
* 관련페이지  :  
* 내용        : SP index 사용현황
* 수정정보    : 'TIGER','up_sttl_vaccount_confirm_not_single_running'
* select plan_handle, count(*) from sys.dm_exec_query_stats group by plan_handle
* select * from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
* select db_name(database_id), object_name(object_id,database_id) from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
*************************************************************************/
CREATE proc up_mon_sp_index_usage
	@db_name sysname, 
	@sp_name sysname,
	@plan tinyint = 0, 
    @table_name sysname = '',
    @index_name sysname = ''
as
declare @db_id int, @object_id int
declare @param nvarchar(100)  = N'@object_id int OUTPUT'
declare @query nvarchar(500)
declare @sql_handle varbinary(64) 

if not @table_name = ''
	SET @table_name=QUOTENAME(@table_name,'[');

if not @index_name = ''
	SET @index_name=QUOTENAME(@index_name,'[');

set @db_id = db_id(@db_name);
set @query =N'select @object_id = object_id from ' + @db_name + '.sys.objects where name = ''' + @sp_name + ''''

execute sp_executesql @query, @param, @object_id = @object_id OUTPUT;

if @object_id is null 
  begin 
    select 'object not founded' 	
	return 
  end

select @sql_handle = sql_handle  from sys.dm_exec_procedure_stats  a where a.database_id = @db_id and a.object_id = @object_id;
if @sql_handle is null 
  begin 
    select 'sql_handle not founded'; 	
	return 
  end;
  
WITH XMLNAMESPACES(DEFAULT 
        'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
        INDEXSEARCH
AS (
		select convert(xml,a.query_plan) query_plan
			   ,convert(xml,b.query_plan) b_query_plan
			   ,plan_handle
			   ,statement_start_offset
			   ,statement_end_offset
			   ,a.dbid
			   ,a.objectid
			   ,M.creation_time	
			   ,M.last_execution_time
			   ,M.execution_count	
			   ,M.total_worker_time
			   ,M.total_physical_reads	
			   ,M.total_logical_writes	
			   ,M.total_logical_reads	
			   ,M.total_clr_time	
			   ,M.total_elapsed_time
		  from sys.dm_exec_query_stats M
		 outer apply sys.dm_exec_text_query_plan (plan_handle,statement_start_offset,statement_end_offset) A
		 outer apply sys.dm_exec_query_plan (plan_handle) B 
		 where sql_handle = @sql_handle
)
SELECT 
		 db_name(IXS.dbid) dbname
		,object_name(IXS.objectid,IXS.dbid) objectname
--		,statement_start_offset
--		,statement_end_offset

		,F.LINE_START
		,F.LINE_END 

		,SUBSTRING(TEXT, statement_start_offset/2, case when statement_end_offset > 0 then (statement_end_offset - statement_start_offset)/2 else (len(TEXT) - statement_end_offset)/2 end )  string

        ,c2.value('@Database','sysname') AS DATABASE_NAME
        ,c2.value('@Schema','sysname') AS SCHEMA_NAME
        ,c2.value('@Table','sysname') AS TABLE_NAME
        ,c2.value('@Index','sysname') AS INDEX_NAME
        ,c2.value('@IndexKind','sysname') AS INDEX_KIND

	    ,c1.value('@NodeId','int')  NodeId
	    ,c1.value('@PhysicalOp','nvarchar(50)')  PhysicalOp 
		,c1.value('@LogicalOp','nvarchar(50)')  LogicalOp
	    ,c1.value('@EstimateRows', 'nvarchar(50)') EstimateRows

		,IXS.creation_time	
		,IXS.last_execution_time
		,IXS.execution_count	
		,IXS.total_worker_time
		,IXS.total_physical_reads	
		,IXS.total_logical_writes	
		,IXS.total_logical_reads	
		,IXS.total_clr_time	
		,IXS.total_elapsed_time

	    ,c1.value('@EstimateIO', 'nvarchar(50)') EstimateIO      
	    ,c1.value('@EstimateCPU', 'nvarchar(50)') EstimateCPU
	    ,c1.value('@AvgRowSize', 'nvarchar(50)') AvgRowSize
	    ,c1.value('@EstimatedTotalSubtreeCost', 'nvarchar(50)')  EstimatedTotalSubtreeCost
	    ,c1.value('@Parallel','nvarchar(50)') Parallel
	    ,c1.value('@EstimateRebinds','nvarchar(50)') EstimateRebinds
	    ,c1.value('@EstimateRewinds','nvarchar(50)') EstimateRewinds
	    ,c1.value('@TableCardinality','nvarchar(50)') TableCardinality



FROM INDEXSEARCH IXS
OUTER APPLY DBMON.DBO.FN_GETOBJECTLINE(plan_handle, statement_start_offset, statement_end_offset) F  
OUTER APPLY sys.dm_exec_sql_text(plan_handle)
CROSS APPLY QUERY_PLAN.nodes('//RelOp') as r(c1)
CROSS APPLY c1.nodes('IndexScan/Object') as o(c2)
WHERE @table_name = case when @table_name = '' then @table_name ELSE c2.value('@Table','sysname') end
  AND @index_name = case when @index_name = '' then @index_name ELSE c2.value('@Index','sysname') end
go



-- dbmon에 있는 Query Paln
/*************************************************************************  
* 프로시저명  : dbo.up_mon_sp_index_usage_dbmon
* 작성정보    : 2014-04-01 by sewkim
* 관련페이지  :  
* 내용        : SP index 사용현황
* 수정정보    : 'TIGER','up_sttl_vaccount_confirm_not_single_running'
* select plan_handle, count(*) from sys.dm_exec_query_stats group by plan_handle
* select * from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
* select db_name(database_id), object_name(object_id,database_id) from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
*************************************************************************/
CREATE proc up_mon_sp_index_usage_dbmon
	@db_name sysname, 
	@sp_name sysname,
	@plan tinyint = 0, 
    @table_name sysname = '',
    @index_name sysname = ''
as
declare @query_plan xml
declare @create_date datetime
declare @plan_handle varbinary(64)
declare @sql_handle varbinary(64)

if not @table_name = ''
	SET @table_name=QUOTENAME(@table_name,'[');

if not @index_name = ''
	SET @index_name=QUOTENAME(@index_name,'[');

SELECT @create_date = max(create_date) FROM DB_MON_QUERY_PLAN_V3 WHERE db_name = @db_name and object_name = @sp_name
if @create_date is null 
  begin 
    select 'object not founded'; 	
	return 
  end;
 
SELECT @sql_handle = sql_handle
  FROM DB_MON_QUERY_PLAN_V3 
 WHERE db_name = @db_name and object_name = @sp_name and create_date = @create_date;

CREATE TABLE #T1
(
	plan_handle varbinary (64),
	statement_start INT,
	statement_end INT,
	line_start	INT,
	line_end	INT,
	CREATE_DATE DATETIME
);

INSERT #T1
SELECT plan_handle, STATEMENT_START, STATEMENT_END,line_start, line_end, MAX(CREATE_DATE)
  FROM DB_MON_QUERY_PLAN_V3 
 WHERE db_name = @db_name and object_name = @sp_name and sql_handle = @sql_handle
 GROUP BY plan_handle, STATEMENT_START, STATEMENT_END,line_start, line_end;

WITH XMLNAMESPACES(DEFAULT 
        'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
        INDEXSEARCH
AS (
		select QP.*
		   ,c2.value('@Table','nvarchar(max)') table_name
		   ,c2.value('@Index','nvarchar(max)') index_name 

		   ,c1.value('@NodeId','int')  NodeId
		   ,c1.value('@PhysicalOp','nvarchar(max)')  PhysicalOp
		   ,c1.value('@LogicalOp','nvarchar(max)')  LogicalOp
		   ,c1.value('@EstimateRows', 'nvarchar(50)') EstimateRows
		   ,c1.value('@EstimateIO', 'nvarchar(50)') EstimateIO      
		   ,c1.value('@EstimateCPU', 'nvarchar(50)') EstimateCPU
		   ,c1.value('@AvgRowSize', 'nvarchar(50)') AvgRowSize
		   ,c1.value('@EstimatedTotalSubtreeCost', 'nvarchar(50)')  EstimatedTotalSubtreeCost
		   ,c1.value('@Parallel','nvarchar(50)') Parallel
		   ,c1.value('@EstimateRebinds','nvarchar(50)') EstimateRebinds
		   ,c1.value('@EstimateRewinds','nvarchar(50)') EstimateRewinds
		   ,c1.value('@TableCardinality','nvarchar(50)') TableCardinality
		   FROM #T1 A 
		   JOIN DBMON.dbo.DB_MON_QUERY_PLAN_V3 QP 
			ON A.plan_handle = QP.plan_handle AND A.statement_start = QP.statement_start AND A.statement_END = QP.statement_END AND A.CREATE_DATE = QP.create_date 
		  CROSS APPLY qp.query_plan.nodes('//RelOp') as r(c1) 
		  CROSS APPLY c1.nodes('IndexScan/Object') as o(c2)  
		 where db_name = @db_name and object_name = @sp_name
)
SELECT	 
		 db_name
		,object_name
		,line_start
		,line_end
		,table_name
		,index_name
		,PhysicalOp
		,LogicalOp
		,NodeId
		,EstimateRows
		,SUBSTRING(st.value('@StatementText','nvarchar(max)'), statement_start/2, case when statement_end > 0 
					then (statement_end - statement_start)/2 
					else (len(st.value('@StatementText','nvarchar(max)')) - statement_end)/2 end )  string
		,query_cost
		,warnings
--		,reg_date
--		,upd_date
--	    ,case when @plan = 0 then null else query_plan		 end query_plan
 FROM INDEXSEARCH
 CROSS APPLY query_plan.nodes('//StmtSimple') as s(st) 
WHERE @table_name = case when @table_name = '' then @table_name ELSE table_name end
  AND @index_name = case when @index_name = '' then @index_name ELSE index_name end
go

/*************************************************************************  
* 프로시저명  : dbo.up_mon_sp_index_usage_dbmon_object
* 작성정보    : 2014-04-01 by sewkim
* 관련페이지  :  
* 내용        : SP index 사용현황
* 수정정보    : 'TIGER','up_sttl_vaccount_confirm_not_single_running'
* select plan_handle, count(*) from sys.dm_exec_query_stats group by plan_handle
* select * from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
* select db_name(database_id), object_name(object_id,database_id) from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
*************************************************************************/
CREATE proc up_mon_sp_index_usage_dbmon_object
	@db_name sysname, 
	@sp_name sysname,
	@plan tinyint = 0, 
    @table_name sysname = '',
    @index_name sysname = ''
as
declare @query_plan xml
declare @create_date datetime
declare @plan_handle varbinary(64)
declare @sql_handle varbinary(64)

if not @table_name = ''
	SET @table_name=QUOTENAME(@table_name,'[');

if not @index_name = ''
	SET @index_name=QUOTENAME(@index_name,'[');

SELECT @create_date = max(create_date) FROM DB_MON_QUERY_PLAN_V3 WHERE db_name = @db_name and object_name = @sp_name
if @create_date is null 
  begin 
    select 'object not founded'; 	
	return 
  end;
 
SELECT @sql_handle = sql_handle
  FROM DB_MON_QUERY_PLAN_V3 
 WHERE db_name = @db_name and object_name = @sp_name and create_date = @create_date;

CREATE TABLE #T1
(
	plan_handle varbinary (64),
	statement_start INT,
	statement_end INT,
	line_start	INT,
	line_end	INT,
	CREATE_DATE DATETIME
);

INSERT #T1
SELECT plan_handle, STATEMENT_START, STATEMENT_END,line_start, line_end, MAX(CREATE_DATE)
  FROM DB_MON_QUERY_PLAN_V3 
 WHERE db_name = @db_name and object_name = @sp_name and sql_handle = @sql_handle
 GROUP BY plan_handle, STATEMENT_START, STATEMENT_END,line_start, line_end;

WITH XMLNAMESPACES(DEFAULT 
        'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
        INDEXSEARCH
AS (
		select QP.*
		   ,c2.value('@Table','nvarchar(max)') table_name
		   ,c2.value('@Index','nvarchar(max)') index_name 

		   ,c1.value('@NodeId','int')  NodeId
		   ,c1.value('@PhysicalOp','nvarchar(max)')  PhysicalOp
		   ,c1.value('@LogicalOp','nvarchar(max)')  LogicalOp
		   ,c1.value('@EstimateRows', 'nvarchar(50)') EstimateRows
		   ,c1.value('@EstimateIO', 'nvarchar(50)') EstimateIO      
		   ,c1.value('@EstimateCPU', 'nvarchar(50)') EstimateCPU
		   ,c1.value('@AvgRowSize', 'nvarchar(50)') AvgRowSize
		   ,c1.value('@EstimatedTotalSubtreeCost', 'nvarchar(50)')  EstimatedTotalSubtreeCost
		   ,c1.value('@Parallel','nvarchar(50)') Parallel
		   ,c1.value('@EstimateRebinds','nvarchar(50)') EstimateRebinds
		   ,c1.value('@EstimateRewinds','nvarchar(50)') EstimateRewinds
		   ,c1.value('@TableCardinality','nvarchar(50)') TableCardinality
		   FROM #T1 A 
		   JOIN DBMON.dbo.DB_MON_QUERY_PLAN_V3 QP 
			ON A.plan_handle = QP.plan_handle AND A.statement_start = QP.statement_start AND A.statement_END = QP.statement_END AND A.CREATE_DATE = QP.create_date 
		  CROSS APPLY qp.query_plan.nodes('//RelOp') as r(c1) 
		  CROSS APPLY c1.nodes('ScalarInsert/Object') as o(c2)  
		 where db_name = @db_name and object_name = @sp_name
)
SELECT	 
		 db_name
		,object_name
		,line_start
		,line_end
		,table_name
		,index_name
		,PhysicalOp
		,LogicalOp
		,NodeId
		,EstimateRows
		,SUBSTRING(st.value('@StatementText','nvarchar(max)'), statement_start/2, case when statement_end > 0 
					then (statement_end - statement_start)/2 
					else (len(st.value('@StatementText','nvarchar(max)')) - statement_end)/2 end )  string
		,query_cost
		,warnings
--		,reg_date
--		,upd_date
--	    ,case when @plan = 0 then null else query_plan		 end query_plan
 FROM INDEXSEARCH
 CROSS APPLY query_plan.nodes('//StmtSimple') as s(st) 
WHERE @table_name = case when @table_name = '' then @table_name ELSE table_name end
  AND @index_name = case when @index_name = '' then @index_name ELSE index_name end
go

/*************************************************************************  
* 프로시저명  : dbo.up_mon_sp_index_usage_dbmon_update
* 작성정보    : 2014-04-01 by sewkim
* 관련페이지  :  
* 내용        : SP index 사용현황
* 수정정보    : 'TIGER','up_sttl_vaccount_confirm_not_single_running'
* select plan_handle, count(*) from sys.dm_exec_query_stats group by plan_handle
* select * from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
* select db_name(database_id), object_name(object_id,database_id) from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
*************************************************************************/
CREATE proc up_mon_sp_index_usage_dbmon_update
	@db_name sysname, 
	@sp_name sysname,
	@plan tinyint = 0, 
    @table_name sysname = '',
    @index_name sysname = ''
as
declare @query_plan xml
declare @create_date datetime
declare @plan_handle varbinary(64)
declare @sql_handle varbinary(64)

if not @table_name = ''
	SET @table_name=QUOTENAME(@table_name,'[');

if not @index_name = ''
	SET @index_name=QUOTENAME(@index_name,'[');

SELECT @create_date = max(create_date) FROM DB_MON_QUERY_PLAN_V3 WHERE db_name = @db_name and object_name = @sp_name
if @create_date is null 
  begin 
    select 'object not founded'; 	
	return 
  end;
 
SELECT @sql_handle = sql_handle
  FROM DB_MON_QUERY_PLAN_V3 
 WHERE db_name = @db_name and object_name = @sp_name and create_date = @create_date;

CREATE TABLE #T1
(
	plan_handle varbinary (64),
	statement_start INT,
	statement_end INT,
	line_start	INT,
	line_end	INT,
	CREATE_DATE DATETIME
);

INSERT #T1
SELECT plan_handle, STATEMENT_START, STATEMENT_END,line_start, line_end, MAX(CREATE_DATE)
  FROM DB_MON_QUERY_PLAN_V3 
 WHERE db_name = @db_name and object_name = @sp_name and sql_handle = @sql_handle
 GROUP BY plan_handle, STATEMENT_START, STATEMENT_END,line_start, line_end;

WITH XMLNAMESPACES(DEFAULT 
        'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
        INDEXSEARCH
AS (
		select QP.*
		   ,c2.value('@Table','nvarchar(max)') table_name
		   ,c2.value('@Index','nvarchar(max)') index_name 

		   ,c1.value('@NodeId','int')  NodeId
		   ,c1.value('@PhysicalOp','nvarchar(max)')  PhysicalOp
		   ,c1.value('@LogicalOp','nvarchar(max)')  LogicalOp
		   ,c1.value('@EstimateRows', 'nvarchar(50)') EstimateRows
		   ,c1.value('@EstimateIO', 'nvarchar(50)') EstimateIO      
		   ,c1.value('@EstimateCPU', 'nvarchar(50)') EstimateCPU
		   ,c1.value('@AvgRowSize', 'nvarchar(50)') AvgRowSize
		   ,c1.value('@EstimatedTotalSubtreeCost', 'nvarchar(50)')  EstimatedTotalSubtreeCost
		   ,c1.value('@Parallel','nvarchar(50)') Parallel
		   ,c1.value('@EstimateRebinds','nvarchar(50)') EstimateRebinds
		   ,c1.value('@EstimateRewinds','nvarchar(50)') EstimateRewinds
		   ,c1.value('@TableCardinality','nvarchar(50)') TableCardinality
		   FROM #T1 A 
		   JOIN DBMON.dbo.DB_MON_QUERY_PLAN_V3 QP 
			ON A.plan_handle = QP.plan_handle AND A.statement_start = QP.statement_start AND A.statement_END = QP.statement_END AND A.CREATE_DATE = QP.create_date 
		  CROSS APPLY qp.query_plan.nodes('//RelOp') as r(c1) 
		  CROSS APPLY c1.nodes('Update/Object') as o(c2)  
		 where db_name = @db_name and object_name = @sp_name
)
SELECT	 
		 db_name
		,object_name
		,line_start
		,line_end
		,table_name
		,index_name
		,PhysicalOp
		,LogicalOp
		,NodeId
		,EstimateRows
		,SUBSTRING(st.value('@StatementText','nvarchar(max)'), statement_start/2, case when statement_end > 0 
					then (statement_end - statement_start)/2 
					else (len(st.value('@StatementText','nvarchar(max)')) - statement_end)/2 end )  string
		,query_cost
		,warnings
--		,reg_date
--		,upd_date
--	    ,case when @plan = 0 then null else query_plan		 end query_plan
 FROM INDEXSEARCH
 CROSS APPLY query_plan.nodes('//StmtSimple') as s(st) 
WHERE @table_name = case when @table_name = '' then @table_name ELSE table_name end
  AND @index_name = case when @index_name = '' then @index_name ELSE index_name end
go
/*************************************************************************  
* 프로시저명  : dbo.up_mon_sp_text
* 작성정보    : 2014-04-01 by sewkim
* 관련페이지  :  
* 내용        : SP index 사용현황
* 수정정보    : 'TIGER','up_sttl_vaccount_confirm_not_single_running'
* select plan_handle, count(*) from sys.dm_exec_query_stats group by plan_handle
* select * from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
* select db_name(database_id), object_name(object_id,database_id) from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
*************************************************************************/
CREATE proc up_mon_sp_text 
	@db_name sysname, 
	@sp_name sysname
as
declare @db_id int, @object_id int
declare @param nvarchar(100)  = N'@object_id int OUTPUT'
declare @query nvarchar(500)
declare @sql_handle varbinary(64)

set @db_id = db_id(@db_name);
set @query =N'select @object_id = object_id from ' + @db_name + '.sys.objects where name = ''' + @sp_name + ''''

execute sp_executesql @query, @param, @object_id = @object_id OUTPUT;

if @object_id is null 
  begin 
    select 'object not founded' 	
	return 
  end

select @sql_handle = sql_handle  from sys.dm_exec_procedure_stats  a where a.database_id = @db_id and a.object_id = @object_id;
if @sql_handle is null 
  begin 
    select 'sql_handle not founded'; 	
	return 
  end;

	select   @sp_name sp_name, statement_start_offset,statement_end_offset
			,case when statement_start_offset > 0 then dbo.fn_getCountReturn(text, statement_start_offset) else -1 end as line_start
			,case when statement_end_offset > 0 then dbo.fn_getCountReturn(text, statement_end_offset) else -1 end as line_end   
			,plan_generation_num
			,total_worker_time / (datediff(minute,creation_time,getdate())) / 60 min_worker_time 
			,total_worker_time / execution_count unit_worker_time 
			,execution_count 
			,total_worker_time 
			,total_physical_reads
			,total_logical_writes
			,total_logical_reads
			,total_clr_time
			,total_elapsed_time
			,REPLACE(REPLACE(REPLACE(SUBSTRING(TEXT, statement_start_offset/2, 
			case when statement_end_offset > 0 then (statement_end_offset - statement_start_offset)/2 else (len(TEXT) - statement_end_offset)/2 end ),CHAR(13), ' '),CHAR(10), ' '),CHAR(09), ' ')  string
	  from 
			(
				select text from sys.dm_exec_procedure_stats M
				   cross apply sys.dm_exec_sql_text (sql_handle) as T
						 where sql_handle =  @sql_handle
			) A
	 left join sys.dm_exec_query_stats B on B.sql_handle = @sql_handle
	 order by statement_start_offset
go
/*************************************************************************  
* 프로시저명  : dbo.up_mon_sp_text
* 작성정보    : 2014-04-01 by sewkim
* 관련페이지  :  
* 내용        : SP index 사용현황
* 수정정보    : 'TIGER','up_sttl_vaccount_confirm_not_single_running'
* select plan_handle, count(*) from sys.dm_exec_query_stats group by plan_handle
* select * from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
* select db_name(database_id), object_name(object_id,database_id) from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
*************************************************************************/
CREATE proc up_mon_sp_text2 
	@db_name sysname, 
	@sp_name sysname
as
declare @db_id int, @object_id int
declare @param nvarchar(100)  = N'@object_id int OUTPUT'
declare @query nvarchar(500)
declare @sql_handle varbinary(64)

set @db_id = db_id(@db_name);
set @query =N'select @object_id = object_id from ' + @db_name + '.sys.objects where name = ''' + @sp_name + ''''

execute sp_executesql @query, @param, @object_id = @object_id OUTPUT;

if @object_id is null 
  begin 
    select 'object not founded' 	
	return 
  end

select @sql_handle = sql_handle  from sys.dm_exec_procedure_stats  a where a.database_id = @db_id and a.object_id = @object_id;
if @sql_handle is null 
  begin 
    select 'sql_handle not founded'; 	
	return 
  end;

	select   @sp_name sp_name, statement_start_offset,statement_end_offset
			,case when statement_start_offset > 0 then dbo.fn_getCountReturn(text, statement_start_offset) else -1 end as line_start
			,case when statement_end_offset > 0 then dbo.fn_getCountReturn(text, statement_end_offset) else -1 end as line_end   
			,REPLACE(REPLACE(REPLACE(REPLACE(SUBSTRING(TEXT, statement_start_offset/2, 
			case when statement_end_offset > 0 then (statement_end_offset - statement_start_offset)/2 
				else (len(TEXT) - statement_end_offset)/2 end ),CHAR(13), ' '),CHAR(10), ' '),CHAR(09), ' '), '  ',' ')  string
	  from 
			(
				select top 1 text,sql_handle from sys.dm_exec_procedure_stats M
				   cross apply sys.dm_exec_sql_text (sql_handle) as T
						 where sql_handle =  @sql_handle
			) A
	 join sys.dm_exec_query_stats B on A.sql_handle = B.sql_handle
	 order by statement_start_offset

go

/*************************************************************************  
* 프로시저명  : dbo.up_mon_sp_index_usage_light
* 작성정보    : 2014-04-01 by sewkim
* 관련페이지  :  
* 내용        : SP index 사용현황
* 수정정보    : 'TIGER','up_sttl_vaccount_confirm_not_single_running'
* select plan_handle, count(*) from sys.dm_exec_query_stats group by plan_handle
* select * from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
* select db_name(database_id), object_name(object_id,database_id) from sys.dm_exec_procedure_stats where plan_handle = 0x05000C006A16396340C16E257F0100000000000000000000
*************************************************************************/
CREATE proc up_mon_sp_index_usage_light
	@db_name sysname, 
	@sp_name sysname,
	@plan tinyint = 0, 
	@text tinyint = 0, 
    @table_name sysname = '',
    @index_name sysname = '',
    @save tinyint = 0
as

set nocount on 

declare @db_id int, @object_id int
declare @param nvarchar(100)  = N'@object_id int OUTPUT'
declare @query nvarchar(500)
declare @sql_handle varbinary(64)
declare @id int, @maxid int

if not @table_name = ''
	SET @table_name=QUOTENAME(@table_name,'[');

if not @index_name = ''
	SET @index_name=QUOTENAME(@index_name,'[');

set @db_id = db_id(@db_name);
set @query =N'select @object_id = object_id from ' + @db_name + '.sys.objects where name = ''' + @sp_name + ''''

execute sp_executesql @query, @param, @object_id = @object_id OUTPUT;

if @object_id is null 
  begin 
    select 'object not founded' 	
	return 
  end

select @sql_handle = sql_handle  from sys.dm_exec_procedure_stats  a where a.database_id = @db_id and a.object_id = @object_id;
if @sql_handle is null 
  begin 
    select 'sql_handle not founded'; 	
	return 
  end;
    
  CREATE TABLE #T1 
  ( 
	 id						int identity
	,query_plan				xml	
	,plan_handle			varbinary(64)
	,statement_start_offset	int
	,statement_end_offset	int
	,dbid					smallint
	,objectid				int
	,creation_time			datetime
	,last_execution_time	datetime
	,execution_count		bigint
	,total_worker_time		bigint
	,total_physical_reads	bigint
	,total_logical_writes	bigint
	,total_logical_reads	bigint
	,total_clr_time			bigint
	,total_elapsed_time		bigint
  )
  
  CREATE TABLE #T2
  (
	 id int identity
	,gn			char(1)
	,dbname		varchar(256) null
	,objectname	varchar(256) null
	,statement_start_offset	int
	,statement_end_offset	int
	,LINE_START	int null
	,LINE_END	int null
	,DATABASE_NAME	sysname null
	,SCHEMA_NAME	sysname null
	,TABLE_NAME		sysname null
	,INDEX_NAME		sysname null
	,INDEX_KIND		sysname null
	,NodeId			int null
	,PhysicalOp		varchar(100) null
	,LogicalOp		varchar(100) null
	,EstimateRows	nvarchar(100) null
	,creation_time	datetime null
	,last_execution_time	datetime null
	,min_worker_time		bigint null
	,unit_worker_time		bigint null
	,execution_count		bigint null
	,total_worker_time		bigint null
	,total_physical_reads	bigint null
	,total_logical_writes	bigint null
	,total_logical_reads	bigint null
	,total_clr_time			bigint null
	,total_elapsed_time		bigint null
	,EstimateIO				varchar(100) null
	,EstimateCPU			varchar(100) null
	,AvgRowSize				varchar(100) null
	,EstimatedTotalSubtreeCost	varchar(100) null
	,Parallel				varchar(100) null
	,EstimateRebinds		varchar(100) null
	,EstimateRewinds		varchar(100) null
	,TableCardinality		varchar(100) null
	,query_stats_plan		xml  null
	,string					varchar(max)  null
  )

set @id = 1

insert #t1
select  convert(xml,a.query_plan) query_plan
		,plan_handle
		,statement_start_offset
		,statement_end_offset
		,a.dbid
		,a.objectid
		,M.creation_time	
		,M.last_execution_time
		,M.execution_count	
		,M.total_worker_time
		,M.total_physical_reads	
		,M.total_logical_writes	
		,M.total_logical_reads	
		,M.total_clr_time	
		,M.total_elapsed_time
	from sys.dm_exec_query_stats M
	outer apply sys.dm_exec_text_query_plan (plan_handle,statement_start_offset,statement_end_offset) A
	outer apply sys.dm_exec_query_plan (plan_handle) B 
	where sql_handle = @sql_handle;

set @maxid = @@identity;

WHILE (@id <= @maxid)	   
BEGIN
	WITH XMLNAMESPACES(DEFAULT 
			'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
			INDEXSEARCH
	AS (
			select * from #t1 where id = @id 
	)
	INSERT #T2
	SELECT 
			 '1' gn
			,db_name(IXS.dbid) dbname
			,object_name(IXS.objectid,IXS.dbid) objectname
			,statement_start_offset
			,statement_end_offset

			,F.LINE_START
			,F.LINE_END 

			,c2.value('@Database','sysname') AS DATABASE_NAME
			,c2.value('@Schema','sysname') AS SCHEMA_NAME
			,c2.value('@Table','sysname') AS TABLE_NAME
			,c2.value('@Index','sysname') AS INDEX_NAME
			,c2.value('@IndexKind','sysname') AS INDEX_KIND

			,c1.value('@NodeId','int')  NodeId
			,c1.value('@PhysicalOp','nvarchar(50)')  PhysicalOp 
			,c1.value('@LogicalOp','nvarchar(50)')  LogicalOp
			,c1.value('@EstimateRows', 'nvarchar(50)') EstimateRows

			,IXS.creation_time	
			,IXS.last_execution_time

			,IXS.total_worker_time / (datediff(minute,IXS.creation_time,getdate()) + 1)  hour_worker_time 
			,IXS.total_worker_time / IXS.execution_count unit_worker_time 

			,IXS.execution_count	
			,IXS.total_worker_time
			,IXS.total_physical_reads	
			,IXS.total_logical_writes	
			,IXS.total_logical_reads	
			,IXS.total_clr_time	
			,IXS.total_elapsed_time

			,c1.value('@EstimateIO', 'nvarchar(50)') EstimateIO      
			,c1.value('@EstimateCPU', 'nvarchar(50)') EstimateCPU
			,c1.value('@AvgRowSize', 'nvarchar(50)') AvgRowSize
			,c1.value('@EstimatedTotalSubtreeCost', 'nvarchar(50)')  EstimatedTotalSubtreeCost
			,c1.value('@Parallel','nvarchar(50)') Parallel
			,c1.value('@EstimateRebinds','nvarchar(50)') EstimateRebinds
			,c1.value('@EstimateRewinds','nvarchar(50)') EstimateRewinds
			,c1.value('@TableCardinality','nvarchar(50)') TableCardinality

			,case when @plan = 0 then null else IXS.query_plan		 end query_stats_plan
			,case when @text = 0 then '' else 
			 REPLACE(REPLACE(REPLACE(SUBSTRING(TEXT, statement_start_offset/2, case when statement_end_offset > 0 then (statement_end_offset - statement_start_offset)/2 
			 else (len(TEXT) - statement_end_offset)/2 end ),CHAR(13), ' '),CHAR(10), ' '),CHAR(09), ' ') end string
	FROM INDEXSEARCH IXS
	OUTER APPLY DBMON.DBO.FN_GETOBJECTLINE(plan_handle, statement_start_offset, statement_end_offset) F  
	OUTER APPLY sys.dm_exec_sql_text(plan_handle)
	CROSS APPLY query_plan.nodes('//RelOp') as r(c1)
	CROSS APPLY c1.nodes('IndexScan/Object') as o(c2)
	WHERE @table_name = case when @table_name = '' then @table_name ELSE c2.value('@Table','sysname') end
	  AND @index_name = case when @index_name = '' then @index_name ELSE c2.value('@Index','sysname') end;
	
	set @id = @id + 1; 
 
END

if (@save = 1)
	INSERT DB_MON_SP_INDEX_USAGE SELECT * FROM #t2 order by id;
else
	SELECT * FROM #t2 order by id;
go