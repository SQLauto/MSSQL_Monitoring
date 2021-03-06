USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_dba_get_perfmonlocal_check]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
up_dba_get_perfmonlocal_check 'gcontentsdb01',  'gcontentsdb02', 'GCONTENTSDB-CLU', 'MSSQL Server'
go
up_dba_get_perfmonlocal_check 'pastdb01',  'pastdb02', 'PASTDB-CLUS', 'SQL Server (MSSQLSERVER)'
*/

CREATE procedure [dbo].[up_dba_get_perfmonlocal_check]
  @node1 varchar(50)
, @node2 varchar(50)
, @clust_name varchar(50)
, @cust_group varchar(50) 
as

set nocount on

DECLARE @temp TABLE(seq int identity(1,1), col1 nvarchar(255))

declare @cmd1 varchar(1024), @cmd2 varchar(1024), @cmd3 varchar(1024)
declare @cluster_owners_node sysname
declare @perfmon_owners_node sysname
set @cluster_owners_node  =  'false'
set @perfmon_owners_node = 'false'

set @cmd1  = '''logman -s ' + @node1+ ' query | findstr "DB_MON_PERF"'''  
set @cmd2  = '''logman -s ' + @node2+ ' query | findstr "DB_MON_PERF"'''  
--set @cmd3 =  '''CLUSTER ' +@clust_name + ' GROUP "' + @cust_group + '" /STATUS | findstr "' +@cust_group +  '"'''  
set @cmd3 =  '''CLUSTER ' +@clust_name + ' GROUP "' + @cust_group + '" /STATUS | findstr 온라인'''  


--성능수집상태 변수에 저장
insert into @temp exec('xp_cmdshell ' + @cmd1)  
	if exists ( select col1 from @temp where col1 is not null and seq <= 1)
		begin
		print 'node1'
		set @perfmon_owners_node = @node1
		end
insert into @temp exec('xp_cmdshell ' + @cmd2)  
    if exists ( select col1 from @temp where col1 is not null and seq > 1)
		begin
			print 'node2'
			set @perfmon_owners_node = @node2
		end
		
insert into @temp exec('xp_cmdshell ' + @cmd3)  

if exists ( select col1 from @temp where col1 like  '%' + @node1 + '%')
	begin
	    print  'LINE55'
		set @cluster_owners_node = @node1
	end
else if exists( select col1 from @temp where col1 like  '%' + @node2+ '%')
begin
       print 'LINE60'
		set @cluster_owners_node = @node2
end 


select top 1 seq as seq
, @@SERVERNAME AS sql_svr_name
, col1 as text
, @perfmon_owners_node as perfmon_owners_node
, @cluster_owners_node as cluster_owners_node
, convert(char(19), getdate(), 121) as reg_dt 
from @temp
where col1 is not null 






GO
