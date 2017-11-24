SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_report_database_disk
* 작성정보    : 2010-07-01 by choi bo ra
* 관련페이지  : 
* 내용        : 
* 수정정보    :
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_report_database_disk
    @server_name sysname,
    @base_date  datetime

AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @from_dt datetime
DEClARE @pre_date date, @after_date date

/* BODY */
SET @from_dt = dateadd(m, -1, @base_date)
SET @pre_date =convert(date, dateadd(m, -1, @base_date))
SET @after_date =convert(date, dateadd(d, -1, @base_date))

-- Disk 현재 상황
SELECT M.letter, M.used_yn, (M.disk_size /1024) as disk_total_size
       ,(M.used_size/1024) as disk_used_size, (M.free_size/1024) as disk_free_size
       ,(M.data_file_size/1024) as data_file_size,  convert(decimal(4,2), (isnull(B.FreeSpace,0) /1024)) as data_free_space
 FROM
 (SELECT  letter , disk_size, used_yn, used_size, isnull(data_file_size,0) as data_file_size
    , (disk_size-used_size) as free_size
 FROM DISK_SIZE with (nolock)
 WHERE server_id = dbo.get_svrid (@server_name) ) AS M
 LEFT JOIN 
     (SELECT C.server_name,LEFT(A.file_full_name, 1) AS Drive 
         , sum(A.usage) as UsedSize ,sum( (A.size - A.usage)) as FreeSpace 
        FROM dbo.DATABASE_FILE_LIST AS A with (nolock) 
            JOIN dbo.INSTANCE  AS B with (nolock)  ON A.server_id = B.server_id AND A.instance_id = B.instance_id  
            JOIN dbo.SERVERINFO AS C with (nolock)  ON  A.server_id = C.server_id  
            JOIN dbo.DATABASE_LIST  AS D with (nolock) ON A.server_id = D.server_id AND A.instance_id = D.instance_id AND A.db_id = D.db_id and A.reg_dt = D.reg_dt  
        WHERE A.reg_dt >= @base_date and A.reg_dt < dateadd(d, 1,@base_date)
            AND C.server_name = @server_name
        GROUP BY C.server_name, LEFT(A.file_full_name, 1) 
      ) AS B ON M.letter = B.Drive

-- 월 증가량  추이
SELECT '1 Month 증가' as title,  '!ALL' as db_name 
     ,convert(decimal(8,2),after.DataSize - pre.dataSize) as diff_DataSize
     ,convert(decimal(8,2),after.logsize- pre.logsize) as diff_LogSize
     ,convert(decimal(8,2),(after.totalsize -pre.totalsize)) as diff_TotalSize
FROM
     (  SELECT  SUM(DataSize)/1024 as DataSize, SUM(LogSize) /1024 as LogSize
            , SUM(TotalSize)/1024 as TotalSize
        FROM VW_DATABASE_FILE_LIST with (nolock)
        WHERE server_name = @server_name
            and reg_dt =@after_date) AS AFTER 
JOIN
    ( SELECT  round(SUM(DataSize) /1024,2) as DataSize, round(SUM(LogSize) /1024,2) as LogSize
            , round(SUM(TotalSize)/1024 ,2) as TotalSize
    FROM VW_DATABASE_FILE_LIST with (nolock)
    WHERE server_name = @server_name
        and reg_dt = @pre_date) AS PRE  ON  1=1
union all

SELECT '1 Month 증가' as title, after.db_name
      ,convert(decimal(8,2),after.DataSize - pre.dataSize) as diff_DataSize
      ,convert(decimal(8,2),after.logsize- pre.logsize) as diff_LogSize
      ,convert(decimal(8,2),after.totalsize -pre.totalsize) as diff_TotalSize
FROM
     (  SELECT  db_name, round(SUM(DataSize)/1024, 2) as DataSize, round(SUM(LogSize) /1024,2) as LogSize
            , round(SUM(TotalSize)/1024,2) as TotalSize
        FROM VW_DATABASE_FILE_LIST with (nolock)
        WHERE server_name = @server_name
            and reg_dt = @after_date
        GROUP BY db_name ) AS AFTER 
 LEFT JOIN
    ( SELECT  db_name, round(SUM(DataSize) /1024,2) as DataSize, round(SUM(LogSize) /1024,2) as LogSize
            , round(SUM(TotalSize)/1024 ,2) as TotalSize
    FROM VW_DATABASE_FILE_LIST with (nolock)
    WHERE server_name = @server_name
        and reg_dt = @pre_date
    GROUP BY db_name ) AS PRE ON PRE.db_name =AFTER.db_name
 ORDER BY db_name
    


-- 최근 한달간 DB, LOG size
SELECT  reg_dt, convert(decimal(8,2), (sum(DataSize) /1024) )as DataSize
       ,convert(decimal(8,2), sum(LogSize) /1024) as LogSize
       ,convert(decimal(8,2), sum(TotalSize) /1024) as TotalSize
FROM VW_DATABASE_FILE_LIST with (nolock)
WHERE server_name = @server_name
    and reg_dt >= @from_dt and reg_dt < @base_date
group by reg_dt
order by reg_dt



-- 싱크 Type별 Size
SELECT  reg_dt, sync_type
       ,convert(decimal(8,2), sum(DataSize) /1024)  as DataSize
       ,convert(decimal(8,2), sum(LogSize)/1024) as LogSize
       ,convert(decimal(8,2), sum(TotalSize)/1024 ) as TotalSize
FROM VW_DATABASE_FILE_LIST with (nolock)
where server_name =  @server_name
    and reg_dt >= @from_dt and reg_dt < @base_date
GROUP BY reg_dt, sync_type
ORDER BY sync_type, reg_dt

-- 최근 한달간 DB별  Size
SELECT  reg_dt, DB_NAME
    ,convert(decimal(8,2),sum(DataSize) /1024 )as DataSize
    ,convert(decimal(8,2),sum(LogSize) /1024) as LogSize
    ,convert(decimal(8,2),sum(TotalSize) /1024 ) as TotalSize
FROM VW_DATABASE_FILE_LIST with (nolock)
WHERE server_name = @server_name
    and reg_dt >= @from_dt and reg_dt < @base_date
group by reg_dt, DB_NAME
order by DB_NAME, reg_dt


-- 현재 날짜 size
SELECT C.server_name, D.db_name, A.name as LogicalName, A.size as FileSize ,A.filegroup
    ,LEFT(A.file_full_name, 1) AS Drive , A.usage as UsedSize ,(A.size - A.usage) as FreeSpace 
    ,CONVERT (nvarchar(8), CAST ((A.size - A.usage) /A.size as decimal(4,2) ) * 100 ) + '%'  as FreeSpacePct
    ,E.sync_type
FROM dbo.DATABASE_FILE_LIST AS A with (nolock) 
    JOIN dbo.INSTANCE  AS B with (nolock)  ON A.server_id = B.server_id AND A.instance_id = B.instance_id  
    JOIN dbo.SERVERINFO AS C with (nolock)  ON  A.server_id = C.server_id  
    JOIN dbo.DATABASE_LIST  AS D with (nolock) ON A.server_id = D.server_id AND A.instance_id = D.instance_id AND A.db_id = D.db_id and A.reg_dt = D.reg_dt  
    LEFT JOIN DB_SYNK AS E with(nolock) ON A.server_id = E.server_id AND A.instance_id = E.instance_id AND A.db_id = E.db_id  
WHERE A.reg_dt >= @base_date and A.reg_dt < @base_date
    AND C.server_name = @server_name
ORDER BY d.db_name, A.name
  

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
