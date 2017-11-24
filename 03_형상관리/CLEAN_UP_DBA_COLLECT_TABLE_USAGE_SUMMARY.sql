
/*************************************************************************                                                                                            
* 프로시저명  : dbo.UP_DBA_COLLECT_TABLE_USAGE_SUMMARY                                                                                                                    
* 작성정보    : 2015-01-22 by choi bo ra TABLE USAGAE summary                                                                                                                                       
* 관련페이지  :                                                                                                                                                       
* 내용       :                                                                                               
* 수정정보    : 2015-02-05 BY CHOI BO RA TABLE_SIZE 기준으로 SUMMARY 변경
				table_size가 
			  2015-02-11 BY CHOI BO RA TABLE_USAGE가 없을 경우 최근 날짜를 가져와서 처리 함.
**************************************************************************/  
ALTER PROCEDURE dbo.UP_DBA_COLLECT_TABLE_USAGE_SUMMARY 
	@reg_date		date                                                                                                               
	                                                                                                                    
AS 

set nocount on 


if exists ( select top 1 * from TABLE_USAGE with(nolock) where reg_date =@reg_date  ) 
	delete  TABLE_USAGE where reg_date = @reg_date 

INSERT INTO DBO.TABLE_USAGE
(
REG_DATE
,SERVER_ID
,DATABASE_NAME
,OBJECT_ID
,OBJECT_NAME
,INDEX_CNT
,USER_SELECT
,USER_UPDATE

,SYSTEM_SELECT
,SYSTEM_UPDATE

,LAST_USER_SELECT
,LAST_USER_UPDATE
,LAST_SYSTEM_SELECT
,LAST_SYSTEM_UPDATE

,USER_DAY_SELECT
,USER_DAY_UPDATE
,SYSTEM_DAY_SELECT
,SYSTEM_DAY_UPDATE
)
SELECT 
	  @reg_date
	, V.SERVER_ID
	, V.DB_NAME
	, V.OBJECT_ID
	, V.TABLE_NAME
	, COUNT(*) AS INDEX_CNT
	, SUM(ISNULL(I.USER_SEEKS,0) + ISNULL(I.USER_SCANS,0) + ISNULL(I.USER_LOOKUPS,0) ) AS USER_SELECT
	, SUM(ISNULL(I.USER_UPDATES,0)) AS USER_UPDATES
	, SUM(ISNULL(I.SYSTEM_SEEKS,0) + isnull(I.SYSTEM_SCANS,0) + isnull(I.SYSTEM_LOOKUPS,0)) AS SYSTEM_SELECT
	, SUM(ISNULL(I.SYSTEM_UPDATES,0)) AS SYSTEM_UPDATES
	, (SELECT MAX(D) FROM (VALUES ( MAX(I.LAST_USER_SEEK)),  ( MAX(I.LAST_USER_SCAN) ), (MAX(I.LAST_USER_LOOKUP))  )  AS USER_READ(D)) 
	, MAX(I.LAST_USER_UPDATE) AS LAST_USER_UPDATE
	, (SELECT MAX(D) FROM (VALUES (MAX(I.LAST_SYSTEM_SEEK) ), (MAX(I.LAST_SYSTEM_SCAN) ), (MAX(I.LAST_SYSTEM_LOOKUP)) ) AS SYSTEM_READ(D) )
	, MAX(I.LAST_SYSTEM_UPDATE) AS LAST_SYSTEM_UPDATE
	,case when  SUM(I.USER_SEEKS + I.USER_SCANS + I.USER_LOOKUPS ) > SUM(P.USER_SEEKS + P.USER_SCANS + P.USER_LOOKUPS )  
					and  (SELECT MAX(D) FROM (VALUES (MAX(I.LAST_USER_SEEK)), (MAX(I.LAST_USER_SCAN)), (MAX(I.LAST_USER_LOOKUP)) ) AS USER_READ(D) )
							 >  (SELECT MAX(D) FROM (VALUES  (MAX(P.LAST_USER_SEEK)), (MAX(P.LAST_USER_SCAN)), (MAX(P.LAST_USER_LOOKUP)) ) AS P_USER_READ(D) )then 
								 SUM(I.USER_SEEKS + I.USER_SCANS + I.USER_LOOKUPS ) - SUM(P.USER_SEEKS + P.USER_SCANS + P.USER_LOOKUPS ) 
		   when SUM(I.USER_SEEKS + I.USER_SCANS + I.USER_LOOKUPS )  <SUM(P.USER_SEEKS + P.USER_SCANS + P.USER_LOOKUPS )  then SUM(I.USER_SEEKS + I.USER_SCANS + I.USER_LOOKUPS )
      else 0  end

	  ,case when  SUM(I.USER_UPDATES ) > SUM(P.USER_UPDATES )  and MAX(ISNULL(I.last_user_update, '1900-01-01') ) > MAX( ISNULL(P.last_user_update, '1900-01-01') ) then 
					 SUM(I.USER_UPDATES) - SUM(P.USER_UPDATES )  
		   when SUM(I.USER_UPDATES)  < SUM(P.USER_UPDATES )   then SUM(I.USER_UPDATES) 
      else 0  end

	  ,case when  SUM(I.SYSTEM_SEEKS + I.SYSTEM_SCANS + I.SYSTEM_LOOKUPS ) > SUM(P.SYSTEM_SEEKS + P.SYSTEM_SCANS + P.SYSTEM_LOOKUPS )  
					and  ( SELECT MAX(D) FROM (VALUES (MAX(I.LAST_SYSTEM_SEEK)), (MAX(I.LAST_SYSTEM_SCAN)), (MAX(I.LAST_SYSTEM_LOOKUP)) )  AS SYSTEM_READ(D) )
							 > ( SELECT MAX(D) FROM (VALUES  (MAX(P.LAST_SYSTEM_SEEK)), (MAX(P.LAST_SYSTEM_SCAN)), (MAX(P.LAST_SYSTEM_LOOKUP)) )  AS P_SYSTEM_READ(D) )then 
								 SUM(I.SYSTEM_SEEKS + I.SYSTEM_SCANS + I.SYSTEM_LOOKUPS ) - SUM(P.SYSTEM_SEEKS + P.SYSTEM_SCANS + P.SYSTEM_LOOKUPS ) 
		   when SUM(I.SYSTEM_SEEKS + I.SYSTEM_SCANS + I.SYSTEM_LOOKUPS )  <SUM(P.SYSTEM_SEEKS + P.SYSTEM_SCANS + P.SYSTEM_LOOKUPS )  then SUM(I.SYSTEM_SEEKS + I.SYSTEM_SCANS + I.SYSTEM_LOOKUPS )
      else 0  end

	  ,case when  SUM(I.SYSTEM_UPDATES ) > SUM(P.SYSTEM_UPDATES )  and MAX(ISNULL(I.LAST_SYSTEM_UPDATE, '1900-01-01') ) > MAX( ISNULL(P.LAST_SYSTEM_UPDATE, '1900-01-01') ) then 
					 SUM(I.SYSTEM_UPDATES) - SUM(P.SYSTEM_UPDATES )  
		   when SUM(I.SYSTEM_UPDATES)  < SUM(P.SYSTEM_UPDATES  )  then SUM(I.SYSTEM_UPDATES) 
      else 0  end

FROM 
	TABLE_VINFO_MASTER as V with(nolock, INDEX(UIDX__TABLE_VINFO_MASTER__SERVER_ID__DB_NAME__SCHEMA_NAME__TABLE_NAME))  -- 2015-03-11 일 현재 SCHEMA_NAME != DBO가 아닌것이 없음. 
	LEFT hash JOIN TABLE_SIZE AS T WITH(NOLOCK)  ON V.SERVER_ID = T.SERVER_ID AND V.DB_NAME = T.DB_NAME AND V.SCHEMA_NAME = T.SCHEMA_NAME AND V.TABLE_NAME = T.TABLE_NAME
			  AND T.reg_dt >= @REG_DATE  AND T.reg_dt < DATEADD(DD, 1, @REG_DATE) 
	LEFT hash JOIN DBO.INDEX_USAGE  AS I WITH(NOLOCK)   ON T.SERVER_ID = I.SERVER_ID AND T.DB_NAME = I.DATABASE_NAME AND T.SCHEMA_NAME = I.SCHEMA_NAME AND T.table_name = I.OBJECT_NAME
			AND	I.REG_DATE >= @REG_DATE  AND I.REG_DATE < DATEADD(DD, 1, @REG_DATE) 
	LEFT hash JOIN DBO.INDEX_USAGE AS P WITH(NOLOCK) ON I.SERVER_ID = P.SERVER_ID AND I.DATABASE_NAME = P.DATABASE_NAME AND I.OBJECT_ID = P.OBJECT_ID
		 AND I.INDEX_ID = P.INDEX_ID AND P.REG_DATE >= DATEADD(DD, -1, @REG_DATE )  AND P.REG_DATE < @REG_DATE
GROUP BY  V.SERVER_ID, V.DB_NAME, V.OBJECT_ID, V.TABLE_NAME
ORDER  BY V.SERVER_ID





--UNUSED DAY CHECK 
--last_select, last_update가 null 일 경우는 앞에 날짜 + 1 처리 한다. 
DECLARE @unused_day date

SELECT TOP 1 @UNUSED_DAY = REG_DATE FROM TABLE_USAGE WITH(NOLOCK) WHERE REG_DATE < @REG_DATE ORDER BY REG_DATE DESC




UPDATE I
SET	 unused_day = 	CASE WHEN I.user_day_select + I.user_day_update = 0 THEN 
					CASE WHEN COALESCE (I.last_user_select, I.last_user_update) IS NULL AND P.OBJECT_NAME IS NOT NULL  THEN  ISNULL(P.UNUSED_DAY,0) + 1   -- 전 일 사용 정보 있으니 미사용 일수 + 1
						 WHEN COALESCE (I.last_user_select, I.last_user_update) IS NULL AND P.OBJECT_NAME IS NULL THEN 1  -- 전일  사용 정보가 없으면 어쩔 수 없이 미 사용 일 수 1

					ELSE DATEDIFF(DD,(SELECT MAX(D) FROM (VALUES (I.last_user_select), (I.last_user_update)  ) AS SEEK(D) ), @REG_DATE) END  -- last 날짜가 있으면.. 
				ELSE 
					CASE WHEN (SELECT MAX(D) FROM (VALUES (I.last_user_select), (I.last_user_update)  ) AS SEEK(D) ) 
							<= (SELECT MAX(D) FROM (VALUES (P.last_user_select), (P.last_user_update)  ) AS SEEK(D) )  THEN ISNULL(P.UNUSED_DAY,0) + 1 
					ELSE  
						CASE WHEN DATEDIFF(HH,(SELECT MAX(D) FROM (VALUES (I.last_user_select), (I.last_user_update)  ) AS SEEK(D) ), @REG_DATE) < 24 THEN 0   -- 24시간이 넘지 않으면 0 으로 처리
						ELSE DATEDIFF(DD,(SELECT MAX(D) FROM (VALUES (I.last_user_select), (I.last_user_update)  ) AS SEEK(D) ), @REG_DATE) END
					END
				END
/*
select  I.DATABASE_NAME, I.OBJECT_NAME,  P.OBJECT_NAME, P.REG_DATE,
				CASE WHEN I.user_day_select + I.user_day_update = 0 THEN 
					CASE WHEN COALESCE (I.last_user_select, I.last_user_update) IS NULL AND P.OBJECT_NAME IS NOT NULL  THEN  ISNULL(P.UNUSED_DAY,0) + 1   -- 전 일 사용 정보 있으니 미사용 일수 + 1
						 WHEN COALESCE (I.last_user_select, I.last_user_update) IS NULL AND P.OBJECT_NAME IS NULL THEN 1  -- 전일  사용 정보가 없으면 어쩔 수 없이 미 사용 일 수 1

					ELSE DATEDIFF(DD,(SELECT MAX(D) FROM (VALUES (I.last_user_select), (I.last_user_update)  ) AS SEEK(D) ), @REG_DATE) END  -- last 날짜가 있으면.. 
				ELSE 
					CASE WHEN (SELECT MAX(D) FROM (VALUES (I.last_user_select), (I.last_user_update)  ) AS SEEK(D) ) 
							<= (SELECT MAX(D) FROM (VALUES (P.last_user_select), (P.last_user_update)  ) AS SEEK(D) )  THEN ISNULL(P.UNUSED_DAY,0) + 1 
					ELSE  DATEDIFF(DD,(SELECT MAX(D) FROM (VALUES (I.last_user_select), (I.last_user_update)  ) AS SEEK(D) ), @REG_DATE) END
				END
*/
FROM TABLE_USAGE AS I
	LEFT  hash JOIN TABLE_USAGE AS P  ON I.SERVER_ID = P.SERVER_ID AND I.DATABASE_NAME = P.DATABASE_NAME AND I.OBJECT_ID = P.OBJECT_ID
		AND P.REG_DATE >=@UNUSED_DAY AND P.REG_DATE < DATEADD(DD,1, @UNUSED_DAY)
WHERE I.REG_DATE >= @REG_DATE  AND I.REG_DATE < DATEADD(DD, 1, @REG_DATE) 


