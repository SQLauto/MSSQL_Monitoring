-- ============================================================
-- 4. 2000 Master 单捞磐海捞胶 function 积己
-- 
-- =============================================================
create function dbo.uf_getSize(@size varchar(100))
returns varchar(100)
as 
begin
	declare @charindex int, @sp_name varchar(100)
	select @charindex = charindex('.', @size)
	if @charindex = 0 
		set @sp_name = @size
	else
		select @sp_name = substring(@size, 1, @charindex-1)
	return (@sp_name)
end