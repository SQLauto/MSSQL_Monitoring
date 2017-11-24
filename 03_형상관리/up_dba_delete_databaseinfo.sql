/*************************************************************************                      
* ���ν�����  : dbo.up_dba_delete_databaseinfo                     
* �ۼ�����    : 2010-02-12 by choi bo ra                    
* ����������  :                      
* ����        : ���� ����͸� ������� ���̺� ����                    
* ��������    :                     
    2010-09-17 : BackupHistory �ߺ� ������ ���� �߰� by daekyung kim  
	2014-09-26 BY CHOI BO RA  TRANS_BASIC_INFO_MASTER_ACCUM �ش� ���� ����               
**************************************************************************/                    
ALTER PROCEDURE [dbo].[up_dba_delete_databaseinfo]                    
     @type          varchar(10) = 'DAY',                    
     @server_id     int ,                    
     @instance_id   int                     
AS                    
/* COMMON DECLARE */                    
SET NOCOUNT ON                    
                    
/* USER DECLARE */                    
DECLARE @get_dt     DATETIME                    
SET @get_dt = CONVERT(nvarchar(10), getdate(), 121)                    
                    
/* BODY */                    
IF @type = 'DAY'                    
BEGIN                    
    DELETE  DATABASE_FILE_LIST WHERE reg_dt >= @get_dt and reg_dt < @get_dt + 1                    
                                   and server_id = @server_id and  instance_id = @instance_id                    
    DELETE  DISK_SIZE_HIST WHERE reg_dt >= @get_dt and reg_dt < @get_dt + 1                    
                                   and server_id = @server_id                     
    DELETE  DATABASE_LIST WHERE reg_dt >= @get_dt and reg_dt < @get_dt + 1                    
                                   and server_id = @server_id                     
    DELETE  VLF_HIST WHERE reg_dt >= @get_dt and reg_dt < @get_dt + 1                    
                                   and server_id = @server_id                     
                       
                         
 DELETE A                    
 FROM TABLE_SIZE AS A                    
 WHERE A.SERVER_ID =  @SERVER_ID  AND A.REG_DT >= @GET_DT AND A.REG_DT < @GET_DT + 1     
                                               
 -- JobInfo �ߺ� ������ ����                    
 DELETE JobInfo                    
 WHERE reg_date >= @get_dt AND reg_date < @get_dt + 1                     
 AND server_id = @server_id AND instance_id = @instance_id                       
 --TRUNCATE TABLE JobInfo                    
            
 DELETE SERVERCONFIG                    
 WHERE server_id = @server_id     
 and ((reg_date >= @get_dt AND reg_date < @get_dt + 1) OR  reg_date < @get_dt-7)    
 --TRUNCATE TABLE JobInfo                 
    
 DELETE SERVERCONFIG_HISTORY    
 WHERE server_id = @server_id and reg_dt >= @get_dt AND reg_dt < @get_dt + 1    
        
 DELETE SERVEROBJECTS                
 WHERE server_id = @server_id                   
        
 DELETE SERVERUSERS              
 WHERE server_id = @server_id                  
        
 DELETE SERVERPROTECTS              
 WHERE server_id = @server_id           
         
 DELETE  DB_IDENTITY_TABLE where server_id = @server_id  and reg_dt =@get_dt        
   
  DELETE  DB_MON_SQL_LOGINS_CONNECTION where server_id = @server_id  and REG_DATE =@get_dt     
  
  
                                                    
END                    
ELSE IF @type = 'COLSINFO'                    
BEGIN       
 DELETE  COLINFO where server_id = @server_id  and reg_dt >= @get_dt AND reg_dt < @get_dt + 1       
END  
ELSE IF @type = 'LOGIN'                    
BEGIN          
 -- LoginInfo �ߺ� ������ ����                    
 DELETE LoginInfo                    
 WHERE reg_date >= @get_dt AND reg_date < @get_dt + 1                     
 AND server_id = @server_id AND  instance_id = @instance_id                     
END            
ELSE IF @type = 'BACKUP'                    
BEGIN          
 -- BackupHistory �ߺ� ������ ����                    
 DELETE BackupHistory                  
 WHERE reg_date >= @get_dt AND reg_date < @get_dt + 1                     
 AND server_id = @server_id AND  instance_id = @instance_id            
END  
ELSE IF @type = 'TRANS_INFO'
BEGIN       
 DELETE  TRANS_BASIC_INFO_MASTER_ACCUM where server_id = @server_id     
END                             
                    
RETURN         
  

