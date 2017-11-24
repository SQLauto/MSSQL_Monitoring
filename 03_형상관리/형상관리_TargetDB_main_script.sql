use dba
-- 옥션의 경우 dbadmin
go

CREATE TABLE vlfcnt_working
( 
	dbname nvarchar (128)   NULL   , 
	vlf_count int    NULL   , 
	stat2_count int    NULL   , 
	server_id int    NULL   , 
	instance_id int    NULL  
)  ON [PRIMARY]
GO


CREATE TABLE SQL_LOG
( 
SQL_LOG text    NULL  
)  ON [PRIMARY]
GO

CREATE TABLE dbo.DB_IDENTITY_TABLE
(
	seq int identity(1,1) NOT NULL
,	db_name sysname NOT NULL
,	db_id int NOT NULL
,	table_name sysname NOT NULL
,	column_name sysname NOT NULL
,   current_value int 
,	reg_dt datetime default(getdate()) NOT NULL
	CONSTRAINT [PK__DB_IDENTITY_TABLE__SEQ] PRIMARY KEY CLUSTERED 
	(
		[seq] ASC
	)
)


--up_dba_select_disksize
--up_dba_select_database_info
--up_dba_select_databasefilelist
--up_dba_select_table_size
--up_conf_JobInfoCollect
--up_dba_select_autogrowth_info
--up_conf_BackupHistoryCollect
-- up_dba_select_vlf_info
--UP_DBA_COLLECT_IDENTITY_TABLE_INDB
--UP_DBA_COLLECT_IDENTITY_TABLE


/*************************************************************************  
* 프로시저명  : dbo.UP_DBA_COLLECT_IDENTITY_TABLE 
* 작성정보    : 2012-09-27 서은미
* 관련페이지  :  
* 내용       : 각 서버에 10억건 이상 초과하는 identity 정보를 수집하여 dbadb1 형상관리 서버에 현황정보를 리포팅한다.
* 수정정보    :
**************************************************************************/
CREATE PROC [dbo].[UP_DBA_COLLECT_IDENTITY_TABLE]
	@base_value INT = '1000000000'
AS
SET NOCOUNT ON  

TRUNCATE TABLE dbo.DB_IDENTITY_TABLE 

DECLARE @db sysname 
DECLARE DBCursor CURSOR FOR  
    SELECT name db
      FROM sys.databases WITH (NOLOCK) 
     WHERE database_id > 4 
     ORDER BY name
 
OPEN DBCursor;  
FETCH DBCursor into @db;  
   
WHILE @@FETCH_STATUS = 0 
	BEGIN 
		EXEC  dbo.UP_DBA_COLLECT_IDENTITY_TABLE_INDB @db, @base_value;
		FETCH DBCursor into @db;    
	END
CLOSE DBCursor;  
DEALLOCATE DBCursor;  

SELECT db_name, db_id, table_name, column_name, current_value, reg_dt 
FROM DB_IDENTITY_TABLE WITH(NOLOCK)
ORDER BY seq
GO

/*************************************************************************  
* 프로시저명  : dbo.UP_DBA_COLLECT_IDENTITY_TABLE_INDB 
* 작성정보    : 2012-09-27 서은미
* 관련페이지  :  
* 내용       : 각 서버에 10억건 이상 초과하는identity 정보를 수집하여 dbadb1 형상관리 서버에 현황정보를 리포팅한다.
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.UP_DBA_COLLECT_IDENTITY_TABLE_INDB
     @db      SYSNAME
,	 @base_value INT = '1000000000'
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @sql            nvarchar(max)
DECLARE @table_name        nvarchar(512)
DECLARE @current_value     int
CREATE TABLE #CURRENT_IDENTITY 
(      
	table_name sysname
,	column_name	sysname
,	current_value int 
)

/* BODY */
DELETE dbo.DB_IDENTITY_TABLE 
WHERE REG_DT >= convert(date,GETDATE()) and REG_DT < convert(date,GETDATE()+1) and db_name = @db;

SELECT @sql = '   
				INSERT INTO #CURRENT_IDENTITY (table_name, column_name)
				SELECT UPPER(o.name), UPPER(c.name)
				FROM ['+ @db +'].sys.columns  as c WITH (NOLOCK)
					   INNER JOIN ['+ @db +'].sys.tables as o WITH (NOLOCK) ON c.object_id = o.object_id
				WHERE c.is_identity = 1 and  type_name(c.user_type_id) = ''int''
				ORDER BY o.name'

EXEC (@sql)  


DECLARE cur_current CURSOR FOR
   SELECT table_name FROM #CURRENT_IDENTITY order by table_name
       
OPEN cur_current
FETCH NEXT FROM cur_current
INTO @table_name

WHILE @@FETCH_STATUS = 0
BEGIN		
		SET @sql = N'use ' + @db + ' SELECT @current = convert(int, IDENT_CURRENT('''+ @table_name +''') )'
		
		exec sp_executesql @sql, N'@current int output', @current =@current_value output

		UPDATE #CURRENT_IDENTITY SET current_value = @current_value where table_name = @table_name
		
		FETCH NEXT FROM cur_current
    INTO @table_name
END

CLOSE cur_current
DEALLOCATE cur_current


INSERT DBO.DB_IDENTITY_TABLE(db_name, db_id, table_name, column_name, current_value)
SELECT @db, db_id(@db), table_name, column_name, current_value
FROM #CURRENT_IDENTITY
WHERE current_value > @base_value
ORDER BY table_name

DROP TABLE #CURRENT_IDENTITY
GO



--=========================================================================
--DBADB1 수집 테이블 정보(형상관리 package에서 수집함, 3개월 보관, 파티션 필요)
--=========================================================================

CREATE PARTITION FUNCTION [PF_DB_IDENTITY_TABLE_REG_DT](date) AS RANGE RIGHT FOR VALUES (N'2012-09-01T00:00:00.000', N'2012-10-01T00:00:00.000',  N'2012-11-01T00:00:00.000')
GO

CREATE PARTITION SCHEME [PS_DB_IDENTITY_TABLE_REG_DT] AS PARTITION [PF_DB_IDENTITY_TABLE_REG_DT] TO ([PRIMARY], [PRIMARY], [PRIMARY], [PRIMARY])
GO

CREATE TABLE DB_IDENTITY_TABLE
(
	seq int identity(1,1) NOT NULL
,	server_id int NOT NULL
,	db_name sysname NOT NULL
,	db_id int NOT NULL
,	table_name sysname NOT NULL
,	column_name sysname NOT NULL
,   current_value int 
,	reg_dt date default(getdate()) NOT NULL
) ON [PS_DB_IDENTITY_TABLE_REG_DT]([reg_dt])
GO

ALTER TABLE DB_IDENTITY_TABLE ADD CONSTRAINT [PK__DB_IDENTITY_TABLE__SEQ] PRIMARY KEY CLUSTERED 
(
	[seq] ASC,
	[reg_dt] ASC
) ON [PS_DB_IDENTITY_TABLE_REG_DT]([reg_dt])
GO



/*************************************************************************    
* 프로시저명  : dbo.up_dba_select_database_info  
* 작성정보    : 2010-02-16 by 노상국  
* 관련페이지  :    
* 내용        : DB정보 가져오기 sql2000, 2005 통합   
* 수정정보    :  
dbo.up_dba_select_database_info 1, 1  
**************************************************************************/  
CREATE PROC dbo.up_dba_select_database_info   
    @server_id          int,  
    @instance_id        int  
  
AS  
/* COMMON DECLARE */  
SET NOCOUNT ON  
SET FMTONLY OFF --ssis 에서 #temp 사용가능 옵션  
  
/* USER DECLARE */  
DECLARE @version    int  
  
/* BODY */  
  
SET @version =  convert(int, left( convert(nvarchar(10), serverproperty('productversion')), 1))  
  
IF @version > 8 -- 2005  
  
BEGIN    
  select   
   @server_id as server_id  
   , @instance_id as instance_id  
   , db.database_id as dbid  
   , convert(nvarchar(128), db.name) as dbname  
   , convert(nvarchar(60) , db.state_desc) as status  
   , convert(bigint, sum(size)) * 8/1024  as dbsize  --MB  
   , db.recovery_model_desc as recovery_model_desc  
   , case dm.mirroring_role when 1 then '주 서버'   
            when 2 then '미러 서버'   
            else 'X'  end as Mirroring_role  
     
   , db.is_auto_shrink_on as is_auto_shrink_on   
   , db.is_auto_create_stats_on as is_auto_create_stats_on  
   , db.is_auto_update_stats_on as is_auto_update_stats_on  
   , convert(char(5), db.is_broker_enabled) as broker_enabled   
   , convert(char(10), db.create_date, 121) as created 
   , ISNULL(SUSER_SNAME(db.owner_sid),'-') as [dbowner] 
  from sys.databases as db with(nolock) join sys.sysaltfiles as sf with(nolock)  
         on db.database_id = sf.dbid join sys.database_mirroring as dm with(nolock)   
               on db.database_id= dm.database_id  
  group by db.database_id, db.name, db.create_date, db.state_desc, db.recovery_model_desc, db.is_auto_shrink_on  
     , db.is_auto_create_stats_on, db.is_auto_update_stats_on , db.is_broker_enabled , dm.mirroring_role, db.owner_sid
  order by db.database_id   
END  
ELSE  
 BEGIN --2000  
  select @server_id as server_id  
    , @instance_id as instance_id  
    , db.dbid as dbid  
    , convert(nvarchar(128), db.name) as dbname  
    , convert(nvarchar(60),DatabasePropertyEx(db.name,'Status')) as status  
    , convert(bigint, sum(size)) * 8/1024  as dbsize  --MB  
    , convert(nvarchar(60), DatabasePropertyEx(db.name,'Recovery')) as recovery_model_desc  
    , convert(char(9),'n/a')  as Mirroring_role  
    , convert(bit, DatabasePropertyEx(db.name,'IsAutoShrink')) as is_auto_shrink_on  
    , convert(bit, DatabasePropertyEx(db.name,'IsAutoCreateStatistics')) as is_auto_create_stats_on  
    , convert(bit, DatabasePropertyEx(db.name,'IsAutoUpdateStatistics')) as is_auto_update_stats_on  
    , convert(char(5), 'n/a') as broker_enabled  
    , convert(char(10), db.crdate, 121) as created
    , ISNULL(SUSER_SNAME(db.sid),'-') as [dbowner]
  from master..sysdatabases as db with(nolock) join master..sysaltfiles as sf with(nolock)  
    on db.dbid = sf.dbid   
  group by db.dbid, db.name, db.crdate, convert(sysname,DatabasePropertyEx(db.name,'Status'))  
      , convert(nvarchar(60), DatabasePropertyEx(db.name,'Recovery'))  
      , convert(bit, DatabasePropertyEx(db.name,'IsAutoShrink'))  
      , convert(bit, DatabasePropertyEx(db.name,'IsAutoCreateStatistics'))   
      , convert(bit, DatabasePropertyEx(db.name,'IsAutoUpdateStatistics') )  
      , db.sid
  order by db.dbid  
END  
   
RETURN
go



/*************************************************************************  
* ???ν?????  : dbo.up_dba_select_vlf_info
* ???????     : 2010-02-17 by ???
* ?????????  : 
* ????           : VLF ?????? select * from dba.dbo.vlfcnt_working ?? ???
* ????????     : sql2000, DB online???? ????????? ????
* ???? ????    : dbo.up_dba_select_vlf_info 1, 1

CREATE TABLE [dbo].[vlfcnt_working](	[dbname] [nvarchar](128) NULL,	[vlf_count] [int] NULL,	
[stat2_count] [int] NULL,	[server_id] [int] NULL,	[instance_id] [int] NULL) 

**************************************************************************/  
CREATE proc [dbo].[up_dba_select_vlf_info]
@server_id int,
@instance_id int

as


/* COMMON DECLARE */
begin

SET NOCOUNT ON
SET FMTONLY OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


/* USER DECLARE */

declare @version int
declare @idx int, @cnt int
declare @dbname		varchar(50)
declare @dbstatus		varchar(30)
declare @command		varchar(8000) 

SET @version =  convert(int, REPLACE(left( convert(nvarchar(10), serverproperty('productversion')), 2),'.','')) --sql ???? ???

/* BODY */

		declare @tbl_dbname table ( seq int identity(1, 1) primary key , dbname nvarchar(128) )  --db ?? ???? ????? ???? ????



		if @version < 9  --sql2000
			begin
				insert into @tbl_dbname(dbname) select name from master..sysdatabases with(nolock)  where dbid > 4 order by dbid;
			end
		else						--sql2005
			begin
				insert into @tbl_dbname(dbname) select name from sys.databases with(nolock) where state_desc = 'ONLINE' and database_id > 4 AND NAME NOT IN ('KIDC_SMS', 'KIDC_SMS_BACKUP') order by database_id;
			end




--		declare @vlfcnt table ( dbname nvarchar(128), vlf_count int, stat2_count int)


		if exists (    select  * from tempdb.dbo.sysobjects o  where o.xtype in ('U')    and o.id = object_id(N'tempdb..#vlftemp'))
		DROP TABLE #vlftemp;

		create table #vlftemp(   -- DB?? dbcc info() ?????? ????? ??? ??????? ?????
							fileid bigint ,
							filesize bigint ,
							startoffset bigint,
							fseqno bigint ,
							status bigint ,
							parity bigint ,
							createLSN varchar(100)
						)
	
		select @cnt = count(*) from @tbl_dbname
		set @idx = 1

		truncate table dbo.vlfcnt_working  --working ????? truncate

		while (@idx <= @cnt)
		begin
				select @dbname = dbname from @tbl_dbname where seq = @idx

			    select @dbstatus =convert(nvarchar(128), DatabasePropertyEx(@dbname, 'Status'), 1) -- online ???????? ??????
				if (@dbstatus = 'ONLINE')
					begin
						set @command = 'insert into #vlftemp execute(''dbcc loginfo(' + @dbname+')'')'

						--print @command
						execute(@command)
						declare @cnt1 int , @cnt2 int 
						select @cnt1 = count(*)
						from #vlftemp with(nolock)

						select @cnt2 = count(*)
						from #vlftemp with(nolock)
						where status = 2
						
						

						insert into dbo.vlfcnt_working(server_id, instance_id, dbname , vlf_count , stat2_count)
						values(@server_id, @instance_id, @dbname, @cnt1 , @cnt2)
--
--						insert into @vlfcnt(dbname , vlf_count , stat2_count)
--						values(@dbname, @cnt1 , @cnt2)
						
						truncate table #vlftemp

				end
				set @idx = @idx +1
			    
				
				
		end
		
--	select @server_id as server_id, @instance_id as instanceid, dbname, vlf_count, stat2_count from @vlfcnt order by dbname

return

end					
go


/*************************************************************************  
* 프로시저명  : dbo.up_dba_select_disksize 
* 작성정보    : 2010-02-10 by 최보라
* 관련페이지  :  
* 내용        : 디스크 size 정보 (sp_diskspace 변경)
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_disksize
    @server_id          int,
    @instance_id        int

AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET FMTONLY OFF

/* USER DECLARE */
DECLARE @hr int    
DECLARE @fso int    
DECLARE @letter char(1)    
DECLARE @odrive int    
DECLARE @disk_size varchar(20)    
DECLARE @MB bigint ; SET @MB = 1048576 

/* BODY */
CREATE TABLE #drives (
    letter char(1) PRIMARY KEY,    
    free_size int NULL,    
    disk_size int NULL
   )    

INSERT #drives(letter,free_size)     
EXEC master.dbo.xp_fixeddrives    
    
EXEC @hr=sp_OACreate 'Scripting.FileSystemObject',@fso OUT    
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso    
    
DECLARE dcur CURSOR LOCAL FAST_FORWARD    
FOR SELECT letter from #drives    
ORDER by letter    
    
OPEN dcur    

FETCH NEXT FROM dcur INTO @letter    
    
WHILE @@FETCH_STATUS=0    
BEGIN    
    
        EXEC @hr = sp_OAMethod @fso,'GetDrive', @odrive OUT, @letter    
        IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso    
            
        EXEC @hr = sp_OAGetProperty @odrive,'TotalSize', @disk_size OUT    
        IF @hr <> 0 EXEC sp_OAGetErrorInfo @odrive    
                            
        UPDATE #drives    
        SET disk_size=@disk_size/@MB    
        WHERE letter=@letter    
            
        FETCH NEXT FROM dcur INTO @letter    
    
END    
    
CLOSE dcur    
DEALLOCATE dcur    

EXEC @hr=sp_OADestroy @fso    
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso  

 
SELECT @server_id as server_id, @instance_id as instance_id ,
       letter,    
       disk_size,
       (disk_size - free_size) as usage_size 
FROM #drives 
ORDER BY letter  
  
  
    
DROP TABLE #drives  

RETURN
;
SET QUOTED_IDENTIFIER ON
go

/*************************************************************************  
* 프로시저명  : dbo.up_dba_select_databasefilelist 
* 작성정보    : 2010-02-10 by 최보라
* 관련페이지  :  
* 내용        : 장비별 데이터베이스 파일 정보
* 수정정보    : EXEC up_dba_select_databasefilelist 1,1
**************************************************************************/
CREATE PROCEDURE [dbo].[up_dba_select_databasefilelist]
    @server_id          int,
    @instance_id        int
    
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET FMTONLY OFF

/* USER DECLARE */
DECLARE @version    int
DECLARE @dbname     varchar(50) 
DECLARE @dbid       nvarchar(50)  
DECLARE @str_sql    nvarchar(4000)  
DECLARE @str_sql1    nvarchar(2000)  
      

/* BODY */
SET @version =  convert(int, REPLACE(left( convert(nvarchar(10), serverproperty('productversion')), 2),'.',''))
CREATE TABLE  #temp_databasefilelist 
(
    seq_no      int identity(1,1),
    server_id   smallint,
    instance_id smallint,
    dbid        int,
    dbname      nvarchar(500),
    fileid      smallint,
    filegroup   nvarchar(50),
    name        nvarchar(50),
    file_full_name  nvarchar(260),
    size        decimal(10,2),
    max_size    decimal(10,2),
    growth     decimal(10,2),
    usage       decimal(10,2),
    reg_dt      datetime
)
    


IF @version < 9 -- 2000 이하
BEGIN
    SET @str_sql1 = 
        N'  sysfiles.fileid, g.groupname,
        	sysfiles.name, sysfiles.filename AS file_full_name, 
        	CAST(sysfiles.size/128.0 AS decimal(10,2)) AS size,
        	CAST(sysfiles.growth/128.0 AS decimal(10,2)) growth, 
        	CASE WHEN sysfiles.maxsize = -1 THEN -1 ELSE CAST(sysfiles.maxsize/128.0 AS decimal(10,2)) END as max_size,
        	CAST(FILEPROPERTY(sysfiles.name, ''SpaceUsed'' ) /128.0 as decimal(10,2)) as usage,
        	convert(datetime,convert(nvarchar(10), GETDATE(), 121)) as reg_dt 
        FROM dbo.sysfiles  left join  dbo.sysfilegroups as g on sysfiles.groupid = g.groupid
        ORDER BY g.groupname, sysfiles.name'
       
END
ELSE
BEGIN
    SET @str_sql1 = 
        N'  sysfiles.fileid, g.groupname,
        	sysfiles.name, sysfiles.filename AS file_full_name, 
        	CAST(sysfiles.size/128.0 AS decimal(10,2)) AS size,
        	CAST(sysfiles.growth/128.0 AS decimal(10,2)) growth, 
        	CASE WHEN sysfiles.maxsize = -1 THEN -1 ELSE CAST(sysfiles.maxsize/128.0 AS decimal(10,2)) END as max_size,
        	CAST(FILEPROPERTY(sysfiles.name, ''SpaceUsed'' ) /128.0 as decimal(10,2)) as usage,
        	convert(datetime,convert(nvarchar(10), GETDATE(), 121)) as reg_dt 
        FROM dbo.sysfiles left join  sysfilegroups as g on sysfiles.groupid = g.groupid
        ORDER BY g.groupname, sysfiles.name'
END


DECLARE dbname_cursor CURSOR FOR 
            SELECT name, convert(nvarchar(50),dbid) as dbid 
            from master..sysdatabases with (nolock)     
            where name not in 
                ('northwind', 'pubs', 'LiteSpeedCentral', 'LiteSpeedLocal', 'credit2')
                and DATABASEPROPERTYEX(name,'status')='ONLINE'
             
      
OPEN dbname_cursor       
FETCH next FROM dbname_cursor into @dbname  , @dbid
WHILE @@fetch_status = 0       
BEGIN    

       SET @str_sql = N' USE [' + @dbname + '] ' 
                      + ' SELECT ' + convert(nvarchar(10), @server_id) 
                      + ', ' + convert(nvarchar(10), @instance_id)
                      + ', ' + @dbid + ', ''' + @dbname + ''','
                      + @str_sql1
                      
                   
                      
       INSERT #temp_databasefilelist EXEC (@str_sql) 


SET @str_sql = ''
FETCH NEXT FROM dbname_cursor INTO @dbname  , @dbid      
      
END  

CLOSE dbname_cursor       
DEALLOCATE dbname_cursor   

SELECT server_id,  instance_id,  dbid, dbname, fileid, filegroup, name, file_full_name, 
    size, max_size, growth, usage, reg_dt
FROM #temp_databasefilelist

DROP TABLE #temp_databasefilelist

RETURN
go

/*************************************************************************      
* 프로시저명  : dbo.up_dba_select_table_size 1,1     
* 작성정보    : 2010-03-23 by choi bo ra    
* 관련페이지  :      
* 내용        : server별 DB별 table size 측정    
* 수정정보    : KB를 MB로 수정 (노상국)    
**************************************************************************/    
CREATE PROCEDURE dbo.up_dba_select_table_size    
    @server_id          int,    
    @instance_id        int    
AS    
/* COMMON DECLARE */    
SET NOCOUNT ON    
SET FMTONLY OFF    
    
/* USER DECLARE */    
DECLARE @version    int    
DECLARE @str_sql        nvarchar(4000)    
DECLARE @str_sql1        nvarchar(4000)    
DECLARE @dbname     varchar(50)     
DECLARE @dbid       nvarchar(50)      
    
CREATE TABLE  #temp_table     
(    
    seq_no      int identity(1,1),    
    server_id   smallint,    
    instance_id smallint,    
    rank        int,    
    db_id        int,    
    db_name                   nvarchar(128),    
    object_id   int,    
    schema_name nvarchar(128),    
    table_name  nvarchar(128),    
    row_count   bigint,    
    reserved     bigint,    
    data         bigint,    
    index_size   bigint,    
    unused       bigint,    
    reg_dt      datetime    
)    
    
/* BODY */    
SET @version =  convert(int, REPLACE(left( convert(nvarchar(10), serverproperty('productversion')), 2),'.',''))  
    
IF @version < 9 -- 2000 이하    
BEGIN    
    set @str_sql1 = N'    
        SELECT ' + convert(nvarchar(20), @server_id) + ' as server_id , ' + convert(nvarchar(20), @instance_id) + ' as instance_id,    
        null as rank,    
        db_id() as db_id,     
        db_name() as db_name,    
        objectid ,    
        u.name as schema_name,    
        table_name,    
        row_count,    
        convert(bigint,reserved) * 8 /1024 as reserved,    
        convert(bigint ,data) * 8 /1024 as data,    
        convert(bigint,used-data )* 8 /1024  as index_size,    
        convert(bigint,(reserved-used)) * 8/1024 as unused,    
        getdate() as reg_dt    
    from    
        (select obj.id as objectid, obj.uid as uid ,obj.name as table_name,    
            sum(case when indid < 2 then rows else 0 end) as row_count,            
            sum(case when indid in (0, 1, 255) then reserved else 0 end) as reserved,            
            sum(case when indid in (0, 1, 255) then dpages else 0 end) as data,            
            sum(case when indid in (0, 1, 255) then used else 0 end) as used            
        from  dbo.sysindexes  as ind with (nolock)     
            join dbo.sysobjects  as obj with (nolock)      on ind.id = obj.id         
        where obj.type = ''U''        
        group by obj.id, obj.uid,obj.name) as A    
       inner join dbo.sysusers as u with(nolock) on a.uid = u.uid    
    order by row_count desc'    
        
        
            
END    
ELSE    
BEGIN    
    set @str_sql1 = N'    
        SELECT ' + convert(nvarchar(20), @server_id) + ' as server_id , ' + convert(nvarchar(20), @instance_id) + ' as instance_id,    
            (row_number() over(order by (a1.reserved) desc)) as rank,    
            db_id() as db_id,    
            db_name() as db_name,    
            a2.object_id ,    
                                a3.name AS schema_name,    
                                a2.name AS table_name,    
                                a1.rows as row_count,    
                                a1.reserved * 8/1024 AS reserved,    
                                a1.data * 8/1024 AS data,    
                               (CASE WHEN (a1.used ) > a1.data THEN (a1.used ) - a1.data ELSE 0 END) * 8 /1024AS index_size,    
                                (CASE WHEN (a1.reserved ) > a1.used THEN (a1.reserved ) - a1.used ELSE 0 END) * 8/1024 AS unused,    
            getdate() as reg_dt    
    FROM         (SELECT   
                            ps.object_id,    
                               SUM (CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END     ) AS [rows],    
     SUM (ps.reserved_page_count) AS reserved,    
                               SUM (    
                                       CASE    
                                       WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)    
                                       ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count)    
                                       END    
                               ) AS data,    
                               SUM (ps.used_page_count) AS used    
        FROM sys.dm_db_partition_stats ps    
        GROUP BY ps.object_id) AS a1    
        INNER JOIN sys.all_objects a2  ON ( a1.object_id = a2.object_id )    
        INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id)    
WHERE a2.type <> ''S'' and a2.type <> ''IT'''      
            
        
        
