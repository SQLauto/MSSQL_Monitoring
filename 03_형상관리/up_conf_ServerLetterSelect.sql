/*************************************************************************  
* 프로시저명  : dbo.up_conf_ServerDiskSizeSelect
* 작성정보    : 2010-09-30 by 서버의 Disk 추이
* 관련페이지  : 
* 내용        : 
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_conf_ServerLetterSelect 
    @server_id      int,
    @letter         char(1),
    @base_date      datetime = null
    
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
IF @base_date IS  NULL
    SELECT @base_date = max(reg_dt)
    FROM DISK_SIZE as d with (nolock) where server_id = @server_id
    
ELSE
begin
     SELECT @base_date = min(reg_dt)
    FROM DISK_SIZE_HIST as d with (nolock) where server_id = @server_id and reg_dt >= @base_date
end



SELECT dbo.get_svrnm(D.server_id) as server_name ,D.reg_dt
        , D.letter, D.disk_size , D.used_size, (D.disk_size-D.used_size) as free_size
       ,isnull(D.data_file_size,0) as db_size, (D.used_size-isnull(D.data_file_size,0)) as file_size
FROM DISK_SIZE_HIST as D with (nolock) 
WHERE  D.server_id = @server_id and D.letter = @letter 
    and D.reg_dt >= DATEADD(D, -10, @base_date) and D.reg_dt  <= @base_date
ORDER BY D.reg_dt
    

RETURN


