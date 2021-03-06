USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[sp_dba_GetFieldsExtendedProperity]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*=====================================================  
SP명:  [dbo].[sp_dba_GetFieldsExtendedProperity]    
작성자: 김세웅  
용  도: 테이블 속성및 확장속성 select  
실행예제: sp_dba_GetFieldsExtendedProperity 'aaa'  
  
수정사항: 2012-10-18  노상국  
   - 테이블확장속성정보를 User table(dbmon.dbo.DB_MON_INFO_FIELDS)로 변경함  
   - 테이블속성은 system catalog에서 가져와서 조인함  
======================================================*/  
CREATE PROC [dbo].[sp_dba_GetFieldsExtendedProperity]  
  @version int  
 ,@objectname nvarchar(256)        
AS        
  
SET NOCOUNT ON  
IF EXISTS (SELECT * FROM DBMON.DBO.DB_MON_INFO_VERSION WHERE class = 'DB_EXCEL' AND [version] <> @version)  
begin   
	select -1
	return (-1)
end

select   
  ext1.column_id  
, ext1.column_name  
, ext1.datatype  
, ext1.length  
, ext1.precision  
, ext1.is_null  
, ext1.is_identity  
, ext1.is_pk  
, ext1.Default_val  
,isnull(ext1.ext_name, '')      as 'ext_name'
,isnull(ext1.ext_value, '')     as 'ext_value'  
                     
                     
,isnull(ext2.name_kr,'')		as 'Name_kr'     
,isnull(ext2.english,'')		as 'English'    
,isnull(ext2.comments,'')		as 'Comments'  
,isnull(ext2.source_db,'')		as 'Source_db'  
,isnull(ext2.source_table,'')	as 'Source_table'  
,isnull(ext2.source_column,'')  as 'Source_column'  
,isnull(ext2.class,'')			as 'Class'
 
from (  
select  
col.column_id  as column_id          
,col.name   as column_name       
,st.name    as datatype       
,col.max_length as length       
,case when st.name in ('decimal','numeric') then convert(varchar(2),col.precision) else '' end precision        
,case when col.is_nullable = 1 then 'Y' else '' end is_null         
,case when col.is_identity = 1 then 'Y' else '' end is_identity  
,case when ic.index_id is not null then 'Y' else '' end as is_pk  
,isnull(defcst.definition,'')  as 'Default_val'
,isnull(ext.ext_name, '')      as 'ext_name'
,isnull(ext.ext_value, '')     as 'ext_value'        
from  sys.tables tbl with(nolock)  
join sys.columns col with(nolock)on tbl.object_id= col.object_id  
left outer join sys.types st with(nolock)on st.user_type_id = col.user_type_id         
left outer join sys.default_constraints defcst with(nolock)    on defcst.parent_object_id = col.object_id and defcst.parent_column_id = col.column_id         
left outer join sys.identity_columns idc with(nolock)            on idc.object_id = col.object_id and idc.column_id = col.column_id    
left outer join sys.indexes as idx with(nolock) on col.object_id = idx.object_id and is_primary_key = 1  
left outer join sys.index_columns as ic with(nolock) on idx.object_id = ic.object_id and idx.index_id = ic.index_id and col.column_id = ic.column_id  
left outer join (select major_id,minor_id, max(name) ext_name, max(value) ext_value from sys.extended_properties ext with (nolock) 
                 where major_id = object_id(@objectname) group by major_id,minor_id) ext 
                 on ext.major_id = object_id(@objectname)  and ext.minor_id = col.column_id  
where tbl.name = @objectname  
) ext1  
left join (select * from dbmon.dbo.DB_MON_INFO_FIELDS with (nolock) where db_name= db_name() and table_name = @objectname )  as ext2   on ext1.column_name     = ext2.column_name  
order by ext1.column_id




GO