END    
    
DECLARE dbname_cursor CURSOR FOR     
            SELECT name, convert(nvarchar(50),dbid) as dbid     
            from master..sysdatabases with (nolock)         
            where name not in     
                ('northwind', 'pubs', 'LiteSpeedCentral', 'LiteSpeedLocal')    
                and DATABASEPROPERTYEX(name,'status')='ONLINE' and dbid  > 4    
                 
          
OPEN dbname_cursor           
FETCH next FROM dbname_cursor into @dbname  , @dbid    
WHILE @@fetch_status = 0           
BEGIN       
        
     SET @str_sql = N' USE [' + @dbname + '] ' + char(10)    
                    + @str_sql1    
   --print @str_sql    
    INSERT #temp_table EXEC (@str_sql)     
    SET @str_sql = ''    
    
FETCH NEXT FROM dbname_cursor INTO @dbname  , @dbid          
          
END      
    
CLOSE dbname_cursor           
DEALLOCATE dbname_cursor      
    
select server_id, instance_id, rank, db_id, db_name, object_id, schema_name, table_name,    
    row_count, reserved, data, index_size, unused, reg_dt from  #temp_table    
    order by db_name    
                           
        
drop table #temp_table    
        
RETURN    
go

-- =============================================							
-- Author:		<Author,,Daekyung Kim>					
-- Create date: <Create Date,,2010-10-08>							
-- Description:	<Description,, 해당서버의 DB Job 정보수집>	
-- EXEC up_conf_JobInfoCollect 1, 2
-- =============================================							
ALTER PROCEDURE [dbo].[up_conf_JobInfoCollect]
    @server_id          int,
    @instance_id        int
AS													
SET NOCOUNT ON;
SET FMTONLY OFF;

DECLARE @stmt NVARCHAR(4000)	
DECLARE @paramDef NVARCHAR(100)

IF LEFT(CAST(SERVERPROPERTY('ProductVersion') As Varchar),1) = '8' -- 2000
BEGIN
	SET @paramDef = N'@server_id int, @instance_id int'
	SET @stmt = N'
	SELECT 
		CONVERT(int, @server_id) AS server_id
		,CONVERT(int, @instance_id) AS instance_id
		,CONVERT(NVARCHAR(100), aa.job_id) AS job_id
		,CONVERT(NVARCHAR(100), aa.name) AS name
		,CONVERT(tinyint, aa.enabled) AS enabled
		,CONVERT(int, bb.failCnt) AS failCnt
		,CONVERT(int, bb.successCnt) AS successCnt
		,CONVERT(int, aa.schedule_id) AS schedule_id
		,CONVERT(datetime, bb.lastRunDate) AS lastRunDate
		,CONVERT(datetime, aa.date_created) AS createDate
		,CONVERT(datetime, aa.date_modified) AS updateDate 		
		,CONVERT(NVARCHAR(255), aa.scheduleDscr) AS scheduleDscr
		,CONVERT(VARCHAR(1024),bb.message) AS message
	FROM	
	(
	SELECT 
		j.job_id,
		j.date_created, 
		j.date_modified, 
		j.name, 
		sj.schedule_id,
		CAST((sj.active_start_time / 10000) AS VARCHAR(10)) + '':'' + 
		RIGHT(''00'' + CAST((sj.active_start_time % 10000) / 100 AS VARCHAR(10)),2) active_start_time,  
		msdb.dbo.udf_schedule_description(sj.freq_type, sj.freq_interval,  
		sj.freq_subday_type, sj.freq_subday_interval, sj.freq_relative_interval,  
		sj.freq_recurrence_factor, sj.active_start_date, sj.active_end_date,  
		sj.active_start_time, sj.active_end_time) AS scheduleDscr, j.enabled 
	FROM msdb.dbo.sysjobs j WITH(NOLOCK) INNER JOIN 
	msdb.dbo.sysjobschedules sj WITH(NOLOCK) ON j.job_id = sj.job_id 
	) aa LEFT OUTER JOIN
	(
	SELECT 
			j.job_id,
			MAX(CAST(
			STUFF(STUFF(CAST(jh.run_date as varchar),7,0,''-''),5,0,''-'') + '' '' + 
			STUFF(STUFF(REPLACE(STR(jh.run_time,6,0),'' '',''0''),5,0,'':''),3,0,'':'') as datetime)) AS lastRunDate,
			ISNULL(SUM(CASE WHEN jh.run_status = 0 THEN 1 END), 0) AS failCnt, 
			ISNULL(SUM(CASE WHEN jh.run_status != 0 THEN 1 END), 0) AS successCnt,
			(
				SELECT TOP 1 message
				FROM msdb.dbo.sysjobhistory a WITH(NOLOCK)
				WHERE job_id = j.job_id
					AND run_date BETWEEN CONVERT(varchar, DATEADD(d, -1, GETDATE()),112) AND CONVERT(varchar, GETDATE(),112)			
				ORDER BY run_status	
			) AS message			
		FROM msdb.dbo.sysjobs j WITH(NOLOCK) 
		INNER JOIN msdb.dbo.sysjobhistory jh WITH(NOLOCK) 
		ON jh.job_id = j.job_id AND jh.step_id = 0 
		inner join msdb.dbo.syscategories sc WITH(NOLOCK) 
		ON j.
category_id = sc.category_id
		WHERE jh.run_date BETWEEN CONVERT(varchar, DATEADD(d, -1, GETDATE()),112) AND CONVERT(varchar, GETDATE(),112)
		GROUP BY j.job_id
	) bb ON aa.job_id = bb.job_id'	
	
	
