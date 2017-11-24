use admon
go


/*************************************************************************  
* 프로시저명: dbo.up_dba_select_blitz_class_level
* 작성정보	: 2015-01-26 by choi bo ra
* 관련페이지:  
* 내용		: 

* 수정정보	: 
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_blitz_class_level
	 @TYPE	 		NVARCHAR(40) = 'BLITZ'
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
SELECT  class_level, PROCESS
FROM  blitz_check_info WITH(NOLOCK) 
	WHERE TYPE = @TYPE
GROUP BY class_level, PROCESS
UNION ALL 
SELECT 0 AS class_level, 'ALL' AS PROCESS
ORDER BY class_level

go

/*************************************************************************  
* 프로시저명: dbo.up_dba_select_blitz_result_detail
* 작성정보	: 2015-01-26 by choi bo ra
* 관련페이지:  
* 내용		: 

* 수정정보	: EXEC up_dba_select_blitz_result_detail '2015-02-01', 10, 0
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_blitz_result_detail
	 @REG_DATE 		DATE, 
	 @SERVER_ID		INT,
	 @CLASS_LEVEL		INT = 0
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/

SELECT  B.REG_DATE, C.CLASS_LEVEL, B.CHECK_ID,B.SERVER_NAME, B.PRIORITY, B.FINDINGS_GROUP, B.FINDING, B.DATABASE_NAME, B.OBJECT_NAME, 
		B.DETAILS, B.QUERY_PLAN, B.QUERY_PLAN_FILTERED, S.OWNER
FROM  BLITZ_RESULT  AS B WITH(NOLOCK) 
	join blitz_check_info as c with(nolock) on b.check_id = c.check_id
	JOIN SERVERINFO AS S WITH(NOLOCK) ON B.SERVER_ID = S.SERVER_ID AND S.USE_YN ='Y'
WHERE  REG_DATE >= convert(date, convert(nvarchar(7), @reg_date, 121) + '-01' )  AND REG_DATE < DATEADD(MM, 1, @REG_DATE)
	AND B.SERVER_ID = CASE  WHEN @SERVER_ID = 0 THEN B.SERVER_ID  ELSE @SERVER_ID END
	AND C.CLASS_LEVEL = CASE WHEN @CLASS_LEVEL = 0 THEN  C.CLASS_LEVEL  ELSE  @CLASS_LEVEL END
	and c.type = 'BLITZ'
ORDER BY C.CLASS_LEVEL, B.PRIORITY
go

/*************************************************************************  
* 프로시저명: dbo.up_dba_select_blitz_index_summary_server_class_level
* 작성정보	: 2015-01-26 by choi bo ra
* 관련페이지:  
* 내용		: 

* 수정정보	: EXEC up_dba_select_blitz_index_summary_server_class_level '2015-02-02', 'G', 10
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_blitz_index_summary_server_class_level
			@REG_DATE			date,
			@SITE_GN		  CHAR(1) = 'G',
			@SERVER_ID		INT = 0 
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */
DECLARE @F_REG_DATE DATE, @T_REG_DATE DATE

/*BODY*/
SET @F_REG_DATE = CONVERT(DATE, CONVERT(NVARCHAR(7),   DATEADD(MM,  -1* (DATEPART(MM, @REG_DATE) % 3),  @REG_DATE), 121) + '-01' )
SET @T_REG_DATE =  CONVERT(DATE,CONVERT(NVARCHAR(7), DATEADD(MM,  3-(DATEPART(MM, @REG_DATE) % 3) , @REG_DATE), 121) + '-01' )


--SELECT @REG_DATE, @F_REG_DATE, @T_REG_DATE


SELECT  C.CLASS_LEVEL, C.PROCESS, S.SERVER_NAME, I.CHECK_ID,
	CASE WHEN  I.FINDING LIKE 'ABNORMAL PSYCHOLOGY: IDENTITY COLUMN WITHIN%' THEN 'IDENTITY COLUMN WITHIN % PERSION END OF RANGE' ELSE I.FINDING END AS FINDING,
	COUNT(*) AS CNT
FROM BLITZ_INDEX AS I WITH(NOLOCK) 
	JOIN SERVERINFO AS S WITH(NOLOCK) ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
	JOIN BLITZ_CHECK_INFO AS C WITH(NOLOCK) ON I.CHECK_ID = C.CHECK_ID
