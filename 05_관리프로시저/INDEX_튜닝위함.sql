
/* �ε��� Ʃ�� �۾� 
�ε��� ��� ��Ȳ�� Ȯ�� �ϱ� ����. 
*/


--1 ���� SP Ȯ��
EXEC dbo.UP_DBA_OBJECT_REFERENCE_TABLE 'maindb2', 'maindb2ex', 'EMONEY_BALANCE_MONITORING' --, '201-04-02'



-- 2. SP�� ������ ����
exec dbmon.dbo.up_mon_sp_text2 'MAINDB2EX','UPIAC_ESCROW_EMONEYBALANCEMONITORING_SELECTBYERRORDATEORDERBYSEQNO'

-- 3.SP�� �ε��� �����Ȳ �ľ�
exec dbmon.dbo.up_mon_sp_index_object_light 'MAINDB2','UPIAC_ESCROW_EMONEYMASTER_UPDATEREMAMOUNTBYREVISEEMONEYBALANCE'
exec dbmon.dbo.up_mon_sp_index_object_light 'MAINDB2','UPIAC_ESCROW_EMONEYMASTER_UPDATEREMAMOUNTBYREVISEEMONEYBALANCE'
exec dbmon.dbo.up_mon_sp_index_usage_light 'MAINDB2','UPIAC_ESCROW_EMONEYMASTER_UPDATEREMAMOUNTBYREVISEEMONEYBALANCE'
