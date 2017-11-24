/*************************************************************************  
* : dbo.up_dba_collect_noused_index_target_update
* 	: 2015-03-02 by choi bo ra
* :  
* 		:  noused_target_index     

* 	: EXEC up_dba_collect_noused_index_target_update 'G'
	- 20150429  UNIQUE INDEX   
	-- 20160813 삭제된 INDEX는 제거 되어야 함.
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_collect_noused_index_target_update
	@site_gn char(1) = 'G', 
	@unused_day int = 90
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/

DECLARE @REG_DATE DATE 
DECLARE @PROCESS_TYPE CHAR(1)
SELECT @PROCESS_TYPE = PROCESS_TYPE FROM NOUSED_TARGET_INDEX_LOG WITH(NOLOCK) WHERE PROCESS_TYPE IN ('S','C') AND SITE_GN = @site_gn
SELECT @REG_DATE = REG_DATE FROM NOUSED_TARGET_INDEX_LOG WITH(NOLOCK) WHERE PROCESS_TYPE =@PROCESS_TYPE AND SITE_GN =@site_gn

IF @reg_date is null 
	return

DECLARE @TODAY DATETIME

SELECT TOP 1  @TODAY  = I.reg_date   FROM  index_usage AS I WITH(NOLOCK) 
	JOIN SERVERINFO AS S WITH(NOLOCK) ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
WHERE I.REG_DATE <= GETDATE() AND S.SITE_GN = @site_gn
ORDER BY I.REG_DATE DESC



--   
update  n
set	 unused_day = I.UNUSED_DAY, 
	 upd_date = getdate()
--SELECT TOP 10 N.*  ,  I.REG_DATE,I.SERVER_ID, I.DATABASE_NAME, I.INDEX_NAME, I.UNUSED_DAY
from noused_target_index as n with(nolock)
	join serverinfo as s with(nolock) on n.server_id = s.server_id and s.use_yn ='Y'
	join index_usage as i with(nolock)  on N.SERVER_ID = i.server_id and n.database_name = i.database_name 
		and n.object_name = i.object_name and i.index_name= n.index_name 
	--left join db_synk as d with(nolock) on N.server_id = d.sync_server_id  and N.database_name = d.db_name  and d.db_name is not null
WHERE N.REG_DATE = @REG_DATE 
    AND i.reg_date >= @TODAY  and i.reg_date < dateadd(dd, 1, @TODAY)
	AND s.site_gn = @site_gn
	ANd n.del_yn = 'N' --    
	AND n.dev_del_yn = 'N'


IF (@PROCESS_TYPE = 'S')  -- S   
BEGIN
	--   
	insert into  noused_target_index
	( REG_DATE, SERVER_ID, DATABASE_NAME, OBJECT_ID, OBJECT_NAME, INDEX_ID, INDEX_NAME, META_DATA_EXIST_YN, UNUSED_DAY, SIZE, DEL_PROC_TARGET, DEL_YN, UPD_DATE, 
		SYNC_UNUSED_DAY, comment)

	select  @reg_date as reg_date, i.server_id, i.database_name, i.object_id, i.object_name, i.index_id, i.index_name, i.meta_data_eixst_yn, 
		i.unused_day, t.index_size_kb as size, 
		case when (t.index_type=1 or t.index_name like 'PK_%' or isnull(t.isunique,0) = 1)  then 'N' else 'Y' end as del_proc_target, 'N' as del_yn , getdate() as upd_date , 0, 
		case when (t.index_type=1 or t.index_name like 'PK_%' or isnull(t.isunique,0) = 1)   then 'pk, clusterd, unique index  ' end  as comment
	--select count(*)
	from index_usage as i with(nolock) 
		inner join serverinfo as s with(nolock) on  i.server_id = s.server_id and s.use_yn = 'Y'
		inner loop join dba_reindex_total_list_accum as t on t.server_id = i.server_id and t.db_name = i.database_name 
				and t.table_name = i.object_name and t.index_name = i.index_name
		left join db_synk as d with(nolock) on i.server_id = d.sync_server_id  and i.database_name = d.db_name  and d.db_name is not null  --    
		left join noused_target_index as ti with(nolock) on  i.server_id = ti.server_id and i.database_name = ti.database_name  and i.object_name = ti.object_name 
				and i.index_name = t.index_name   AND ti.reg_date = @reg_date
	where i.unused_day >= @unused_day 
		and s.site_gn = @site_gn
		and i.reg_date >= @TODAY  and i.reg_date < dateadd(dd, 1, @TODAY)
		and d.server_id is null
		and ti.index_name is null
		and t.IS_DELETE = 0
		and i.database_name <> 'dbmon'
		--and i.server_id = 160 and i.database_name = 'refer'
	order by i.server_id, i.database_name, i.object_name

END


--싱크정보 갱신
update  n
set	 sync_unused_day = case when i.index_name is null  then 90 else I.UNUSED_DAY end,
	  upd_date = getdate()
--SELECT TOP 10 I.REG_DATE,I.SERVER_ID, I.DATABASE_NAME, I.INDEX_NAME, I.UNUSED_DAY,N.*
from noused_target_index as n with(nolock)
	join serverinfo as s with(nolock) on n.server_id = s.server_id and s.use_yn ='Y'
	join db_synk as d with(nolock) on n.server_id = d.server_id and n.database_name  = d.db_name
	left join index_usage as i with(nolock)  on D.sync_server_id = i.server_id and n.database_name = i.database_name 
		and n.object_name = i.object_name and i.index_name= n.index_name  AND i.reg_date >= @TODAY  and i.reg_date < dateadd(dd, 1, @TODAY)
WHERE n.reg_date = @reg_date 
	AND s.site_gn = @site_gn
	AND n.dev_del_yn ='N' AND  n.del_yn ='N'    -- DEV, REAL     
	
	
--싱크 되는 서버의 TARGET UPDATE
update n 
	set 	DEL_PROC_TARGET = case when unused_day >= @unused_day  and sync_unused_day >= @unused_day then 'Y' else 'N' end, 
	comment = case when unused_day >= @unused_day  and sync_unused_day >= @unused_day    then null else '   ' end, 
	upd_date = getdate()									
from noused_target_index as n with(nolock)
	join serverinfo as s with(nolock) on n.server_id = s.server_id and s.use_yn ='Y'
	join db_synk as d with(nolock) on n.server_id = d.server_id and n.database_name  = d.db_name
WHERE n.reg_date = @reg_date 
	AND s.site_gn = @site_gn
	AND n.dev_del_yn ='N' AND  n.del_yn ='N'    -- DEV, REAL     
	--AND N.COMMENT <> '      '


--싱크 되지 않은 서버의 TARGET UPDATE
update n 
	set  DEL_PROC_TARGET = case when unused_day >=@unused_day  then 'Y' else 'N' end, 
	comment = case when unused_day >= @unused_day then null else '   ' end, 
	upd_date = getdate()	
--select n.*
from noused_target_index as n with(nolock)
	join serverinfo as s with(nolock) on n.server_id = s.server_id and s.use_yn ='Y'
	left join db_synk as d with(nolock) on n.server_id = d.server_id and n.database_name  = d.db_name
WHERE n.reg_date = @reg_date
		AND s.site_gn = @site_gn
	and d.server_id is null
	AND n.dev_del_yn ='N' AND  n.del_yn ='N'    -- DEV, REAL     
	--AND N.COMMENT <> '      '



update n 
	set  DEL_PROC_TARGET = 'N'
--SELECT *
from noused_target_index as n with(nolock)
where del_proc_target = 'Y' and  ( INDEX_ID=1 or index_name like 'PK_%' ) AND n.reg_date = @reg_date
	and dev_del_yn = 'N' and del_yn = 'N'

-- UNIQUE INDEX    
update n 
	set  del_proc_target = 'N'
--SELECT *
from noused_target_index as n with(nolock)
	inner loop join dba_reindex_total_list_accum as t on t.server_id = N.server_id and t.db_name = n.database_name 
			and t.table_name = n.object_name and t.index_name = n.index_name
where del_proc_target = 'Y' and  isnull(t.isunique,0) = 1  AND n.reg_date = @reg_date
	and dev_del_yn = 'N' and del_yn = 'N'

-- 삭제된 index는 제거 한다. 
delete ti
from noused_target_index as ti
	 inner loop join dba_reindex_total_list_accum as t on t.server_id = ti.server_id and t.db_name = ti.database_name 
				and t.table_name = ti.object_name and t.index_name = ti.index_name
where t.is_delete = 1
 and ti.reg_date = @reg_date
go

