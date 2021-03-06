USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[UP_SCRIPT_PARTITION_CREATE]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*  파티션 표준 생성 스크립트   
exec UP_SCRIPT_PARTITION_CREATE   
 @table_name = 'DB_MON_BLOCKING', -- 파티션으로 잡을 테이블  
 @column_name = 'reg_date',   -- 파티션으로 잡을 컬럼  
 @partition_cnt = 6,     -- 파티션 개수  
 @partition_duration = 10   -- 파티션 각각의 주기  
*/  
CREATE PROCEDURE [dbo].[UP_SCRIPT_PARTITION_CREATE]  
    @table_name    sysname   -- 테이블의 이름(prefix 제외 부분)  
  , @column_name   sysname   -- 파티션 기준이 될 컬럼 이름  
  , @partition_cnt int    -- 파티션을 나눌 개수  
  , @partition_duration int   -- 파티션 하나당 기간   
AS  
  
declare @seq int  
declare @script_declare nvarchar(4000)  
declare @script_set nvarchar(4000)  
declare @script_fnc nvarchar(4000)  
declare @script_scheme nvarchar(4000)  
  
set @script_declare = ''  
set @script_set = ''  
set @script_fnc = '  
CREATE PARTITION FUNCTION PF__' + @table_name  + '__' + @column_name + ' (datetime)  
AS RANGE RIGHT FOR VALUES ('  
  
set @seq = 1  
  
while @seq <= @partition_cnt  
begin  
 set @script_declare = @script_declare + 'declare @pf_time' + convert(varchar(10), @seq) + ' datetime' + char(13) + char(10)  
 set @script_set = @script_set + 'set @pf_time' + convert(varchar(10), @seq) + ' = convert(datetime, convert(char(10), getdate() + ' + convert(varchar(10), @partition_duration * @seq) + ', 121), 121)' + char(13) + char(10)  
 set @script_fnc = @script_fnc + '@pf_time' + convert(varchar(10), @seq) + case when @seq = @partition_cnt then ')' else ', ' end  
  
 set @seq = @seq + 1  
  
end  
  
set @script_fnc = @script_fnc + char(13) + char(10) + 'go'   
set @script_scheme = '  
CREATE PARTITION SCHEME PS__' + @table_name  + '__' + @column_name + '  
AS PARTITION PF__' + @table_name  + '__' + @column_name + ' ALL TO ([PRIMARY])  
go'  
  
print @script_declare  
print ''  
print @script_set  
print @script_fnc  
print @script_scheme  
  
  
  
  
GO
