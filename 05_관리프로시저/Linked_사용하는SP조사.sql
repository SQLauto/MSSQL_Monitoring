


select 'insert into tb_linkedserver ( server_id, linked_nm) values ( 86, ''' + linked_nm + ''')'
from dba.dbo.tb_linkedserver

CREATE TABLE TB_LINKEDSERVER
( 
LINKED_NM varchar (100)   NOT NULL  
)  ON [PRIMARY]
GO
ALTER TABLE TB_LINKEDSERVER ADD CONSTRAINT PK__TB_LINKEDSERVER__0A695708 primary key clustered ([LINKED_NM] ASC ) ON [PRIMARY] 
GO

CREATE TABLE TB_LINKEDSERVER_SP
( 
SERVER_NM varchar (100)   NOT NULL   , 
LINKED_NM varchar (100)   NOT NULL   , 
DBNAME nvarchar (128)   NULL   , 
SPNAME nvarchar (128)   NULL  
)  ON [PRIMARY]
GO


/*     
 Function Name  : fn_del_comments    
 Function Specification : Delete comments in SP or Function    
 Create    : 2010-08-02    
 Creator   : Kwon, Byung-Jun    
 Modify   : 2010-08-04 (Bug Fix)    
*/    
CREATE FUNCTION dbo.fn_del_comments (@srch_txt  AS nvarchar(max))    
RETURNS nvarchar(max)    
AS    
BEGIN    
 DECLARE @sub_txt nvarchar(max)    
    
 WHILE patindex('%/*%', @srch_txt) > 0    
 BEGIN    
  SET @sub_txt = substring(@srch_txt, patindex('%/*%', @srch_txt) + 1, len(@srch_txt) - patindex('%/*%', @srch_txt))    
  SET @srch_txt = left(@srch_txt, patindex('%/*%', @srch_txt) - 1) + case when right(@sub_txt, len(@sub_txt) - patindex('%*/%', @sub_txt) - 1) is null then '' else right(@sub_txt, len(@sub_txt) - patindex('%*/%', @sub_txt) - 1) end    
 END    
    
 WHILE patindex('%--%', @srch_txt) > 0    
 BEGIN    
  SET @sub_txt = substring(@srch_txt, patindex('%--%', @srch_txt), len(@srch_txt) - patindex('%--%', @srch_txt) + 1)    
  SET @srch_txt = left(@srch_txt, patindex('%--%', @srch_txt) - 1) + case when patindex('%' + char(13) + '%', @sub_txt) = 0  then '' else right(@sub_txt, len(@sub_txt) - patindex('%' + char(13) + '%', @sub_txt) + 1) end    
 END    
    
 RETURN @srch_txt    
END
go    






ALTER PROC up_dba_tb_linkedserver_sp_select  
AS  
 IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[TB_LINKEDSERVER]') AND type in (N'U'))  
 BEGIN  
  CREATE TABLE [TB_LINKEDSERVER]  
   ([LINKED_NM] [varchar](100) NOT NULL PRIMARY KEY)  
 END  
  
 TRUNCATE TABLE [dbo].[TB_LINKEDSERVER]  
    
 INSERT [dbo].[TB_LINKEDSERVER]  
 SELECT NAME FROM SYS.SERVERS WHERE NOT NAME = @@SERVERNAME  
  
  
 IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[TB_LINKEDSERVER_SP]') AND type in (N'U'))  
 BEGIN  
  CREATE TABLE [TB_LINKEDSERVER_SP]  
  (  
    [SERVER_NM]   [varchar](100) NOT NULL,  
      [LINKED_NM]  [varchar](100) NOT NULL,  
      [DBNAME]     [nvarchar](128) NULL,  
      [SPNAME]     [nvarchar](128) NULL  
  )  
 END  
  
 TRUNCATE TABLE TB_LINKEDSERVER_SP  
  
 DECLARE @SQL VARCHAR(MAX), @EXEC_SQL VARCHAR(MAX)   
DECLARE @dbname     varchar(50)   
DECLARE @dbid       nvarchar(50)    
  
SET @SQL = '  
    USE @@DB  
             INSERT DBA.DBO.TB_LINKEDSERVER_SP  
             
             SELECT DISTINCT @@SERVERNAME SERVER_NM, LINKED_NM, ''@@DB'' DBNAME, OBJECT_NAME(ID,DB_ID(''@@DB'')) SPNAME   
             FROM @@DB.SYS.SYSCOMMENTS WITH (NOLOCK)   
				JOIN DBA.dbo.TB_LINKEDSERVER WITH (NOLOCK) ON   
					(DBA.dbo.fn_del_comments(text) LIKE ''%'' + LINKED_NM + ''.%'')   
				 OR (DBA.dbo.fn_del_comments(text) LIKE ''%[[]'' + LINKED_NM + ''].%'')   
				 OR (DBA.dbo.fn_del_comments(text) LIKE ''%OPENQUERY([ ]'' + LINKED_NM + ''%'')  
				 OR (DBA.dbo.fn_del_comments(text) LIKE ''%OPENQUERY([ ][[]'' + LINKED_NM + '']%'') '  
  
DECLARE dbname_cursor CURSOR FOR   
        SELECT name  
        from master..sysdatabases with (nolock)       
        where name not in   
            ('northwind', 'pubs', 'LiteSpeedCentral', 'LiteSpeedLocal', 'credit2', 'tempdb')  
        and DATABASEPROPERTYEX(name,'status')='ONLINE'  
  
  
OPEN dbname_cursor         
FETCH next FROM dbname_cursor into @dbname    
  
WHILE @@FETCH_STATUS = 0  
BEGIN  
                
    SELECT @exec_sql = REPLACE(@SQL,'@@DB',@dbname)  
       EXEC(@EXEC_SQL)  
         
         
       IF  @@ERROR <> 0   
       BEGIN  
   INSERT INTO TB_LINKEDSERVER_SP ( [SERVER_NM], [DBNAME], [LINKED_NM])  
   VALUES ( @@servername,  @dbname, 'ERROR')  
       END  
         
       FETCH NEXT FROM dbname_cursor INTO @dbname  
END  
  
CLOSE dbname_cursor  
DEALLOCATE dbname_cursor