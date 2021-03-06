USE [DBMON]
GO
/****** Object:  UserDefinedFunction [dbo].[fnc_getresourcehobt]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnc_getresourcehobt](@str nvarchar(1024))
RETURNS TABLE 
AS
RETURN (
select case when charindex('associatedObjectId=', @str) = 0 then CONVERT(bigint, -1)
			else  substring(@str, charindex('associatedObjectId=', @str) + LEN('associatedObjectId='), 
				case when charindex(' ', @str, charindex('associatedObjectId=', @str)+ 1) > 0 
					 then charindex(' ', @str, charindex('associatedObjectId=', @str)+ 1) - charindex('associatedObjectId=', @str) - LEN('associatedObjectId=') else LEN(@str) end ) end as hobt_id,
case when charindex('dbid=', @str) = 0 then CONVERT(int, -1)
			else  substring(@str, charindex('dbid=', @str) + LEN('dbid='), 
				case when charindex(' ', @str, charindex('dbid=', @str)+ 1) > 0 
					 then charindex(' ', @str, charindex('dbid=', @str)+ 1) - charindex('dbid=', @str) - LEN('dbid=') else LEN(@str) end ) end as db_id
)
GO
