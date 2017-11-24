/*IF EXISTS (SELECT name 
              FROM   sysobjects 
              WHERE  name = N'up_dba_backup_check_db_yn' 
              AND              type = 'P')
    DROP PROCEDURE  procedure_name
*/

/*************************************************************************  
* ���ν�����  : dbo.up_dba_backup_check_db_yn
* �ۼ�����    : 2007-12-18
* ����������  : �� �� ��   
* ����        :
* ��������    :
--BACKUP_MASTER�� �⺻������ ��´�.
--BACKUP_MASTER�� ������ �ִµ� BACKUP_DETAIL�� �����Ͱ� ������ ��� ���� 
--SSIS�� ����븮���� ���� 9�ÿ� �����͸� BACKUP_DETAIL�� �ִ´�
--���� 9�� ����, 9�� 30��~ 10�� 30�л��̿� BACKUP_DETAIL�� ��ϵ� �ð�(reg_dt)�� �����ֱ��� ����ð��� �������� �ִ´�.
--�̶� �����Ͱ� ������, ��� ����
--�����Ͱ� ������ �������
exec dbo.up_dba_backup_check_db_yn '2007-12-14'
--�������� 1) ��¥�Է¹ޱ� 2) ������ ��ġ��
2007-12-28 by choi bo ra, ������ �ʿ� ��� ����
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_backup_check_db_yn
	@todayDate		datetime     
AS
/* COMMON DECLARE */
SET NOCOUNT ON
/* USER DECLARE */
DECLARE @nextdayDate DATETIME
SET @nextdayDate  = DATEADD(dd, 1, @todayDate)

/* BODY */
--DB
SELECT 
       'DOC NAME' AS doc_name
	 , bm.server_name as server_name
	 , bm.database_name	 as db_name 
	 , (CASE bm.backup_flag WHEN 1 THEN 'DB + LOG '
							WHEN 2 THEN 'DB' 
							WHEN 3 THEN 'LOG' 
							ELSE 'TYPE ERROR' END) as backup_type 	
	 , (CASE bm.backup_cycle WHEN 1 THEN 'DAILY'
							 WHEN 2 THEN 'WEEKLY'
							 WHEN 3 THEN 'MONTHLY'
							 ELSE 'CYCLE CASE ERROR' END ) as backup_cycle
	 , bd.name 
	 , bd.backup_diffday  		 
	 , bd.type
	 , (CASE bm.backup_cycle WHEN 1 THEN (CASE WHEN bd.backup_diffday <= bm.backup_day THEN '����' ELSE '����' END) 
							 WHEN 2 THEN (CASE WHEN bd.backup_diffday <= bm.backup_day * 7 THEN '����' ELSE '����' END) 
							 WHEN 3 THEN (CASE WHEN bd.backup_diffday <= bm.backup_day * 30 THEN '����' ELSE '����' END)
							 ELSE 'ERROR' END) as success_flag							
	 , bd.backup_start_date 	 
	 , (DATEDIFF(mi, bd.backup_start_date, bd.backup_finish_date)) as backupTime
	 , bd.physical_device_name
	 , bd.backup_size as [size]
	 ,  bd.reg_dt
FROM backup_master AS bm WITH (NOLOCK)
        INNER JOIN backup_detail AS bd WITH (NOLOCK) ON bm.server_name = bd.server_name AND bm.database_name = bd.database_name 
        
WHERE bd.type = 'FULL BACKUP' AND reg_dt > @todayDate and reg_dt < @nextdayDate  
ORDER BY bm.server_name, bm.database_name, bm.seq_no

IF @@ERROR <> 0 RETURN

RETURN



