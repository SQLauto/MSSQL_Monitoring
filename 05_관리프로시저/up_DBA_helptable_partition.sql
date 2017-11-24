
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_helptable_partition' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_helptable_partition
*/

/*************************************************************************  
* 프로시저명  : up_DBA_helptable_partition 
* 작성정보    : 2007-10-23 choi bo ra
* 관련페이지  :  
* 내용        : SQL 2005의 파티션 테이블 상세 정보
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE up_DBA_helptable_partition
     @objectname       sysname
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @dbname     sysname, @objid int, @type char(2)  
DECLARE @row_count  int
DECLARE @data_space_id int

/* BODY */
-- 1.null check
IF @objectname IS NULL   
begin  
    EXEC sp_help NULL
    RETURN  
end

-- 2. Make sure the @objname is local to the current database.  
select @dbname = parsename(@objectname,3)  
  
if @dbname is not null and @dbname <> db_name()  
begin  
 raiserror(15250,-1,-1)  
 return (-1)  
end  


-- obejct check   
select @objid = object_id, @type = type  from sys.objects  where object_id = object_id(@objectname)    
if @objid = null   
begin  
      raiserror(15009,-1,-1,@objectname,@dbname)  
      return (-1)  
end 

-- check partition table
SELECT @row_count = COUNT(*) FROM sys.dm_db_partition_stats WHERE object_id = @objid AND index_id = 1 -- Table
IF @row_count < 2
BEGIN
      raiserror(15009,-1,-1, @objectname,@dbname)  
      return (-1) 
END


if  @type in ('U', 'S')  
begin  
    -- data_space_id 알아두기
    select @data_space_id = sps.data_space_id
    from sys.indexes as side  inner join sys.partition_schemes as sps
    		ON side.data_space_id = sps.data_space_id 
    where object_id = @objid AND side.index_id = 1
    
     /*===================================================================================== 
        TABLE Information  
        Database    TableName   Rows  reserved  data  index unused 
    =======================================================================================*/  
    SELECT
    	DB_NAME() AS database_name ,
    	tablename,
    	rows ,
    	reserved ,
    	data ,
    	Used - Data AS index_size ,
    	Reserved - Used AS unused
    FROM ( SELECT	USR.name + '.' + OBJ.name AS TableName ,
    				SUM(CASE WHEN (index_id < 2) THEN row_count ELSE 0 END) AS Rows ,
    				SUM(8 * reserved_page_count) + MAX(COALESCE(LOBDATA.LobReserved,0)) AS reserved,
    				SUM (8*
    					  CASE
    						WHEN (index_id < 2) THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count)
    						ELSE lob_used_page_count + row_overflow_used_page_count
    					END
    			) AS Data,
    			SUM (8*used_page_count)+ MAX(COALESCE(LOBDATA.LobUsed,0)) AS Used
    		FROM dbo.sysobjects AS OBJ
    			INNER JOIN sys.schemas AS USR
    				ON OBJ.uid = USR.schema_id
    			INNER JOIN sys.dm_db_partition_stats AS PS
    				ON PS.object_id = OBJ.id
    			LEFT JOIN(
    				SELECT 
    					parent_id,
    					SUM(8*reserved_page_count) AS LOBReserved,
    					SUM(8*used_page_count) AS LOBUsed
    				FROM sys.dm_db_partition_stats p 
    					INNER JOIN sys.internal_tables it
    					ON p.object_id = it.object_id
    		WHERE it.internal_type IN (202,204)
    		GROUP BY IT.parent_id
    		) AS LOBDATA
    	ON LOBDATA.parent_id = OBJ.Id
    WHERE OBJ.type='U' AND OBJ.id = @objid
    GROUP BY USR.name + '.' + OBJ.name
    ) AS DT
    
    IF @@ERROR <> 0 RETURN
    
    /*===================================================================================== 
        SCHEMA Information  
        Scheme_name   Data_space_id Function_name   Next_filegroup  Function_create Function_modify
    =======================================================================================*/  
    select sps.name as scheme , sps.Data_space_id, spf.name as function_name,
        (case when  spf.fanout < (select count(*) from sys.destination_data_spaces as sdd where sps.data_space_id = sdd.partition_scheme_id)
        	 then  (select sf.name from sys.filegroups as sf inner join sys.destination_data_spaces as sdd
        				on sf.data_space_id = sdd.data_space_id
        			 where sps.data_space_id = sdd.partition_scheme_id and sdd.destination_id > spf.fanout )
        	 else null end) as next_filegroup,
        spf.create_date as function_create, spf.modify_date as function_modify
    from sys.partition_schemes as sps inner join sys.partition_functions as spf
    	ON sps.function_id = spf.function_id
    where sps.data_space_id = @data_space_id
    
     IF @@ERROR <> 0 RETURN
    
    /*==================================================================================
        Function Range
        boundary, range, destination_id, file_group
    ====================================================================================*/
    select (case spf.boundary_value_on_right when 1 then 'RIGHT' else 'LEFT' end ) as boundary,
       (select case spf.boundary_value_on_right 
    			when 1 then  -- RIGHT
    				(case when sds.destination_id =1  then cast(min(value) as varchar(1000)) + '미만'
    					  when sds.destination_id = spf.fanout then cast(max(value) as varchar(1000))+' 이상'
    					  else cast(min(value) as varchar(1000))+' 이상 ~ ' + cast(max(value) as varchar(1000))+' 미만' 
    				  end )
    			when 0 then --LEFT
    			    (case when sds.destination_id = 1 then min(cast(value as varchar(1000)))+' 이하'
    					  when sds.destination_id = spf.fanout then max(cast(value as varchar(1000)))+' 초과'
    					  else min(cast(value as varchar(1000)))+' 초과 ~ ' +  max(cast(value as varchar(1000)))+' 이하' 
    				  end)
    			end		 
        from sys.partition_range_values as srv
    	where srv.function_id = spf.function_id
    		and boundary_id between ( case when boundary_id is null  then sds.destination_id else sds.destination_id-1 end)   
    								and sds.destination_id
    	) as range,
    sds.destination_id, sfg.name as file_group
    from sys.partition_schemes as sps inner join sys.partition_functions as spf
    	on sps.function_id = spf.function_id inner join sys.destination_data_spaces as sds
    	on sps.data_space_id = sds.partition_scheme_id join sys.filegroups as sfg
    	on sds.data_space_id = sfg.data_space_id
    where sps.data_space_id = @data_space_id

	 IF @@ERROR <> 0 RETURN
    
end

RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
