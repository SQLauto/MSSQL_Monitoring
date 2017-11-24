SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_partition_list' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_partition_list
*/

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_partition_list 
* 작성정보    : 2007-10-23
* 관련페이지  :  
* 내용        : 파티션 테이블 목록
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_partition_list
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT DISTINCT SCHEMA_NAME(stable.schema_id) AS [schema], stable.name AS table_name, stable.object_id,
		stable.create_date, stable.modify_date
FROM sys.partition_schemes AS psch 
		JOIN sys.data_spaces AS pspace ON psch.data_space_id = pspace.data_space_id
		JOIN sys.indexes AS sindex ON pspace.data_space_id = sindex.data_space_id
		JOIN sys.tables AS stable ON stable.object_id = sindex.object_id
RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO