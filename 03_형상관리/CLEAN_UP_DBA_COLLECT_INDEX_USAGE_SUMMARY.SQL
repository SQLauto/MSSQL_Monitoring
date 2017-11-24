--exec UP_DBA_COLLECT_INDEX_USAGE_SUMMARY '2014-08-01'

/*************************************************************************                                                                                            
* 프로시저명  : dbo.UP_DBA_COLLECT_INDEX_USAGE_SUMMARY                                                                                                                    
* 작성정보    : 2015-01-22 by choi bo ra index_usage summary                                                                                                                                       
* 관련페이지  :                                                                                                                                                       
* 내용       :                                                                                               
* 수정정보    : 2015-02-27 BY CHOI BO RA 모든 INDEX 정보 입력
**************************************************************************/  
CREATE PROCEDURE dbo.UP_DBA_COLLECT_INDEX_USAGE_SUMMARY 
	@reg_date		datetime                                                                                                               
	                                                                                                                    
AS 

set nocount on

DECLARE @TABLE_SIZE_REG_DATE DATETIME


SELECT TOP 1 @TABLE_SIZE_REG_DATE = REG_DT FROM TABLE_SIZE WITH(NOLOCK)  WHERE REG_DT <= @REG_DATE ORDER BY REG_DT DESC
--SELECT @TABLE_SIZE_REG_DATE


-- 모든 Index 입력 하기 
insert into [INDEX_USAGE]
(
 reg_date, server_id, database_id, database_name, object_id, schema_name, object_name, index_id, index_name, 
 user_seeks, user_scans, user_lookups, user_updates, 
 last_user_seek, last_user_scan, last_user_lookup, last_user_update, 
 system_seeks, system_scans, system_lookups, system_updates, 
 last_system_seek, last_system_scan, last_system_lookup, last_system_update, META_DATA_EIXST_YN -- 사용 내역 없는 것
 ) 
select  @reg_date, t.server_id, d.db_id, t.db_name, ta.object_id, ta.schema_name, t.table_name, t.INDEX_ID, t.INDEX_NAME,
		0, 0, 0, 0, null, null, null, null,
		0, 0, 0, 0, null, null, null, null, 'N'
from dbo.dba_reindex_total_list_accum as t with(nolock)  -- 인덱스 최신 버전 Total
	left HASH join index_usage as i with(nolock)  on t.server_id = i.server_id and t.db_name = i.database_name 
			and t.table_name = i.object_name and t.index_id = i.index_id
			and i.reg_date >= @reg_date  and i.reg_date < dateadd(dd, 1, @reg_date)
	 join serverinfo as s with(nolock) on  T.server_id = s.server_id and s.use_yn = 'y'
	 join database_list_today as d with(nolock)  on t.server_id = d.server_id and t.db_name = d.db_name
	 join table_size as ta with(nolock) on t.server_id = ta.server_id and t.db_name = ta.db_name and t.table_name = ta.table_name 
	 and ta.reg_dt >= @TABLE_SIZE_REG_DATE  and ta.reg_dt < dateadd(dd, 1, @TABLE_SIZE_REG_DATE)
where i.index_id is null
	and t.is_delete = 0
order by t.server_id, t.db_name, t.table_name



UPDATE I 
	SET USER_DAY_SELECT = case when  (I.USER_SEEKS + I.USER_SCANS + I.USER_LOOKUPS ) > (P.USER_SEEKS + P.USER_SCANS + P.USER_LOOKUPS )  
								and  (SELECT MAX(D) FROM (VALUES (I.LAST_USER_SEEK),(I.LAST_USER_SCAN), (I.LAST_USER_LOOKUP) )  AS value(D) )
										 >  (SELECT MAX(D) FROM (VALUES  (P.LAST_USER_SEEK), (P.LAST_USER_SCAN), (P.LAST_USER_LOOKUP) ) AS value(D) )then 
											 (I.USER_SEEKS + I.USER_SCANS + I.USER_LOOKUPS ) - (P.USER_SEEKS + P.USER_SCANS + P.USER_LOOKUPS ) 
					   when (I.USER_SEEKS + I.USER_SCANS + I.USER_LOOKUPS ) <= (P.USER_SEEKS + P.USER_SCANS + P.USER_LOOKUPS )  then (I.USER_SEEKS + I.USER_SCANS + I.USER_LOOKUPS )
				  else 0  end, 
		user_day_update = case when  (I.USER_UPDATES ) > (P.USER_UPDATES )  and ISNULL(I.last_user_update, '1900-01-01' ) >   ISNULL(P.last_user_update, '1900-01-01')  then 
								(I.USER_UPDATES) - (P.USER_UPDATES )  
							when (I.USER_UPDATES)  <= (P.USER_UPDATES )   then (I.USER_UPDATES) 
							 else 0  end , 
		SYSTEM_DAY_SELECT = case when  (I.SYSTEM_SEEKS + I.SYSTEM_SCANS + I.SYSTEM_LOOKUPS ) > (P.SYSTEM_SEEKS + P.SYSTEM_SCANS + P.SYSTEM_LOOKUPS )  
								and  ( SELECT MAX(D) FROM (VALUES (I.LAST_SYSTEM_SEEK), (I.LAST_SYSTEM_SCAN), (I.LAST_SYSTEM_LOOKUP) )  AS value(D) )
										 > ( SELECT MAX(D) FROM (VALUES  (P.LAST_SYSTEM_SEEK), (P.LAST_SYSTEM_SCAN), (P.LAST_SYSTEM_LOOKUP) )  AS P_SYSTEM_READ(D) )then 
											 (I.SYSTEM_SEEKS + I.SYSTEM_SCANS + I.SYSTEM_LOOKUPS ) - (P.SYSTEM_SEEKS + P.SYSTEM_SCANS + P.SYSTEM_LOOKUPS ) 
					   when (I.SYSTEM_SEEKS + I.SYSTEM_SCANS + I.SYSTEM_LOOKUPS )  <=(P.SYSTEM_SEEKS + P.SYSTEM_SCANS + P.SYSTEM_LOOKUPS )  
						then (I.SYSTEM_SEEKS + I.SYSTEM_SCANS +I.SYSTEM_LOOKUPS )
						else 0  end ,
		SYSTEM_DAY_UPDATE =   case when  (I.SYSTEM_UPDATES ) > (P.SYSTEM_UPDATES )  and ISNULL(I.LAST_SYSTEM_UPDATE, '1900-01-01') 
									 > ISNULL(P.LAST_SYSTEM_UPDATE, '1900-01-01')  then  (I.SYSTEM_UPDATES) - (P.SYSTEM_UPDATES )  
								when (I.SYSTEM_UPDATES)  <= (P.SYSTEM_UPDATES  )  then (I.SYSTEM_UPDATES) 
								else 0  end, 
		LAST_USER_SELECT = (SELECT MAX(D) FROM (VALUES (I.LAST_USER_SEEK),  (I.LAST_USER_SCAN) , (I.LAST_USER_LOOKUP)  )  AS value(D)), 
		LAST_SYSTEM_SELECT = (SELECT MAX(D) FROM (VALUES (I.LAST_SYSTEM_SEEK) , (I.LAST_SYSTEM_SCAN) , (I.LAST_SYSTEM_LOOKUP) ) AS SYSTEM_READ(D) )