END
ELSE
BEGIN	
	SET @paramDef = N'@server_id int, @instance_id int'
	SET @stmt = N'
	SELECT 
		CONVERT(int, @server_id) AS server_id
		,CONVERT(int, @instance_id) AS instance_id
		,CONVERT(NVARCHAR(100), aa.job_id) AS job_id
		,CONVERT(NVARCHAR(100), aa.name) AS name
		,CONVERT(tinyint, aa.enabled) AS enabled

		,CONVERT(int, bb.failCnt) AS failCnt
		,CONVERT(int, bb.successCnt) AS successCnt
		,CONVERT(int, aa.schedule_id) AS schedule_id
		,CONVERT(datetime, bb.lastRunDate) AS lastRunDate
		,CONVERT(datetime, aa.date_created) AS createDate
		,CONVERT(datetime,aa.date_modified) AS updateDate 		
		,CONVERT(NVARCHAR(255), aa.scheduleDscr) AS scheduleDscr
		,CONVERT(VARCHAR(1024),bb.message) AS message
	FROM
	(
SELECT 
	j.job_id, 
	j.date_created, 
	j.date_modified, 
	j.name, 
	js.schedule_id,
	CAST(s.active_start_time / 10000 AS VARCHAR(10)) + '':'' + RIGHT(''00'' + CAST(s.active_start_time % 10000 / 100 AS VARCHAR(10)), 2) AS active_start_time, 
	msdb.dbo.udf_schedule_description(s.freq_type, s.freq_interval,  
		s.freq_subday_type, s.freq_subday_interval, s.freq_relative_interval,  
		s.freq_recurrence_factor, s.active_start_date, s.active_end_date,  
		s.active_start_time, s.active_end_time) AS scheduleDscr, j.enabled  
	FROM msdb.dbo.sysjobs j WITH(NOLOCK) INNER JOIN  
	msdb.dbo.sysjobschedules js WITH(NOLOCK) ON j.job_id = js.job_id INNER JOIN  
	msdb.dbo.sysschedules s WITH(NOLOCK)ON js.schedule_id = s.schedule_id 
	) aa LEFT OUTER JOIN
	(
		SELECT 
			j.job_id,
			MAX(CAST(
			STUFF(STUFF(CAST(jh.run_date as varchar),7,0,''-''),5,0,''-'') + '' '' + 
			STUFF(STUFF(REPLACE(STR(jh.run_time,6,0),'' '',''0''),5,0,'':''),3,0,'':'') as datetime)) AS lastRunDate,
			ISNULL(SUM(CASE WHEN jh.run_status = 0 THEN 1 END), 0) AS failCnt, 
			ISNULL(SUM(CASE WHEN jh.run_status != 0 THEN 1 END), 0) AS successCnt,
			(
	
			SELECT TOP 1 message
				FROM msdb.dbo.sysjobhistory a WITH(NOLOCK)
				WHERE job_id = j.job_id
					AND run_date BETWEEN CONVERT(varchar, DATEADD(d, -1, GETDATE()),112) AND CONVERT(varchar, GETDATE(),112)			
				ORDER BY run_status	
			) AS message			

		FROM msdb.dbo.sysjobs j WITH(NOLOCK) 
		INNER JOIN msdb.dbo.sysjobhistory jh WITH(NOLOCK) 
		ON jh.job_id = j.job_id AND jh.step_id = 0 
		inner join msdb.dbo.syscategories sc WITH(NOLOCK) 
		ON j.category_id = sc.category_id
		WHERE jh.run_date BETWEEN CONVERT(varchar, DATEADD(d, -1, GETDATE()),112) AND CONVERT(varchar, GETDATE(),112)
		GROUP BY j.job_id
	) bb ON aa.job_id = bb.job_id'	
