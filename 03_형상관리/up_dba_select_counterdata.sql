/*************************************************************************  
* ���ν�����   : up_dba_select_counterdata 
* �ۼ�����     : 2010-03-04 by ���
* ������Ű��   : 
* ����         : ���ɸ���� ������ ��������
* ��������     : 
* ���� ����    : up_dba_select_counterdata 0
							 	 2010-05-10 by �ֺ��� PK ������ ���� InstanceName �� ���� �߰�
**************************************************************************/  
CREATE  proc up_dba_select_counterdata
@vparam int
as
begin

SET NOCOUNT ON
SET FMTONLY OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED



if (@vparam >= 24 or @vparam < 0)
	begin
	print 'check Param'
	return
end


declare @startDate smalldatetime, @endDate smalldatetime, @basic_dt smalldatetime
set @basic_dt = convert( varchar(10),  getdate()-1, 121) + ' 00:00:00'      --2010-03-07 00:00:00


select @startDate  = dateadd(hh, @vparam, convert(datetime, @basic_dt ))
select @endDate  =  dateadd(hh, @vparam+1, convert(datetime, @basic_dt))
--select @basic_dt, @startdate, @enddate

--��ũ�弭�� ���λ��
select tcdt.ID as ID
			,convert(char(10), convert(datetime,convert(varchar(19) , scd.counterdatetime, 121)), 121) as CounterDate
		  ,convert(char(8), convert(datetime,convert(varchar(19) , scd.counterdatetime, 121)), 108) as CounterTime
			,convert(float(8), scd.CounterValue) as CounterValue
from  PerfLogs.dbo.CounterDetails scdt with(nolock) 
		join PerfLogs.dbo.CounterData scd with(nolock) on   scdt.CounterID = scd.CounterID 
		join dbadb1.perflogs.dbo.CounterDetailsAll tcdt with(nolock) 
			on   scdt.MachineName = tcdt.MachineName and scdt.CounterName = tcdt.CounterName
				and scdt.InstanceName = tcdt.InstanceName
where  convert(datetime,convert(varchar(19) , scd.counterdatetime, 121))  >= @startDate
		and convert(datetime,convert(varchar(19) , scd.counterdatetime, 121)) < @endDate
order by convert(datetime,convert(varchar(19) , scd.counterdatetime, 121)) desc






---- SSIS�������λ��
--select	
----top 100
--  --cdt.CounterID
--cdt.MachineName
--, cdt.CounterName
--, convert(char(10), convert(datetime,convert(varchar(19) , cd.counterdatetime, 121)), 121) as CounterDate
--, convert(char(8), convert(datetime,convert(varchar(19) , cd.counterdatetime, 121)), 108) as CounterTime
--, convert(float(8), cd.CounterValue) as CounterValue
--from  PerfLogs.dbo.CounterDetails cdt with(nolock) join PerfLogs.dbo.CounterData cd with(nolock)
--		on cdt.CounterID = cd.CounterID
--		where  convert(datetime,convert(varchar(19) , cd.counterdatetime, 121))  >= @startDate  
--		and convert(datetime,convert(varchar(19) , cd.counterdatetime, 121)) < @enddate


--order by cdt.MachineName, cdt.CounterName

end





