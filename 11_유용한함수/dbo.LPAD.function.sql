/****** ??:  UserDefinedFunction [dbo].[LPAD]    ???? ??: 06/21/2007 15:33:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION LPAD(@S VARCHAR(255), @N INT, @P VARCHAR(255) )
RETURNS VARCHAR(255)
AS 
BEGIN
RETURN ISNULL(REPLICATE(@P, @N-LEN(@S)), '') +@S
END 

GO
