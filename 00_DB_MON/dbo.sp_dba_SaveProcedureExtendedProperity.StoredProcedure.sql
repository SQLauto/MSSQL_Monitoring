USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[sp_dba_SaveProcedureExtendedProperity]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_dba_SaveProcedureExtendedProperity]  
 @SchemaName     nvarchar(256)      
,@ProcedureName  nvarchar(256)     
,@comment        varchar(1000)  
,@bigo           varchar(1000)  
,@creator        varchar(1000)  
,@schedule       varchar(1000)  
,@jobname        varchar(1000)  
,@stepname       varchar(1000)  
,@history        varchar(1000)  
,@detail         varchar(1000)  
AS  
-- comment  
IF EXISTS(SELECT * FROM fn_listextendedproperty         
    ('comment', 'schema', @SchemaName, 'Procedure', @ProcedureName, null, null))        
 EXEC sp_dropextendedproperty       
  @name = 'comment',       
  @level0type = 'schema' ,@level0name = @SchemaName,      
  @level1type = 'Procedure' ,@level1name = @ProcedureName    
  
EXEC sp_addextendedproperty       
 @name = 'comment',   
 @value = @comment,      
 @level0type = N'Schema', @level0name = @SchemaName,      
 @level1type = 'Procedure' ,@level1name = @ProcedureName     
  
-- bigo   
IF EXISTS(SELECT * FROM fn_listextendedproperty         
    ('bigo', 'schema', @SchemaName, 'Procedure', @ProcedureName, null, null))        
 EXEC sp_dropextendedproperty       
  @name = 'bigo',       
  @level0type = 'schema' ,@level0name = @SchemaName,      
  @level1type = 'Procedure' ,@level1name = @ProcedureName    
  
EXEC sp_addextendedproperty       
 @name = 'bigo',   
 @value = @bigo,      
 @level0type = N'Schema', @level0name = @SchemaName,      
 @level1type = 'Procedure' ,@level1name = @ProcedureName     
  
-- creator   
IF EXISTS(SELECT * FROM fn_listextendedproperty         
    ('creator', 'schema', @SchemaName, 'Procedure', @ProcedureName, null, null))        
 EXEC sp_dropextendedproperty       
  @name = 'creator',       
  @level0type = 'schema' ,@level0name = @SchemaName,      
  @level1type = 'Procedure' ,@level1name = @ProcedureName    
  
EXEC sp_addextendedproperty       
 @name = 'creator',   
 @value = @creator,      
 @level0type = N'Schema', @level0name = @SchemaName,      
 @level1type = 'Procedure' ,@level1name = @ProcedureName      
  
  
-- schedule   
IF EXISTS(SELECT * FROM fn_listextendedproperty         
    ('schedule', 'schema', @SchemaName, 'Procedure', @ProcedureName, null, null))        
 EXEC sp_dropextendedproperty       
  @name = 'schedule',       
  @level0type = 'schema' ,@level0name = @SchemaName,      
  @level1type = 'Procedure' ,@level1name = @ProcedureName    
  
EXEC sp_addextendedproperty       
 @name = 'schedule',   
 @value = @schedule,      
 @level0type = N'Schema', @level0name = @SchemaName,      
 @level1type = 'Procedure' ,@level1name = @ProcedureName      
  
-- jobname   
IF EXISTS(SELECT * FROM fn_listextendedproperty         
    ('jobname', 'schema', @SchemaName, 'Procedure', @ProcedureName, null, null))        
 EXEC sp_dropextendedproperty       
  @name = 'jobname',       
  @level0type = 'schema' ,@level0name = @SchemaName,      
  @level1type = 'Procedure' ,@level1name = @ProcedureName    
  
EXEC sp_addextendedproperty       
 @name = 'jobname',   
 @value = @jobname,      
 @level0type = N'Schema', @level0name = @SchemaName,      
 @level1type = 'Procedure' ,@level1name = @ProcedureName      
  
-- stepname   
IF EXISTS(SELECT * FROM fn_listextendedproperty         
    ('stepname', 'schema', @SchemaName, 'Procedure', @ProcedureName, null, null))        
 EXEC sp_dropextendedproperty       
  @name = 'stepname',       
  @level0type = 'schema' ,@level0name = @SchemaName,      
  @level1type = 'Procedure' ,@level1name = @ProcedureName    
  
EXEC sp_addextendedproperty       
 @name = 'stepname',   
 @value = @stepname,      
 @level0type = N'Schema', @level0name = @SchemaName,      
 @level1type = 'Procedure' ,@level1name = @ProcedureName     
  
-- history   
IF EXISTS(SELECT * FROM fn_listextendedproperty         
    ('history', 'schema', @SchemaName, 'Procedure', @ProcedureName, null, null))        
 EXEC sp_dropextendedproperty       
  @name = 'history',       
  @level0type = 'schema' ,@level0name = @SchemaName,      
  @level1type = 'Procedure' ,@level1name = @ProcedureName    
  
EXEC sp_addextendedproperty       
 @name = 'history',   
 @value = @history,      
 @level0type = N'Schema', @level0name = @SchemaName,      
 @level1type = 'Procedure' ,@level1name = @ProcedureName    
  
  
-- history   
IF EXISTS(SELECT * FROM fn_listextendedproperty         
    ('detail', 'schema', @SchemaName, 'Procedure', @ProcedureName, null, null))        
 EXEC sp_dropextendedproperty       
  @name = 'detail',       
  @level0type = 'schema' ,@level0name = @SchemaName,      
  @level1type = 'Procedure' ,@level1name = @ProcedureName    
  
EXEC sp_addextendedproperty       
 @name = 'detail',   
 @value = @detail,      
 @level0type = N'Schema', @level0name = @SchemaName,      
 @level1type = 'Procedure' ,@level1name = @ProcedureName    
  
  







GO