END

EXEC sp_executesql @stmt, @paramDef, @server_id = @server_id, @instance_id = @instance_id
go


/*************************************************************************      
* 프로시저명  : dbo.up_dba_select_autogrowth_info    
* 작성정보    : 2012-09-25 by 김대경
* 관련페이지  :      
* 내용        : auto grwoth 정보 수집
* 수정정보    :    
dbo.up_dba_select_autogrowth_info 167
**************************************************************************/    

CREATE PROC dbo.up_dba_select_autogrowth_info     
	@server_id          int	
AS

declare @stmt nvarchar(2000)
declare @params nvarchar(100)
 
set @stmt=N'
begin try  
	if (select convert(int,value_in_use) from sys.configurations where name = ''default trace enabled'' ) = 1 
	begin 
	declare @curr_tracefilename varchar(500) ; 
	declare @base_tracefilename varchar(500) ; 
	declare @indx int ;

	select @curr_tracefilename = path from sys.traces where is_default = 1 ; 
	set @curr_tracefilename = reverse(@curr_tracefilename);
	select @indx  = patindex(''%\%'', @curr_tracefilename) ;
	set @curr_tracefilename = reverse(@curr_tracefilename) ;
	set @base_tracefilename = left( @curr_tracefilename,len(@curr_tracefilename) - @indx) + ''\log.trc'' ;  

	select  
			convert(varchar(20),@@servername) as servername
			,@p_server_id as server_id				
			,convert(varchar(256),DatabaseName) as db_name
			,convert(varchar(256),Filename) as file_name
			,count(*) as auto_growth_cnt
			,avg(Duration/1000) as avg_duration_ms
			,Min(StartTime) as min_start_dt
			,Max(EndTime) as max_end_dt
			,(avg(IntegerData)*8/1024) as change_in_size_mb 
	from ::fn_trace_gettable( @base_tracefilename, default ) 
	where EventClass >=  92  and EventClass <=  95  and ServerName = @@servername   
		and StartTime>convert(varchar(10), getdate(), 121)
	group by DatabaseName, Filename
	order by DatabaseName, Filename  
	end     
	else    
	select 
		convert(varchar(20),@@servername) as servername
		,@p_server_id as server_id
		,NULL as db_name
		,NULL as file_name
		,NULL as auto_growth_cnt
		,NULL as avg_duration_ms
		,NULL as min_start_dt
		,NULL as max_end_dt
		,NULL as change_in_size_mb
		,getdate() as reg_dt 
end try 
begin catch 
select 
		convert(varchar(20),@@servername) as servername
		,@p_server_id as server_id
		,NULL as db_name
		,NULL as file_name
		,NULL as auto_growth_cnt
		,NULL as avg_duration_ms
		,NULL as min_start_dt
		,NULL as max_end_dt
		,NULL as change_in_size_mb
		,getdate() as reg_dt 
end catch' 

set @params = N'@p_server_id int'

exec sp_executesql @stmt,@params,@p_server_id=@server_id
go

