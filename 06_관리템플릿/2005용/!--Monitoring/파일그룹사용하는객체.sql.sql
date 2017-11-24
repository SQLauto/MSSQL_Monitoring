-- =====================================================
-- 특정 파일 그룹을 사용하는 사용자 테이블
-- 파일 그룹이 지우거나 확장 하지 못하게 할 때 필요
-- =====================================================

SELECT SG.name, CONVERT(DEC(15,2),SUM(SIZE) /128) AS 'size(MB)'
FROM SYS.SYSFILES AS SF  JOIN SYS.FILEGROUPS AS SG ON SF.GROUPID = DATA_SPACE_ID
WHERE sg.name = 'PRIMARY'
GROUP BY SG.NAME


--1. 테이블 단위로 보기 
SELECT sobj.file_gorup, sobj.name, sps.reserved as 'reserved(MB)', sps.row
FROM
 (
	SELECT object_id , 
		  convert(dec(15,2), SUM (reserved_page_count) / 128) as reserved,  
		  convert(dec(15,2), SUM(  
				   CASE  
					WHEN (index_id < 2) THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count)  
					ELSE lob_used_page_count + row_overflow_used_page_count  
				   END  
				   ) /128) as data,  
		   SUM ( CASE WHEN (index_id < 2) THEN row_count  ELSE 0  END ) as row 
	FROM sys.dm_db_partition_stats 
	GROUP BY object_id 
 ) AS sps
 INNER JOIN 
 (
	SELECT distinct sfg.name  as file_gorup , obj.name, obj.object_id
	FROM sys.indexes as ind
		 inner join sys.filegroups as sfg on ind.data_space_id = sfg.data_space_id
		 inner join sys.objects as obj on ind.object_id = obj.object_id
	WHERE sfg.name = 'PRIMARY'  AND obj.type = 'U'
	UNION ALL
	SELECT DISTINCT sfg.name as file_group , obj.name, obj.object_id
	FROM   sys.partition_schemes as sps 
				inner join sys.destination_data_spaces as sds on sps.data_space_id = sds.partition_scheme_id 
				inner join sys.filegroups as sfg on sds.data_space_id = sfg.data_space_id
				inner join sys.indexes as ind on ind.data_space_id = sps.data_space_id
				inner join sys.objects as obj on ind.object_id = obj.object_id
	WHERE sfg.name = 'PRIMARY'  AND obj.type = 'U' 
  ) AS sobj ON  sps.object_id = sobj.object_id 
ORDER BY sobj.name

-- 2. 인덱스 단위로 보기 
SELECT sobj.file_gorup, sobj.table_name, sps.reserved as 'reserved(MB)', sps.row, sobj.name
FROM 
 (
	SELECT object_id , 
		  convert(dec(15,2), SUM (reserved_page_count) / 128) as reserved,  
		  convert(dec(15,2), SUM(  
				   CASE  
					WHEN (index_id < 2) THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count)  
					ELSE lob_used_page_count + row_overflow_used_page_count  
				   END  
				   ) /128) as data,  
		   SUM ( CASE WHEN (index_id < 2) THEN row_count  ELSE 0  END ) as row 
	FROM sys.dm_db_partition_stats 
	GROUP BY object_id 
 ) AS sps
 INNER JOIN 
 (
	SELECT  sfg.name  as file_gorup ,  ind.object_id, object_name(ind.object_id) as table_name ,  ind.name 
		FROM sys.indexes as ind
			 inner join sys.filegroups as sfg on ind.data_space_id = sfg.data_space_id
			 inner join sys.objects as obj on ind.object_id = obj.object_id
		WHERE sfg.name = 'PRIMARY' 
	UNION ALL
	SELECT DISTINCT sfg.name as file_group, ind.object_id, object_name(ind.object_id) as table_name, ind.name 
	FROM   sys.partition_schemes as sps 
				inner join sys.destination_data_spaces as sds on sps.data_space_id = sds.partition_scheme_id 
				inner join sys.filegroups as sfg on sds.data_space_id = sfg.data_space_id
				inner join sys.indexes as ind on ind.data_space_id = sps.data_space_id
				inner join sys.objects as obj on ind.object_id = obj.object_id
	WHERE sfg.name = 'PRIMARY' 
  ) AS sobj ON  sps.object_id = sobj.object_id 
ORDER BY sobj.table_name, sobj.name