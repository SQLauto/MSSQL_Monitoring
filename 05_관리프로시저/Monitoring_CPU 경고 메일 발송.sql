SET NOCOUNT ON

DECLARE @TimeNow bigint 

SELECT @TimeNow = cpu_ticks / convert(float, ms_ticks) 
from sys.dm_os_sys_info 


-- Collect Data from DMV
Select record_id 
	 ,getdate() as EventTime
	--, dateadd(ss ,  -1 *  (@TimeNow - [timestamp])  , GetDate())  EventTime
    , SQLSvcUtilization
	, SystemIdle 
	,(100 - SystemIdle - SQLSvcUtilization) AS OtherOSProcessUtilization 
into #tempCPURecords
from ( select record.value('(./Record/@id)[1]', 'int')record_id
		,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]','int') AS SystemIdle
		,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]','int') AS SQLSvcUtilization
		,timestamp 
from ( select timestamp, convert(xml, record)record 
		from sys.dm_os_ring_buffers 
		where ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
		and record like '%<SystemHealth>%')x )y  
order by record_id desc

-- To send detailed sql server session reports consuming high cpu
-- For a dedicated SQL Server you can monitor 'SQLProcessUtilization' 
-- if (select avg(SQLSvcUtilization) from #temp where EventTime>dateadd(mm,-5,getdate()))>=80
-- For a Shared SQL Server you can monitor 'SQLProcessUtilization'+'OtherOSProcessUtilization'




if (select avg(SQLSvcUtilization+OtherOSProcessUtilization) 
from #tempCPURecords) >=10
begin

		print 'CPU Alert Condition Ture, Sending Email..'
		DECLARE @tableHTML  NVARCHAR(MAX) ;

			SET @tableHTML =
				N'<H1>High CPU Utilization Reported</H1>' +
				N'<H2>SQL Server Session Details</H2>' +
				N'<table border="1">' +
				N'<tr><th>SPID</th><th>Status</th><th>Login</th><th>Host</th><th>BlkBy</th>'+
			N'<th>DatabaseID</th><th>CommandType</th><th>SQLStatement</th><th>ElapsedMS</th>'+
			N'<th>CPUTime</th><th>IOReads</th><th>IOWrites</th><th>LastWaitType</th>'+
			N'<th>StartTime</th><th>Protocol</th><th>ConnectionWrites</th>'+
			N'<th>ConnectionReads</th><th>ClientAddress</th><th>Authentication</th></tr>'+
			CAST ( ( SELECT  TOP 50 -- or all by using *
			td= er.session_id,'',
			td= ses.status,'',
			td= ses.login_name,'',  
			td= ses.host_name,'',   
			td= er.blocking_session_id,'',  
			td= er.database_id,'',  
			td= er.command,'',  
			td= st.text,'',  
			td= er.total_elapsed_time,'',  
			td= er.cpu_time,'',  
			td= er.reads,'',  
			td= er.writes,'',  
			td= er.last_wait_type,'',  
			td= er.start_time,'',  
			td= con.net_transport,'',  
			td= con.num_writes,'',  
			td= con.num_reads,'',  
			td= con.client_net_address,'',  
			td= con.auth_scheme,''  
			FROM sys.dm_exec_requests er  
			OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) st  
			LEFT JOIN sys.dm_exec_sessions ses  
			ON ses.session_id = er.session_id  LEFT JOIN sys.dm_exec_connections con  
			ON con.session_id = ses.session_id  
			WHERE er.session_id > 50  
			ORDER BY er.cpu_time DESC ,er.blocking_session_id
			FOR XML PATH('tr'), TYPE 
			)AS NVARCHAR(MAX))+
			N'</table>' 


		-- Change SQL Server Email notification code here
		EXEC msdb.dbo.sp_send_dbmail 
		@recipients='bochoi@ebay.com',
		--@profile_name = 'SQLProfileName',    
		@subject = 'ServerName:Last 5 Minutes Avg CPU Utilization Over 10%',
		@body = @tableHTML,
		@body_format = 'HTML';
END


-- Drop the Temporary Table
DROP Table #tempCPURecords


exec sp_mon_execute
select * from sys.sysprocesses where spid = 144

--KILLED/ROLLBACK 

-- batch time, 
-- cmd 값이 있으면 좋겠다. 
