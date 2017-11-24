/*************************************************************************  
* ���ν�����: dbo.up_dba_collect_noused_table_target_update
* �ۼ�����	: 2015-03-16 ������
* ����������:  
* ����		:  noused_target_table ���̺� �۾� �� ���� ����

* ��������	: EXEC up_dba_collect_noused_table_target_update 'G',180
			 2015-03-25 by choi bo ra  ��� update ���� ����
**************************************************************************/
alter PROCEDURE dbo.up_dba_collect_noused_table_target_update
	@site_gn char(1) = 'G', 
	@unused_day int = 180
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

SELECT TOP 1  @TODAY  = I.reg_date   FROM  table_usage AS I WITH(NOLOCK) 
	JOIN SERVERINFO AS S WITH(NOLOCK) ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
WHERE I.REG_DATE <= GETDATE() AND S.SITE_GN = @site_gn
ORDER BY I.REG_DATE DESC




-- �̻�� �ϼ� ����
update  n
set	 unused_day = I.UNUSED_DAY, 
	 upd_date = getdate()
--SELECT TOP 10 N.*  ,  I.REG_DATE,I.SERVER_ID, I.DATABASE_NAME, I.object_name, I.UNUSED_DAY
from noused_target_table as n with(nolock)
	join serverinfo as s with(nolock) on n.server_id = s.server_id and s.use_yn ='Y'
	join table_usage as i with(nolock)  on N.SERVER_ID = i.server_id and n.database_name = i.database_name 
		and n.object_name = i.object_name
	left join db_synk as d with(nolock) on N.server_id = d.sync_server_id  and N.database_name = d.db_name 
WHERE N.REG_DATE = @REG_DATE 
    AND i.reg_date >= @TODAY  and i.reg_date < dateadd(dd, 1, @TODAY)
	AND s.site_gn = @site_gn
	ANd n.del_yn = 'N' -- ���� �ȵȰ� �� ����
	AND n.dev_del_yn = 'N'
	AND n.database_name != 'DBA'

IF (@PROCESS_TYPE = 'S')
BEGIN
	-- �ű� �߰� 
	insert into  noused_target_table
	( REG_DATE, SERVER_ID, DATABASE_NAME, OBJECT_ID, OBJECT_NAME, UNUSED_DAY, SIZE, DEL_PROC_TARGET, DEL_YN, UPD_DATE, SYNC_UNUSED_DAY , DEV_DEL_YN )
	select  @REG_DATE as reg_date, i.server_id, i.database_name, i.object_id, i.object_name, i.unused_day, t.reserved as size, 'Y' as del_proc_target, 'N' as del_yn , getdate() as upd_date , 0
	, 'N'
	--select count(*)
	from table_usage as i with(nolock) 
		inner join serverinfo as s with(nolock) on  i.server_id = s.server_id and s.use_yn = 'y'
		inner loop join table_size as t on t.server_id = i.server_id and t.db_name = i.database_name and t.table_name = i.object_name and t.reg_dt > getdate()-1
		left join db_synk as d with(nolock) on i.server_id = d.sync_server_id  and i.database_name = d.db_name  and d.db_name is not null  -- ��ũ�Ǵ� ���� ���Ÿ� ����
		left join noused_target_table as ti with(nolock) on  i.server_id = ti.server_id and i.database_name = ti.database_name  and i.object_name = ti.object_name 
	where i.unused_day >= @unused_day 
		and s.site_gn = @site_gn
		and i.reg_date >= @TODAY  and i.reg_date < dateadd(dd, 1, @TODAY)
		and d.server_id is null
		and ti.object_name is null
		and i.database_name <> 'dbmon'
		and ( i.object_name not like 'unused_%'  OR  I.OBJECT_NAME NOT LIKE 'SYS%')
		--and i.server_id = 160 and i.database_name = 'refer'
	order by i.server_id, i.database_name, i.object_name

END

-- ��ũ ���� ���� 
update  n
set	 sync_unused_day = I.UNUSED_DAY, 
	  upd_date = getdate()
--SELECT TOP 10 I.REG_DATE,I.SERVER_ID, I.DATABASE_NAME, I.INDEX_NAME, I.UNUSED_DAY,N.*
from noused_target_table as n with(nolock)
	join serverinfo as s with(nolock) on n.server_id = s.server_id and s.use_yn ='Y'
	join db_synk as d with(nolock) on n.server_id = d.server_id and n.database_name  = d.db_name
	join table_usage as i with(nolock)  on D.sync_server_id = i.server_id and n.database_name = i.database_name and n.object_name = i.object_name 
WHERE n.reg_date = @reg_date 
	 AND i.reg_date >= @TODAY  and i.reg_date < dateadd(dd, 1, @TODAY)
	AND s.site_gn = @site_gn
	AND n.dev_del_yn ='N' AND  n.del_yn ='N'    -- DEV, REAL ���� ���� ���� �͸� ����
		AND n.database_name != 'DBA'



-- ��ũ ���� del_proc_target update
update N
	set DEL_PROC_TARGET = case when unused_day >= @unused_day  and sync_unused_day >= @unused_day  then 'Y'  else 'N' end, 
		comment = case when unused_day >= @unused_day  and sync_unused_day >= @unused_day then null else '���� �� ��ȸ �߻�' end, 
		upd_date = getdate()		
from noused_target_table as n with(nolock)
	join serverinfo as s with(nolock) on n.server_id = s.server_id and s.use_yn ='Y'
	join db_synk as d with(nolock) on n.server_id = d.server_id and n.database_name  = d.db_name
WHERE n.reg_date = @reg_date 
	AND s.site_gn = @site_gn
	AND n.dev_del_yn ='N' AND  n.del_yn ='N'    -- DEV, REAL ���� ���� ���� �͸� ����
		AND n.database_name != 'DBA'



-- non ��ũ ���� del_proc_target update
update N
	set DEL_PROC_TARGET = case when unused_day >= @unused_day  then 'Y'  else 'N' end, 
		comment = case when unused_day >= @unused_day then null else '������ ��ȸ �߻�' end, 
		upd_date = getdate()		
from noused_target_table as n with(nolock)
	join serverinfo as s with(nolock) on n.server_id = s.server_id and s.use_yn ='Y'
	left join db_synk as d with(nolock) on n.server_id = d.server_id and n.database_name  = d.db_name
WHERE n.reg_date = @reg_date 
	AND s.site_gn = @site_gn
	and d.server_id is null
	AND n.dev_del_yn ='N' AND  n.del_yn ='N'    -- DEV, REAL ���� ���� ���� �͸� ����
		AND n.database_name != 'DBA'



