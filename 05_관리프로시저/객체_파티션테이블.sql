/*************************************************************************    
* 프로시저명  : dbo.up_DBA_select_avaliable_partion_cnt  
* 작성정보    : 2008-01-02 김태환  
* 관련페이지  :    
* 내용        : DB별 파티션별 여유 파티션 개수  
* 수정정보    : 2009-07-28 by choi bo ra  조건절 변경  
**************************************************************************/  
CREATE PROC dbo.up_DBA_select_avaliable_partion_cnt  
AS  
    set nocount on  
    set transaction isolation level read uncommitted  
  
    SELECT db_name, name, sum(  (case when rows > 0 then 0 else 1  end))  
      FROM dbo.PARTITION_TABLE_INFO WITH (NOLOCK)  
     WHERE range is not null  
     GROUP BY db_name, name  
     ORDER BY db_name, name  
  
    set nocount off  
    
 go
 
 /*IF EXISTS (SELECT name   
    FROM   sysobjects   
    WHERE  name = N'up_DBA_select_partition_table_info'   
    AND    type = 'P')  
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
   