USE [DBMON]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_hexadecimal]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fn_hexadecimal] ( @binvalue varbinary(255) )
returns varchar(255)
as
begin
      declare @charvalue varchar(255)
      declare @i int
      declare @length int
      declare @hexstring char(16)
      select @charvalue = '0x'
      select @i = 1
      select @length = datalength(@binvalue)
      select @hexstring = '0123456789abcdef'
      while (@i <= @length)
      begin
            declare @tempint int
            declare @firstint int
            declare @secondint int
            select @tempint = convert(int, substring(@binvalue,@i,1))
            select @firstint = floor(@tempint/16)
            select @secondint = @tempint - (@firstint*16)
            select @charvalue = @charvalue +
            substring(@hexstring, @firstint+1, 1) +
            substring(@hexstring, @secondint+1, 1)
            select @i = @i + 1
      end
return ( @charvalue )
end

GO
