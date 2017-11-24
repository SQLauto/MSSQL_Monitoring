/****** ??:  UserDefinedFunction [dbo].[dec2bin]    ???? ??: 06/21/2007 15:33:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function dec2bin(@dec int)
returns varchar(31)
as
begin
    declare @ret  varchar(31),@div2  int,@mod2  int
    if @dec < 0
       set @dec = @dec & 2147483647

    select @div2 = @dec / 2,@mod2 = @dec % 2,@ret = ''
    while @div2 <> 0
    begin
        select @ret =  convert(char(1),@mod2) + @ret,
                   @dec = @dec / 2,
                   @div2 = @dec / 2,
                   @mod2 = @dec % 2
    end    
    set @ret =  right(replicate('0',31) + convert(char(1),@mod2) + @ret,31)
    return @ret
end



GO
