/****** ??:  UserDefinedFunction [dbo].[fn_getSPNameIgnoreOwner]    ???? ??: 06/21/2007 15:33:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function dbo.fn_getSPNameIgnoreOwner(@sql varchar(3000))
returns varchar(100)
as 
begin
	declare @pos_space smallint, @pos_comma smallint, @sp_name varchar(100)
	select @pos_comma = charindex('.', @sql), @pos_space = charindex(' ', @sql)

	-- Parameter? ?? ??
	if @pos_space = 0 begin
		-- ???? ???? ?? ??
		if (@pos_comma > 0)
			set @sp_name = substring(@sql, @pos_comma +1, len(@sql) - @pos_comma)
		else
			set @sp_name = @sql
	end else
	begin
		if (@pos_comma > 0 and @pos_comma < @pos_space)
			set @sp_name = substring(@sql, @pos_comma +1, @pos_space - @pos_comma)
		else
			set @sp_name = substring(@sql, 1, @pos_space)
	end

	return (@sp_name)
end


GO
