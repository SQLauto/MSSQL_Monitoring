SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* ���ν�����  : dbo.sp_mon_mirroring_status
* �ۼ�����    : 2010-02-22
* ����������  :  
* ����        : �̷��� ���� ����
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.sp_mon_mirroring_status

AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT 
      DB_NAME(database_id) AS 'DatabaseName' 
       , database_id                                               -- �����ͺ��̽�ID 
       , mirroring_guid                                            -- �̷�����Ʈ�ʰ�����ID
       , CASE mirroring_state                                      -- �̷��������ǻ���
             WHEN 0 THEN '�Ͻ�������'
             WHEN 1 THEN '�������'
             WHEN 2 THEN '����ȭ��'
             WHEN 3 THEN '�����ġ(Failover) ������'
             WHEN 4 THEN '����ȭ��'
             WHEN null THEN '�����ͺ��̽����¶����̾ƴ�'    
         END AS mirroring_state   
    , mirroring_role_desc    
       , CASE mirroring_safety_level                                     -- �̷��������ǻ���
             WHEN 0 THEN '�˼����»���'
             WHEN 1 THEN 'Off[�񵿱�]'
             WHEN 2 THEN 'Full[����]'          
             WHEN null THEN '�����ͺ��̽����¶����̾ƴ�'    
         END AS mirroring_safety_level       
    , mirroring_safety_sequence --Ʈ����Ǻ��ȼ��غ��泻�뿡���ѽ�������ȣ��������Ʈ�մϴ�.
    , mirroring_role_sequence --�����ġ�Ǵ°������񽺷����ع̷�����Ʈ�ʰ��ּ����׹̷�������������ȯ��Ƚ���Դϴ�. 
    , mirroring_partner_instance
    , mirroring_witness_name
    --, mirroring_witness_state_desc
       ,CASE mirroring_witness_state                                     -- �̷��������ǻ���
             WHEN 0 THEN '�˼�����'
             WHEN 1 THEN '�����'
             WHEN 2 THEN '�������'             
             WHEN null THEN '�̷�������Ͱ����������ʰų������ͺ��̽����¶����̾ƴ�'       
         END AS mirroring_witness_state    
    , mirroring_failover_lsn --�����ġ�Ŀ�����Ʈ�ʴ�mirroring_failover_lsn�����̷����������̷������ͺ��̽��ͻ��ֵ����ͺ��̽����ǵ���ȭ�������ϴ���������
FROM sys.database_mirroring  as dm WITH(NOLOCK)
WHERE mirroring_guid IS NOT NULL;

RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO