USE [DBMON]
GO
/****** Object:  UserDefinedFunction [dbo].[fnc_hexa2decimal]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/********************************************************  
 *** 함 수 명 : fnc_hexa2decimal  
 *** 목    적 : binary type 의 값을 char 형으로 변환  
 *** 예    제 : SELECT dbo.fnc_hexa2decimal(0x092012304abc)  
********************************************************/  
CREATE FUNCTION [dbo].[fnc_hexa2decimal] (@binary varbinary(256))  
RETURNS varchar(256)  
AS  
BEGIN  
 DECLARE @LEN INT, @SEQ INT  
 DECLARE @CHAR VARCHAR(256)  
 DECLARE @HEXSTRING CHAR(16)  
 SET @HEXSTRING = '0123456789ABCDEF'    
 SET @CHAR = '0x'  
 SET @LEN = DATALENGTH(@binary)  
 SET @SEQ = 1   
  
 WHILE @SEQ <= @LEN  
 BEGIN  
 DECLARE @tmp INT, @first int, @second int  
   
 SET @tmp = CONVERT(int, SUBSTRING(@binary, @SEQ, 1))  
 SET @first = FLOOR(@tmp / 16)  
 SET @second = @tmp - (@first * 16)  
 SET @CHAR = @CHAR + SUBSTRING(@HEXSTRING, @first + 1, 1) + SUBSTRING(@HEXSTRING, @second + 1, 1)  
 SET @SEQ = @SEQ + 1  
 END  
 RETURN @CHAR  
END
GO