-- =============================================							
-- Author:		<Author,,Daekyung Kim>					
-- Create date: <Create Date,,2010-09-15>							
-- Description:	<Description,, 해당서버의 DB 백업정보수집>						
-- =============================================							

CREATE PROCEDURE up_conf_BackupHistoryCollect
    @server_id          int,
    @instance_id        int,				
	@backupTime			varchar(5)
AS							
BEGIN							
	SET NOCOUNT ON;						
							
	DECLARE @stmt NVARCHAR(3000)						
	DECLARE @paramDef NVARCHAR(100
)
	
	SET @paramDef = N'@server_id int, @instance_id int, @backupTime varchar(5)'
							
	IF LEFT(CAST(SERVERPROPERTY('ProductVersion') As Varchar),1)='1' -- 2008 : add compressed_backup_size
		SET @stmt= N'					
			DECLARE @endDate DATETIME				
			DECLARE @time VARCHAR(8)				
			SET @time = '' ''+ @backupTime
			SET @endDate = CONVERT(DATETIME,CONVERT(VARCHAR(10),GETDATE(),111)) + @time				
			SELECT
				@server_id AS server_id
				,@instance_id AS instance_id				
				,@@servername AS server_name			
				,s.name AS database_name			
				,CONVERT(NVARCHAR(120), s.recovery_model_desc) AS recovery_model			
				,s.compatibility_level			
				, CASE WHEN m.database_name is null THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS has_backupset			
				,m.backup_type			

				,m.backupset_name
				,m.backup_size			
				,m.compressed_backup_size			
				,m.logical_device_name			
				,m.physical_device_name			
				,m.backup_start_date			
				,m.backup_finish_date
				,CASE
					WHEN m.database_name IS NOT NULL AND m.backupset_name = ''COMMVAULT GALAXY BACKUP'' THEN 2
					WHEN m.database_name IS NOT NULL THEN 1
					WHEN m.database_name IS NULL THEN 0
				END AS backup_method
			FROM sys.databases s with(nolock) 				
				LEFT OUTER JOIN(			
					SELECT		
						bs.database_name,	
						bs.type AS backup_type,	
						bs.compatibility_level,	
						bs.name AS backupset_name,	
						bs.backup_size/1024/1024 AS backup_size,	
						CASE 	
							WHEN bs.compatibility_level = 100 THEN bs.compressed_backup_size/1024/1024
							ELSE 0 END AS compressed_backup_size,
						bf.logical_device_name, 	
						bf.physical_device_name,	
						bs.backup_start_date, 	
						bs.backup_finish_date	
					FROM msdb.dbo.backupset bs WITH(NOLOCK) INNER JOIN msdb.dbo.backupmediafamily bf WITH(NOLOCK) ON bs.media_set_id = bf.media_set_id		
					WHERE bs.backup_finish_date BETWEEN DATEADD(DD,-1, @endDate) AND @endDate		
				) m ON s.name = m.database_name			
			WHERE s.name != ''tempdb''				
			'				
	ELSE IF LEFT(CAST(SERVERPROPERTY('ProductVersion') As Varchar),1)='9' -- 2005 : add compressed_backup_size						
		SET @stmt= N'					
			DECLARE @endDate DATETIME				
			DECLARE @time VARCHAR(8)				
			SET @time = '' ''+ @backupTime			
			SET @endDate = CONVERT(DATETIME,CONVERT(VARCHAR(10),GETDATE(),111))+ @time				
			SELECT
				@server_id AS server_id
				,@instance_id AS instance_id						
				,@@servername AS server_name			
				,s.name AS database_name			
				,CONVERT(NVARCHAR(120), s.recovery_model_desc) AS recovery_model			
				,s.compatibility_level			
				, CASE WHEN m.database_name is null THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS has_backupset			
				,m.backup_type			
				,m.backupset_name
				,m.backup_size			
				,m.compressed_backup_size			
				,m.logical_device_name			
				,m.physical_device_name			
				,m.backup_start_date			
				,m.backup_finish_date
				,CASE
					WHEN m.database_name IS NOT NULL AND m.backupset_name = ''COMMVAULT GALAXY BACKUP'' THEN 2
					WHEN m.database_name IS NOT NULL THEN 1
					WHEN m.database_name IS NULL THEN 0
				END AS backup_method	
			FROM sys.databases s with(nolock) 				
				LEFT OUTER JOIN(			
					SELECT		
						bs.database_name,	
						bs.type AS backup_type,	
						bs.compatibility_level,	
						bs.name AS backupset_name,	
						bs.backup_size/1024/1024 AS backup_size,	
						0 AS compressed_backup_size,	
						bf.logical_device_name, 	
						bf.physical_device_name,	
						bs.backup_start_date, 	
						bs.backup_finish_date	
					FROM msdb.dbo.backupset bs WITH(NOLOCK) INNER JOIN msdb.dbo.backupmediafamily bf WITH(NOLOCK) ON bs.media_set_id = bf.media_set_id		
					WHERE bs.backup_finish_date BETWEEN DATEADD(DD,-1, @endDate) AND @endDate		
				) m ON s.name = m.database_name			
			WHERE s.name != ''tempdb''				
			'
	ELSE IF LEFT(CAST(SERVERPROPERTY('ProductVersion') As Varchar),1)='8' -- 2000 : add compressed_backup_size						
		SET @stmt= N'					
			DECLARE @endDate DATETIME				
			DECLARE @time VARCHAR(8)				
			SET @time = '' ''+ @backupTime			
			SET @endDate = CONVERT(DATETIME,CONVERT(VARCHAR(10),GETDATE(),111)) + @time				
			SELECT
				@server_id AS server_id
				,@instance_id AS instance_id						
				,@@servername AS server_name			
				,s.name AS database_name			
				,CONVERT(NVARCHAR(120),Databasepropertyex(s.name, ''Recovery'')) AS recovery_model			
				,s.cmptlevel AS compatibility_level			
				, CASE WHEN m.database_name is null THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS has_backupset			
				,m.backup_type			
				,m.backupset_name	
				,m.backup_size			
				,m.compressed_backup_size			
				,m.logical_device_name			
				,m.physical_device_name			
				,m.backup_start_date			
				,m.backup_finish_date
				,CASE
					WHEN m.database_name IS NOT NULL AND m.backupset_name = ''COMMVAULT GALAXY BACKUP'' THEN 2
					WHEN m.database_name IS NOT NULL THEN 1
					WHEN m.database_name IS NULL THEN 0
				END AS backup_method		
			FROM master.dbo.sysdatabases s with(nolock) 				
				LEFT OUTER JOIN(			
					SELECT		
						bs.database_name,	
						bs.type AS backup_type,	
						bs.compatibility_level,	
						bs.name AS backupset_name,	
						bs.backup_size/1024/1024 AS backup_size,	
						0 AS compressed_backup_size,	
						bf.logical_device_name, 	
						bf.physical_device_name,	
						bs.backup_start_date, 	
						bs.backup_finish_date	
					
		FROM msdb.dbo.backupset bs WITH(NOLOCK) INNER JOIN msdb.dbo.backupmediafamily bf WITH(NOLOCK) ON bs.media_set_id = bf.media_set_id		
					WHERE bs.backup_finish_date BETWEEN DATEADD(DD,-1, @endDate) AND @endDate		
				) m ON s.name = m.database_name			
		
	WHERE s.name != ''tempdb''				
			'			
	EXEC sp_executesql @stmt, @paramDef, @server_id = @server_id, @instance_id = @instance_id, @backupTime = @backupTime	
