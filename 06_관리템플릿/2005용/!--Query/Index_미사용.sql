-- =========================
--  사용되지 않은 Index
-- =========================
-- unused tables & indexes.

DECLARE @dbid INT

SET @dbid = DB_ID('AdventureWorks')


SELECT OBJECT_NAME(IDX.object_id) as object_name,
        IDX.name AS index_name,
        CASE WHEN IDX.type = 1 THEN 'Clustered'
          WHEN IDX.type = 2 THEN 'Non-Clustered'
          ELSE 'Unknown' END Index_Type
FROM sys.dm_db_index_usage_stats  AS DIS
       RIGHT OUTER JOIN sys.indexes AS IDX  ON DIS.object_id = IDX.object_id AND DIS.index_id = IDX.index_id
       JOIN sys.objects AS OBJ  ON IDX.object_id = OBJ.object_ID
WHERE  OBJ.type IN ('U', 'V') AND DIS.object_id IS NULL
ORDER BY OBJECT_NAME(IDX.object_id), IDX.name


DECLARE @dbid INT

SET @dbid = DB_ID('AdventureWorks')



--- rarely used indexes appear first

SELECT OBJECT_NAME(DIS.object_id) as object_name,
        IDX.name AS index_name, IDX.index_id,
        CASE WHEN IDX.type = 1 THEN 'Clustered'
          WHEN IDX.type = 2 THEN 'Non-Clustered'
          ELSE 'Unknown' END Index_Type,
         DIS.user_seeks, DIS.user_scans, DIS.user_lookups, DIS.user_updates
FROM sys.dm_db_index_usage_stats AS DIS
             JOIN sys.indexes AS IDX ON DIS.object_id = IDX.object_id AND DIS.index_id = IDX.index_id
WHERE DIS.database_id = @dbid AND objectproperty(DIS.object_id,'IsUserTable') = 1
             AND DIS.user_updates > 0 AND DIS.user_seeks = 0 
             AND DIS.user_scans = 0 AND DIS.user_lookups  = 0  --(업데이트는 일어나는 사용되지 않은것, 관리 부담만 있다.)
			 AND dis.object_id is not null 
ORDER BY (DIS.user_updates + DIS.user_seeks + DIS.user_scans + DIS.user_lookups ) asc



-- ====================
-- SQL 2000용
-- ====================
SELECT  USER_NAME( OBJECTPROPERTY( I.ID, 'DBOWR_WORK' ) ) AS OWNER
   ,OBJECT_NAME( I.ID ) AS [TABLE]
   , I.NAME AS [INDEX]
   ,CASE INDEXPROPERTY( I.ID , I.NAME , 'ISCLUSTERED')  WHEN 1 THEN 'Y'  ELSE ''   END AS ISCLUSTERED
   ,CASE INDEXPROPERTY( I.ID , I.NAME , 'ISUNIQUE'    )  WHEN 1 THEN 'Y'  ELSE ''   END AS ISUNIQUE
   ,STATS_DATE( I.ID , I.INDID ) AS LASTUPDATEDDATE
   ,DPAGES * 8. /1024 AS MB
FROM SYSINDEXES AS I
WHERE OBJECTPROPERTY( I.ID, 'ISMSSHIPPED' ) = 0 
 AND 1 NOT IN ( INDEXPROPERTY( I.ID , I.NAME , 'ISSTATISTICS'   ) 
  , INDEXPROPERTY( I.ID , I.NAME , 'ISAUTOSTATISTICS' ) 
  , INDEXPROPERTY( I.ID , I.NAME , 'ISHYPOTHETICAL'   )  )
 AND I.INDID BETWEEN 1 AND 250
-- AND DPAGES > 100 --작은 크기 테이블 무시
 AND (STATS_DATE( I.ID , I.INDID ) < GETDATE() - 15 
  OR STATS_DATE( I.ID , I.INDID ) IS NULL) --15일 이전까지도 업데이트 안된 것
ORDER BY OWNER, [TABLE], [INDEX]
GO
