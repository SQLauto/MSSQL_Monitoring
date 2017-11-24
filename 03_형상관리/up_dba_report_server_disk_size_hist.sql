SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* 프로시저명  : dbo.up_dba_report_server_disk_size_hist 
* 작성정보    : 2010-02-16 by 최보라
* 관련페이지  :  
* 내용        : 서버별, 일자별 디스크 사이즈 추이
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_report_server_disk_size_hist
     @site_gn       nvarchar(30),          
     @from_dt       datetime    = null,
     @to_dt         datetime    = null,
     @server_id     int, 
     @free_rate     int         = 100 --여휴공간 %이하인것만 보고 싶을경우
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @get_from_dt    datetime
DECLARE @get_to_dt      datetime

/* BODY */
IF @free_rate is null set @free_rate = 0

IF @from_dt is null 
BEGIN
    SET @get_from_dt = convert(datetime,convert(nvarchar(10), getdate() , 121) )
    SET @get_to_dt = convert(datetime,convert(nvarchar(10), getdate() + 1, 121) )
    
END
ELSE 
BEGIN
    SET @get_from_dt = @from_dt
    SET @get_to_dt = @to_dt
END

SELECT convert(nvarchar(10), d.reg_dt, 121) as reg_dt, s.server_id, s.server_name,  d.letter, d.disk_size,
       d.used_size,  isnull(d.data_file_size, 0) as data_file_size, isnull((d.used_size -d.data_file_size),0) as etc_file_size,
       (d.disk_size-d.used_size) as free_size, 
       round((d.disk_size-d.used_size) / convert(float,d.disk_size) * 100, 2) as free_rate
FROM DISK_SIZE_HIST  as d with (nolocK)
     join serverinfo as s on d.server_id = s.server_id 
WHERE d.reg_dt >= @get_from_dt and d.reg_dt < @get_to_dt
    and (( @free_rate = 0 AND (d.disk_size-d.used_size) = (d.disk_size-d.used_size) ) OR round((d.disk_size-d.used_size) / convert(float,d.disk_size) * 100, 2) <= @free_rate)
    and ((@server_id = 0 and s.server_id = s.server_id ) or s.server_id = @server_id)
    and  s.site_gn = @site_gn
ORDER BY convert(nvarchar(10), d.reg_dt, 121), s.server_id, d.letter




RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO