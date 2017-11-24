/*==============================================================
����	: ���� Ʈ���̽������� ���̺�� ��ȯ
�ۼ���	: ����ȯ
�ۼ���	: 2004.08.06.
����	: EXEC dbo.up_ReadTrace N'TB_FMTrace', 'C:\TEMP\Trace\Trace.trc'
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