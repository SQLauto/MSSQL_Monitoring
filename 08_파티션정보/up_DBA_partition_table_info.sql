SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_insert_partition_table_info' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_insert_partition_table_info
*/

/*************************************************************************  
* ���ν�����  : dbo.up_DBA_insert_partition_table_info 
* �ۼ�����    : 2007-12-07 by choi bo ra
* ����������  :  
* ����        : ��Ƽ�� �׷쿡 ���� row ����
* ��������    : 
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_insert_partition_table_info
   @db_name      SYSNAME
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @reg_dt DATETIME
SET @reg_dt = GETDATE()

/* BODY */


INSERT DBA.dbo.PARTITION_TABLE_INFO (db_name, name, boundary, range, partition_number, 
        file_group, rows, reg_dt)
select  @db_name, object_name(id.object_id) as name, 
	(case spf.boundary_value_on_right when 1 then 'RIGHT' else 'LEFT' end ) as boundary,
       (select case spf.boundary_value_on_right 
    			when 1 then  -- RIGHT
    				(case when sds.destination_id =1  then cast(min(value) as varchar(1000)) + '�̸�'
    					  when sds.destination_id = spf.fanout then cast(max(value) as varchar(1000))+' �̻�'
    					  else cast(min(value) as varchar(1000))+' �̻� ~ ' + cast(max(value) as varchar(1000))+' �̸�' 
    				  end )
    			when 0 then --LEFT
    			    (case when sds.destination_id = 1 then min(cast(value as varchar(1000)))+' ����'
    					  when sds.destination_id = spf.fanout then max(cast(value as varchar(1000)))+' �ʰ�'
    					  else min(cast(value as varchar(1000)))+' �ʰ� ~ ' +  max(cast(value as varchar(1000)))+' ����' 
    				  end)
    			end		 
        from sys.partition_range_values as srv
    	where srv.function_id = spf.function_id
    		and boundary_id between ( case when boundary_id is null  then sds.destination_id else sds.destination_id-1 end)   
    								and sds.destination_id
    	) as range,
    par.partition_number, sfg.name as file_group, par.rows, @reg_dt
from  	sys.partition_schemes as sps 
		inner join sys.partition_functions as spf on sps.function_id = spf.function_id 
		inner join sys.destination_data_spaces as sds on sps.data_space_id = sds.partition_scheme_id 
		inner join sys.filegroups as sfg on sds.data_space_id = sfg.data_space_id
		left join (select * from sys.partitions  WHERE index_id = 1 ) AS par on  sds.destination_id = par.partition_number
		inner join sys.indexes as id on id.object_id = par.object_id  AND id.data_space_id = sps.data_space_id
where id.index_id < 2 
order by id.object_id , par.partition_number

RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO