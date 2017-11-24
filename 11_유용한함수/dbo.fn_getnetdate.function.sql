/****** ??:  UserDefinedFunction [dbo].[fn_getnetdate]    ???? ??: 06/21/2007 15:33:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function dbo.fn_getnetdate (@date1 datetime, @date2 datetime )
returns int 
as 
begin

---- @date1? ? ? ????. @date
	declare 	@cnt	int,
		@cur_date	datetime
	set @cnt = 0
	set @cur_date  = @date2

	while (@cur_date <= @date1)

	begin

		if datepart(dw, @cur_date ) >=2 and  datepart(dw, @cur_date ) <= 6  
			set @cnt = @cnt  + 1


		set @cur_date = @cur_date + 1		
	end

	return (@cnt-1)


end


GO
