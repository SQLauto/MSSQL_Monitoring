USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[sp_dba_GetChildTable]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_dba_GetChildTable]  
@ObjectName nvarchar(256)  
AS  
  select    
       object_name(parent_object_id) ChildTable   
     , object_name(object_id)  ConstraintName  
   from sys.foreign_keys 
   where referenced_object_id = OBJECT_ID(436196604) 
   order by 1




GO
