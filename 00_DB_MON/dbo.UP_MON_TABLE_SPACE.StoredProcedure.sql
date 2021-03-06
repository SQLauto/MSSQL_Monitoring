USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[UP_MON_TABLE_SPACE]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UP_MON_TABLE_SPACE]
AS
SET NOCOUNT ON  
DECLARE @db sysname 
DECLARE DBCursor CURSOR FOR  
    SELECT name db
      FROM sys.databases WITH (NOLOCK) 
     WHERE database_id > 4 
     ORDER BY name
 
OPEN DBCursor;  
FETCH DBCursor into @db;  
   
WHILE @@FETCH_STATUS = 0 
	BEGIN 
		EXEC  dba_SpaceUsed_write @DB;
		FETCH DBCursor into @db;    
	END
CLOSE DBCursor;  
DEALLOCATE DBCursor;  


GO
