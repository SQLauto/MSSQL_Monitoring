

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_select_partition_table_info' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_select_partition_table_info
*/

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_select_partition_table_info 
* 작성정보    : 2007-12-07
* 관련페이지  :  
* 내용        :
* 수정정보    : 장비DB별 파티션 정보 조회
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_select_partition_table_info
     
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT db_name, name, boundary, range, partition_number, file_group, rows
FROM dbo.partition_table_info WITH (NOLOCK)
ORDER BY db_name, name

IF @@ERROR <> 0  RETURN -1


RETURN
	
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO