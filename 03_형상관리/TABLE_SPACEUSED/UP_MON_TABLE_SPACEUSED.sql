

IF OBJECT_ID('UP_MON_TABLE_SPACEUSED') IS NOT NULL
	DROP PROCEDURE UP_MON_TABLE_SPACEUSED
GO

        
CREATE PROCEDURE UP_MON_TABLE_SPACEUSED        
AS        
BEGIN        
SET NOCOUNT ON        
        
declare @min_value datetime, @max_value datetime, @new_value datetime, @now datetime        
        
select @min_value = min(CONVERT(datetime, value)), @max_value = max(CONVERT(datetime, value))        
from sys.partition_range_values v JOIN sys.partition_functions f ON v.function_id = f.function_id        
where f.name = 'PF_MON_TABLE_SPACEUSED'        
        
if @max_value < GETDATE()        
begin        
         
 SET @new_value = DATEADD(day, 10, @max_value)        
        
 -- 1 번파티션을TESTDATA_BAK 으로이관        
 ALTER TABLE DB_MON_TABLE_SPACEUSED SWITCH PARTITION 1 TO DB_MON_TABLE_SPACEUSED_TEMP        
        
 -- TESTDATA_BAK 을모두지움        
 TRUNCATE TABLE DB_MON_TABLE_SPACEUSED_TEMP        
        
 -- 다음 사용 PARTITION 을지정        
 ALTER PARTITION SCHEME PS_MON_TABLE_SPACEUSED NEXT USED [PRIMARY]        
        
 -- 기존의1 번파티션과2번파티션을MERGE        
 ALTER PARTITION FUNCTION PF_MON_TABLE_SPACEUSED() MERGE RANGE (@min_value)        
        
 -- 새로운파티션생성        
 ALTER PARTITION FUNCTION PF_MON_TABLE_SPACEUSED() SPLIT RANGE (@new_value)        
        
end        
        
declare @script nvarchar(3000)        
declare @seq int, @max int        
declare @dbname sysname, @database_id int        
        
declare @db_list TABLE (        
 SEQ INT IDENTITY(1, 1) PRIMARY KEY,        
 database_id int,        
 dbname sysname        
)        
        
INSERT @db_list (database_id, dbname)        
SELECT database_id, name FROM sys.databases WHERE database_id >= 5        
        
SELECT @seq = 1, @max = @@ROWCOUNT        
      
SET @now = GETDATE()      
        
WHILE @seq <= @max        
BEGIN        
         
 SELECT @database_id = database_id, @dbname = dbname FROM @db_list WHERE SEQ = @seq        
        
 SET @script = '        
  insert DB_MON_TABLE_SPACEUSED (now, dbname, objectname, rows, reserved, data, indexed, unused)        
  select ''' + CONVERT(VARCHAR(23), @now, 121) + ''',       
      ''' + @dbname + ''',        
      object_name(id, ' + CONVERT(varchar, @database_id) + '),        
      rows,        
      reserved * 8 / 1024,        
      data * 8  / 1024,        
      (used - data) * 8  / 1024,        
      (reserved - used) * 8  / 1024        
  from (        
   select id, sum(case when indid < 2 then rows else 0 end) as rows,        
    sum(case when indid in (0, 1, 255) then reserved else 0 end) as reserved,        
    sum(case when indid in (0, 1, 255) then dpages else 0 end) as data,        
    sum(case when indid in (0, 1, 255) then used else 0 end) as used        
   from ' + @dbname + '.dbo.sysindexes with (nolock)         
   where id in (select id from ' + @dbname + '.dbo.sysobjects where type = ''U'')        
   group by id        
  ) A        
  order by reserved desc'        
        
-- PRINT @script        
 EXEC sp_executesql @script        
         
 SET @seq = @seq + 1        
        
END        
        
END        
  
  