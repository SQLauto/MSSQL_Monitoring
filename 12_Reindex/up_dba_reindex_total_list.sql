/*************************************************************************  
* 프로시저명: dbo.up_dba_reindex_total_list
* 작성정보	: 2015-08-13
* 관련페이지:  
* 내용		:  로컬 index dbadb1에 반영 함.

* 수정정보	: 
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_reindex_total_list
	@server_id int
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
-- 결과 update
update  i
	set index_name = w.index_name
		,index_type = w.index_type
		,index_type_desc = w.index_type_desc
		,disabled_yn = w.disabled_yn
		,HYPOTHETICAL_YN = w.HYPOTHETICAL_YN
		,row_count = w.row_count
		,index_size_kb =w.index_size_kb
		,chg_dt =w.chg_dt
		,ISUNIQUE =w.ISUNIQUE
		,unused_index_size_kb = w.unused_index_size_kb
from DBA_REINDEX_TOTAL_LIST_ACCUM_WORK as w
	join DBA_REINDEX_TOTAL_LIST_ACCUM as i 
on w.server_id = i.server_id  and w.db_name = i.db_name and w.table_name = i.table_name and w.index_id =i.index_id
 where i.is_delete =0
 
 -- 신규 입력


insert  DBA_REINDEX_TOTAL_LIST_ACCUM
(
SERVER_NAME
,SERVER_ID
,DB_NAME
,SCHEMA_NAME
,TABLE_NAME
,INDEX_NAME
,OBJECT_ID
,INDEX_ID
,PARTITION_NUMBER
,INDEX_TYPE
,INDEX_TYPE_DESC
,DISABLED_YN
,HYPOTHETICAL_YN
,ROW_COUNT
,INDEX_SIZE_KB
,REG_DT
,CHG_DT
,ISUNIQUE
,UNUSED_INDEX_SIZE_KB
)
select 
w.SERVER_NAME
,w.SERVER_ID
,w.DB_NAME
,w.SCHEMA_NAME
,w.TABLE_NAME
,w.INDEX_NAME
,w.OBJECT_ID
,w.INDEX_ID
,w.PARTITION_NUMBER
,w.INDEX_TYPE
,w.INDEX_TYPE_DESC
,w.DISABLED_YN
,w.HYPOTHETICAL_YN
,w.ROW_COUNT
,w.INDEX_SIZE_KB
,w.REG_DT
,w.CHG_DT
,w.ISUNIQUE
,w.UNUSED_INDEX_SIZE_KB

from DBA_REINDEX_TOTAL_LIST_ACCUM_WORK as w
	left join DBA_REINDEX_TOTAL_LIST_ACCUM as i 
on w.server_id = i.server_id  and w.db_name = i.db_name and w.table_name = i.table_name and w.index_id =i.index_id
where i.index_name is null

-- 없는것 삭제 표시
update DBA_REINDEX_TOTAL_LIST_ACCUM
	set is_delete = 1

 from DBA_REINDEX_TOTAL_LIST_ACCUM_WORK as w
	right join DBA_REINDEX_TOTAL_LIST_ACCUM as i 
on w.server_id = i.server_id  and w.db_name = i.db_name and w.table_name = i.table_name and w.index_id =i.index_id
where i.index_name is null


UPDATE DBA_REINDEX_TOTAL_LIST_ACCUM 
SET IS_DELETE = 1
WHERE  CHG_DT < CONVERT(NVARCHAR(10), dateadd(DD,-8, getdate()), 121) 
 AND SERVER_ID = @server_id 


-- 6개월 이전 Index 삭제
delete DBA_REINDEX_TOTAL_LIST_ACCUM  where is_delete = 1 and chg_dt < dateadd(mm,-6, getdate())
and server_id = @server_id 