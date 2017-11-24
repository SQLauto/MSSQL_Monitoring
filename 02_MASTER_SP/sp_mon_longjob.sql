SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* ���ν�����  : dbo.sp_mon_longjob
* �ۼ�����    : 2010-02-22 by �ֺ���
* ����������  :  
* ����        : 1�ð� �̻�  ����� job ���
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.sp_mon_longjob
    @duration        int = 60
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
select 'KILL ' + cast(s.session_id as varchar) as 'kill', 
               s.session_id,
	           j.name as job_name, 
	           cast(datediff(mi, s.login_time, getdate()) as varchar)+ '��' as duration
	           , s.login_time
	           , s.host_name
 	           , s.client_interface_name
	from sys.dm_exec_sessions as s with (nolock)
        inner join msdb.dbo.sysjobs j with (nolock)
        on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
									    substring(left(j.job_id,8),5,2) +
									    substring(left(j.job_id,8),3,2) +
									    substring(left(j.job_id,8),1,2))
where s.session_id > 50  and datediff(mi, s.login_time, getdate()) >= @duration
order by datediff(mi, s.login_time, getdate()) desc

RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO