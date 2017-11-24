/*************************************************************************  
* : dbo.up_dba_collect_noused_table_target
* 	: 2015-03-02 by choi bo ra
* :  
* 		:  noused_target_table  

* 	: EXEC up_dba_collect_noused_table_target 'G', 180
	TRUNCATE TABLE NOUSED_TARGET_TABLE_LOG
	2015-05-12 by choi bo ra  unused_  
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_collect_noused_table_target
	@site_gn char(1) = 'G', 
	@unused_day  int = 180
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/

DECLARE @REG_DATE DATE 
set @reg_date = getdate()

IF EXISTS ( SELECT TOP 1 * FROM NOUSED_TARGET_TABLE_LOG  WITH(NOLOCK) WHERE SITE_GN = @SITE_GN  AND PROCESS_TYPE IN ('S','C')) 
begin
	 RAISERROR ('    . (TABLE : NOUSED_TARGET_INDEX_LOG)' , 10,1 ) 
	return
end

DECLARE @TODAY DATETIME

SELECT TOP 1  @TODAY  = I.reg_date   FROM  table_usage AS I WITH(NOLOCK) 
	JOIN SERVERINFO AS S WITH(NOLOCK) ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
WHERE I.REG_DATE <= GETDATE() AND S.SITE_GN = @site_gn
ORDER BY I.REG_DATE DESC

insert into  noused_target_table
( REG_DATE, SERVER_ID, DATABASE_NAME, OBJECT_ID, OBJECT_NAME, UNUSED_DAY, SIZE, DEL_PROC_TARGET, DEL_YN, UPD_DATE, SYNC_UNUSED_DAY, DEV_DEL_YN )
select  @REG_DATE as reg_date, i.server_id, i.database_name, i.object_id, i.object_name, i.unused_day, t.reserved as size, 'Y' as del_proc_target, 'N' as del_yn , getdate() as upd_date , 0, 'Y'
--select count(*)
from table_usage as i with(nolock) 
	inner join serverinfo as s with(nolock) on  i.server_id = s.server_id and s.use_yn = 'y'
	inner loop join table_size as t on t.server_id = i.server_id and t.db_name = i.database_name and t.table_name = i.object_name and t.reg_dt > getdate()-1
	left join db_synk as d with(nolock) on i.server_id = d.sync_server_id  and i.database_name = d.db_name  and d.db_name is not null  --    
where i.unused_day >= @unused_day 
	and s.site_gn = @site_gn
	and i.reg_date >= @TODAY  and i.reg_date < dateadd(dd, 1, @TODAY)
	and d.server_id is null
	and i.database_name <> 'dbmon'
	and  ( i.object_name not like 'unused_%' OR  i.object_name not like 'SYS%' ) 
	--and i.server_id = 160 and i.database_name = 'refer'
order by i.server_id, i.database_name, i.object_name

--    
update  n
set	  sync_unused_day = I.UNUSED_DAY, 
	  upd_date = getdate()
--SELECT TOP 10 I.REG_DATE,I.SERVER_ID, I.DATABASE_NAME, I.INDEX_NAME, I.UNUSED_DAY,N.*
from noused_target_table as n with(nolock)
	join serverinfo as s with(nolock) on n.server_id = s.server_id and s.use_yn ='Y'
	join db_synk as d with(nolock) on n.server_id = d.server_id and n.database_name  = d.db_name
	join table_usage as i with(nolock)  on D.sync_server_id = i.server_id and n.database_name = i.database_name and n.object_name = i.object_name
WHERE n.reg_date = @reg_date 
	and i.reg_date >= @TODAY  and i.reg_date < dateadd(dd, 1, @TODAY)
	AND s.site_gn = @site_gn

INSERT INTO NOUSED_TARGET_TABLE_LOG 
( REG_DATE, SITE_GN, PROCESS_TYPE )
VALUES 
( GETDATE(), @SITE_GN, 'S')





