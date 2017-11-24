SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'sp_current_recompile' 
	   AND 	  type = 'P')
    DROP PROCEDURE  sp_current_recompile
*/

/*************************************************************************  
* ���ν�����  : dbo.sp_current_recompile 
* �ۼ�����    : 2007-10-30 
* ����������  :  
* ����        : ���ν����� �������� ��ġ
* ��������    :
**************************************************************************/
CREATE PROCEDURE sp_current_recompile  
as  
set nocount on  
select top 100  
 plan_generation_num,  
 execution_count,  
 isnull(db_name(dbid), dbid),  
 isnull(object_name(objectid), objectid),  
 substring(qt.text,A.statement_start_offset/2,   
   (case when A.statement_end_offset = -1   
   then len(convert(nvarchar(max), qt.text)) * 2   
   else A.statement_end_offset end - A.statement_start_offset)/2)   
  as executing_query_text   --- this is the statement executing right now  
from sys.dm_exec_query_stats a  
 Cross apply sys.dm_exec_sql_text(sql_handle) as QT  
where plan_generation_num >1  
order by plan_generation_num desc  
  
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO