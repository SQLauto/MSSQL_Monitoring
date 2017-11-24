SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.sp_mon_mirroring_status
* 작성정보    : 2010-02-22
* 관련페이지  :  
* 내용        : 미러링 연결 상태
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.sp_mon_mirroring_status

AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT 
      DB_NAME(database_id) AS 'DatabaseName' 
       , database_id                                               -- 데이터베이스ID 
       , mirroring_guid                                            -- 미러링파트너관계의ID
       , CASE mirroring_state                                      -- 미러링세션의상태
             WHEN 0 THEN '일시중지됨'
             WHEN 1 THEN '연결끊김'
             WHEN 2 THEN '동기화중'
             WHEN 3 THEN '장애조치(Failover) 보류중'
             WHEN 4 THEN '동기화됨'
             WHEN null THEN '데이터베이스가온라인이아님'    
         END AS mirroring_state   
    , mirroring_role_desc    
       , CASE mirroring_safety_level                                     -- 미러링세션의상태
             WHEN 0 THEN '알수없는상태'
             WHEN 1 THEN 'Off[비동기]'
             WHEN 2 THEN 'Full[동기]'          
             WHEN null THEN '데이터베이스가온라인이아님'    
         END AS mirroring_safety_level       
    , mirroring_safety_sequence --트랜잭션보안수준변경내용에대한시퀀스번호를업데이트합니다.
    , mirroring_role_sequence --장애조치또는강제서비스로인해미러링파트너가주서버및미러서버역할을전환한횟수입니다. 
    , mirroring_partner_instance
    , mirroring_witness_name
    --, mirroring_witness_state_desc
       ,CASE mirroring_witness_state                                     -- 미러링세션의상태
             WHEN 0 THEN '알수없음'
             WHEN 1 THEN '연결됨'
             WHEN 2 THEN '연결끊김'             
             WHEN null THEN '미러링모니터가존재하지않거나데이터베이스가온라인이아님'       
         END AS mirroring_witness_state    
    , mirroring_failover_lsn --장애조치후에두파트너는mirroring_failover_lsn을새미러서버가새미러데이터베이스와새주데이터베이스와의동기화를시작하는조정지점
FROM sys.database_mirroring  as dm WITH(NOLOCK)
WHERE mirroring_guid IS NOT NULL;

RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO