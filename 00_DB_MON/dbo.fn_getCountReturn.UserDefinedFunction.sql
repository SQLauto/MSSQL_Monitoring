USE [DBMON]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_getCountReturn]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* version : 2010-08-25 09:30 */
CREATE FUNCTION [dbo].[fn_getCountReturn](@text varchar(max), @end_pos int)  
RETURNS int  
BEGIN  
 declare @position int, @position_sum int, @count int  
   
 select @position = 1, @position_sum = 0, @count = 0  
   
 if @end_pos = -1 return -1  
   
 set @text = substring(@text, 1, @end_pos / 2)  
   
 while @position > 0  
 begin  
  select @position = charindex(char(13) + char(10), substring(@text, @position_sum + 2, datalength(@text)))  
    
  set @count = @count + 1  
  set @position_sum = @position_sum + @position   
    
 end  
    
 return @count  
  
END

GO
