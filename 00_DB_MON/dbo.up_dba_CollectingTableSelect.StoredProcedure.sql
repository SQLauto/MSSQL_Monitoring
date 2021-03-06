USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_dba_CollectingTableSelect]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[up_dba_CollectingTableSelect]
	@server_id		int
	,@instance_id	int
	,@up_dt				datetime
	,@reg_dt			datetime
	,@table_name	varchar(100)	
AS    
SET NOCOUNT ON

DECLARE @date DATETIME
DECLARE @stmt NVARCHAR(4000)
DECLARE @param NVARCHAR(200)

SET @date = CONVERT(VARCHAR(10),GETDATE(),120)
SET @date = DATEADD(hh, DATEPART(hh, GETDATE()), @date)

IF @@ERROR = 0
BEGIN	
	SET @param = N'@reg_date datetime, @up_date datetime'
	SET @stmt = N'SELECT ' + CONVERT(VARCHAR,@server_id) + ' AS server_id, ' + CONVERT(VARCHAR,@instance_id) + ' AS instance_id,  * FROM ' + @table_name + ' WHERE reg_date between @up_date AND @reg_date'		
	EXEC sp_executesql @stmt, @param, @up_date = @up_dt, @reg_date = @reg_dt
END

GO
