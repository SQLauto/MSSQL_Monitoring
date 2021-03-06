
/*********************************  *****************************************************/
/* 2010-08-25 10:52 
 2014-10-27 BY CHOI BO RA  TOTAL_SUM  
 2014-11-24 BY CHOI BO RA  query_hash,query_plan_hash 추가 
 2014-12-01 BY CHOI BO RA  PREAPARE, ADHOC과 구분 
*/
CREATE PROCEDURE [DBO].[UP_MON_COLLECT_QUERY_STATS_TOTAL_V3]  
AS  
SET NOCOUNT ON  
SET QUERY_GOVERNOR_COST_LIMIT 0  
EXEC UP_SWITCH_PARTITION @TABLE_NAME = 'DB_MON_QUERY_STATS_TOTAL_V3', @COLUMN_NAME = 'REG_DATE'   
   
  
DECLARE @REG_DATE DATETIME  
DECLARE @ERROR_NUM INT, @ERROR_MESSAGE SYSNAME  
SET @REG_DATE = GETDATE() 

BEGIN TRY

 
--  
INSERT DB_MON_QUERY_STATS_TOTAL_V3  
 (REG_DATE, PLAN_HANDLE, STATEMENT_START, STATEMENT_END, DB_ID, OBJECT_ID, SET_OPTIONS, CREATE_DATE,  
  CNT, CPU, WRITES, READS, DURATION, OBJECT_NAME, QUERY_TEXT,sql_handle, query_hash,query_plan_hash)   
SELECT 
	 @reg_date, 
	 --CASE WHEN cp.objtype = 'Prepared' THEN 'P'
		--  WHEN cp.objtype = 'Adhoc' THEN 'A'
		--  WHEN cp.objtype = 'Trigger' THEN 'T'
		--  ELSE 'S' END TYPE,
	 --CASE WHEN CONVERT(VARBINARY, LEFT(SQL_HANDLE, 1)) = 0X02 THEN 'P' ELSE 'S' END TYPE,
	 QS.PLAN_HANDLE,   
	 QS.STATEMENT_START_OFFSET  AS STATEMENT_START,   
	 QS.STATEMENT_END_OFFSET AS STATEMENT_END,   
	 QT.DBID,   
	 QT.OBJECTID,   
	 (SELECT CONVERT(INT, VALUE) FROM SYS.DM_EXEC_PLAN_ATTRIBUTES(QS.PLAN_HANDLE) WHERE ATTRIBUTE = 'SET_OPTIONS') AS SET_OPTIONS,   
	 QS.CREATION_TIME,  
	 QS.EXECUTION_COUNT AS CNT,  
	 QS.TOTAL_WORKER_TIME AS CPU,  
	 QS.TOTAL_LOGICAL_WRITES AS WRITES,  
	 QS.TOTAL_LOGICAL_READS AS READS,  
	 QS.TOTAL_ELAPSED_TIME AS DURATION, 
	 OBJECT_NAME(QT.OBJECTID, QT.DBID)  AS OBJECT_NAME, 
	CASE WHEN CONVERT(VARBINARY, LEFT(SQL_HANDLE, 1)) = 0X02 THEN
			CASE WHEN LEN(QT.TEXT) < (STATEMENT_END_OFFSET / 2) + 1 THEN QT.TEXT
			WHEN SUBSTRING(QT.TEXT, (STATEMENT_START_OFFSET/2), 2) LIKE N'[A-ZA-Z0-9][A-ZA-Z0-9]' THEN QT.TEXT
			ELSE
				CASE
					WHEN STATEMENT_START_OFFSET > 0 THEN
						SUBSTRING
						(	QT.TEXT,((STATEMENT_START_OFFSET/2) + 1),
							(
								CASE
									WHEN STATEMENT_END_OFFSET = -1 THEN 2147483647
									ELSE ((STATEMENT_END_OFFSET - STATEMENT_START_OFFSET)/2) + 1
								END
							)
						)
					ELSE RTRIM(LTRIM(QT.TEXT))
				END
			END
		ELSE NULL END as query_text, 
		QS.SQL_HANDLE, 
		QS.query_hash,
		QS.query_plan_hash
FROM SYS.DM_EXEC_QUERY_STATS   AS QS 
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(QS.PLAN_HANDLE)  AS QT 
WHERE SUBSTRING(QS.SQL_HANDLE, 3, 1) <> 0XFF


-- DELETE Adhoc 삭제 
DELETE DB_MON_QUERY_STATS_TOTAL_V3
FROM DB_MON_QUERY_STATS_TOTAL_V3 AS QS
	INNER JOIN SYS.DM_EXEC_CACHED_PLANS AS CP ON QS.PLAN_HANDLE=CP.PLAN_HANDLE
WHERE REG_DATE = @REG_DATE
	AND CP.objtype = 'Adhoc'

--   UPDATE
UPDATE QS
	SET TYPE = 
		CASE WHEN cp.objtype = 'Prepared' THEN 'P'
			  WHEN cp.objtype = 'Trigger' THEN 'T'
			  ELSE 'S' END 
FROM DB_MON_QUERY_STATS_TOTAL_V3 AS QS
	INNER JOIN SYS.DM_EXEC_CACHED_PLANS AS CP ON QS.PLAN_HANDLE=CP.PLAN_HANDLE
WHERE REG_DATE = @REG_DATE



UPDATE DB_MON_QUERY_STATS_TOTAL_V3
	SET OBJECT_NAME = SUBSTRING(QUERY_TEXT, CHARINDEX('--SP::',QUERY_TEXT)+6, CHARINDEX('::SP', QUERY_TEXT)-6-CHARINDEX('--SP::',QUERY_TEXT))
WHERE REG_DATE = @REG_DATE
	AND TYPE = 'P'
	AND CHARINDEX('::SP', QUERY_TEXT) > 0 
	AND query_text not like '%query_text%'  --    .



/*
INSERT DB_MON_QUERY_STATS_TOTAL_V3  
 (REG_DATE, PLAN_HANDLE, STATEMENT_START, STATEMENT_END, DB_ID, OBJECT_ID, SET_OPTIONS, CREATE_DATE,  
  CNT, CPU, WRITES, READS, DURATION, OBJECT_NAME, QUERY_TEXT)  
SELECT   
 @REG_DATE,  
 QS.PLAN_HANDLE,   
 QS.STATEMENT_START,   
 QS.STATEMENT_END,   
 ISNULL(QT.DBID,-1) AS DB_ID,   
 QT.OBJECTID,   
 (SELECT CONVERT(INT, VALUE) FROM SYS.DM_EXEC_PLAN_ATTRIBUTES(QS.PLAN_HANDLE) WHERE ATTRIBUTE = 'SET_OPTIONS') AS SET_OPTIONS,   
 QS.CREATION_TIME,  
 QS.CNT,  
 QS.CPU,  
 QS.WRITES,  
 QS.READS,  
 QS.DURATION  ,
 SUBSTRING(QT.TEXT, CHARINDEX('--SP::',QT.TEXT)+6, CHARINDEX('::SP', QT.TEXT)-6-CHARINDEX('--SP::',QT.TEXT)) AS OBJECT_NAME 
,CASE WHEN CONVERT(VARBINARY, LEFT(SQL_HANDLE, 1)) = 0X02 THEN 
		SUBSTRING(QT.TEXT, CHARINDEX('SELECT --SP::',QT.TEXT), LEN(QT.TEXT))
 ELSE NULL 
 END AS QUERY_TEXT
FROM (   
 SELECT   
    SQL_HANDLE
  , PLAN_HANDLE   
  , STATEMENT_START_OFFSET AS STATEMENT_START  
  , STATEMENT_END_OFFSET AS STATEMENT_END  
  , CREATION_TIME  
  , EXECUTION_COUNT AS CNT  
  , TOTAL_WORKER_TIME AS CPU  
  , TOTAL_LOGICAL_WRITES AS WRITES  
  , TOTAL_LOGICAL_READS AS READS  
  , TOTAL_ELAPSED_TIME AS DURATION   
 FROM SYS.DM_EXEC_QUERY_STATS  
 WHERE CONVERT(VARBINARY, LEFT(SQL_HANDLE, 1)) IN ( 0X02)
    AND SUBSTRING(SQL_HANDLE, 3, 1) <> 0XFF			-- SYSTEM   
) QS  
CROSS APPLY SYS.DM_EXEC_SQL_TEXT(QS.PLAN_HANDLE) AS QT  
WHERE (CONVERT(VARBINARY, LEFT(SQL_HANDLE, 1)) = 0X02 AND QT.TEXT IS NOT NULL AND QT.TEXT LIKE '%SP::%' AND QT.TEXT LIKE '%::SP%')
*/

END TRY
BEGIN CATCH
	SET @ERROR_NUM = ERROR_NUMBER() 
	SET @ERROR_MESSAGE = ERROR_MESSAGE()

	RAISERROR (N'UP_MON_COLLECT_QUERY_STATS_TOTAL_V3- NUM: %d , MESSAGE: %s', -- MESSAGE TEXT.
           16, 
           1, 
           @ERROR_NUM, 
           @ERROR_MESSAGE);

END CATCH




