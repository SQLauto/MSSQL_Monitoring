use dba
-- use dbadmin
go

-- =============================================                 
-- Author:  <Author,,Daekyung Kim>               
-- Create date: <Create Date,,2010-10-01>                 
-- Description: <Description,,DB Login>                
-- [up_conf_LoginInfoCollect] 1,1        
-- =============================================                 
CREATE PROCEDURE [dbo].[up_conf_LoginInfoCollect]          
    @server_id          int,          
    @instance_id        int          
AS                 
                
 SET NOCOUNT ON;            
           
 IF LEFT(CAST(SERVERPROPERTY('ProductVersion') As Varchar),1) = '8'           
  SELECT          
   @server_id AS server_id          
   ,@instance_id AS instance_id            
   ,NULL AS IsLocked          
   ,NULL AS IsExpired          
   ,NULL AS IsMustChange          
   ,NULL AS BadPasswordCount          
   ,NULL AS BadPasswordTime          
   ,NULL AS LockoutTime          
   ,NULL AS PasswordLastSetTime           
   ,CASE WHEN password IS NULL THEN 'N' ELSE 'Y' END AS setPassword
   ,*          
   ,NULL AS is_policy_checked          
   ,NULL AS is_expiration_checked    
   ,NULL AS is_disabled                   
   ,0  AS connection        
  FROM master.dbo.syslogins WITH(NOLOCK)          
 ELSE          
 BEGIN          
           
  DECLARE @stmt NVARCHAR(3000)                
  DECLARE @paramDef NVARCHAR(100)              
            
  SET @paramDef = N'@server_id int, @instance_id int'          
  SET @stmt = N'          
   SELECT          
    @server_id AS server_id          
    ,@instance_id AS instance_id          
    ,CONVERT(INT, LOGINPROPERTY(a.name,''IsLocked'')) AS IsLocked          
    ,CONVERT(INT, LOGINPROPERTY(a.name,''IsExpired'')) AS IsExpired          
    ,CONVERT(INT, LOGINPROPERTY(a.name,''IsMustChange'')) AS IsMustChange          
    ,CONVERT(INT, LOGINPROPERTY(a.name,''BadPasswordCount'')) AS BadPasswordCount          
    ,CONVERT(INT, LOGINPROPERTY(a.name,''BadPasswordTime'')) AS BadPasswordTime          
    ,CONVERT(INT, LOGINPROPERTY(a.name,''LockoutTime'')) AS LockoutTime          
    ,CONVERT(INT, LOGINPROPERTY(a.name,''PasswordLastSetTime'')) AS PasswordLastSetTime          
    ,CASE WHEN a.password IS NULL THEN ''N'' ELSE ''Y'' END AS setPassword
    ,a.*            
    ,b.is_policy_checked, b.is_expiration_checked, b.is_disabled              
    ,ISNULL(c.connetion,0) as connection            
   FROM sys.syslogins a WITH(NOLOCK) JOIN sys.sql_logins b WITH(NOLOCK)          
    ON a.sid = b.sid          
   LEFT JOIN (SELECT * FROM DBMON.dbo.DB_MON_SQL_LOGINS WITH(NOLOCK) WHERE reg_date = CONVERT(VARCHAR(10), GETDATE()-1,121)) c      
 ON a.name COLLATE DATABASE_DEFAULT = c.login_name COLLATE DATABASE_DEFAULT        
  '          
          
  EXEC sp_executesql @stmt, @paramDef, @server_id = @server_id, @instance_id = @instance_id          
 END

