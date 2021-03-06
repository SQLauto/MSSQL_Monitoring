/*************************************************************************  
* 프로시저명  : dbo.UP_DBMON_COLLECT_QUERYS_STATS_USAGE
* 작성정보    : 2013-02-06
* 관련페이지  : 
* 내용       : SP호출정보 파악을 위해 DBMON => DBADB1.ADMIN으로 수집
* 수정정보    : up_dbmon_collect_querys_stats 160,'2013-07-17 00:00:00.000'
			   2015-02-16 이름 변경, 컬럼 내역 변경
			   2015-03-11 호출 gap이 크지 않으면 DB_MON_QUERY_STATS_V3 에서는 누락되는 SP가 존재 한다. 
			EXEC UP_DBMON_COLLECT_QUERYS_STATS_USAGE 160
**************************************************************************/
CREATE PROCEDURE dbo.UP_DBMON_COLLECT_QUERYS_STATS_USAGE
	 @server_id int
	,@reg_date datetime = null
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

IF @REG_DATE IS NULL 
	SET @reg_date =  convert(datetime,convert(nvarchar(10), GETDATE()-1, 121))

DECLARE @TO_CPU BIGINT, @TOT_CNT BIGINT, @TOT_READ BIGINT, @TOT_DURATION BIGINT
/* BODY */


TRUNCATE TABLE QUERY_STATS_USAGE


SELECT @TO_CPU =sum(cpu_total) , @TOT_CNT = sum(cnt_min) , @TOT_READ =sum(reads_cnt) , 
	@TOT_DURATION=sum(duration_cnt) 
FROM DB_MON_QUERY_STATS_V3 WITH(NOLOCK) 
WHERE REG_DATE >= @REG_DATE AND REG_DATE < DATEADD(DD,1,@REG_DATE) 



INSERT INTO QUERY_STATS_USAGE 
( UPD_DATE, SERVER_ID, DATABASE_NAME,  OBJECT_ID, OBJECT_NAME,  CNT_RATE, CPU_RATE, READ_RATE, DURATION_RATE, 
	AVG_MIN_CNT, MIN_MIN_CNT, MAX_MIN_CNT, AVG_CPU, MIN_CPU, MAX_CPU, 
	AVG_READ, MIN_READ,MAX_READ, AVG_DURATION, MAX_DURATION, MIN_DURATION, LAST_CALL_DATE
 ) 
SELECT @REG_DATE AS REG_DATE, @SERVER_ID AS SERVER_ID, D.DB_NAME, MAX(D.OBJECT_ID) AS OBJECT_ID, D.OBJECT_NAME, 
	 CONVERT(MONEY, (sum(D.cnt_min) * 1.0 / @TOT_CNT ), 2)    *  100 AS CNT_RATE, 
	 CONVERT(MONEY, (sum(D.cpu_total) * 1.0 / @TO_CPU ), 2)    *  100 AS CPU_RATE, 
	 CONVERT(MONEY, (sum(D.reads_cnt) * 1.0 / @TOT_READ ), 2)    *  100 AS READ_RATE, 
	 CONVERT(MONEY, (sum(D.duration_cnt) * 1.0 / @TOT_DURATION ), 2)    *  100 AS DURATION_RATE, 
	 AVG(D.cnt_min) AS AVG_MIN_CNT, MIN(D.cnt_min) AS MIN_MIN_CNT, MAX(D.cnt_min) AS MAX_MIN_CNT,
	 AVG(D.cpu_cnt) AS AVG_CPU, MIN(D.cpu_cnt) AS MIN_CPU, MAX(D.cpu_cnt) AS MAX_CPU, 
	AVG(D.READS_CNT) AS AVG_READ, MIN(D.READS_CNT) AS MIN_READ, MAX(D.READS_CNT) AS MAX_READ,
	 AVG(D.DURATION_CNT) AS AVG_DURATION, MIN(D.DURATION_CNT) AS MIN_DURATION, MAX(D.DURATION_CNT) AS MAX_DURATION, 
	 MAX(REG_DATE) AS LAST_CALL_DATE
FROM DB_MON_QUERY_STATS_V3 AS D WITH(NOLOCK) 
WHERE REG_DATE >= @REG_DATE AND REG_DATE < DATEADD(DD,1,@REG_DATE)
	AND D.OBJECT_NAME != ''
 --	AND D.OBJECT_NAME = 'up_cstool_get_customercenterlist_sub_proc_dt'
GROUP BY D.DB_NAME, D.OBJECT_NAME
ORDER BY 6 desc



SELECT @TO_CPU =sum(cpu_min) , @TOT_CNT = sum(cnt_min) , @TOT_READ =sum(reads_cnt) , 
	@TOT_DURATION=sum(duration_cnt) 
FROM DB_MON_PROCEDURE_STATS WITH(NOLOCK) 
WHERE REG_DATE >= @REG_DATE AND REG_DATE < DATEADD(DD,1,@REG_DATE) 



INSERT INTO QUERY_STATS_USAGE 
( UPD_DATE, SERVER_ID, DATABASE_NAME,  OBJECT_ID,  OBJECT_NAME,  
	CNT_RATE, CPU_RATE, READ_RATE, DURATION_RATE, 
	AVG_MIN_CNT, MIN_MIN_CNT, MAX_MIN_CNT, AVG_CPU, MIN_CPU, MAX_CPU, 
	AVG_READ, MIN_READ,MAX_READ, AVG_DURATION, MIN_DURATION, MAX_DURATION, LAST_CALL_DATE
 ) 
SELECT  @REG_DATE AS REG_DATE, @SERVER_ID AS SERVER_ID, isnull(D.DB_NAME, 'master') as db_name, MAX(D.OBJECT_ID) AS OBJECT_ID, D.OBJECT_NAME, 
	 CONVERT(MONEY, (sum(D.cnt_min) * 1.0 / @TOT_CNT ), 2)    *  100 AS CNT_RATE, 
	 CONVERT(MONEY, (sum(D.cpu_min) * 1.0 / @TO_CPU ), 2)    *  100 AS CPU_RATE, 
	 CONVERT(MONEY, (sum(D.reads_cnt) * 1.0 / @TOT_READ ), 2)    *  100 AS READ_RATE, 
	 CONVERT(MONEY, (sum(D.duration_cnt) * 1.0 / @TOT_DURATION ), 2)    *  100 AS DURATION_RATE, 
	 AVG(D.cnt_min) AS AVG_MIN_CNT, MIN(D.cnt_min) AS MIN_MIN_CNT, MAX(D.cnt_min) AS MAX_MIN_CNT,
	 AVG(D.cpu_cnt) AS AVG_CPU, MIN(D.cpu_cnt) AS MIN_CPU, MAX(D.cpu_cnt) AS MAX_CPU, 
	 AVG(D.READS_CNT) AS AVG_READ, MIN(D.READS_CNT) AS MIN_READ, MAX(D.READS_CNT) AS MAX_READ,
	 AVG(D.DURATION_CNT) AS AVG_DURATION, MIN(D.DURATION_CNT) AS MIN_DURATION, MAX(D.DURATION_CNT) AS MAX_DURATION, 
	 MAX(REG_DATE) AS LAST_CALL_DATE
FROM DB_MON_PROCEDURE_STATS AS D WITH(NOLOCK)
	LEFT HASH JOIN QUERY_STATS_USAGE AS Q WITH(NOLOCK) ON D.db_name = Q.DATABASE_NAME  AND D.OBJECT_NAME = Q.OBJECT_NAME
WHERE REG_DATE >= @REG_DATE AND REG_DATE < DATEADD(DD,1,@REG_DATE)
	AND Q.OBJECT_NAME IS NULL
	
--AND OBJECT_NAME = 'UPGMKT_Discount_OrderCostInfo_UpdateByCustNo'
GROUP BY D.DB_NAME, D.OBJECT_NAME
ORDER BY 6 desc


UPDATE D 
	SET CNT_RATE =CONVERT(MONEY, (D.AVG_MIN_CNT * 1.0 / T.total_cnt ), 2)    *  100 , 
	 CPU_RATE =CONVERT(MONEY, (D.AVG_CPU * 1.0 / T.TOTAL_CPU) , 2)    *  100 , 
	 READ_RATE =  CONVERT(MONEY, (D.AVG_READ * 1.0 / T.total_reads ), 2)    *  100, 
	 DURATION_RATE = CONVERT(MONEY, (D.AVG_DURATION * 1.0 / T.total_duration ), 2)    *  100
FROM QUERY_STATS_USAGE  AS D 
 CROSS JOIN 
	 ( 
		SELECT sum(AVG_CPU) AS TOTAL_CPU, sum(AVG_MIN_CNT) as total_cnt , sum(AVG_READ) as total_reads, 
		sum(AVG_DURATION) as total_duration
		FROM QUERY_STATS_USAGE WITH(NOLOCK)
	 )  AS T


SELECT * FROM QUERY_STATS_USAGE WITH(NOLOCK) 






