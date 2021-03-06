USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[sp_dba_SaveTableExtendedProperity]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_dba_SaveTableExtendedProperity]         
  @version int     
, @db_name varchar(128)  
, @type varchar(9)   
, @table_name varchar(128)   
, @object_id int   
, @rows BIGINT  
, @package varchar(300)  
, @class varchar(100)   
, @site varchar(30)  
, @comment varchar(500)  
, @english varchar(100)  
, @fymd varchar(100)  
, @term varchar(50)  
, @symd varchar(50)  
, @time varchar(19)  
, @owner varchar(50)  
AS  
  
set nocount on
   
IF EXISTS (SELECT * FROM DBMON.DBO.DB_MON_INFO_VERSION WHERE class = 'DB_EXCEL' AND [version] <> @version)  
begin   
	select -1
	return (-1)
end
else
	select  1
 
IF EXISTS (select object_id   
     from dbmon.dbo.DB_MON_INFO_TABLES with(nolock)  
      where  db_name = @db_name and object_id = @object_id)  
 BEGIN  
  --변경된 정보 업데이트  
  update tbl  
  set   
   tbl.rows   =  @rows
  ,tbl.type   =  @type   
  ,tbl.package  =  @package   
  ,tbl.class   =  @class   
  ,tbl.site   =  @site  
  ,tbl.comment  =  @comment   
  ,tbl.english  =  @english  
  ,tbl.fymd   =  @fymd   
  ,tbl.term   =  @term   
  ,tbl.symd   =  @symd   
  ,tbl.time   =  @time  
  ,tbl.owner    =  @owner 
  ,tbl.server_name  = @@servername
  ,upd_date = getdate()
  ,last_user = SUSER_NAME()
  from dbmon.dbo.DB_MON_INFO_TABLES tbl   
  where db_name = @db_name
  and object_id = @object_id  
 END  
ELSE  
 BEGIN  
  INSERT INTO dbmon.dbo.DB_MON_INFO_TABLES(  
      object_id 
     ,server_name  
     ,db_name  
     ,table_name  
     ,rows  
     ,type    
     ,package  
     ,class  
     ,site  
     ,comment  
     ,english  
     ,fymd  
     ,term  
     ,symd  
     ,time  
     ,owner
     ,ins_date 
     ,upd_date 
     ,last_user
     )  
     VALUES  
     (  
     @object_id 
     ,@@servername 
     ,@db_name
     ,@table_name  
     ,@rows
     ,@type   
     ,@package  
     ,@class  
     ,@site  
     ,@comment  
     ,@english  
     ,@fymd  
     ,@term  
     ,@symd  
     ,@time  
     ,@owner
     ,GETDATE()
     ,GETDATE()
     ,SUSER_NAME()  
     )  
 END  
 
/*  
--DECLARE @property_name varchar(100)          
set @property_name =       
 CASE @Class       
 WHEN 1  THEN 'package'     
 WHEN 2  THEN 'class'     
 WHEN 3  THEN 'site'     
 WHEN 4  THEN 'comment'                
 WHEN 5  THEN 'english'                
 WHEN 6  THEN 'fymd'     
 WHEN 7  THEN 'term'     
 WHEN 8  THEN 'symd'     
 WHEN 9  THEN 'time'     
 WHEN 10 THEN 'owner'     
 END           
IF @Comment <> ''           
  BEGIN            
 IF EXISTS( SELECT * FROM fn_listextendedproperty             
        (@property_name, 'schema', @SchemaName, @ObjComment, @ObjName, null, null))            
   EXEC sp_updateextendedproperty             
   @name = @property_name, @value = @Comment,            
   @level0type = N'Schema', @level0name = @SchemaName,            
   @level1type = @ObjComment,  @level1name = @ObjName            
 ELSE            
   EXEC sp_addextendedproperty             
   @name = @property_name, @value = @Comment,            
   @level0type = N'Schema', @level0name = @SchemaName,            
   @level1type = @ObjComment,  @level1name = @ObjName            
  END            
ELSE            
  BEGIN            
 IF EXISTS( SELECT * FROM fn_listextendedproperty             
        (@property_name, 'schema', @SchemaName, @ObjComment, @ObjName, null, null))            
   EXEC sp_dropextendedproperty             
     @name = @property_name,             
     @level0type = 'schema' ,@level0name = @SchemaName,            
     @level1type = @ObjComment ,@level1name = @ObjName            
  END     
 */  
    




GO
