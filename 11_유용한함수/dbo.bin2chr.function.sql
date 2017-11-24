/****** ??:  UserDefinedFunction [dbo].[bin2chr]    ???? ??: 06/21/2007 15:33:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function bin2chr(@bin VARCHAR(35))
returns varchar(600)
as
begin
    declare @LEN INT, @RET VARCHAR(600), @INC INT, @TMPCHR VARCHAR(10)
	SET @LEN = LEN(@BIN)
    SET @INC = 1
    SET @RET = ''
    while @LEN >= @INC
    begin
     SET @TMPCHR = SUBSTRING(@BIN,@INC,1)
     IF @TMPCHR = '1'
	 BEGIN
      SET @RET = @RET + CONVERT(VARCHAR,@LEN-@INC) + ', '
     END

	 SET @INC = @INC + 1
    end    

    return @ret
end

GO
