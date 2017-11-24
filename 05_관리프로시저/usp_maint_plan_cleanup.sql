use msdb
go
--drop proc usp_maint_plan_cleanup
create procedure usp_maint_plan_cleanup 
	@simpleplan varchar(128) = 'NoPlan',
	@fullplan varchar(128) = 'NoPlan',
	@excluded varchar(128) = ''
as
/*****************************************************************
*** SQL Server Maintenance Plan Cleanup and Audit
*** Procedure  : usp_maint_plan_cleanup 

*** Usage:	1.)  usp_maint_plan_cleanup @simpleplan = 'Simple Databases', @fullplan = 'Full Databases'
		2.)  usp_maint_plan_cleanup @simpleplan = 'Simple Databases', @fullplan = 'Full Databases', @excluded = 'Test Databases'

*** Description: Checks all databases and assigns them to a plan based on recovery mode
*** Input  : 	@simpleplan - REQUIRED - the name of the simple mode maintenance plan
		@fullplan - REQUIRED - the name of the full mode maintenance plan
		@excluded - OPTIONAL - the name of the plan that has databases that should not be in either
		of the above

*** Output : Outputs the results of the audit after cleanup
*** Revision: 1.1  (Fixed the audit section to use FQN and removed go statements)
*** Revision History: 1.0 First Release
*** Author/: Sean Gorman
*** Date: 8/22/2006
*** Notes:  Creates table dbo.Maintenance_Plan_Audit which is used to store audit data
******************************************************************/

/*  LOADS UP THE VARIABLES FOR A MANUAL RUN OF THE CODE - IGNORE UNLESS RUNNING OUTSIDE OF PROC
declare @simpleplan varchar(128)
, @fullplan varchar(128)

enter name of simple recovery plan here 
--set @simpleplan = 'Simple Databases'

enter name of full recovery plan here 
--set @fullplan = 'Full Databases'
 
enter plan which has databases that should NOT belong to the simple or full job
set to '' to ignore this   
--set @excluded = 'Test Databases'
*/


declare @simpleplanid varchar(128)
declare @fullplanid varchar(128)
declare @dbname varchar(128), @dbid smallint
declare @action varchar(50)
declare @currentplanid varchar(128), @currentplan varchar(128)

if @simpleplan = 'NoPlan'
	set @simpleplanid = 'NoPlan'
else
	If exists (select 1 from msdb..sysdbmaintplans where plan_name = @simpleplan)
		select @simpleplanid = plan_id
		from msdb..sysdbmaintplans 
		where plan_name = @simpleplan
	else
		begin
			print 'Simple Plan does not exist'
			goto error
		end

if @fullplan = 'NoPlan'
	set @fullplanid = 'NoPlan'
else
	If exists (select 1 from msdb..sysdbmaintplans where plan_name = @fullplan)
		select @fullplanid = plan_id
		from msdb..sysdbmaintplans 
		where plan_name = @Fullplan
	else
		begin
			print 'Full Plan does not exist'
			goto error
		end

-- Determine whether plan(s) is for all databases. If so, only verify that all databases use same recovery model
if exists(select 1 from msdb..sysdbmaintplan_databases where database_name = 'All User Databases')
		select @action = 'Verify_model'
	else
		select @action = 'Verify_databases'

If not exists (select 1 from msdb..sysobjects where name = 'MaintPlan_Changes' and xtype = 'U')
	create table msdb.dbo.MaintPlan_Changes 
		(DBName varchar(128),
		 TStamp datetime, 
		 Change	Varchar(1024),
		 MPName varchar(128))

-- Log deletion of non existent databases from MaintPlan
Insert into msdb..maintplan_changes (dbname, tstamp, change,mpname )
select database_name, getdate(), 'Non Existent Database removed', plan_name
from master..sysdatabases sd
right outer join msdb..sysdbmaintplan_databases mpd
on sd.name = mpd.database_name
inner join msdb..sysdbmaintplans mp
on mp.plan_id = mpd.plan_id
where sd.name is null
and mpd.database_name not in ('All User Databases','All System Databases')

--Deletion of non existent databases from MaintPlan
delete from msdb..sysdbmaintplan_databases
where database_name not in (select name from master..sysdatabases) 
and database_name not in ('All User Databases','All System Databases')

-- Loop through all user databases
declare dbnamecur cursor for
select [name], dbid as server from master.dbo.sysdatabases
where [name] not in ('master','tempdb','model','msdb','distribution')

open dbnamecur
fetch next from dbnamecur into
@dbname, @dbid

while @@fetch_status = 0
begin 

--Check whether database is in a plan
if not exists (select 1 from msdb..sysdbmaintplan_databases where database_name = @dbname)
	-- Check whether database is covered by wildcard in plan definition
	if @action = 'Verify_Databases'
		-- Check whether database is in exclusion list
		if @excluded not like ('%' + @dbname + '%')
			-- Determine which plan, based on recovery model
			if (select databasepropertyex(@dbname, 'recovery')) = 'full'
				begin
					-- Log and add to full plan
					Insert into msdb..maintplan_changes (dbname, tstamp, change,mpname )
					values (@dbname, getdate(), 'Added database to Full Recovery Plan',@fullplan)

					insert msdb.dbo.sysdbmaintplan_databases
					values (@fullplanid, @dbname)
				end
			else 
				if (select databasepropertyex(@dbname, 'recovery')) = 'simple'
					begin
						-- Log and add to simple plan
						Insert into msdb..maintplan_changes (dbname, tstamp, change,mpname )
						values (@dbname, getdate(), 'Added database to Simple Recovery Plan',@simpleplan)

						insert msdb.dbo.sysdbmaintplan_databases
						values (@simpleplanid, @dbname)
					end
				else
					-- Note that database was not added to plan, due to recovery mode
					Insert into msdb..maintplan_changes (dbname, tstamp, change,mpname )
					values (@dbname, getdate(), 'Database in Bulk Recovery','Bulk Recovery')
		else 
					-- Note that database was excluded manually and not added to plan
					Insert into msdb..maintplan_changes (dbname, tstamp, change,mpname )
					values (@dbname, getdate(), 'Database Excluded','Excluded')
	else -- In plan under all databases, Check for right plan
		Begin
			set @currentplanid = null
			set @currentplan = null
			select @currentplanid = mpd.plan_id, @currentplan = plan_name
			from msdb..sysdbmaintplan_databases mpd
			inner join msdb..sysdbmaintplans mp
			on mp.plan_id = mpd.plan_id
			where database_name = 'All User Databases'

			if (@currentplanid = @fullplanid) and (databasepropertyex(@dbname, 'recovery') <> 'full')
				Insert into msdb..maintplan_changes (dbname, tstamp, change,mpname )
				values (@dbname, getdate(), 'MANUAL FIX - Wrong Plan ',@currentplan)

			if (@currentplanid = @simpleplanid) and (databasepropertyex(@dbname, 'recovery') <> 'simple')
				Insert into msdb..maintplan_changes (dbname, tstamp, change,mpname )
				values (@dbname, getdate(), 'MANUAL FIX - Wrong Plan ',@currentplan)

		End
else -- In Plan, check for right plan
	Begin
		set @currentplanid = null
		set @currentplan = null
		select @currentplanid = mpd.plan_id, @currentplan = plan_name
		from msdb..sysdbmaintplan_databases mpd
		inner join msdb..sysdbmaintplans mp
		on mp.plan_id = mpd.plan_id
		where database_name = @dbname

		if (@currentplanid = @fullplanid) and (databasepropertyex(@dbname, 'recovery') <> 'full')
			Begin
				Insert into msdb..maintplan_changes (dbname, tstamp, change,mpname )
				values (@dbname, getdate(), 'Wrong plan - Not Full ',@currentplan)
			
				Delete from msdb..sysdbmaintplan_databases 
				where database_name = @dbname and plan_id = @currentplanid

				Insert msdb..sysdbmaintplan_databases (plan_id, database_name)
				values (@simpleplanid, @dbname)

			end
		if (@currentplanid = @simpleplanid) and (databasepropertyex(@dbname, 'recovery') <> 'simple')
			Begin
				Insert into msdb..maintplan_changes (dbname, tstamp, change,mpname )
				values (@dbname, getdate(), 'Wrong plan - Not Simple',@currentplan)

				Delete from msdb..sysdbmaintplan_databases 
				where database_name = @dbname and plan_id = @currentplanid

				Insert msdb..sysdbmaintplan_databases (plan_id, database_name)
				values (@fullplanid, @dbname)
			End
	End


fetch next from dbnamecur into
@dbname, @dbid

end
close dbnamecur
deallocate dbnamecur

error:
GO