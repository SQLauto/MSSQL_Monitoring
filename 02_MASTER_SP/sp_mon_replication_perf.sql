SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.sp_mon_replication_perf 
* 작성정보    : 2010-02-19 by 이성표
* 관련페이지  :  
* 내용        :
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.sp_mon_replication_perf
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT instance_name, 
  SUM(CASE counter_name WHEN 'Dist:Delivery Latency' THEN cntr_value ELSE 0 END) AS delivery_Latency,
  SUM(CASE counter_name WHEN 'Dist:Delivered Cmds/sec' THEN cntr_value ELSE 0 END) AS delivery_cmds,
  SUM(CASE counter_name WHEN 'Dist:Delivered Trans/sec' THEN cntr_value ELSE 0 END) AS delivery_trans  
  FROM sys.dm_os_performance_counters with (nolock)
WHERE (object_name like '%Replication Dist.%')
GROUP BY instance_name

RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO