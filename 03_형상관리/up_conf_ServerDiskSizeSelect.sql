use admin
go


  
/*************************************************************************    
* 프로시저명  : dbo.up_conf_ServerDiskSizeSelect  
* 작성정보    : 2010-09-30 by 서버의 Disk 추이  
* 관련페이지  :   
* 내용        :   
* 수정정보    :  
**************************************************************************/  
ALTER PROCEDURE dbo.up_conf_ServerDiskSizeSelect 
    @server_id      int,  
    @use_yn         char(1) = 'Y'
    @base_date      datetime = NULL  
   
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
  
  
  
SELECT dbo.get_svrnm(D.server_id) as server_name ,D.reg_dt, D.letter, D.used_yn, D.disk_size 
       ,D.used_size, (D.disk_size-D.used_size) as free_size  
       ,isnull(D.data_file_size,0) as db_size, (D.used_size-isnull(D.data_file_size,0)) as file_size  
       ,isnull(H.data_day,0) as data_day, isnull(H.etc_day,0) as etc_day  
       ,case when (isnull(H.data_day,0) + isnull(H.etc_day,0)) > 0   
            then convert(nvarchar(10), dateadd(dd, (D.disk_size-D.used_size) / (H.data_day + H.etc_day), GETDATE()), 121)   
        else null end close_date  
FROM DISK_SIZE as D with (nolock)   
 JOIN   
    (    
        select h.server_id, h.letter,  
               sum(h.data_file_size -p.data_file_size)/ datediff(dd,DATEADD(m, -1, @base_date), @base_date) as data_day,  
               sum((h.used_size - h.data_file_size)  - (p.used_size - p.data_file_size)) /datediff(dd,DATEADD(m, -1, @base_date), @base_date) as etc_day
               --AVG(h.data_file_size -p.data_file_size) * DATEDIFF(d, min(h.reg_dt), max(h.reg_dt)) as data_month,  
               --AVG((h.used_size - h.data_file_size)  - (p.used_size - p.data_file_size)) * DATEDIFF(d, min(h.reg_dt), max(h.reg_dt)) as etc_month  
        from DISK_SIZE_HIST  as h with (nolock)  
            join  DISK_SIZE_HIST as p with (nolock) on   
                convert(nvarchar(10),h.reg_dt, 121) =  convert(nvarchar(10),dateadd(dd, 1, p.reg_dt), 121)    
                and h.server_id = p.server_id and h.letter = p.letter   
        where h.server_id = @server_id and h.reg_dt >= dateadd(M,-1,CONVERT(nvarchar(10), @base_date, 121)) and h.reg_dt < dateadd(d,1,CONVERT(nvarchar(10), @base_date, 121))  
        group by h.server_id, h.letter   
    ) AS H ON D.server_id = H.server_id and D.letter = H.letter  
WHERE  D.server_id = @server_id   and D.used_yn = @use_yn
      
  
RETURN  
GO
