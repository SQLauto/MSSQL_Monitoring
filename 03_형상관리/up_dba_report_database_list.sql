SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* ���ν�����  : dbo.up_dba_report_database_list 
* �ۼ�����    : 2010-02-16 by �ֺ���
* ����������  :  
* ����        : ��� ���� ����Ʈ 
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_report_database_list
     @server_id     int,
     @instance_id   int, 
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
    FROM DATABASE_LIST with (nolock)
    WHERE server_id  = @server_id
        and instance_id = @instance_id
        
    
    SET @get_to_dt =dateadd(dd, 1, @get_from_dt)
    
END
ELSE 
BEGIN
    SET @get_from_dt = @from_dt
    SET @get_to_dt = @to_dt
END

SELECT db_id, db_name, convert( float, (rtrim(ltrim(substring(dbsize, 1, 10 ))) )) as dbsize
    , owner, db_desc, created, reg_dt
FROM DATABASE_LIST   with (nolock)
WHERE reg_dt >= @get_from_dt and reg_dt < @get_to_dt
    and server_id  = @server_id
    and instance_id = @instance_id
ORDER BY convert(nvarchar(10), reg_dt, 121), convert( float, (rtrim(ltrim(substring(dbsize, 1, 10 ))) ))
    , reg_dt



RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO