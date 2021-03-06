USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[sp_dba_GetFieldsExtendedProperity_original]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[sp_dba_GetFieldsExtendedProperity_original]      
 @ObjectName nvarchar(256)      
AS      
SET NOCOUNT ON       
select       
 col.column_id,       
 col.name,       
 st.name as DT_name,       
 col.max_length length,      
 CASE WHEN st.name IN ('decimal','numeric') THEN convert(varchar(2),col.precision) ELSE '' END precision,      
 CASE WHEN col.is_nullable = 1 THEN 'Y' ELSE '' END is_Null,       
 CASE WHEN col.is_identity = 1 THEN 'Y' ELSE '' END is_identity,
 CASE WHEN IC.INDEX_ID IS NOT NULL THEN 'Y' ELSE '' END AS IS_PK,
 isnull(defCst.definition,'') default_val,    
 isnull(ext.value,'') MS_Description,  
 isnull(ext2.value,'') MS_Details,
 isnull(ext3.value,'') MS_Class
  
from sys.columns col       
left outer join sys.types st on st.user_type_id = col.user_type_id       
left outer join sys.default_constraints defCst     
 on defCst.parent_object_id = col.object_id and defCst.parent_column_id = col.column_id       
left outer join sys.identity_columns idc     
 on idc.object_id = col.object_id and idc.column_id = col.column_id  
left outer join sys.extended_properties ext     
 on ext.major_id = col.object_id and ext.minor_id = col.column_id  and ext.name = 'MS_Description' and ext.class = 1     
left outer join sys.extended_properties ext2     
 on ext2.major_id = col.object_id and ext2.minor_id = col.column_id and ext2.name = 'MS_Details' and ext.class = 1      
left outer join sys.extended_properties ext3     
 on ext3.major_id = col.object_id and ext3.minor_id = col.column_id and ext3.name = 'MS_Class' and ext.class = 1      
left JOIN SYS.INDEXES AS idx WITH(NOLOCK) ON col.object_id = idx.OBJECT_ID and IS_PRIMARY_KEY = 1
left JOIN sys.index_columns AS IC WITH(NOLOCK) ON idx.OBJECT_ID = IC.OBJECT_ID AND idx.INDEX_ID = IC.INDEX_ID AND col.COLUMN_ID = IC.COLUMN_ID
where col.object_id = object_id(@ObjectName)   
order by 1







GO
