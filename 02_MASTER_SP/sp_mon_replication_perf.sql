SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* ���ν�����  : dbo.sp_mon_replication_perf 
* �ۼ�����    : 2010-02-19 by �̼�ǥ
* ����������  :  
* ����        :
* ��������    :
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