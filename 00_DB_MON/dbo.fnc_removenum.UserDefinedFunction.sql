USE [DBMON]
GO
/****** Object:  UserDefinedFunction [dbo].[fnc_removenum]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnc_removenum] (@str varchar(50))  
RETURNS varchar(50)  
AS  
BEGIN  
 DECLARE @seq int  
  
 SET @seq = 0  
  
 SET @str = REPLACE(@str, ' ', '')  
  
 WHILE @seq <= 9  
 BEGIN  
  
  SET @str = REPLACE(@str, convert(char(1), @seq), '')  
  
  SET @seq = @seq + 1  
  
 END  
  
 RETURN @str  
END  

GO
