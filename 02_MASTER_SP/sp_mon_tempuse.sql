SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.sp_mon_tempuse 
* 작성정보    : 2010-02-19 by choi bo ra
* 관련페이지  :  
* 내용        :
* 수정정보    : 2013-09-25 by choi bo ra
**************************************************************************/
CREATE PROCEDURE dbo.sp_mon_tempuse
    @type       int = 0
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */

IF @type = 1
BEGIN
    select  
         u.session_id,    
        s.host_name,    
        s.login_name,  
        s.status,  
        s.program_name, 
        sum(u.user_objects_alloc_page_count+u.internal_objects_alloc_page_count)*8 tempdb_space_alloc_kB,    
        sum(u.user_objects_dealloc_page_count+u.internal_objects_dealloc_page_count)*8 tempdb_space_dealloc_kB,   
        sum(u.user_objects_alloc_page_count+u.internal_objects_alloc_page_count -u.user_objects_dealloc_page_count - u.internal_objects_dealloc_page_count)*8 remaining_tempdb_space_alloc_kB    
    from sys.dm_db_session_space_usage as u   
        join sys.dm_exec_sessions as s on s.session_id = u.session_id   
    where u.database_id = 2    
    group by u.session_id, s.host_name,  s.status, s.login_name, s.program_name   
    order by 8 desc  
END
ELSE IF @type = 0
BEGIN
    select  
        u.session_id, 
        s.host_name,    
        s.login_name,  
        s.status,  
        object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [object_name],
        s.program_name, 
        sum(u.user_objects_alloc_page_count+u.internal_objects_alloc_page_count)*8 tempdb_space_alloc_kB,    
        sum(u.user_objects_dealloc_page_count+u.internal_objects_dealloc_page_count)*8 tempdb_space_dealloc_kB,   
        sum(u.user_objects_alloc_page_count+u.internal_objects_alloc_page_count -u.user_objects_dealloc_page_count - u.internal_objects_dealloc_page_count)*8 remaining_tempdb_space_alloc_kB    
    from sys.dm_db_session_space_usage as u   
        join sys.dm_exec_sessions as s on s.session_id = u.session_id   
        left join sys.dm_exec_requests r on s.session_id = r.session_id
        outer  apply sys.dm_exec_sql_text(sql_handle) as qt
    where u.database_id = 2  and u.session_id > 50 --and r.wait_type <> 'WAITFOR'
    group by u.session_id, s.host_name,  s.status, s.login_name, s.program_name 
        ,  object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid)
    order by  9 desc  

END


RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO