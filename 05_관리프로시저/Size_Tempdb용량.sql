use master
go

/*************************************************************************  
* 프로시저명: dbo.sp_mon_database_size
* 작성정보	: 2012-07-04 by choi bo ra
* 관련페이지:  
* 내용		:  
* 수정정보	:
**************************************************************************/
CREATE PROCEDURE sp_mon_tempdb_database_size

AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare	 @dbsize bigint
		,@logsize bigint
		,@reservedpages  bigint


/* BODY */

select @dbsize = sum(convert(bigint,case when status & 0x40 = 0 then size else 0 end))
	 , @logsize = sum(convert(bigint,case when status & 0x40 <> 0 then size else 0 end))
from tempdb.dbo.sysfiles


select @reservedpages = sum(a.total_pages)
from tempdb.sys.partitions p  WITH(NOLOCK)
	join tempdb.sys.allocation_units a  WITH(NOLOCK) on p.partition_id = a.container_id

SELECT 'tempdb' as database_name, ( @dbsize + @logsize ) * 8192 / 1048576 as database_size, 
	case when @dbsize >= @reservedpages then  (@dbsize -@reservedpages) * 8192 / 1048576 else 0 end
	as unallocated_size

go