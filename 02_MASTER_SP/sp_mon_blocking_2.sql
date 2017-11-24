SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.sp_mon_blocking_2 
* 작성정보    : 2010-02-23 by 이성표
* 관련페이지  :  
* 내용        :
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE sp_mon_blocking_2
AS

    select req.spid, req.blocked,   
     db_name(qt.dbid) as dbname,  
     object_name(qt.objectid, qt.dbid) as objectname,   
     object_name(bqt.objectid, bqt.dbid) as blockobject,  
     req.waittime,  
     req.waittype,   
     req.blockwaittype,  
     req.waitresource,  
     req.blockwaitresource,  
     req.lastwaittype,  
     req.open_tran,  
     req.hostname,  
     req.program_name,  
     req.loginame,  
     case when qt.text is null   
      then ''                   
      else isnull(substring(qt.text, req.stmt_start / 2, (case when req.stmt_start = -1 then len(convert(varchar(max), qt.text)) * 2   
        else req.stmt_end end - req.stmt_end) / 2), '')        
           end as querytext,  
     case when bqt.text is null   
      then ''                   
      else isnull(substring(bqt.text, req.block_stmt_start / 2, (case when req.block_stmt_start = -1 then len(convert(varchar(max), bqt.text)) * 2   
        else req.block_stmt_end end - req.block_stmt_end) / 2), '')        
           end as blockquerytext  
    from (  
     select top 50   
     b.spid as spid,   
     b.blocked as blocked,  
     b.waittime as waittime,  
     b.cmd as cmd,  
     b.status,  
     b.open_tran as open_tran,  
     b.waittype as waittype,  
     b.lastwaittype as lastwaittype,  
     b.waitresource as waitresource,  
     b.sql_handle,  
     b.stmt_start,  
     b.stmt_end,  
     a.waittype as blockwaittype,  
     a.sql_handle as blocksqlhandle,  
     a.stmt_start as block_stmt_start,  
     a.stmt_end as block_stmt_end,  
     a.waitresource as blockwaitresource,  
     b.hostname,  
     b.program_name,  
     b.loginame  
     from sys.sysprocesses a         
      join sys.sysprocesses b on (a.spid = b.blocked)        
     where a.spid <> a.blocked and b.spid <> b.blocked and a.blocked = 0      
    ) req  
     cross apply sys.dm_exec_sql_text(req.sql_handle) as qt        
     cross apply sys.dm_exec_sql_text(req.blocksqlhandle) as bqt

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

