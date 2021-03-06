-- ============================================================
-- 4. 2000 Master 데이터베이스 function 생성
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