/*************************************************************************  
* 프로시저명  : dbo.up_dba_partition_split
* 작성정보    : 2010-05-26 by choi bo ra
* 관련페이지  : 
* 내용        : 파티션 자동으로 split 하는 sp
* 수정정보    :
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_partition_split 
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET FMTONLY OFF

/* USER DECLARE */
declare @value nvarchar(30), @pre_value nvarchar(30)
declare @function_id int, @diff_day int, @execute_yn char(1), @seq_no int
declare @next_value nvarchar(30), @boundary_id int, @data_space_id int, @step_yn char(1)
declare @sql nvarchar(2000), @next_file_group nvarchar(50), @file_group nvarchar(50)

declare @scheme_name  sysname, @scheme_name_old sysname, @function_name sysname, @object_name nvarchar(128), @ret_code int
declare @dbname sysname, @dbid int, @m_sql nvarchar(1000), @db_name sysname	,@real_value nvarchar(30)


/* BODY */

SET @db_name = db_name()
SET @step_yn ='Y'

--CREATE TABLE #PARTITION_SPLIT_ERROR 
--(
--	seq_no	int identity(1,1) ,
--	db_name sysname,
--	table_name sysname,
--	error_code int,
--	error_message nvarchar(2000),
--	execute_yn char(1)
--)

DECLARE dbname_cursor CURSOR FOR 
	select distinct object_name(s.object_id)
			,ps.name,  pf.function_id,pf.name
			, ps.data_space_id
	from sys.dm_db_partition_stats as s
		inner join sys.indexes i  ON i.OBJECT_ID = s.OBJECT_ID AND i.index_id = s.index_id
		inner join sys.partition_schemes as ps on ps.data_space_id = i.data_space_id 
		inner join sys.partition_functions as pf on pf.function_id = ps.function_id
	where s.index_id IN (0,1)  and object_name(s.object_id) != 'BAD_CONTENT_VIEW_HISTORY'
	
OPEN dbname_cursor       
FETCH next FROM dbname_cursor into @object_name  , @scheme_name, @function_id, @function_name, @data_space_id
WHILE @@fetch_status = 0       
BEGIN  
	

	if isnull(@scheme_name_old,'') != @scheme_name -- 같은 스키마를 쓰는 테이블은 한번만 처리
	begin
		select @value = null, @boundary_id = 0, @pre_value = null, @next_value = null, @real_value = null
		
		select @boundary_id = max(boundary_id) , @value = convert(nvarchar(30),max(value) )
		from sys.partition_range_values  
		where function_id =@function_id

			if isdate(@value) = 0 --날짜가 아니다.
			begin
				
				select @boundary_id = m.boundary_id 
				,@value =convert(nvarchar(30),m.value)
				,@pre_value=convert(nvarchar(30)
				,(select value from sys.partition_range_values  where function_id = @function_id and boundary_id = m.boundary_id -1) ) 
			from 
				( select max(boundary_id) as boundary_id , max(value) as value
				  from sys.partition_range_values  as prv
				  where function_id =@function_id
				) as  m
				
				--select @value, @pre_value, @boundary_id
				
				set @diff_day = convert(int,@value) -convert(int,@pre_value) 
				
				declare @partition_count int
				
				select @partition_count= count(*)
				from sys.dm_db_partition_stats with (nolock)
				where object_id = object_id (@object_name) and index_id  in (0, 1) and row_count =0
					--and partition_number > @boundary_id
				    
				 
				
				if @partition_count > 2  SET @step_yn = 'N'
				else set @step_yn = 'Y'
				
				set @next_value = convert(nvarchar(30),convert(int,@value) + @diff_day)
				
			end
			else  -- 날짜이면
			begin


				select @boundary_id = m.boundary_id 
					,@value =convert(nvarchar(30),m.value)
					,@pre_value=convert(nvarchar(30)
					,(select value from sys.partition_range_values  where function_id = @function_id and boundary_id = m.boundary_id -1) ) 
				from 
					( select max(boundary_id) as boundary_id , max(value) as value
					  from sys.partition_range_values  as prv
					  where function_id =@function_id
						and convert(datetime,value ) <= getdate()  
					) as  m
				
				
				set @diff_day = isnull(datediff (mm, convert(datetime,@pre_value), convert(datetime,@value)),1)
				--select @diff_day

				-- 한달치를 넘기면 안된다.
				if @diff_day > 1 and @@servername != 'PASTDB' set @diff_day  = 1
				

				select  @real_value = convert(nvarchar(30), value )
				from sys.partition_range_values with (nolock)
				where function_id = @function_id and boundary_id = @boundary_id + 1
				
				
				if len(@value) = 10
				begin
					set @next_value = convert(nvarchar(10), dateadd(mm,@diff_day, convert(datetime,@value)), 121)
					set @real_value = convert(nvarchar(10), convert(datetime,@real_value), 121)
					
						if @next_value < convert(nvarchar(8), dateadd(mm, 1, getdate()), 121) + '01'
							set @next_value =convert(nvarchar(8), dateadd(mm, 1, getdate()), 121) + '01'
				end			
				else if len(@value) = 8 
				begin
					set @next_value = convert(nvarchar(8), dateadd(mm,@diff_day, convert(datetime,@value)), 112)
					set @real_value = convert(nvarchar(8), convert(datetime,@real_value), 112)
					
					if @next_value < convert(nvarchar(6), dateadd(mm, 1, getdate()), 112) + '01'
							set @next_value =convert(nvarchar(6), dateadd(mm, 1, getdate()), 112) + '01'
				end
				else 
				begin
					set @next_value = convert(nvarchar(10), dateadd(mm,@diff_day, convert(datetime,@value)), 121)
					set @real_value = convert(nvarchar(10), convert(datetime,@real_value), 121)

					if @next_value < convert(nvarchar(8), dateadd(mm, 1, getdate()), 121) + '01'
							set @next_value =convert(nvarchar(8), dateadd(mm, 1, getdate()), 121) + '01'
				end
					

				if @real_value = @next_value SET @step_yn = 'N'
				else set @step_yn = 'Y'
				
				declare @partition_count int
				
				select @partition_count= count(*)
				from sys.dm_db_partition_stats with (nolock)
				where object_id = object_id (@object_name) and index_id  in (0, 1) and row_count =0
					--and partition_number > @boundary_id
				    
				 
				
				if @partition_count > 2  SET @step_yn = 'N'
				else set @step_yn = 'Y'
				
				--select  @diff_day, @next_value,@value, @pre_value, @step_yn
		 end	


		if @step_yn = 'Y'
		begin
			
			-- 파일 그룹
			select @file_group =sfg.name 
			from sys.destination_data_spaces as sds
			 inner join sys.filegroups as sfg on sds.data_space_id = sfg.data_space_id
			where sds.partition_scheme_id = @data_space_id and sds.destination_id =@boundary_id
				


			-- 파티션 추가 
			if ISNUMERIC ( right(@file_group,1)) = 1
				set @next_file_group =  substring(@file_group, 1,len(@file_group) -1) 
						+ case when  convert(int,right(@file_group,1)) = 3 then 
							convert(nvarchar(2),convert(int,right(@file_group,1)) -2)
						  else convert(nvarchar(2),convert(int,right(@file_group,1)) + 1) end
			else
			   set @next_file_group = @file_group
			 
			--select @next_file_group
			--select @scheme_name

			begin try

			
				set @sql = 'ALTER PARTITION SCHEME ' + @scheme_name + ' NEXT USED ' + @next_file_group + char(10)

				exec sp_executesql @sql
				print @sql

				insert into dba.dbo.PARTITION_SPLIT_ERROR (db_name, table_name, error_code, error_message, execute_yn)
				values (@db_name,  @object_name, 0, @sql, 'Y')
				
				set @seq_no = @@identity


				set @sql = 'ALTER PARTITION FUNCTION ' + @function_name + '() SPLIT RANGE (''' + @next_value + ''') '  + char(10)
				print @sql
				exec sp_executesql @sql

				
				insert into dba.dbo.PARTITION_SPLIT_ERROR (db_name, table_name, error_code, error_message, execute_yn)
				values (@db_name,  @object_name, 0, @sql, 'Y')
				
				set @seq_no = @@identity

				set @sql = 'ALTER PARTITION SCHEME ' + @scheme_name + ' NEXT USED ' + @next_file_group + char(10)
				print @sql
				exec sp_executesql @sql
				
				insert into dba.dbo.PARTITION_SPLIT_ERROR (db_name, table_name, error_code, error_message, execute_yn)
				values (@db_name,  @object_name, 0, @sql, 'Y')
				
				set @seq_no = @@identity

			end try
			begin catch

				 DECLARE @try_error nvarchar(2000)
				 SET @try_error = 'name = ' + @object_name + ' error_no = ' + convert(nvarchar(10), ERROR_NUMBER())  + ' error_msg = ' + ERROR_MESSAGE()+ char(10)
									+ 'STR = ' + @sql
				 set @execute_yn = 'N'
				 set @ret_code = ERROR_NUMBER()
				 
				 insert into dba.dbo.PARTITION_SPLIT_ERROR (db_name, table_name, error_code, error_message, execute_yn)
				 values (@db_name,  @object_name, @ret_code, @try_error, 'N')


			end catch
		end 
	end
SET @sql = ''
SET @scheme_name_old = @scheme_name
FETCH NEXT FROM dbname_cursor INTO @object_name  , @scheme_name, @function_id, @function_name, @data_space_id

end

CLOSE dbname_cursor       
DEALLOCATE dbname_cursor   


RETURN


