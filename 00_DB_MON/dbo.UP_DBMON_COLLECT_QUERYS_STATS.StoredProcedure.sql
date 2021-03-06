USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[UP_DBMON_COLLECT_QUERYS_STATS]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* 프로시저명  : dbo.up_dbmon_collect_querys_stats
* 작성정보    : 2013-02-06
* 관련페이지  : 
* 내용       : SP호출정보 파악을 위해 DBMON => DBADB1.ADMIN으로 수집
* 수정정보    : up_dbmon_collect_querys_stats 160,'2013-07-17 00:00:00.000'
**************************************************************************/
CREATE PROCEDURE [dbo].[UP_DBMON_COLLECT_QUERYS_STATS]
	@server_id int
	,@reg_date datetime = null
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

--SET @reg_date =  convert(datetime,convert(nvarchar(10), @reg_date-1, 121))

/* BODY */

SELECT @server_id  server_id
--, @reg_date reg_date
, CONVERT(VARCHAR(100),@@servername) server_name, db_name, object_name, object_id, MAX(cpu_rate) cpu_rate
, case when max(cnt_day) = 0 then 1 else max(cnt_day) end cnt_day
, min(reg_date) min_reg_date, max(reg_date) max_reg_date, count(distinct reg_date) cnt
FROM DB_MON_QUERY_STATS_DAILY_V2 with(nolock)
WHERE type='A'
	and ((reg_date > @reg_date) OR (@reg_date is null and reg_date = reg_date))
GROUP BY db_name, object_name, object_id
ORDER BY db_name, object_name
GO
