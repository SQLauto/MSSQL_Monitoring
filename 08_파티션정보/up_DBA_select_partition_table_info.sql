

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
* ���ν�����  : dbo.up_DBA_select_partition_table_info 
* �ۼ�����    : 2007-12-07
* ����������  :  
* ����        :
* ��������    : ���DB�� ��Ƽ�� ���� ��ȸ
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