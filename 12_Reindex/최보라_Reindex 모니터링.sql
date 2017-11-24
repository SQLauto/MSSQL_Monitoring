use dba
go

-- 상태가 미 실행 상태이면, 서버 들어가서 실행 해 주세요. 
-- 에러날 경우 그냥 두세요.
exec dba.dbo.up_dba_reindex_mon_reindex_job 'A'  -- 전체 JOB 실행 상태

--실패난 서버만 보고 싶을 때 , 이 경우 서버가서 실행 직접 해 보시면 됩니다.
exec dba.dbo.up_dba_reindex_mon_reindex_job 'F'

-- Site Close 되었는데 실행 되고 있는 job이 있는지 확인 kill session 가 나오니까 해당 서버 가서 kill 해 주시면됨
exec dba.dbo.up_dba_reindex_mon_reindex_job 'I'


--job 실행 정보 
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




/** Reindx 진행 사항 */

--INDEX REINDEX 대기 건
SELECT * FROM dba.dbo.DBA_REINDEX_TARGET_LIST A WITH(NOLOCK)

SELECT b.target_seq %3 as mod, * 
FROM dba.dbo.DBA_REINDEX_TARGET_LIST A WITH(NOLOCK)
INNER JOIN dba.dbo.DBA_REINDEX_MOD_META B WITH(NOLOCK) ON A.TARGET_SEQ = B.TARGET_SEQ

-- 지금 진행하고 있는 Index
exec dba.dbo.up_dba_reindex_mon_reindex_ing

--전체 통계
exec dba.dbo.up_dba_reindex_mon_reindex

-- 전체 내역 List 상세
exec dba.dbo.up_dba_reindex_mon_reindex_detail

--완료된 내역 
exec dba.dbo.up_dba_reindex_mon_reindex_complete

-- 상태가 미 실행 상태이면, 서버 들어가서 실행 해 주세요. 
-- 에러날 경우 그냥 두세요.
exec dba.dbo.up_dba_reindex_mon_reindex_job 'A'  -- 전체 JOB 실행 상태

--실패난 서버만 보고 싶을 때 , 이 경우 서버가서 실행 직접 해 보시면 됩니다.
exec dba.dbo.up_dba_reindex_mon_reindex_job 'F'

-- Site Close 되었는데 실행 되고 있는 job이 있는지 확인 kill session 가 나오니까 해당 서버 가서 kill 해 주시면됨
exec dba.dbo.up_dba_reindex_mon_reindex_job 'I'

--job 실행 정보 
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

-- 중지
--exec UP_DBA_KILL_REINDEX_PROCESS

-- job 상태
SELECT   sj.name, min(sja.start_execution_date) as start_execution_date 
	, max(sja.stop_execution_date) as stop_execution_date
	, max(run_status ) as [상태]
	FROM 
	 msdb.dbo.sysjobs AS sj  with(nolock)
	left join msdb.dbo.sysjobactivity AS sja   with(nolock) ON sja.job_id = sj.job_id
	left JOIN msdb.dbo.sysjobhistory as sh on sj.job_id = sh.job_id  and sh.run_date >= convert(int,convert(nvarchar(8), getdate(),112))
where sj.name like '%REINDEX AUTOMATION - REINDEX MOD%'
group by  sj.name
--having   max(sja.stop_execution_date) is null