END							
go

use msdb
go
CREATE FUNCTION udf_schedule_description
(
	@freq_type INT , 
  @freq_interval INT , 
  @freq_subday_type INT , 
  @freq_subday_interval INT , 
  @freq_relative_interval INT , 
  @freq_recurrence_factor INT , 
  @active_start_date INT , 
  @active_end_date INT, 
  @active_start_time INT , 
  @active_end_time INT ) 
RETURNS NVARCHAR(255) AS 
BEGIN 
DECLARE @schedule_description NVARCHAR(255) 
DECLARE @loop INT 
DECLARE @idle_cpu_percent INT 
DECLARE @idle_cpu_duration INT 

IF (@freq_type = 0x1) -- OneTime 
BEGIN 
SELECT @schedule_description = N'Once on ' + CONVERT(NVARCHAR, @active_start_date) + N' at ' + CONVERT(NVARCHAR, cast((@active_start_time / 10000) as varchar(10)) + ':' + right('00' + cast((@active_start_time % 10000) / 100 as varchar(10)),2)) 
RETURN @schedule_description 
END 
IF (@freq_type = 0x4) -- Daily 
BEGIN 
SELECT @schedule_description = N'Every day ' 
END 
IF (@freq_type = 0x8) -- Weekly 
BEGIN 
SELECT @schedule_description = N'Every ' + CONVERT(NVARCHAR, @freq_recurrence_factor) + N' week(s) on ' 
SELECT @loop = 1 
WHILE (@loop <= 7) 
BEGIN 
IF (@freq_interval & POWER(2, @loop - 1) = POWER(2, @loop - 1)) 
SELECT @schedule_description = @schedule_description + DATENAME(dw, N'1996120' + CONVERT(NVARCHAR, @loop)) + N', '
SELECT @loop = @loop + 1 
END 
IF (RIGHT(@schedule_description, 2) = N', ') 
SELECT @schedule_description = SUBSTRING(@schedule_description, 1, (DATALENGTH(@schedule_description) / 2) - 2) + N' ' 
END 
IF (@freq_type = 0x10) -- Monthly 
BEGIN 
SELECT @schedule_description = N'Every ' + CONVERT(NVARCHAR, @freq_recurrence_factor) + N' months(s) on day ' + CONVERT(NVARCHAR, @freq_interval) + N' of that month ' 
END 
IF (@freq_type = 0x20) -- Monthly Relative 
BEGIN 
SELECT @schedule_description = N'Every ' + CONVERT(NVARCHAR, @freq_recurrence_factor) + N' months(s) on the ' 
SELECT @schedule_description = @schedule_description + 
CASE @freq_relative_interval 
WHEN 0x01 THEN N'first ' 
WHEN 0x02 THEN N'second ' 
WHEN 0x04 THEN N'third ' 
WHEN 0x08 THEN N'fourth ' 
WHEN 0x10 THEN N'last ' 
END + 
CASE 
WHEN (@freq_interval > 00) 
AND (@freq_interval < 08) THEN DATENAME(dw, N'1996120' + CONVERT(NVARCHAR, @freq_interval)) 
WHEN (@freq_interval = 08) THEN N'day' 
WHEN (@freq_interval = 09) THEN N'week day' 
WHEN (@freq_interval = 10) THEN N'weekend day' 
END + N' of that month ' 
END 
IF (@freq_type = 0x40) -- AutoStart 
BEGIN 
SELECT @schedule_description = FORMATMESSAGE(14579) 
RETURN @schedule_description 
END 
IF (@freq_type = 0x80) -- OnIdle 
BEGIN 
EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 
N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', 
N'IdleCPUPercent', 
@idle_cpu_percent OUTPUT, 
N'no_output' 
EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 
N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', 
N'IdleCPUDuration', 
@idle_cpu_duration OUTPUT, 
N'no_output' 
SELECT @schedule_description = FORMATMESSAGE(14578, ISNULL(@idle_cpu_percent, 10), ISNULL(@idle_cpu_duration, 600)) 
RETURN @schedule_description 
END 
-- Subday stuff 
SELECT @schedule_description = @schedule_description + 
CASE @freq_subday_type 
WHEN 0x1 THEN N'at ' + CONVERT(NVARCHAR, cast((@active_start_time / 10000) as varchar(10)) + ':' + right('00' + cast((@active_start_time % 10000) / 100 as varchar(10)),2)) 
WHEN 0x2 THEN N'every ' + CONVERT(NVARCHAR, @freq_subday_interval) + N' second(s)' 
WHEN 0x4 THEN N'every ' + CONVERT(NVARCHAR, @freq_subday_interval) + N' minute(s)' 
WHEN 0x8 THEN N'every ' + CONVERT(NVARCHAR, @freq_subday_interval) + N' hour(s)' 
END 
IF (@freq_subday_type IN (0x2, 0x4, 0x8)) 
SELECT @schedule_description = @schedule_description + N' between ' + 
CONVERT(NVARCHAR, cast((@active_start_time / 10000) as varchar(10)) + ':' + right('00' + cast((@active_start_time % 10000) / 100 as varchar(10)),2) ) + N' and ' + CONVERT(NVARCHAR, cast((@active_end_time / 10000) as varchar(10)) + ':' + right('00' + cast(
(@active_end_time % 10000) / 100 as varchar(10)),2) ) 

RETURN @schedule_description 
END