/*select  I.SERVER_ID, I.DATABASE_NAME, I.OBJECT_NAME,  I.INDEX_NAME,

				case when  (I.USER_SEEKS + I.USER_SCANS + I.USER_LOOKUPS ) > (P.USER_SEEKS + P.USER_SCANS + P.USER_LOOKUPS )  
								and  (SELECT MAX(D) FROM (VALUES (I.LAST_USER_SEEK),(I.LAST_USER_SCAN), (I.LAST_USER_LOOKUP) )  AS value(D) )
										 >  (SELECT MAX(D) FROM (VALUES  (P.LAST_USER_SEEK), (P.LAST_USER_SCAN), (P.LAST_USER_LOOKUP) ) AS value(D) )then 
											 (I.USER_SEEKS + I.USER_SCANS + I.USER_LOOKUPS ) - (P.USER_SEEKS + P.USER_SCANS + P.USER_LOOKUPS ) 
					   when (I.USER_SEEKS + I.USER_SCANS + I.USER_LOOKUPS )  <(P.USER_SEEKS + P.USER_SCANS + P.USER_LOOKUPS )  then (I.USER_SEEKS + I.USER_SCANS + I.USER_LOOKUPS )
				  else 0  end  AS DAY_USER_SELECT, 
		   case when  (I.USER_UPDATES ) > (P.USER_UPDATES )  and ISNULL(I.last_user_update, '1900-01-01' ) >   ISNULL(P.last_user_update, '1900-01-01')  then 
								(I.USER_UPDATES) - (P.USER_UPDATES )  
							when (I.USER_UPDATES)  < (P.USER_UPDATES )   then (I.USER_UPDATES) 
							 else 0  end  AS DAY_USER_UPDATE , 
		 (SELECT MAX(D) FROM (VALUES (I.LAST_USER_SEEK),  (I.LAST_USER_SCAN) , (I.LAST_USER_LOOKUP)  )  AS value(D)) AS LAST_USER_SELECT , 
		  case when  (I.SYSTEM_SEEKS + I.SYSTEM_SCANS + I.SYSTEM_LOOKUPS ) > (P.SYSTEM_SEEKS + P.SYSTEM_SCANS + P.SYSTEM_LOOKUPS )  
								and  ( SELECT MAX(D) FROM (VALUES (I.LAST_SYSTEM_SEEK), (I.LAST_SYSTEM_SCAN), (I.LAST_SYSTEM_LOOKUP) )  AS value(D) )
										 > ( SELECT MAX(D) FROM (VALUES  (P.LAST_SYSTEM_SEEK), (P.LAST_SYSTEM_SCAN), (P.LAST_SYSTEM_LOOKUP) )  AS P_SYSTEM_READ(D) )then 
											 (I.SYSTEM_SEEKS + I.SYSTEM_SCANS + I.SYSTEM_LOOKUPS ) - (P.SYSTEM_SEEKS + P.SYSTEM_SCANS + P.SYSTEM_LOOKUPS ) 
					   when (I.SYSTEM_SEEKS + I.SYSTEM_SCANS + I.SYSTEM_LOOKUPS )  <(P.SYSTEM_SEEKS + P.SYSTEM_SCANS + P.SYSTEM_LOOKUPS )  
						then (I.SYSTEM_SEEKS + I.SYSTEM_SCANS +I.SYSTEM_LOOKUPS )
						else 0  end  AS DAY_SYSTEM_SELECT,
		   case when  (I.SYSTEM_UPDATES ) > (P.SYSTEM_UPDATES )  and ISNULL(I.LAST_SYSTEM_UPDATE, '1900-01-01') 
									 > ISNULL(P.LAST_SYSTEM_UPDATE, '1900-01-01')  then  (I.SYSTEM_UPDATES) - (P.SYSTEM_UPDATES )  
								when (I.SYSTEM_UPDATES)  < (P.SYSTEM_UPDATES  )  then (I.SYSTEM_UPDATES) 
								else 0  end  AS DAY_SYSTEM_UPDATE,
		 (SELECT MAX(D) FROM (VALUES (I.LAST_SYSTEM_SEEK) , (I.LAST_SYSTEM_SCAN) , (I.LAST_SYSTEM_LOOKUP) ) AS SYSTEM_READ(D) )   AS LAST_SYSTEM_SELECT
*/
	FROM INDEX_USAGE AS I WITH(NOLOCK)
		LEFT  HASH JOIN INDEX_USAGE AS P WITH(NOLOCK)  ON I.SERVER_ID = P.SERVER_ID AND I.DATABASE_NAME = P.DATABASE_NAME AND I.OBJECT_ID = P.OBJECT_ID AND I.INDEX_ID = P.INDEX_ID
			AND P.REG_DATE >= DATEADD(DD, -1, @REG_DATE )  AND P.REG_DATE < @REG_DATE

	WHERE I.REG_DATE >= @REG_DATE  AND I.REG_DATE < DATEADD(DD, 1, @REG_DATE) 
		--AND I.SERVER_ID < 1000


DECLARE @UNUSED_DAY DATE
SELECT TOP 1 @UNUSED_DAY = REG_DATE FROM index_usage  WITH(NOLOCK)  WHERE REG_DATE < @REG_DATE ORDER BY REG_DATE DESC 



UPDATE  I  SET UNUSED_DAY = 
		CASE WHEN I.user_day_select = 0 THEN 
			CASE WHEN I.last_user_select IS NULL AND P.INDEX_NAME IS NOT NULL  THEN  ISNULL(P.UNUSED_DAY,0) + 1   -- 전 일 사용 정보 있으니 미사용 일수 + 1
					WHEN I.last_user_select IS NULL AND P.INDEX_NAME IS NULL THEN 1  -- 전일  사용 정보가 없으면 어쩔 수 없이 미 사용 일 수 1

			ELSE DATEDIFF(DD,I.last_user_select, @REG_DATE) END  -- last 날짜가 있으면.. 
		ELSE 
			CASE WHEN I.last_user_select
					<=P.last_user_select THEN ISNULL(P.UNUSED_DAY,0) + 1 
			ELSE  DATEDIFF(DD,I.last_user_select, @REG_DATE) END
		END
FROM index_usage AS I
LEFT  HASH JOIN index_usage AS P  ON I.SERVER_ID = P.SERVER_ID AND I.DATABASE_NAME = P.DATABASE_NAME AND I.OBJECT_ID = P.OBJECT_ID and i.index_id = p.index_id
AND P.REG_DATE >= @UNUSED_DAY  AND P.REG_DATE < DATEADD(DD, 1, @UNUSED_DAY)
WHERE I.REG_DATE >= @REG_DATE  AND I.REG_DATE < DATEADD(DD, 1, @REG_DATE) 
go