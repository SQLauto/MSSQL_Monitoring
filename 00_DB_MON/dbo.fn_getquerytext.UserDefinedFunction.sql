USE [DBMON]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_getquerytext]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* version : 2010-08-25 10:41 */
CREATE FUNCTION [dbo].[fn_getquerytext](@plan_handle varbinary(64), @start int, @end int)
RETURNS varchar(max)
BEGIN
	declare @str varchar(max)
	
	select @str =  isnull(substring(text,@start / 2 + 1,                            
     (case when @end = -1 then len(convert(nvarchar(max), text)) * 2 else @end end - @start) / 2), '')  
	from sys.dm_exec_sql_text(@plan_handle)

	return  @str
	
END	

GO
