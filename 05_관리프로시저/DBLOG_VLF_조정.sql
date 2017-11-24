USE DBA
GO
/*************************************************************************  
* ���ν�����  : dbo.[up_dba_vlf_create]
* �ۼ�����    : 2015-12-15 by choi bo ra
* ����������  : 
* ����        : VLF ����
* ��������    : 
EXEC [up_dba_tempdb_create] 8, 102400, 'M:\TEMPDB'
**************************************************************************/
ALTER PROCEDURE [dbo].[up_dba_vlf_create]
	 @TYPE		char(1) = 'S' -- S shrink file, -C Create DB
	,@DB_NAME	sysname
	,@LOG_SIZE  int			  --MB ����
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @i int , @init_size int, @filegrowth int 
DECLARE @str_sql nvarchar(3000), @add_growth_size int
DECLARE @tot_loop int, @add_size int
DECLARE @log_file sysname

SET @str_sql = 'USE ' + @DB_NAME + CHAR(10)

if @TYPE = 'C' -- create database
begin

	-- log �ʱ� ���� setting
	if @log_size  <= 1024 -- 1gb ����
	begin
		set @init_size = @log_size 
		set @filegrowth = 128
	end
	else if @log_size  > 1024 and @log_size <  8*1024 -- 8gb �̸�
	begin
		set @init_size = 1024
		set @filegrowth = 512
		set @add_growth_size = 1024 -- 1GB
	end
	else if  @log_size  >=  8*1024 -- 8gb �̻�
	begin
		set @init_size = 8*1024
		set @filegrowth = 512
		set @add_growth_size = 8*1024 -- 8GB


	end

		select @LOG_SIZE AS [�α� Size MB],  @init_size AS [�ֱ� Size] ,@filegrowth AS [FILEGRWOTH Size], @add_growth_size AS  [�������� Size]


	set @str_sql = @str_sql+ 'CREATE DATABASE ' + @db_name + char(10)
				  + 'ON PRIMARY' + char(10)
				  + '		(NAME = '+ @db_name+'_DATA,' + char(10)
				  + '	      FILENAME = N'''',' + char(10)
				  + '		  SIZE = MB,' + char(10)
				  + '		  FILEGROWTH = MB)' + char(10)
				  + 'LOG ON' + char(10)
				  + '		( NAME = '+@db_name+'_LOG,' + char(10)
				  + '		  FILENAME = N'''',' + char(10)
				  + '		  SIZE = ' + convert(nvarchar(10), @init_size ) + 'MB,'  + char(10)
				  + '		  FILEGROWTH = ' + convert(nvarchar(10), @filegrowth) + 'MB)'+ char(10)
				  + '	GO '


	-- file ���� 
	SET @tot_loop = 0
	IF @log_size  >=  1024
	begin
		
		
		select  @tot_loop = round((@LOG_SIZE -  (@init_size) ) *1.0 / @add_growth_size,0)


		set @i = 1
		set @add_size = @init_size
		while (@i <= @tot_loop)
		begin
			
			set @add_size = @add_size + @add_growth_size

			set @str_sql =  @str_sql + char(10)
						 + 'ALTER DATABASE  ' + @db_name + ' MODIFY FILE ( NAME = '+@db_name+'_LOG, SIZE = ' + convert(nvarchar(10), @add_size) + 'MB )'
	
			set @i = @i + 1
		end


		-- 8GB �̻� ���� �ʾ��� ��� 1GB�� ����
        if  @log_size -@add_size > 0 
		begin
			select  @tot_loop = ( @LOG_SIZE  -  (@add_size) )  /  (1*1024 )
	

			set @i = 1
			set @add_size = @add_size
			while (@i <= @tot_loop)
			begin
			
				set @add_size = @add_size +1024

				set @str_sql =  @str_sql + char(10)
							 + 'ALTER DATABASE  ' + @db_name + ' MODIFY FILE ( NAME = '+@db_name+'_LOG, SIZE = ' + convert(nvarchar(10), @add_size) + 'MB )'
	
				set @i = @i + 1
			end
		end



	end

	
end
else if @TYPE=  'S' -- dbcc shrinkfile
begin

	select  @log_file = f.name
	from sys.sysaltfiles as f with(nolock) 
		join sys.databases as d with(nolock) on f.dbid = d.database_id
	where  d.name = @db_name
		and f.groupid =0

	set @str_sql = @str_sql + 'DBCC SHRINKFILE('+ @log_file + ', EMPTYFILE) ' + char(10)
	set @str_sql = @str_sql + 'DBCC SHRINKFILE('+ @log_file + ', EMPTYFILE) ' + char(10)

	-- log �ʱ� ���� setting
	if @log_size  <= 1024 -- 1gb ����
	begin

		set @filegrowth = 128
	end
	else if @log_size  > 1024 and @log_size <  8*1024 -- 8gb �̸�
	begin
		set @filegrowth = 512
		set @add_growth_size = 1024 -- 1GB
	end
	else if  @log_size  >=  8*1024 -- 8gb �̻�
	begin
	
		set @filegrowth = 512
		set @add_growth_size = 8*1024 -- 8GB
	end

	
	select @LOG_SIZE AS [�α� Size MB],@filegrowth AS [FILEGRWOTH Size], @add_growth_size AS  [�������� Size]

	-- file ���� 
	SET @tot_loop = 0
	IF @log_size  >=  1024
	begin
		
		select  @tot_loop = round(@LOG_SIZE *1.0 / @add_growth_size,0)

		set @i = 1
		set @add_size = 0
		
		while (@i <= @tot_loop)
		begin
			
			set @add_size = @add_size + @add_growth_size
	
			set @str_sql = @str_sql + char(10)
						+  'ALTER DATABASE  ' + @db_name + ' MODIFY FILE ( NAME = '+@log_file + ', SIZE = ' + convert(nvarchar(10), @add_size) + 'MB )'
			set @i = @i + 1
		end

	

		-- 8GB �̻� ���� �ʾ��� ��� 1GB�� ����
        if  @log_size -@add_size > 0 
		begin
			
			select  @tot_loop = ( @LOG_SIZE  -  (@add_size) )  /  (1*1024 )
	
			set @i = 1
			set @add_size = @add_size
			while (@i <= @tot_loop)
			begin
			
				set @add_size = @add_size +1024

				set @str_sql =  @str_sql + char(10)
							 + 'ALTER DATABASE  ' + @db_name + ' MODIFY FILE ( NAME = '+@log_file+', SIZE = ' + convert(nvarchar(10), @add_size) + 'MB )'
	
				set @i = @i + 1
			end
		end
		


	end
	else
	begin
		set @str_sql = @str_sql + char(10)
						+  'ALTER DATABASE  ' + @db_name + ' MODIFY FILE ( NAME = '+@log_file + ', SIZE = ' + convert(nvarchar(10), @LOG_SIZE) + 'MB )'
	end
		set @str_sql =  @str_sql + char(10)
			+ 'ALTER DATABASE  ' + @db_name + ' MODIFY FILE ( NAME = '+@log_file + ', FILEGROWTH = ' + convert(nvarchar(10), @filegrowth) + 'MB)'+ char(10)

end

	set @str_sql = @str_sql + char(10) + 'DBCC LOGINFO' + CHAR(10) + 'GO'
	print @str_sql