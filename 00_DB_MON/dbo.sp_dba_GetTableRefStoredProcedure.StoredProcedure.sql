USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[sp_dba_GetTableRefStoredProcedure]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_dba_GetTableRefStoredProcedure]        
@Tablename VARCHAR(256)        
AS        

set nocount on

CREATE TABLE #T1
(
id int identity,
dbname	varchar(256),
objtype	varchar(256),
objname	varchar(256),
)    

insert #T1 (dbname,objtype,objname)
SELECT DISTINCT DB_NAME(), 
       CASE TYPE WHEN 'P'  THEN 'Procedure' 
                 WHEN 'TR' THEN 'Trigger' 
                 WHEN 'FN' THEN 'Function' 
                 WHEN 'V'  THEN 'View' 
                 ELSE TYPE 
       END Class, 
       b.name  name         
  FROM SYS.SYSCOMMENTS A        
  LEFT JOIN SYS.SYSOBJECTS B ON A.ID = B.ID        
 WHERE TEXT LIKE '%' + @Tablename + '%'        
ORDER BY         
	CASE TYPE 
		WHEN 'P'  THEN 'Procedure' 
		WHEN 'TR' THEN 'Trigger' 
		WHEN 'FN' THEN 'Function' 
		WHEN 'V'  THEN 'View' 
		ELSE TYPE 
	END,         
	NAME 

IF NOT DB_NAME() LIKE 'dba%'
BEGIN
	declare @text varchar(1000), @sql varchar(1000), @dbname VARCHAR(20)
	set @text =  'insert #T1 (dbname,objtype,objname)
				  SELECT DISTINCT ''[@1]'', 
				   CASE TYPE WHEN ''P''  THEN ''Procedure'' 
							 WHEN ''TR'' THEN ''Trigger'' 
							 WHEN ''FN'' THEN ''Function'' 
							 WHEN ''V''  THEN ''View'' 
							 ELSE TYPE 
				   END Class, 
				   b.name  name         
			  FROM [@1].SYS.SYSCOMMENTS A        
			  LEFT JOIN [@1].SYS.SYSOBJECTS B ON A.ID = B.ID        
			 WHERE TEXT LIKE ''%' + db_name() + '.dbo.' + @Tablename + '%''        
 			 ORDER BY         
				CASE TYPE 
					WHEN ''P''  THEN ''Procedure'' 
					WHEN ''TR'' THEN ''Trigger'' 
					WHEN ''FN'' THEN ''Function'' 
					WHEN ''V''  THEN ''View'' 
					ELSE TYPE 
				END,         
				NAME'
	 
	declare db_cursor cursor        
	 for         
	 select name         
	 from sys.sysdatabases 
	 where dbid <> db_id() and dbid > 4
	        
	        
	open db_cursor        
	fetch next from db_cursor into @dbname  

	while @@fetch_STATUS = 0        
	begin        
	 set @sql = replace(@text,'[@1]',@dbname)
	 exec(@sql)         
	 fetch next from db_cursor into @dbname         
	end       
	close db_cursor        
	deallocate db_cursor
END
select dbname,objtype,objname from #T1 order by id






GO
