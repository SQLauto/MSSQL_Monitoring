/*==============================================================
목적	: 로컬 트레이싱파일을 테이블로 전환
작성자	: 김준환
작성일	: 2004.08.06.
사용법	: EXEC dbo.up_ReadTrace N'TB_FMTrace', 'C:\TEMP\Trace\Trace.trc'
==============================================================*/
CREATE PROCEDURE [dbo].[up_ReadTrace](
					@p_TraceTableName	NVARCHAR(255),
					@p_TraceFile		NVARCHAR(255)
					)
AS

	DECLARE @v_SQL NVARCHAR(2000)
	
	SET @v_SQL = 
		'SELECT	Identity(int,1,1) as RowNum, * ' +
		'INTO	' + @p_TraceTableName + ' ' +
		'FROM	::fn_trace_gettable(''' + @p_TraceFile + ''', default)'
	PRINT @v_SQL
	
	EXEC dbo.sp_executesql @v_SQL
	
	SET @v_SQL = 
		'Create index ix_rownumber on ' + @p_TraceTableName + '(RowNum)'
	EXEC dbo.sp_executesql @v_SQL

	SET @v_SQL = 
		'create index ix_spid on ' + @p_TraceTableName + '(spid)'
	EXEC dbo.sp_executesql @v_SQL

	SET @v_SQL = 
		'create index ix_duration_cpu on ' + @p_TraceTableName + '(duration, cpu)'
	EXEC dbo.sp_executesql @v_SQL
	
	SET @v_SQL = 
		'create index ix_eventclass on ' + @p_TraceTableName + '(eventclass)'
	EXEC dbo.sp_executesql @v_SQL
	
RETURN