WHERE C.TYPE = 'BLITZ_INDEX' 
--AND  I.SERVER_ID = 10 
  AND  REG_DATE >= @F_REG_DATE  AND REG_DATE < @T_REG_DATE
  AND S.SITE_GN = 'G'
	AND S.SERVER_ID = CASE WHEN @SERVER_ID = 0  THEN S.SERVER_ID ELSE @SERVER_ID END
GROUP BY  C.CLASS_LEVEL, C.PROCESS, S.SERVER_NAME, I.CHECK_ID,  
	CASE WHEN  I.FINDING LIKE 'ABNORMAL PSYCHOLOGY: IDENTITY COLUMN WITHIN%' THEN 'IDENTITY COLUMN WITHIN % PERSION END OF RANGE' ELSE I.FINDING END
ORDER BY C.CLASS_LEVEL, I.CHECK_ID

go


/*************************************************************************  
* 프로시저명: dbo.up_dba_select_blitz_index_summary_class_level
* 작성정보	: 2015-01-26 by choi bo ra
* 관련페이지:  
* 내용		: 

* 수정정보	: EXEC up_dba_select_blitz_index_summary_class_level '2015-02-02', 'G'
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_blitz_index_summary_class_level
			@REG_DATE			date,
			@SITE_GN		  CHAR(1) = 'G'
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */
DECLARE @F_REG_DATE DATE, @T_REG_DATE DATE
/*BODY*/
SET @F_REG_DATE = CONVERT(DATE, CONVERT(NVARCHAR(7),   DATEADD(MM,  -1* (DATEPART(MM, @REG_DATE) % 3),  @REG_DATE), 121) + '-01' )
SET @T_REG_DATE =  CONVERT(DATE,CONVERT(NVARCHAR(7), DATEADD(MM,  3-(DATEPART(MM, @REG_DATE) % 3) , @REG_DATE), 121) + '-01' )


--SELECT @REG_DATE, @F_REG_DATE, @T_REG_DATE


SELECT  convert(nvarchar(7),I.reg_date ) as YYYYMM, C.CLASS_LEVEL, C.PROCESS, I.CHECK_ID,  I.FINDINGS_GROUP,
	CASE WHEN  I.FINDING LIKE 'ABNORMAL PSYCHOLOGY: IDENTITY COLUMN WITHIN%' THEN 'IDENTITY COLUMN WITHIN % PERSION END OF RANGE' ELSE I.FINDING END AS FINDING,
	COUNT(*) AS CNT
FROM BLITZ_INDEX AS I WITH(NOLOCK) 
	JOIN SERVERINFO AS S WITH(NOLOCK) ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
	JOIN BLITZ_CHECK_INFO AS C WITH(NOLOCK) ON I.CHECK_ID = C.CHECK_ID
WHERE C.TYPE = 'BLITZ_INDEX' 
--AND  I.SERVER_ID = 10 
  AND  REG_DATE >= @F_REG_DATE  AND REG_DATE < @T_REG_DATE
  AND S.SITE_GN = 'G'
GROUP BY  convert(nvarchar(7),I.reg_date ),C.CLASS_LEVEL, C.PROCESS, I.CHECK_ID,  i.FINDINGS_GROUP,
	CASE WHEN  I.FINDING LIKE 'ABNORMAL PSYCHOLOGY: IDENTITY COLUMN WITHIN%' THEN 'IDENTITY COLUMN WITHIN % PERSION END OF RANGE' ELSE I.FINDING END
ORDER BY C.CLASS_LEVEL, I.CHECK_ID

go


/*************************************************************************  
* 프로시저명: dbo.up_dba_select_blitz_index_summary_class_level
* 작성정보	: 2015-01-26 by choi bo ra
* 관련페이지:  
* 내용		: 

* 수정정보	: EXEC up_dba_select_blitz_index_summary_report '2015-02-02'
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_blitz_index_summary_report
			@SITE_GN		  CHAR(1) = 'G'
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */
DECLARE @F_REG_DATE DATE, @T_REG_DATE DATE
/*BODY*/
SET @F_REG_DATE = convert(date,convert(nvarchar(4), getdate(), 121) +'-01-01')
SET @T_REG_DATE = dateadd(mm,12,@F_REG_DATE)


--SELECT @REG_DATE, @F_REG_DATE, @T_REG_DATE


SELECT  convert(nvarchar(7),I.reg_date ) as YYYYMM, C.CLASS_LEVEL, C.PROCESS,
	    COUNT(*) AS CNT
FROM BLITZ_INDEX AS I WITH(NOLOCK) 
	JOIN SERVERINFO AS S WITH(NOLOCK) ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
	JOIN BLITZ_CHECK_INFO AS C WITH(NOLOCK) ON I.CHECK_ID = C.CHECK_ID
WHERE C.TYPE = 'BLITZ_INDEX' 
--AND  I.SERVER_ID = 10 
  AND  REG_DATE >= @F_REG_DATE  AND REG_DATE < @T_REG_DATE
  AND S.SITE_GN = 'G'
  and c.CLASS_LEVEL != 5
GROUP BY  convert(nvarchar(7),I.reg_date ),C.CLASS_LEVEL, C.PROCESS
ORDER BY C.CLASS_LEVEL
go


/*************************************************************************  
* 프로시저명: dbo.up_dba_select_blitz_result_summary_check_id
* 작성정보	: 2015-01-26 by choi bo ra
* 관련페이지:  
* 내용		: 

* 수정정보	: 
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_blitz_result_summary_check_id
	@reg_date			date,
	@site_gn			char(1) ='G'
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/


SELECT convert(nvarchar(7),B.reg_date, 121) as YYYYMM, C.class_level,  B.check_id, B.findings_group, B.finding, count(*)  as count, c.process
 from  BLITZ_RESULT AS B WITH(NOLOCK) 
	join blitz_check_info as c with(nolock) on b.check_id = c.check_id
	join serverinfo as s with(nolock) on b.server_id = s.server_id and s.use_yn = 'Y'
 where B.check_id in 
(6
,7
,8
,15
,16
,24
,25
,26
,27
,28
,29
,38
,39
,40
,41
,47
,50
,51
,55
,63
,64
,65
,66
,67
,69
,78
,79
,89
,90
,107
,108
,109
,112
,118
,122
,124
,125
,145
,146
,147
,151
)
and  REG_DATE >= convert(date, convert(nvarchar(7), @reg_date, 121) + '-01' )  AND REG_DATE < DATEADD(MM, 1, @REG_DATE)
and c.type = 'BLITZ'
and s.site_gn =@site_gn
group by convert(nvarchar(7),reg_date, 121),  b.check_id, b.findings_group, b.finding, C.class_level, c.process

order by findings_group, check_id
go

/*************************************************************************  
* 프로시저명: dbo.up_dba_select_blitz_index_summary_server_class_level
* 작성정보	: 2015-01-26 by choi bo ra
* 관련페이지:  
* 내용		: 

* 수정정보	: EXEC up_dba_select_blitz_index_server_class_level '2015-02-02', 'G', 10,0
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_blitz_index_server_class_level
			@REG_DATE			date,
			@SITE_GN		  CHAR(1) = 'G',
			@SERVER_ID			INT = 0 , 
			@CLASS_LEVEL		 int = 0
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */
DECLARE @F_REG_DATE DATE, @T_REG_DATE DATE
/*BODY*/
SET @F_REG_DATE = CONVERT(DATE, CONVERT(NVARCHAR(7),   DATEADD(MM,  -1* (DATEPART(MM, @REG_DATE) % 3),  @REG_DATE), 121) + '-01' )
SET @T_REG_DATE =  CONVERT(DATE,CONVERT(NVARCHAR(7), DATEADD(MM,  3-(DATEPART(MM, @REG_DATE) % 3) , @REG_DATE), 121) + '-01' )


--SELECT @REG_DATE, @F_REG_DATE, @T_REG_DATE


SELECT  C.CLASS_LEVEL, C.PROCESS, I.REG_DATE, S.SERVER_NAME, I.CHECK_ID,  
	 I.DATABASE_NAME, I.TABLE_NAME, I.INDEX_NAME, I.ROWS, I.RESERVED, I.FINDINGS_GROUP, I.FINDING, I.DETAILS, I.INDEX_DEFINITION, I.SECRET_COLUMNS, 
	 I.READS,I.WRITES, I.USAGE, I.RESERVED_LOB,I.RESERVED_OVERFLOW,I.MORE_INFO, I.TSQL, S.owner
FROM BLITZ_INDEX AS I WITH(NOLOCK) 
	JOIN SERVERINFO AS S WITH(NOLOCK) ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
	JOIN BLITZ_CHECK_INFO AS C WITH(NOLOCK) ON I.CHECK_ID = C.CHECK_ID
WHERE C.TYPE = 'BLITZ_INDEX' 
  AND  REG_DATE >= @F_REG_DATE  AND REG_DATE < @T_REG_DATE
  AND S.SITE_GN = @SITE_GN
  AND S.SERVER_ID = CASE WHEN @SERVER_ID = 0  THEN S.SERVER_ID ELSE @SERVER_ID END
  AND C.CLASS_LEVEL = CASE WHEN @CLASS_LEVEL = 0 THEN C.CLASS_LEVEL ELSE @CLASS_LEVEL END
ORDER BY C.CLASS_LEVEL, I.CHECK_ID , I.DATABASE_NAME, I.TABLE_NAME
go

/*************************************************************************  
* 프로시저명: dbo.up_dba_select_blitz_result_summary_server
* 작성정보	: 2015-01-26 by choi bo ra
* 관련페이지:  
* 내용		: 

* 수정정보	: 
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_blitz_result_summary_server
			@reg_date			date, 
			@site_gn			char(1) ='G'
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/



SELECT convert(nvarchar(7),reg_date, 121) as YYYYMM, b.SERVER_NAME, b.server_id,  c.class_level, b.check_id, b.findings_group, b.finding, count(*)  as count
 from  BLITZ_RESULT as b WITH(NOLOCK) 
	join serverinfo as s with(nolock) on b.server_id = s.server_id and s.use_yn ='Y'
	join blitz_check_info as c with(nolock) on b.check_id = c.check_id
 where b.check_id in 
(6
,7
,8
,15
,16
,24
,25
,26
,27
,28
,29
,38
,39
,40
,41
,47
,50
,51
,55
,63
,64
,65
,66
,67
,69
,78
,79
,89
,90
,107
,108
,109
,112
,118
,122
,124
,125
,145
,146
,147
,151
)
and  REG_DATE >= convert(date, convert(nvarchar(7), @reg_date, 121) + '-01' )  AND REG_DATE < DATEADD(MM, 1, @REG_DATE)
and s.site_gn = @site_gn
group by convert(nvarchar(7),reg_date, 121),  b.SERVER_NAME, b.server_id, b.check_id, b.findings_group, b.finding, c.class_level
order by b.SERVER_NAME, findings_group, check_id

go

/*************************************************************************  
* 프로시저명: dbo.up_dba_select_blitz_index_database_summary
* 작성정보	: 2015-01-26 by choi bo ra
* 관련페이지:  
* 내용		: 

* 수정정보	: EXEC up_dba_select_blitz_index_database_summary '2015-02-02', 'G', 10
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_blitz_index_database_summary
			@REG_DATE			date,
			@SITE_GN			CHAR(1) = 'G',
			@SERVER_ID			INT = 0,  
			@DATABASE_NAME		sysname = NULL
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */
DECLARE @F_REG_DATE DATE, @T_REG_DATE DATE
/*BODY*/
IF @REG_DATE IS NULL
begin 
	SET @T_REG_DATE =  CONVERT(DATE,CONVERT(NVARCHAR(7), DATEADD(MM,  3-(DATEPART(MM, GETDATE()) % 3) ,  GETDATE()), 121) + '-01' )
	
end
ELSE
BEGIN 	
	SET @F_REG_DATE = CONVERT(DATE, CONVERT(NVARCHAR(7),   DATEADD(MM,  -1* (DATEPART(MM, @REG_DATE) % 3),  @REG_DATE), 121) + '-01' )
	SET @T_REG_DATE =  CONVERT(DATE,CONVERT(NVARCHAR(7), DATEADD(MM,  3-(DATEPART(MM, @REG_DATE) % 3) , @REG_DATE), 121) + '-01' )
END


IF @REG_DATE  IS NOT  NULL
BEGIN

	SELECT SU.REG_DATE, S.SERVER_NAME, SU.DATABASE_NAME,
		CONVERT(BIGINT,SU.NUMBER_OBJECTS) AS COUNT,
		CONVERT(MONEY,SU.ALL_GB) AS [ALL], 
		CONVERT(BIGINT,SU.CLUSTERED_TABLES)  AS CLUSTERED_TABLES,
		CONVERT(MONEY,SU.CLUSTERED_TABLES_GB)  AS CLUSTERED_TABLES_GB,
		CONVERT(BIGINT,SU.NC_INDEXES)  AS NC_INDEXES,
		CONVERT(MONEY,SU.NC_INDEXES_GB)  AS NC_INDEXES_GB,
		CONVERT(BIGINT,SU.HEAPS)  AS HEAPS,
		CONVERT(MONEY,SU.HEAPS_GB)  AS HEAPS_GB,
		CONVERT(BIGINT,SU.PARTITIONED_TABLES)  AS PARTITIONED_TABLES,
		CONVERT(BIGINT,SU.COUNT_TABLES_1GB) AS  COUNT_TABLES_1GB ,
		CONVERT(BIGINT,SU.COUNT_TABLES_10GB) AS COUNT_TABLES_10GB ,
		CONVERT(BIGINT,SU.COUNT_TABLES_100GB) AS  COUNT_TABLES_100GB,
		CONVERT(BIGINT,SU.COUNT_NCS_1GB) AS COUNT_NCS_1GB ,
		CONVERT(BIGINT,SU.COUNT_NCS_10GB) AS COUNT_NCS_10GB ,
		CONVERT(BIGINT,SU.COUNT_NCS_100GB) AS COUNT_NCS_100GB 
	FROM BLITZ_INDEX_SUMMARY AS SU
		JOIN SERVERINFO AS S ON SU.SERVER_ID = S.SERVER_ID AND S.USE_YN ='Y'
	WHERE S.SITE_GN = @SITE_GN
		AND S.SERVER_ID = @SERVER_ID
		AND SU.REG_DATE >= @F_REG_DATE 
		AND SU.REG_DATE < @T_REG_DATE
		AND SU.DATABASE_NAME = CASE WHEN @DATABASE_NAME IS NULL THEN SU.DATABASE_NAME ELSE @DATABASE_NAME END
	ORDER BY SU.REG_DATE, SU.DATABASE_NAME

END 
ELSE 
BEGIN
	SELECT SU.REG_DATE, S.SERVER_NAME, SU.DATABASE_NAME,
		CONVERT(BIGINT,SU.NUMBER_OBJECTS) AS COUNT,
		CONVERT(MONEY,SU.ALL_GB) AS [ALL], 
		CONVERT(BIGINT,SU.CLUSTERED_TABLES)  AS CLUSTERED_TABLES,
		CONVERT(MONEY,SU.CLUSTERED_TABLES_GB)  AS CLUSTERED_TABLES_GB,
		CONVERT(BIGINT,SU.NC_INDEXES)  AS NC_INDEXES,
		CONVERT(MONEY,SU.NC_INDEXES_GB)  AS NC_INDEXES_GB,
		CONVERT(BIGINT,SU.HEAPS)  AS HEAPS,
		CONVERT(MONEY,SU.HEAPS_GB)  AS HEAPS_GB,
		CONVERT(BIGINT,SU.PARTITIONED_TABLES)  AS PARTITIONED_TABLES,
		CONVERT(BIGINT,SU.COUNT_TABLES_1GB) AS  COUNT_TABLES_1GB ,
		CONVERT(BIGINT,SU.COUNT_TABLES_10GB) AS COUNT_TABLES_10GB ,
		CONVERT(BIGINT,SU.COUNT_TABLES_100GB) AS  COUNT_TABLES_100GB,
		CONVERT(BIGINT,SU.COUNT_NCS_1GB) AS COUNT_NCS_1GB ,
		CONVERT(BIGINT,SU.COUNT_NCS_10GB) AS COUNT_NCS_10GB ,
		CONVERT(BIGINT,SU.COUNT_NCS_100GB) AS COUNT_NCS_100GB 
	FROM BLITZ_INDEX_SUMMARY AS SU
		JOIN SERVERINFO AS S ON SU.SERVER_ID = S.SERVER_ID AND S.USE_YN ='Y'
	WHERE S.SITE_GN = @SITE_GN
		AND S.SERVER_ID = @SERVER_ID
		AND SU.REG_DATE < @T_REG_DATE
		AND SU.DATABASE_NAME = CASE WHEN @DATABASE_NAME IS NULL THEN SU.DATABASE_NAME ELSE @DATABASE_NAME END
	ORDER BY SU.REG_DATE, SU.DATABASE_NAME
END
go

/*************************************************************************  
* 프로시저명: dbo.up_dba_select_blitz_index_summary
* 작성정보	: 2015-01-26 by choi bo ra
* 관련페이지:  
* 내용		: 

* 수정정보	: EXEC up_dba_select_blitz_index_summary '2015-02-02', 'G', 10
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_blitz_index_summary
			@REG_DATE			date = NULL,
			@SITE_GN		  CHAR(1) = 'G',
			@SERVER_ID			INT = 0 
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */
DECLARE @F_REG_DATE DATE, @T_REG_DATE DATE
/*BODY*/
SET @F_REG_DATE = CONVERT(DATE, CONVERT(NVARCHAR(7),   DATEADD(MM,  -1* (DATEPART(MM, @REG_DATE) % 3),  @REG_DATE), 121) + '-01' )
SET @T_REG_DATE =  CONVERT(DATE,CONVERT(NVARCHAR(7), DATEADD(MM,  3-(DATEPART(MM, @REG_DATE) % 3) , @REG_DATE), 121) + '-01' )


--SELECT @REG_DATE, @F_REG_DATE, @T_REG_DATE

IF @SERVER_ID  = 0 
BEGIN

	SELECT SU.REG_DATE, S.SERVER_ID, S.SERVER_NAME, 
		SUM(CONVERT(MONEY,SU.ALL_GB)) AS [ALL], 
		SUM(CONVERT(BIGINT,SU.CLUSTERED_TABLES) ) AS CLUSTERED_TABLES,
		SUM(CONVERT(MONEY,SU.CLUSTERED_TABLES_GB) ) AS CLUSTERED_TABLES_GB,
		SUM(CONVERT(BIGINT,SU.NC_INDEXES) ) AS NC_INDEXES,
		SUM(CONVERT(MONEY,SU.NC_INDEXES_GB) ) AS NC_INDEXES_GB,
		SUM(CONVERT(BIGINT,SU.HEAPS) ) AS HEAPS,
		SUM(CONVERT(MONEY,SU.HEAPS_GB) ) AS HEAPS_GB,
		SUM(CONVERT(BIGINT,SU.PARTITIONED_TABLES) ) AS PARTITIONED_TABLES
	FROM BLITZ_INDEX_SUMMARY AS SU
		JOIN SERVERINFO AS S ON SU.SERVER_ID = S.SERVER_ID AND S.USE_YN ='Y'
	WHERE S.SITE_GN = @SITE_GN
		AND SU.REG_DATE >= @F_REG_DATE 
		AND SU.REG_DATE < @T_REG_DATE
	GROUP BY SU.REG_DATE, S.SERVER_ID,S.SERVER_NAME
	ORDER BY S.SERVER_NAME
END 
ELSE 
BEGIN
		SELECT SU.REG_DATE, S.SERVER_ID, S.SERVER_NAME, 
		SUM(CONVERT(MONEY,SU.ALL_GB)) AS [ALL], 
		SUM(CONVERT(BIGINT,SU.CLUSTERED_TABLES) ) AS CLUSTERED_TABLES,
		SUM(CONVERT(MONEY,SU.CLUSTERED_TABLES_GB) ) AS CLUSTERED_TABLES_GB,
		SUM(CONVERT(BIGINT,SU.NC_INDEXES) ) AS NC_INDEXES,
		SUM(CONVERT(MONEY,SU.NC_INDEXES_GB) ) AS NC_INDEXES_GB,
		SUM(CONVERT(BIGINT,SU.HEAPS) ) AS HEAPS,
		SUM(CONVERT(MONEY,SU.HEAPS_GB) ) AS HEAPS_GB,
		SUM(CONVERT(BIGINT,SU.PARTITIONED_TABLES) ) AS PARTITIONED_TABLES
	FROM BLITZ_INDEX_SUMMARY AS SU
		JOIN SERVERINFO AS S ON SU.SERVER_ID = S.SERVER_ID AND S.USE_YN ='Y'
	WHERE S.SITE_GN = @SITE_GN
		AND S.SERVER_ID = @SERVER_ID
		AND SU.REG_DATE >= DATEADD(YY,-1,@T_REG_DATE)
		AND SU.REG_DATE < @T_REG_DATE
	GROUP BY SU.REG_DATE, S.SERVER_ID,S.SERVER_NAME
	ORDER BY SU.REG_DATE, S.SERVER_NAME
END
go