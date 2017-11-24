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
    
SET @version =  convert(int, REPLACE(left( convert(nvarchar(10), serverproperty('productversion')), 2),'.',''))  
    
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
  from sys.databases as db with(nolock) join sys.sysaltfiles as sf with(nolock)    
         on db.database_id = sf.dbid join sys.database_mirroring as dm with(nolock)     
               on db.database_id= dm.database_id    
  group by db.database_id, db.name, db.create_date, db.state_desc, db.recovery_model_desc, db.is_auto_shrink_on    
     , db.is_auto_create_stats_on, db.is_auto_update_stats_on , db.is_broker_enabled , dm.mirroring_role    
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
  from master..sysdatabases as db with(nolock) join master..sysaltfiles as sf with(nolock)    
    on db.dbid = sf.dbid     
  group by db.dbid, db.name, db.crdate, convert(sysname,DatabasePropertyEx(db.name,'Status'))    
      , convert(nvarchar(60), DatabasePropertyEx(db.name,'Recovery'))    
      , convert(bit, DatabasePropertyEx(db.name,'IsAutoShrink'))    
      , convert(bit, DatabasePropertyEx(db.name,'IsAutoCreateStatistics'))     
      , convert(bit, DatabasePropertyEx(db.name,'IsAutoUpdateStatistics') )    
  order by db.dbid    
END    
     
RETURN 