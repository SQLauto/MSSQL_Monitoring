CREATE FUNCTION dbo.fnc_removenumeric (@str varchar(50))  
RETURNS varchar(50)  
AS  
BEGIN  
 DECLARE @seq int  
  
 SET @seq = 0  
  
 SET @str = REPLACE(@str, ' ', '')  
  
 WHILE @seq <= 9  
 BEGIN  
  
  SET @str = REPLACE(@str, convert(char(1), @seq), '')  
  
  SET @seq = @seq + 1  
  
 END  
  
 RETURN @str  
END  
GO

CREATE PROCEDURE dbo.sp_mon_con_byhost
AS
SET NOCOUNT ON 
    select dbo.fnc_removenumeric(hostname) as hostname, count(*) as connection_count
    FROM master.dbo.sysprocesses with (nolock)  
    where spid > 50
    group by dbo.fnc_removenumeric(hostname)  
    order by count(*) desc  
;
