/****** ??:  UserDefinedFunction [dbo].[fn_getSPName]    ???? ??: 06/21/2007 15:33:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function dbo.fn_getSPName(@sql varchar(3000))
returns varchar(100)
as 
begin
	declare @charindex smallint, @sp_name varchar(100)
	select @charindex = charindex(' ', @sql)
	if @charindex = 0 
		set @sp_name = @sql
	else
		select @sp_name = substring(@sql, 1, @charindex)
	return (@sp_name)
end

GO
