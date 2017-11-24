/*****************************************************************************      
SP명  : up_DBA_SQL_Server_List  
작성정보 : 2006-10-19  김태환  
내용  : SQL 서버 목록  
******************************************************************************/  
--DROP PROCEDURE [dbo].up_DBA_SQL_Server_List  
  
CREATE PROCEDURE [dbo].up_DBA_SQL_Server_List  
  
AS  
  
BEGIN  
 SET NOCOUNT ON    
  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
   
  
 SELECT svr_id, sql_svr_name,SERVER_NAME, ip, private_ip, port, product_level, product_version,  
              svr_start_account, clustering_yn  ,mirroring_yn,replication_yn
    FROM sql_server_list WITH (NOLOCK)
 WHERE service_level in (1,3)  
 ORDER BY svr_id
  
   
 SET NOCOUNT OFF  
END  
  
  