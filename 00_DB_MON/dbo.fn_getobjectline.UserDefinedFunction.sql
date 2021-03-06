USE [DBMON]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_getobjectline]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* version : 2010-08-25 10:13 */
CREATE FUNCTION [dbo].[fn_getobjectline](@plan_handle varbinary(64), @start int, @end int)  
RETURNS TABLE  
AS  
RETURN (  
 select dbo.fn_getCountReturn(text, @start) as line_start,  
  case when @end > 0 then dbo.fn_getCountReturn(text, @end) else -1 end as line_end  
 from sys.dm_exec_sql_text(@plan_handle) qt  
)  

GO
