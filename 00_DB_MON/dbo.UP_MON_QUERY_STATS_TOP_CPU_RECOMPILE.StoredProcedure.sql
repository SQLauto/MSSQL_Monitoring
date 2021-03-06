USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[UP_MON_QUERY_STATS_TOP_CPU_RECOMPILE]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*************************************************************************  
* 프로시저명  : dbo.UP_MON_QUERY_STATS_TOP_CPU_RECOMPILE 
* 작성정보    : 2014-04-26 by sanoh
* 관련페이지  :  
* 내용        : CPU 높은 SP recompile PM종료이후
* 수정정보    :
**************************************************************************/

CREATE PROCEDURE [dbo].[UP_MON_QUERY_STATS_TOP_CPU_RECOMPILE] 
@rowcount INT = 10
AS
SET NOCOUNT ON

DECLARE @date DATETIME
DECLARE @hh INT

SELECT @hh = datepart(hour, getdate())

----오전 8시에만  실행가능
--if @hh <> 8
--begin
--                        RAISERROR('오전 8시에만 실행가능합니다.', 16, 1)
--                        return
--end
SELECT @date = dateadd(hour, 8, convert(CHAR(10), getdate(), 121)) -- 해당일 08시 셋팅

SELECT TOP 1 @date = reg_date
FROM db_mon_query_stats_v2(NOLOCK)
WHERE reg_date <= @date
ORDER BY reg_date DESC

--select @date
--truncate table dbo.db_mon_query_stats_top_cpu_rank
INSERT INTO dbo.db_mon_query_stats_top_cpu_rank (
	cpu_rank
	,db_name
	,object_name
	,to_date
	,term
	,set_options
	,line_start
	,line_end
	,cnt_min
	,cpu_rate
	,cpu_min
	,reads_min
	,duration_min
	,cpu_cnt
	,reads_cnt
	,duration_cnt
	,statement_start
	,statement_end
	,create_date
	,query_plan
	)
SELECT TOP (@rowcount) row_number() OVER ( ORDER BY s.cpu_min DESC) AS cpu_rank
	,s.db_name
	,s.object_name
	,s.reg_date AS to_date
	,s.term
	,s.set_options
	,p.line_start
	,p.line_end
	,s.cnt_min
	,s.cpu_rate
	,s.cpu_min
	,s.reads_min
	,s.duration_min
	,s.cpu_cnt
	,s.reads_cnt
	,s.duration_cnt
	,s.statement_start
	,s.statement_end
	,s.create_date
	,p.query_plan
FROM dbo.db_mon_query_stats_v2 s(NOLOCK)
LEFT JOIN dbo.db_mon_query_plan_v2 p(NOLOCK) ON s.plan_handle = p.plan_handle
	AND s.statement_start = p.statement_start
	AND s.statement_end = p.statement_end
	AND s.create_date = p.create_date
WHERE s.reg_date = @date
ORDER BY s.reg_date DESC
	,s.cpu_min DESC

DECLARE @rank INT = 1
DECLARE @db_name VARCHAR(32) = ''
DECLARE @object_name VARCHAR(255) = ''
DECLARE @cmdstring VARCHAR(300) = ''

WHILE (@rank <= @rowcount)
BEGIN
	SELECT @db_name = db_name
		,@object_name = object_name
	FROM dbo.db_mon_query_stats_top_cpu_rank WITH (NOLOCK)
	WHERE to_date = @date
		AND cpu_rank = @rank

	SET @cmdstring = 'USE ' + @db_name + ' EXEC SP_RECOMPILE ' + @object_name

	--print @cmdstring
	EXECUTE (@cmdstring)

	SET @rank = @rank + 1
END



/*=============================================================
USE [DBMON]
GO
CREATE TABLE [dbo].[db_mon_query_stats_top_cpu_rank](
	[cpu_rank] [bigint] NULL,
	[db_name] [varchar](32) COLLATE Korean_Wansung_CI_AS NOT NULL,
	[object_name] [varchar](255) COLLATE Korean_Wansung_CI_AS NOT NULL,
	[to_date] [datetime] NOT NULL,
	[term] [bigint] NULL,
	[set_options] [int] NULL,
	[line_start] [int] NULL,
	[line_end] [int] NULL,
	[cnt_min] [bigint] NULL,
	[cpu_rate] [numeric](6, 2) NULL,
	[cpu_min] [bigint] NULL,
	[reads_min] [bigint] NULL,
	[duration_min] [bigint] NULL,
	[cpu_cnt] [bigint] NULL,
	[reads_cnt] [bigint] NULL,
	[duration_cnt] [bigint] NULL,
	[statement_start] [int] NOT NULL,
	[statement_end] [int] NOT NULL,
	[create_date] [datetime] NULL,
	[query_plan] [xml] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
WITH(DATA_COMPRESSION=PAGE)
=============================================================*/

GO
