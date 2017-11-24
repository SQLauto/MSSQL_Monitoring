use dba
go

-- ���°� �� ���� �����̸�, ���� ���� ���� �� �ּ���. 
-- ������ ��� �׳� �μ���.
exec dba.dbo.up_dba_reindex_mon_reindex_job 'A'  -- ��ü JOB ���� ����

--���г� ������ ���� ���� �� , �� ��� �������� ���� ���� �� ���ø� �˴ϴ�.
exec dba.dbo.up_dba_reindex_mon_reindex_job 'F'

-- Site Close �Ǿ��µ� ���� �ǰ� �ִ� job�� �ִ��� Ȯ�� kill session �� �����ϱ� �ش� ���� ���� kill �� �ֽø��
exec dba.dbo.up_dba_reindex_mon_reindex_job 'I'


--job ���� ���� 
select N'KILL '+ CONVERT(nvarchar(10), r.session_id),  j.name 
	from sys.dm_exec_requests r
		inner join sys.dm_exec_sessions s on r.session_id = s.session_id
	--cross apply sys.dm_exec_sql_text(sql_handle) as qt
				left outer join msdb.dbo.sysjobs j
					on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
												substring(left(j.job_id,8),5,2) +
												substring(left(j.job_id,8),3,2) +
												substring(left(j.job_id,8),1,2))
	where r.session_id != @@spid and j.name in
		('[DBA] REINDEX AUTOMATION - REINDEX MOD0','[DBA] REINDEX AUTOMATION - REINDEX MOD1','[DBA] REINDEX AUTOMATION - REINDEX MOD2')
	order by r.cpu_time DESC




/** Reindx ���� ���� */

--INDEX REINDEX ��� ��
SELECT * FROM dba.dbo.DBA_REINDEX_TARGET_LIST A WITH(NOLOCK)

SELECT b.target_seq %3 as mod, * 
FROM dba.dbo.DBA_REINDEX_TARGET_LIST A WITH(NOLOCK)
INNER JOIN dba.dbo.DBA_REINDEX_MOD_META B WITH(NOLOCK) ON A.TARGET_SEQ = B.TARGET_SEQ

-- ���� �����ϰ� �ִ� Index
exec dba.dbo.up_dba_reindex_mon_reindex_ing

--��ü ���
exec dba.dbo.up_dba_reindex_mon_reindex

-- ��ü ���� List ��
exec dba.dbo.up_dba_reindex_mon_reindex_detail

--�Ϸ�� ���� 
exec dba.dbo.up_dba_reindex_mon_reindex_complete

-- ���°� �� ���� �����̸�, ���� ���� ���� �� �ּ���. 
-- ������ ��� �׳� �μ���.
exec dba.dbo.up_dba_reindex_mon_reindex_job 'A'  -- ��ü JOB ���� ����

--���г� ������ ���� ���� �� , �� ��� �������� ���� ���� �� ���ø� �˴ϴ�.
exec dba.dbo.up_dba_reindex_mon_reindex_job 'F'

-- Site Close �Ǿ��µ� ���� �ǰ� �ִ� job�� �ִ��� Ȯ�� kill session �� �����ϱ� �ش� ���� ���� kill �� �ֽø��
exec dba.dbo.up_dba_reindex_mon_reindex_job 'I'

--job ���� ���� 
select N'KILL '+ CONVERT(nvarchar(10), r.session_id),  j.name 
	from sys.dm_exec_requests r
		inner join sys.dm_exec_sessions s on r.session_id = s.session_id
	--cross apply sys.dm_exec_sql_text(sql_handle) as qt
				left outer join msdb.dbo.sysjobs j
					on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
												substring(left(j.job_id,8),5,2) +
												substring(left(j.job_id,8),3,2) +
												substring(left(j.job_id,8),1,2))
	where r.session_id != @@spid and j.name in
		('[DBA] REINDEX AUTOMATION - REINDEX MOD0','[DBA] REINDEX AUTOMATION - REINDEX MOD1','[DBA] REINDEX AUTOMATION - REINDEX MOD2')
	order by r.cpu_time DESC

-- ����
--exec UP_DBA_KILL_REINDEX_PROCESS

-- job ����
SELECT   sj.name, min(sja.start_execution_date) as start_execution_date 
	, max(sja.stop_execution_date) as stop_execution_date
	, max(run_status ) as [����]
	FROM 
	 msdb.dbo.sysjobs AS sj  with(nolock)
	left join msdb.dbo.sysjobactivity AS sja   with(nolock) ON sja.job_id = sj.job_id
	left JOIN msdb.dbo.sysjobhistory as sh on sj.job_id = sh.job_id  and sh.run_date >= convert(int,convert(nvarchar(8), getdate(),112))
where sj.name like '%REINDEX AUTOMATION - REINDEX MOD%'
group by  sj.name
--having   max(sja.stop_execution_date) is null
