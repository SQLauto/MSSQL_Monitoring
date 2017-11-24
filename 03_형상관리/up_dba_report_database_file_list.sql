SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* ���ν�����  : dbo.up_dba_report_database_file_list 
* �ۼ�����    : 2010-02-16 by �ֺ���
* ����������  :  
* ����        : ��� ���� ����Ʈ 
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_report_database_file_list
     @server_id     int,
     @instance_id   int, 
     @db_id         int,    
     @from_dt       datetime    = null,
     @to_dt         datetime    = null

AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @get_from_dt    datetime
DECLARE @get_to_dt      datetime

/* BODY */


IF @from_dt is null 
BEGIN
    
    SELECT  @get_from_dt = max(reg_dt) 
    FROM DATABASE_FILE_LIST with (nolock)
    WHERE server_id  = @server_id
        and instance_id = @instance_id
        and db_id = @db_id
        
    
    SET @get_to_dt =dateadd(dd, 1, @get_from_dt)
    
END
ELSE 
BEGIN
    SET @get_from_dt = @from_dt
    SET @get_to_dt = @to_dt
END

SELECT db_id, file_id, filegroup, name, file_full_name, size,max_size
    ,growth,usage, (round(convert(float,size),0)- round(convert(float,usage),0)) as free_size
    ,reg_dt
FROM DATABASE_FILE_LIST   with (nolock)
WHERE reg_dt >= @get_from_dt and reg_dt < @get_to_dt
    and server_id  = @server_id
    and instance_id = @instance_id
    and db_id = @db_id
ORDER BY convert(nvarchar(10), reg_dt, 121), db_id, file_id, size desc




RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO