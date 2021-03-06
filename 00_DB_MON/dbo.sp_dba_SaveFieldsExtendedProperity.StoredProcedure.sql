USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[sp_dba_SaveFieldsExtendedProperity]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*=====================================================  
SP명:  [dbo].[sp_dba_SaveFieldsExtendedProperity]    
작성자: 김세웅  
용  도: 테이블 속성및 확장속성 SAVE  
실행예제: [sp_dba_SaveFieldsExtendedProperity] 'aaa'  
  
수정사항: 2012-10-18  노상국  
   - 테이블확장속성정보를 User table(dbmon.dbo.DB_MON_INFO_FIELDS)로 변경함  

BIDSP.dbo.sp_dba_SaveFieldsExtendedProperity'3','dbo','BIDSP','AG_MEMBER','1','IAC_MEMB_ID','옥션 고객 아이디','','','','','',''

SELECT * FROM dbmon.dbo.DB_MON_INFO_FIELDS
  
======================================================*/  
CREATE PROC [dbo].[sp_dba_SaveFieldsExtendedProperity]      
  @version		int
, @SchemaName	varchar(256)  
, @DBName		varchar(256)  
, @TableName	varchar(256)  
, @column_id	int      
, @ColumnName	varchar(256)   
, @Name_KR		varchar(256)  
, @English		varchar(256)   
, @comment		varchar(1000)         
, @SourceDB		varchar(256)     
, @SourceTable  varchar(256)  
, @SourceColumn varchar(256)  
, @Class		varchar(256)          
AS      
SET NOCOUNT ON      

IF EXISTS (SELECT * FROM DBMON.DBO.DB_MON_INFO_VERSION WHERE class = 'DB_EXCEL' AND [version] <> @version)  
begin   
	select -1
	return (-1)
end
else
	select  1
  
DECLARE @Delimiter CHAR(1)      
DECLARE @Caption VARCHAR(2001)      
DECLARE @Name  VARCHAR(20)       
DECLARE @Table_full_name VARCHAR(100)

SET @Table_full_name = @DBName+'.'+@SchemaName+'.'+@TableName
  
--테이블에 저장하기  
IF EXISTS(select table_name from dbmon.dbo.DB_MON_INFO_FIELDS with(nolock)  
    where db_name = @DBName  and table_name = @TableName and column_name = @ColumnName )  
  BEGIN  
    update ext  
    set ext.Name_kr  = @Name_KR  
    , ext.English   = @English  
    , ext.Comments  = @comment  
    , ext.Source_db  = @SourceDB  
    , ext.Source_table = @SourceTable  
    , ext.Source_column = @SourceColumn  
    , ext.Class    = @Class  
    , ext.upd_date = getdate()
	, ext.last_user =  SUSER_NAME()
    , ext.server_name  = @@servername
    from dbmon.dbo.DB_MON_INFO_FIELDS  ext  
    where db_name   = @DBName 
    and table_name  = @TableName  
    and column_name =@ColumnName
  END  
ELSE  
  BEGIN  
    insert into dbmon.dbo.DB_MON_INFO_FIELDS(  
       object_id  
	 , server_name
     , db_name  
     , table_name  
     , column_id  
     , column_name  
     , Name_kr  
     , English  
     , Comments  
     , Source_db  
     , Source_table  
     , Source_column  
     , Class
     , ins_date
     , upd_date
     , last_user
     )  
     values(  
       object_id(@Table_full_name) -- table_object_id 
     , @@Servername    
     , @DBName  
     , @TableName  
     , @column_id  
     , @ColumnName  
     , @Name_KR  
     , @English  
     , @comment  
     , @SourceDB  
     , @SourceTable  
     , @SourceColumn  
     , @Class
     , getdate()
     , getdate()
     , SUSER_NAME()
     )  
  END  
  
  
/*  
-- system catalog에 적용  
--버그교정용 임시  
IF @Name_KR = ''  
SET @Name_KR= '-'  
/*=============================================================    
Name Properity  
=============================================================*/  
SET @Name = 'Name_KR'      
  
IF NOT @Name_KR = ''      
 BEGIN      
 IF EXISTS( SELECT * FROM fn_listextendedproperty(@Name, 'schema', @SchemaName, 'table', @TableName, 'column', @ColumnName) )      
   BEGIN      
       EXEC  sp_updateextendedproperty       
       @name = @Name, @value = @Name_KR,      
       @level0type = N'Schema',@level0name = @SchemaName,      
       @level1type = N'Table', @level1name = @TableName,      
       @level2type = N'Column', @level2name = @ColumnName;      
    END      
 ELSE      
   BEGIN      
     EXEC sp_addextendedproperty       
     @name = @Name, @value = @Name_KR,      
     @level0type = N'Schema', @level0name = @SchemaName,      
     @level1type = N'Table',  @level1name = @TableName,      
     @level2type = N'Column', @level2name = @ColumnName;      
   END      
  END      
ELSE  IF EXISTS( SELECT * FROM fn_listextendedproperty (@Name, 'schema', @SchemaName, 'table', @TableName, 'column', @ColumnName))      
  EXEC sp_dropextendedproperty       
    @name = @Name,       
    @level0type = 'schema' ,@level0name = @SchemaName,      
    @level1type = 'table' ,@level1name = @TableName,      
    @level2type = 'column' ,@level2name = @ColumnName;      
  
  
  
/*=============================================================    
comments Properity  
=============================================================*/      
SET @Name = 'Comments'      
  
IF NOT @Comment = ''      
 BEGIN      
 IF EXISTS( SELECT * FROM fn_listextendedproperty(@Name, 'schema', @SchemaName, 'table', @TableName, 'column', @ColumnName) )      
   BEGIN      
     EXEC  sp_updateextendedproperty       
     @name = @Name, @value = @Comment,      
     @level0type = N'Schema',@level0name = @SchemaName,      
     @level1type = N'Table', @level1name = @TableName,      
     @level2type = N'Column', @level2name = @ColumnName;      
    END      
 ELSE      
   BEGIN      
     EXEC sp_addextendedproperty       
     @name = @Name, @value = @Comment,      
     @level0type = N'Schema', @level0name = @SchemaName,      
     @level1type = N'Table',  @level1name = @TableName,      
     @level2type = N'Column', @level2name = @ColumnName;      
   END      
  END      
ELSE      
 IF EXISTS( SELECT * FROM fn_listextendedproperty (@Name, 'schema', @SchemaName, 'table', @TableName, 'column', @ColumnName))      
 BEGIN  
  EXEC sp_dropextendedproperty       
    @name = @Name,       
    @level0type = 'schema' ,@level0name = @SchemaName,      
    @level1type = 'table' ,@level1name = @TableName,      
    @level2type = 'column' ,@level2name = @ColumnName;      
 print 'sp_dropextendedproperty'  
 END  
/*=============================================================    
English Properity  
=============================================================*/       
 SET @Name = 'English'      
IF NOT  @English = ''      
 BEGIN      
 IF EXISTS( SELECT * FROM fn_listextendedproperty (@name, 'schema', @SchemaName, 'table', @TableName, 'column', @ColumnName))      
  BEGIN      
   EXEC  sp_updateextendedproperty       
   @name = @Name, @value = @English,      
   @level0type = N'Schema', @level0name = @SchemaName,      
   @level1type = N'Table',  @level1name = @TableName,      
   @level2type = N'Column', @level2name = @ColumnName;      
  END      
 ELSE      
  BEGIN      
   EXEC sp_addextendedproperty       
   @name = @Name, @value = @English,      
   @level0type = N'Schema', @level0name = @SchemaName,      
   @level1type = N'Table',  @level1name = @TableName,      
   @level2type = N'Column', @level2name = @ColumnName;      
  END      
END      
ELSE      
 IF EXISTS( SELECT * FROM fn_listextendedproperty (@name, 'schema', @SchemaName, 'table', @TableName, 'column', @ColumnName))      
  EXEC sp_dropextendedproperty       
    @name = @Name,       
    @level0type = 'schema' ,@level0name = @SchemaName,      
    @level1type = 'table' ,@level1name = @TableName,      
    @level2type = 'column' ,@level2name = @ColumnName;      
  
  
  
  
/*=============================================================    
Source DB Properity  
=============================================================*/  
 SET @Name = 'Source DB'      
      
IF NOT  @SourceDB = ''      
 BEGIN      
 IF EXISTS( SELECT * FROM fn_listextendedproperty(@name, 'schema', @SchemaName, 'table', @TableName, 'column', @ColumnName))      
  BEGIN      
   EXEC  sp_updateextendedproperty       
   @name = @Name, @value = @SourceDB,      
   @level0type = N'Schema', @level0name = @SchemaName,      
   @level1type = N'Table',  @level1name = @TableName,      
   @level2type = N'Column', @level2name = @ColumnName;      
  END      
 ELSE      
  BEGIN      
   EXEC sp_addextendedproperty       
   @name = @Name, @value = @SourceDB,      
   @level0type = N'Schema', @level0name = @SchemaName,      
   @level1type = N'Table',  @level1name = @TableName,      
   @level2type = N'Column', @level2name = @ColumnName;      
  END      
  END      
ELSE    
 IF EXISTS( SELECT * FROM fn_listextendedproperty  (@name, 'schema', @SchemaName, 'table', @TableName, 'column', @ColumnName))      
  EXEC sp_dropextendedproperty       
    @name = @Name,       
    @level0type = 'schema' ,@level0name = @SchemaName,      
    @level1type = 'table' ,@level1name = @TableName,      
    @level2type = 'column' ,@level2name = @ColumnName;      
  
    
/*=============================================================    
Source Table Properity  
=============================================================*/  
SET @Name = 'Source Table'      
      
IF NOT  @SourceTable = ''      
 BEGIN      
 IF EXISTS( SELECT * FROM fn_listextendedproperty(@name, 'schema', @SchemaName, 'table', @TableName, 'column', @ColumnName))      
  BEGIN      
   EXEC  sp_updateextendedproperty       
   @name = @Name, @value = @SourceTable,      
   @level0type = N'Schema', @level0name = @SchemaName,      
   @level1type = N'Table',  @level1name = @TableName,      
   @level2type = N'Column', @level2name = @ColumnName;      
  END      
 ELSE      
  BEGIN      
   EXEC sp_addextendedproperty       
   @name = @Name, @value = @SourceTable,      
   @level0type = N'Schema', @level0name = @SchemaName,      
   @level1type = N'Table',  @level1name = @TableName,      
   @level2type = N'Column', @level2name = @ColumnName;      
  END      
  END      
ELSE      
 IF EXISTS( SELECT * FROM fn_listextendedproperty  (@name, 'schema', @SchemaName, 'table', @TableName, 'column', @ColumnName))      
  EXEC sp_dropextendedproperty       
    @name = @Name,       
    @level0type = 'schema' ,@level0name = @SchemaName,      
    @level1type = 'table' ,@level1name = @TableName,      
    @level2type = 'column' ,@level2name = @ColumnName;      
  
/*=============================================================    
Source Column Properity  
=============================================================*/  
SET @Name = 'Source Column'      
      
IF NOT  @SourceColumn = ''      
 BEGIN      
 IF EXISTS( SELECT * FROM fn_listextendedproperty(@name, 'schema', @SchemaName, 'table', @TableName, 'column', @ColumnName))      
  BEGIN      
   EXEC  sp_updateextendedproperty       
   @name = @Name, @value = @SourceColumn,      
   @level0type = N'Schema', @level0name = @SchemaName,      
   @level1type = N'Table',  @level1name = @TableName,    
   @level2type = N'Column', @level2name = @ColumnName;      
  END      
 ELSE      
  BEGIN      
   EXEC sp_addextendedproperty       
   @name = @Name, @value = @SourceColumn,      
   @level0type = N'Schema', @level0name = @SchemaName,      
   @level1type = N'Table',  @level1name = @TableName,      
   @level2type = N'Column', @level2name = @ColumnName;      
  END      
  END      
ELSE      
 IF EXISTS( SELECT * FROM fn_listextendedproperty  (@name, 'schema', @SchemaName, 'table', @TableName, 'column', @ColumnName))      
  EXEC sp_dropextendedproperty       
    @name = @Name,       
    @level0type = 'schema' ,@level0name = @SchemaName,      
    @level1type = 'table' ,@level1name = @TableName,      
    @level2type = 'column' ,@level2name = @ColumnName;      
  
/*=============================================================    
뷴류  Properity  
=============================================================*/  
SET @Name = 'Class'      
      
IF NOT  @Class = ''      
 BEGIN      
 IF EXISTS( SELECT * FROM fn_listextendedproperty(@name, 'schema', @SchemaName, 'table', @TableName, 'column', @ColumnName))      
  BEGIN      
   EXEC  sp_updateextendedproperty       
   @name = @Name, @value = @Class,      
   @level0type = N'Schema', @level0name = @SchemaName,      
   @level1type = N'Table',  @level1name = @TableName,      
   @level2type = N'Column', @level2name = @ColumnName;      
  END      
 ELSE  
  BEGIN      
   EXEC sp_addextendedproperty       
   @name = @Name, @value = @Class,      
   @level0type = N'Schema', @level0name = @SchemaName,      
   @level1type = N'Table',  @level1name = @TableName,      
   @level2type = N'Column', @level2name = @ColumnName;      
  END      
  END      
ELSE      
 IF EXISTS( SELECT * FROM fn_listextendedproperty  (@name, 'schema', @SchemaName, 'table', @TableName, 'column', @ColumnName))      
  EXEC sp_dropextendedproperty       
    @name = @Name,       
    @level0type = 'schema' ,@level0name = @SchemaName,      
    @level1type = 'table' ,@level1name = @TableName,      
    @level2type = 'column' ,@level2name = @ColumnName;      
  */
  



GO
