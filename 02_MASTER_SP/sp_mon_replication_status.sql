/*************************************************************************                
* ���ν�����  : dbo.sp_mon_replication_status               
* �ۼ�����    : 2009-06-15  �μ�ȯ                
* ����������  :                
* ����        : ���� ������Ʈ ���    
* ��������    : 2009-12-07 �ֺ��� agent_id �߰�             
**************************************************************************/      
  CREATE PROCEDURE sp_mon_replication_status  
AS  
set nocount on  
declare @v_agentid_table table (  
 i int identity(1,1) primary key,  
 agent_id int);  
  
declare @v_repl_hist table(
 agent_id   int,  
 agent_name nvarchar(100) primary key,  
 runstatus nvarchar(10),  
 [time]  datetime,  
 delivery_latency int,  
 comments nvarchar(4000),  
 duration int,  
 delivery_rate float,  
 delivered_transactions int,  
 delivered_commands int,  
 average_commands int,  
 error_id int,  
 current_delivery_rate float,  
 current_delivery_latency int,  
 total_delivered_commands int);  
  
declare @vloop int  
set @vloop = 1  
insert into @v_agentid_table (agent_id)  
select  
 agent.id agent_id  
from msdb.dbo.sysjobs job with (nolock)  
inner join Distribution.dbo.MSdistribution_agents agent with (nolock)  
 on job.name = agent.name  
  
while (@vloop <= (select max(i) from @v_agentid_table))  
begin  
insert into @v_repl_hist  
select top 1  
     temp.agent_id,
     agent.name,  
     case hist.runstatus when 1 then '����'  
          when 2 then '����'  
          when 3 then '������'  
          when 4 then '���޻���'  
          when 5 then '�ٽýõ�'  
          when 6 then '����' end runstatus,  
     'time' = sys.fn_replformatdatetime(time),  
     hist.delivery_latency,  
     hist.comments,  
     hist.duration,  
     hist.delivery_rate,  
     hist.delivered_transactions,  
     hist.delivered_commands,  
     hist.average_commands,  
     hist.error_id,  
     hist.current_delivery_rate,  
     hist.current_delivery_latency,  
     hist.total_delivered_commands  
from msdb.dbo.sysjobs job with (nolock)  
    inner join Distribution.dbo.MSdistribution_agents agent with (nolock)  
     on job.name = agent.name  
    inner join Distribution.dbo.MSdistribution_history hist with (nolock)  
     on agent.id = hist.agent_id  
    inner join @v_agentid_table temp  
     on agent.id = temp.agent_id  
where temp.i = @vloop  
order by hist.timestamp desc, hist.delivery_latency desc
 set @vloop = @vloop + 1  
end;  
  
select @@servername as distribute_server_name , * from @v_repl_hist  
order by delivery_latency desc 

