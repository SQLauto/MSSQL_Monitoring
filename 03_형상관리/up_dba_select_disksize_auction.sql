/*************************************************************************  
* 프로시저명  : dbo.up_dba_select_disksize 
* 작성정보    : 2010-02-10 by 최보라
* 관련페이지  :  
* 내용        : 디스크 size 정보 (sp_diskspace 변경)
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_disksize
    @server_id          int,
    @instance_id        int

AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET FMTONLY OFF

/* USER DECLARE */
DECLARE @hr int    
DECLARE @fso int    
DECLARE @letter char(1)    
DECLARE @odrive int    
DECLARE @disk_size varchar(20)    
DECLARE @MB bigint ; SET @MB = 1048576 

/* BODY */
CREATE TABLE #drives (
    letter char(1) PRIMARY KEY,    
    free_size int NULL,    
    disk_size int NULL
   )    

INSERT #drives(letter,free_size)     
EXEC master.dbo.xp_fixeddrives    
    
EXEC @hr=sp_OACreate 'Scripting.FileSystemObject',@fso OUT    
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso    
    
DECLARE dcur CURSOR LOCAL FAST_FORWARD    
FOR SELECT letter from #drives    
ORDER by letter    
    
OPEN dcur    

FETCH NEXT FROM dcur INTO @letter    
    
WHILE @@FETCH_STATUS=0    
BEGIN    
    
        EXEC @hr = sp_OAMethod @fso,'GetDrive', @odrive OUT, @letter    
        IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso    
            
        EXEC @hr = sp_OAGetProperty @odrive,'TotalSize', @disk_size OUT    
        IF @hr <> 0 EXEC sp_OAGetErrorInfo @odrive    
                            
        UPDATE #drives    
        SET disk_size=@disk_size/@MB    
        WHERE letter=@letter    
            
        FETCH NEXT FROM dcur INTO @letter    
    
END    
    
CLOSE dcur    
DEALLOCATE dcur    

EXEC @hr=sp_OADestroy @fso    
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso  

 
SELECT @server_id as server_id, @instance_id as instance_id ,
       letter,    
       disk_size,
       (disk_size - free_size) as usage_size 
FROM #drives 
ORDER BY letter  
  
  
    
DROP TABLE #drives  

RETURN


