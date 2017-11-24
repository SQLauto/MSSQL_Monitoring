/*  
exec dbo.up_DBA_findjob 'J', '%종합%'  
*/  
CREATE proc dbo.up_DBA_findjob  
 @gubun char(1) = 'S'   
, @name  nvarchar(100)  
as  
  
set nocount on  
  
if @gubun = 'S' begin  
 select j.name as JOB이름  
 ,  command  as 실행스크립트  
 from msdb.dbo.sysjobsteps s with(nolock)   
  inner join msdb.dbo.sysjobs j with(nolock) on s.job_id = j.job_id  
 where command like @name  
end  
else begin  
 select  top 30   
    j.name as JOB이름  
 ,   js.step_name as 단계  
 ,   case jh.run_status   
     when 0 then '실패'  
     when 1 then '성공'  
     when 2 then '재시도'  
     when 3 then '취소'  
     when 4 then '진행중'  
    end as 상태  
 ,   run_date as 날짜  
 ,   tiger.dbo.lpad(cast(run_time as varchar), 6, '0')  as 시분초  
 ,   jh.run_duration as 걸린시간  
 ,   jh.message as 메시지  
 ,   js.command as SP이름  
 from msdb.dbo.sysjobhistory jh with(nolock)  
  inner join msdb.dbo.sysjobs j with(nolock) on jh.job_id = j.job_id  
  inner join msdb.dbo.sysjobsteps js with(nolock) on js.job_id = j.job_id  
 where j.name like @name  
 order by run_date + run_time desc  
end  
  