SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_update_disksizehist 
* 작성정보    : 2010-02-10 by  choi bo ra
* 관련페이지  :  
* 내용        : 장비별 디스크별 디비사이즈 총합
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_update_disksizehist

AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
UPDATE  dbo.DISK_SIZE_HIST
     SET  data_file_size = 
            (select sum(convert(numeric(10,2),f.size)) 
                from dbo.DATABASE_FILE_LIST  as f with (nolock)
                where f.server_id = d.server_id and f.instance_id = d.instance_id
                    and left(f.file_full_name, 1) = d.letter
                    and f.reg_dt  >= (select max(reg_dt) from dbo.database_file_list  with (nolock))
               )
FROM  DISK_SIZE_HIST as d 
WHERE d.reg_dt >= (select convert(nvarchar(10), max(reg_dt), 121) from DISK_SIZE_HIST with(nolock))

-- 디스크의 최신 정보를 담음
select  server_id, instance_id, letter, used_yn, memo
into #disk_temp
from disk_size


truncate table  dbo.DISK_SIZE

insert into dbo.DISK_SIZE (server_id, instance_id, letter, disk_size, used_size, data_file_size, reg_dt)
select h.server_id, h.instance_id, h.letter, h.disk_size, h.used_size, h.data_file_size, h.reg_dt 
from DISK_SIZE_HIST  as h with (nolock)  
    join (select server_id, max(reg_dt) as reg_dt from DISK_SIZE_HIST group by server_id) as d
        on h.server_id = d.server_id and h.reg_dt = d.reg_dt
order by h.server_id, h.reg_dt



update disk_size 
set used_yn = t.used_yn
    ,memo = t.memo
from #disk_temp as t  
    inner join disk_size as d on t.server_id = d.server_id and t.instance_id = d.instance_id and t.letter = d.letter

drop table #disk_temp

RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
