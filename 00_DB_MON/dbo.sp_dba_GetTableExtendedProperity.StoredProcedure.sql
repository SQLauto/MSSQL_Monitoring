USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[sp_dba_GetTableExtendedProperity]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_dba_GetTableExtendedProperity]   
--테이블 속성 가져오기  
 @version varchar(10)  
,@TableAll varchar(1) = 'Y'  
AS        
  
SET NOCOUNT ON  
IF EXISTS (SELECT * FROM DBMON.DBO.DB_MON_INFO_VERSION WHERE class = 'DB_EXCEL' AND [version] <> @version)  
begin   
	select -1
	return (-1)
end
  
if @TableAll = 'A'  
 --메타테이블 에서 정보 가져오기 dbmon.dbo.DB_MON_INFO_TABLES  
 select   
  case when obj.type='U' then 'TABLE' else 'Procedure' END object   
 , obj.name  
 , isnull(obj.id, '')   as object_id    
 --, db_name()    as db_name   
 , isnull(i.rows, '')   as rows    
 , isnull(ext.ext_name, '')      as 'ext_name'
 , isnull(ext.ext_value, '')     as 'ext_value' 
 , isnull(tbl.package, '') as package  
 , isnull(tbl.class, '')  as class   
 , isnull(tbl.site, '')   as site  
 , isnull(tbl.comment, '') as comment  
 , isnull(tbl.english, '')  as english   
 , isnull(tbl.fymd, '')  as fymd    
 , isnull(tbl.term, '')  as term   
 , isnull(tbl.symd, '')  as symd   
 , isnull(tbl.time , '')  as time  
 , isnull(tbl.owner, '')  as owner  

 from sysobjects obj with(nolock)  
 left join dbmon.dbo.DB_MON_INFO_TABLES tbl with(nolock) on  obj.id = tbl.object_id and tbl.db_name = db_name()  
 left join (select major_id, max(name) ext_name, max(value) ext_value from sys.extended_properties ext with (nolock) where minor_id = 0
             group by major_id)  ext on ext.major_id =  obj.id 
 join sysindexes i  on i.id =  obj.id and  i.indid < 2   
 WHERE obj.TYPE = 'U'    
 order by obj.name asc  
else  
 select   
  case when obj.type='U' then 'TABLE' else 'Procedure' END object   
 , obj.name  
 , isnull(obj.id, '')   as object_id    
 --, db_name()    as db_name   
 , isnull(i.rows, '')   as rows    
 , isnull(ext.ext_name, '')      as 'ext_name'
 , isnull(ext.ext_value, '')     as 'ext_value' 
 , isnull(tbl.package, '') as package  
 , isnull(tbl.class, '')  as class   
 , isnull(tbl.site, '')   as site  
 , isnull(tbl.comment, '') as comment  
 , isnull(tbl.english, '')  as english   
 , isnull(tbl.fymd, '')  as fymd    
 , isnull(tbl.term, '')  as term   
 , isnull(tbl.symd, '')  as symd   
 , isnull(tbl.time , '')  as time  
 , isnull(tbl.owner, '')  as owner  
 from sysobjects obj with(nolock)  
 left join dbmon.dbo.DB_MON_INFO_TABLES tbl with(nolock) on  obj.id = tbl.object_id and tbl.db_name = db_name()  
 left join (select major_id, max(name) ext_name, max(value) ext_value from sys.extended_properties ext with (nolock) where minor_id = 0 
              group by major_id)  ext on ext.major_id =  obj.id 
 join sysindexes i  on i.id =  obj.id and  i.indid < 2   
 WHERE obj.TYPE = 'U'    
   AND comment <> ''  
 order by obj.name asc 








GO
