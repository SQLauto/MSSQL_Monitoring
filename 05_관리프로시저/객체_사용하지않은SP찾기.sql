use dba
go


-- Error 목록
CREATE TABLE DBA_SP_REFERENCED_ERROR 
(	seqno  int identity(1,1) not null , 
	reg_date datetime  null ,
	db_name sysname null, 
	sp_id int null ,
	schema_name sysname null ,
	sp_name sysname null , 
	ref_server_name sysname null,
	ref_db_name sysname null ,
	ref_schema_name sysname null ,
	ref_table_name sysname null,
	error_no int null )
go

CREATE CLUSTERED INDEX CIDX__DBA_SP_REFERENCED_ERROR__DB_NAME ON DBA_SP_REFERENCED_ERROR 
( DB_NAME)
go




-- 찾을 SP명
CREATE TABLE DBA_SP_REFERENCED_LIST 
(	
    seqno  int identity(1,1) not null , 
	db_name sysname, 
	object_id int,
	object_name sysname
)
go


SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO


/*************************************************************************  
* 프로시저명  : dbo.up_dba_sp_referenced_error
* 작성정보    : 2011-05-26 by choi bo ra
* 관련페이지  : 
* 내용        : 테이블이나 객체에 없는 SP 찾기.
* 수정정보    : exec up_dba_sp_referenced_error 'DBA', null
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_sp_referenced_error
    @db_name    sysname = null,
    @type    nvarchar(20) = null
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

DECLARE @SQL nvarchar(2000)
DECLARE @SQL1 nvarchar(2000)
DECLARE @dbname sysname, @spname sysname,  @dbid int , @count  int
DECLARE @schema_name sysname, @error_no int, @object_id int, @seqno int
DECLARE @parmdefinition nvarchar(500)
DECLARE @ref_server_name sysname, @ref_db_name sysname, @ref_schema_name sysname, @ref_table_name sysname
SET @count = 0



/* BODY */
IF @db_name is null 
BEGIN
    TRUNCATE TABLE dbo.DBA_SP_REFERENCED_ERROR
END
ELSE 
BEGIN
    DELETE dbo.DBA_SP_REFERENCED_ERROR WHERE db_name = @db_name
END

DECLARE dbname_cursor CURSOR FOR 
    SELECT name, convert(nvarchar(50),dbid) as dbid 
    FROM master..sysdatabases with (nolock)     
    WHERE name not in 
        ('northwind', 'pubs', 'LiteSpeedCentral', 'LiteSpeedLocal', 'credit2')
        and DATABASEPROPERTYEX(name,'status')='ONLINE'
     AND  name  = case when @db_name is null  then name else @db_name end
             
OPEN dbname_cursor       
FETCH next FROM dbname_cursor into @dbname  , @dbid
WHILE @@fetch_status = 0       
BEGIN 

	IF @type  = 'A'
	begin   
    
		SET @SQL = 'select identity(int,1, 1) as seqno,name , object_schema_name(object_id, ' + convert(nvarchar(10), @dbid) + ') as schema_name, object_id' + char(10)
					+ ' into #SP_LIST from  ' + @dbname +'.sys.procedures with (nolock) ' + char(10)
				 --   + ' where name like  case when ' + @spname + ' is ''''  then name else + ' @spname + ' end'
	    
		EXEC sp_executesql @SQL
		
   end
   else
   begin
   
		SELECT identity(int,1, 1) as seqno ,object_name as name, object_schema_name(object_id, @dbid) as schema_name,
				object_id into #SP_LIST
		FROM DBA_SP_REFERENCED_LIST with (nolock)
   end

    
        DECLARE spname_cursor CURSOR FOR 
            --EXEC sp_executesql @SQL
            SELECT name, schema_name,object_id  FROM ##SP_LIST

        OPEN spname_cursor       
        FETCH next FROM spname_cursor into @spname, @schema_name, @object_id
        WHILE @@fetch_status = 0       
        BEGIN       

				--select @spname,@schema_name,@object_id
				SET @SQL1 = 'SELECT  @count=count(*)' + char(10)
                            + ' FROM ' + @dbname 
                            + '.SYS.DM_SQL_REFERENCED_ENTITIES(''' + @schema_name+ '.' + @spname+ ''',''OBJECT'')' + char(10)
   
				
				
               
              BEGIN TRY            
                
                EXEC sp_executesql @SQL1, N'@count int output', @count = @count output
              END TRY
              BEGIN CATCH
              
					SET @ERROR_NO = ERROR_NUMBER()
					IF @ERROR_NO  = 2020
					BEGIN

						SET @SQL1 = ' SELECT  TOP 1 @ref_server_name = referenced_server_name '
							+ ', @ref_db_name = referenced_database_name , @ref_schema_name =referenced_schema_name  ' + char(10)
							+ ', @ref_table_name = referenced_entity_name ' +  char(10)
                            + ' FROM ' + @dbname 
                            + '.SYS.DM_SQL_REFERENCED_ENTITIES(''' + @schema_name+ '.' + @spname+ ''',''OBJECT'')' + char(10)
                            + ' WHERE referenced_id is null '
                           

                            
                       BEGIN TRY                   
							SET @parmdefinition = '@ref_server_name sysname output, @ref_db_name sysname output, @ref_schema_name sysname output, @ref_table_name sysname output'
							EXEC sp_executesql @SQL1, @parmdefinition, @ref_server_name=@ref_server_name output ,@ref_db_name = @ref_db_name output, 
													@ref_schema_name = @ref_schema_name output, @ref_table_name = @ref_table_name  output
							
							INSERT INTO DBO.DBA_SP_REFERENCED_ERROR
							( db_name, reg_date,sp_id, schema_name, sp_name, ref_server_name, ref_db_name, ref_schema_name, ref_table_name, error_no)
							VALUES (@dbname, getdate(), @object_id, @schema_name, @spname, @ref_server_name,@ref_db_name, @ref_schema_name, @ref_table_name, 
								@error_no)
					   END TRY					
					   BEGIN CATCH 
							print 'DETAIL ERROR'
					   END CATCH				
									
							

					END
		      END CATCH    
          
        ERROR_HANDLER:
        FETCH NEXT FROM spname_cursor into @spname, @schema_name,@object_id
        END
   
  
	CLOSE spname_cursor       
	DEALLOCATE spname_cursor   

FETCH NEXT FROM dbname_cursor INTO @dbname  , @dbid      
      
END  

CLOSE dbname_cursor       
DEALLOCATE dbname_cursor   
DROP TABLE #SP_LIST

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO