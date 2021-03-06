USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[UP_MON_INDEXS_USAGE]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UP_MON_INDEXS_USAGE]
AS
SET NOCOUNT ON  

declare @date date, @ins_date date
set @date = GETDATE()-1
set @ins_date = GETDATE()

DELETE DB_MON_INDEX_USAGE WHERE INS_DATE = @ins_date

INSERT DB_MON_INDEX_USAGE
SELECT 
	 @ins_date ins_date
	,a.database_id, a.object_id, object_name(a.object_id,a.database_id) object_nm , a.index_id
	,a.user_seeks   - isnull(b.user_seeks,0)  user_seeks
	,a.user_scans   - isnull(b.user_scans,0)  user_scans
	,a.user_lookups - isnull(b.user_lookups,0)  user_lookups
	,a.user_updates - isnull(b.user_updates,0)  user_updates
	,a.last_user_seek, a.last_user_scan, a.last_user_lookup, a.last_user_update 
  FROM sys.dm_db_index_usage_stats A
  LEFT JOIN DB_MON_INDEX_USAGE B with (nolock) ON 
       a.database_id = b.database_id 
   AND @date = b.ins_date
   AND a.object_id = b.object_id
   AND a.index_id = b.index_id
   where a.database_id > 4
  and (a.user_seeks > 0 or a.user_scans > 0 or a.user_lookups > 0 or a.user_updates > 0)
  and (a.last_user_seek >= @date or a.last_user_scan >= @date or a.last_user_lookup >= @date or a.last_user_update >= @date  )

GO
