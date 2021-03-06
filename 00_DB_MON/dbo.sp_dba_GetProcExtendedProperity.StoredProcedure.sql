USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[sp_dba_GetProcExtendedProperity]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[sp_dba_GetProcExtendedProperity]  
@objectname nvarchar(256)  
AS  
SELECT   
	a.name  
	,isnull(b.value,'') as class   
	,isnull(c.value,'') as comment    
	,isnull(d.value,'') as bigo    
	,isnull(e.value,'') as creator    
	,isnull(f.value,'') as schedule  
	,isnull(g.value,'') as jobname  
	,isnull(h.value,'') as stepname  
	,isnull(i.value,'') as history  
	,isnull(j.value,'') as detail  
FROM sys.sysobjects a              
LEFT JOIN fn_listextendedproperty ('class',   'schema', 'dbo', 'Procedure', @objectname, null, null) b ON 1=1              
LEFT JOIN fn_listextendedproperty ('comment', 'schema', 'dbo', 'Procedure', @objectname, null, null) c ON 1=1              
LEFT JOIN fn_listextendedproperty ('bigo',    'schema', 'dbo', 'Procedure', @objectname, null, null) d ON 1=1 
LEFT JOIN fn_listextendedproperty ('creator', 'schema', 'dbo', 'Procedure', @objectname, null, null) e ON 1=1  
LEFT JOIN fn_listextendedproperty ('schedule','schema', 'dbo', 'Procedure', @objectname, null, null) f ON 1=1          
LEFT JOIN fn_listextendedproperty ('jobname', 'schema', 'dbo', 'Procedure', @objectname, null, null) g ON 1=1    
LEFT JOIN fn_listextendedproperty ('stepname','schema', 'dbo', 'Procedure', @objectname, null, null) h ON 1=1          
LEFT JOIN fn_listextendedproperty ('history', 'schema', 'dbo', 'Procedure', @objectname, null, null) i ON 1=1            
LEFT JOIN fn_listextendedproperty ('detail',  'schema', 'dbo', 'Procedure', @objectname, null, null) j ON 1=1            
WHERE (TYPE = 'P' AND a.name = @objectname) 







GO
