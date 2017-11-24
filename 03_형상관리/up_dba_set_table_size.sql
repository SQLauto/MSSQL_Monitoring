/*************************************************************************                  
* 프로시저명  : up_dba_set_table_size 'I'                
* 작성정보    : 2010-03-29 by 김세웅                
* 관련페이지  :                  
* 내용        : DB정보 가져오기 sql2000, 2005 통합                 
* 수정정보    : gmarket, Auction별로 table_size_info delete로 변경 by 노상국                
         try~catch 추가                
up_dba_set_table_size 'G'                
up_dba_set_table_size 'I'                
**************************************************************************/                
ALTER PROC up_dba_set_table_size                
 @site_gn as char(1)                
                
AS                
                
SET NOCOUNT ON                
                
DECLARE @error_code INT                
                            
SET @error_code = -1                
                
BEGIN TRY                
      

   
UPDATE TABLE_SIZE_CONFIG SET db_id = dl.db_id      
FROM  TABLE_SIZE_CONFIG tc WITH(NOLOCK) 
JOIN       
    (      
    select server_id, instance_id, db_id, db_name from database_list with(nolock)      
    WHERE reg_dt = CONVERT(VARCHAR(10), GETDATE(), 121)      
    ) dl 
 ON tc.server_id = dl.server_id AND tc.instance_id = dl.instance_id AND tc.db_name = dl.db_name      
where tc.db_id != dl.db_id  
  
   
-- TABLE_BASE에 DB ID 변경되었을 시 수정
UPDATE TABLE_BASE SET db_id = dl.db_id      
FROM  TABLE_BASE tb WITH(NOLOCK) 
    JOIN       
    (      
    select server_id, instance_id, db_id, db_name from database_list with(nolock)      
    WHERE reg_dt = CONVERT(VARCHAR(10), GETDATE(), 121)      
    ) dl ON tb.server_id = dl.server_id AND tb.instance_id = dl.instance_id AND tb.db_name = dl.db_name      
where tb.db_id != dl.db_id    

   
-- TABLE_BASE에 db_id 가 null일때 수정  
UPDATE TABLE_BASE 
SET db_name = dl.db_name      
FROM  TABLE_BASE tb WITH(NOLOCK) JOIN       
    (      
    select server_id, instance_id, db_id, db_name from database_list with(nolock)      
    WHERE reg_dt = CONVERT(VARCHAR(10), GETDATE(), 121)      
    ) dl ON tb.server_id = dl.server_id AND tb.instance_id = dl.instance_id AND tb.db_id = dl.db_id  
where tb.db_id IS NULL  


--신규테이블 추가 등록                      
INSERT TABLE_BASE                 
(server_id, instance_id, db_id, schema_name, object_id, table_name, db_name)                
SELECT  a.server_id ,a.instance_id ,a.db_id ,a.schema_name, a.object_id, a.table_name, a.db_name as db_name  
FROM  
    (      
    SELECT  A.server_id ,A.instance_id ,C.db_id ,A.schema_name, max(a.object_id) as object_id, A.table_name
           , C.db_name as db_name                  
    FROM TABLE_SIZE_INFO A with(nolock)                
        JOIN TABLE_SIZE_CONFIG AS C with(nolock) ON A.seq = C.seq                
		join serverinfo as s with (nolock) on A.server_id = s.server_id                
     WHERE  s.site_gn  = @site_gn AND s.use_yn = 'Y'                            
    GROUP BY  A.server_id ,A.instance_id ,C.db_id ,A.schema_name ,A.table_name , C.db_name            
    ) a 
  LEFT JOIN TABLE_BASE b WITH(NOLOCK)  
ON a.server_id = b.server_id and a.instance_id=b.instance_id 
    and a.db_name = b.db_name and a.schema_name=b.schema_name and a.table_name=b.table_name  
WHERE b.Table_ID is null   
                    
         
END TRY                
                
BEGIN CATCH                
   INSERT INTO PKG_ERRORLOG(site_gn, item, sp_name, error_msg, error_line)                 
           VALUES(@site_gn, 'TABLE_SIZE_INFO', ERROR_PROCEDURE(), ERROR_MESSAGE(), ERROR_LINE())                
END CATCH                  
                                                    
BEGIN TRY                
            
  
                
 INSERT TABLE_SIZE  --테이블 사이즈 관리 테이블에 등록                
  (Table_id, reg_dt, rank, row_count, reserved, data, index_size, unused)             
 SELECT a.Table_ID, a.reg_dt, a.rank, a.row_count, a.reserved, a.data, a.index_size, a.unused          
 FROM          
 (          
 SELECT tb.Table_ID, tsi.reg_dt, tsi.rank, tsi.row_count, tsi.reserved, tsi.data, tsi.index_size, tsi.unused                
   FROM TABLE_SIZE_INFO tsi with(nolock)            
   JOIN TABLE_SIZE_CONFIG AS tsc with(nolock) ON tsi.seq = tsc.seq                
   JOIN TABLE_BASE tb                 
     ON tsc.server_id    =tb.server_id                 
     AND tsc.instance_id  = tb.instance_id                
     AND tsc.db_name = tb.db_name  
     AND tsi.schema_name  = tb.schema_name                
     AND tsi.table_name   = tb.table_name                 
   join serverinfo as s with (nolock) on tsc.server_id = s.server_id                
   WHERE s.site_gn = @site_gn                    
   and s.use_yn = 'Y' AND tsi.reg_dt >= CONVERT(VARCHAR(10), DATEADD(d, -30, GETDATE()), 121)           
 ) a LEFT JOIN          
 (          
 SELECT table_id,reg_dt FROM  TABLE_SIZE WITH(NOLOCK)          
 WHERE REG_DT >= CONVERT(VARCHAR(10), DATEADD(d, -30, GETDATE()), 121)            
 ) b ON a.table_id = b.table_id AND a.reg_dt = b.reg_dt          
 WHERE b.table_id IS NULL                 
                        
 SET @error_code = @@ERROR                 
                      
                        
                   
END TRY                
BEGIN CATCH  --에러가 발생하면 로그 쌓기                
      INSERT INTO PKG_ERRORLOG(site_gn, item, sp_name, error_msg, error_line)                 
           VALUES(@site_gn, 'TABLE_SIZE_INFO', ERROR_PROCEDURE(), ERROR_MESSAGE(), ERROR_LINE())                
                        
END CATCH 