SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_conf_ServerDBSizeHistorySelect
* 작성정보    : 2010-11-11 by choi bo ra
* 관련페이지  : DB 하나의 히스토리
* 내용        : 
* 수정정보    :
**************************************************************************/
ALTER PROCEDURE dbo.up_conf_ServerDBSizeHistorySelect 
    @server_id          int,
    @db_id              int,
    @file_id            int = 0 ,
    @base_date          datetime = null
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
IF @base_date IS  NULL
   SELECT @base_date = MAX(reg_dt ) from DATABASE_FILE_LIST  with (nolock)
   WHERE server_id = @server_id 
    
ELSE
BEGIN
   SELECT @base_date = MAX(reg_dt ) from DATABASE_FILE_LIST  with (nolock)
   WHERE server_id = @server_id and reg_dt <= @base_date
END

SELECT  dbo.get_svrnm(f.server_id) as server_name,f.reg_dt, f.DB_ID,
        f.filegroup,f.file_id,f.name, f.file_full_name,
        f.size,usage, (f.size-f.usage) as free
FROM DATABASE_FILE_LIST  as f with (nolock)
WHERE reg_dt >= DATEADD(D, -10, @base_date) and reg_dt  <= @base_date
    and server_id = @server_id 
    and db_id = @db_id
    and file_id = case when @file_id = 0 then file_id else @file_id end
order by filegroup, file_id, reg_dt
    

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
