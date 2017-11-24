drop table LOG_KILLED_PROCESS
CREATE TABLE LOG_KILLED_PROCESS
(
 SEQ		BIGINT IDENTITY(1,1) NOT NULL,	
 REG_DATE	DATETIME  NOT NULL,
 EVENT_TYPE	VARCHAR(20)  NOT NULL, 
 DATABASE_NAME	SYSNAME NOT NULL, 
 USER_NAME		SYSNAME NOT NULL,
 ISSYSADMIN		BIT NOT NULL,
 KILL_YN		CHAR(1) NOT NULL, 
 RESTORE_YN		CHAR(1) NULL
)
ALTER TABLE LOG_KILLED_PROCESS  ADD CONSTRAINT PK__LOG_KILLED_PROCESS__SEQ  PRIMARY KEY NONCLUSTERED ( SEQ ) WITH (DATA_COMPRESSION = PAGE) 
CREATE CLUSTERED INDEX CIDX__LOG_KILLED_PROCESS__DATABASE_NAME___REG_DATE  ON LOG_KILLED_PROCESS ( DATABASE_NAME, REG_DATE ) WITH(DATA_COMPRESSION = PAGE)
GO

drop proc up_DBA_ProcessKill 
go

/*************************************************************************  
* 프로시저명: dbo.up_DBA_ProcessKill
* 작성정보	: 2016-08-22  최보라
* 관련페이지:  
* 내용		: 

* 수정정보	: 
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_ProcessKill
	@EVENT_TYPE  VARCHAR(20) = 'RESTORE', 
	@DATABASE_NAME sysname,
	@KILL_YN  char(1) ='Y'
AS

/* COMMON DECLARE */
SET NOCOUNT ON 
SET ANSI_WARNINGS OFF

/* USER DECLARE  */
 declare  @spid  smallint, @loginname sysname,  @loginname_before sysname , @str  varchar(2000) , @issysadmin bit 
/*BODY*/

IF @KILL_YN ='Y'
BEGIN

	 set @loginname_before = ''
	 select a.spid ,rtrim(a.loginame) as loginame , b.sysadmin as issysadmin into  #spid_user                     
	 from master.dbo.sysprocesses AS A 
			join master.dbo.syslogins   as b  on a.loginame = b.name                      
	 where dbid=db_id(@DATABASE_NAME) and cmd not like 'restore log%'                 
	 and spid > 50
	 order by loginame


	 declare spid_cursor cursor                           
	 for select spid , loginame, issysadmin  from #spid_user for read only                          
	 open spid_cursor                          
              
	 fetch next from spid_cursor into @spid ,  @loginname , @issysadmin
                 
	  while @@fetch_status = 0                          
	 begin                         
 
	  set @str = 'kill ' + convert (char(5), @spid)              
	  execute (@str)              
  

	  if @loginname_before !=@loginname

		  insert into LOG_KILLED_PROCESS
		  (event_type, database_name, user_name, issysadmin,  kill_yn , reg_date)
		  values 
		  (@event_type, @database_name, @loginname,  @issysadmin, 'Y', getdate())
  
	  begin try
	  
	  if @loginname not like 'ebaykorea%'
	  begin
		exec sp_droprolemember 'db_datareader', @loginname
	  end
	  else if @loginname like 'ebaykorea%'
	  begin
		exec sp_droprolemember 'NPI_GROUP', @loginname
	  end
	 end try 
	 begin catch
		if ERROR_NUMBER ( )  =15151 
			print '권한 없음'
	 end catch 
  
	  set @loginname_before = @loginname
	  fetch next from spid_cursor into @spid , @loginname  ,@issysadmin       
	 end              
                         
	 close spid_cursor                          
	 deallocate spid_cursor                          
    
	drop table #spid_user
END
ELSE IF @KILL_YN ='N' -- 복원 필요 
BEGIN
	declare spid_cursor cursor  
	for 	
	select rtrim(user_name)
	from log_killed_process with(nolock)
	where database_name = @database_name  and kill_yn='Y' and reg_date >= convert(date, getdate())  and reg_date < convert(date, getdate()+1)
	and issysadmin  = 0
	group by user_name
	
	open spid_cursor    

	 fetch next from spid_cursor into  @loginname 
	 while @@fetch_status = 0                          
	 begin   
		if @loginname not like 'ebaykorea%'
		begin
		 	set @str = 'use ' + @database_name + char(10)
		    + 'exec sp_addrolemember ''db_datareader'', ''' + rtrim(@loginname) + ''''
		  print @str
		  execute (@str)     
		end
	
	   else if @loginname like 'ebaykorea%'
	   begin
		 set @str = 'use ' + @database_name + char(10)
		      + 'exec sp_addrolemember ''npi_group'', ''' + rtrim(@loginname) + ''''
		 print @str
		 execute (@str)     
	   end
	        
	
	  set @str = ''
	  fetch next from spid_cursor into  @loginname 
     end

	  close spid_cursor                          
	  deallocate spid_cursor          

	    
END

