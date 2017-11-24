/*************************************************************************  
* 프로시저명: dbo.up_dba_collect_noused_index_target
* 작성정보	: 2015-03-02 by choi bo ra
* 관련페이지:  
* 내용		:  noused_target_index 대상 선정

* 수정정보	: EXEC up_dba_collect_noused_index_target 'G', 90
	TRUNCATE TABLE NOUSED_TARGET_INDEX_LOG
	2015-05-08 by choi bo ra 생성 하는 곳에서 부터 제외 
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_collect_noused_index_target
	@site_gn char(1) = 'G', 
	@unused_day  int = 90
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/

DECLARE @REG_DATE DATE 
set @reg_date = getdate()

IF EXISTS ( SELECT TOP 1 * FROM NOUSED_TARGET_INDEX_LOG  WITH(NOLOCK) WHERE SITE_GN = @SITE_GN  AND PROCESS_TYPE IN ('S','C')) 
begin
	 RAISERROR ('작업 중인 대상이 존재 합니다. (TABLE : NOUSED_TARGET_INDEX_LOG)' , 10,1 ) 
	return
end

DECLARE @TODAY DATETIME

SELECT TOP 1  @TODAY  = I.reg_date   FROM  index_usage AS I WITH(NOLOCK) 
	JOIN SERVERINFO AS S WITH(NOLOCK) ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
WHERE I.REG_DATE <= GETDATE() AND S.SITE_GN = @site_gn
ORDER BY I.REG_DATE DESC

insert into  noused_target_index
( REG_DATE, SERVER_ID, DATABASE_NAME, OBJECT_ID, OBJECT_NAME, INDEX_ID, INDEX_NAME, META_DATA_EXIST_YN, UNUSED_DAY, SIZE, DEL_PROC_TARGET, DEL_YN, UPD_DATE, 
SYNC_UNUSED_DAY, COMMENT , DEV_DEL_YN)

select  @reg_date as reg_date, i.server_id, i.database_name, i.object_id, i.object_name, i.index_id, i.index_name, i.meta_data_eixst_yn, 
	i.unused_day, t.index_size_kb as size, 
	-- unique, clustered, pk 제외 
	case when (t.index_type=1 or t.index_name like 'PK_%' or isnull(t.isunique,0) = 1) then 'N' else 'Y' end as del_proc_target, 'N' as del_yn , getdate() as upd_date , 0, 
	case when (t.index_type=1 or t.index_name like 'PK_%' or isnull(t.isunique,0) = 1)   then 'pk, clusterd, unique index 제외 ' end  as comment, 'N' AS DEV_DEL_YN
--select count(*)
from index_usage as i with(nolock) 
	inner join serverinfo as s with(nolock) on  i.server_id = s.server_id and s.use_yn = 'y'
	inner loop join dba_reindex_total_list_accum as t on t.server_id = i.server_id and t.db_name = i.database_name 
			and t.table_name = i.object_name and t.index_name = i.index_name
	left join db_synk as d with(nolock) on i.server_id = d.sync_server_id  and i.database_name = d.db_name  and d.db_name is not null  -- 싱크되는 정보 제거를 위해
where i.unused_day >= @unused_day 
	and s.site_gn = @site_gn
	and i.reg_date >= @TODAY  and i.reg_date < dateadd(dd, 1, @TODAY)
	and d.server_id is null
	and i.database_name <> 'dbmon'
	--and i.server_id = 160 and i.database_name = 'refer'
order by i.server_id, i.database_name, i.object_name

-- 싱크 정보 갱신 
update  n
set	  sync_unused_day = I.UNUSED_DAY, 
	  upd_date = getdate()
--SELECT TOP 10 I.REG_DATE,I.SERVER_ID, I.DATABASE_NAME, I.INDEX_NAME, I.UNUSED_DAY,N.*
from noused_target_index as n with(nolock)
	join serverinfo as s with(nolock) on n.server_id = s.server_id and s.use_yn ='Y'
	join db_synk as d with(nolock) on n.server_id = d.server_id and n.database_name  = d.db_name
	join index_usage as i with(nolock)  on D.sync_server_id = i.server_id and n.database_name = i.database_name 
		and n.object_name = i.object_name and i.index_name= n.index_name
WHERE n.reg_date = @reg_date 
	and i.reg_date >= @TODAY  and i.reg_date < dateadd(dd, 1, @TODAY)
	AND s.site_gn = @site_gn



INSERT INTO NOUSED_TARGET_INDEX_LOG 
( REG_DATE, SITE_GN, PROCESS_TYPE )
VALUES 
( GETDATE(), @SITE_GN, 'S')



