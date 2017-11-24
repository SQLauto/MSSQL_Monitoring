
/* 인덱스 튜닝 작업 
인덱스 사용 현황을 확인 하기 위함. 
*/


--1 종속 SP 확인
EXEC dbo.UP_DBA_OBJECT_REFERENCE_TABLE 'maindb2', 'maindb2ex', 'EMONEY_BALANCE_MONITORING' --, '201-04-02'



-- 2. SP별 라인을 구함
exec dbmon.dbo.up_mon_sp_text2 'MAINDB2EX','UPIAC_ESCROW_EMONEYBALANCEMONITORING_SELECTBYERRORDATEORDERBYSEQNO'

-- 3.SP별 인덱스 사용현황 파악
exec dbmon.dbo.up_mon_sp_index_object_light 'MAINDB2','UPIAC_ESCROW_EMONEYMASTER_UPDATEREMAMOUNTBYREVISEEMONEYBALANCE'
exec dbmon.dbo.up_mon_sp_index_object_light 'MAINDB2','UPIAC_ESCROW_EMONEYMASTER_UPDATEREMAMOUNTBYREVISEEMONEYBALANCE'
exec dbmon.dbo.up_mon_sp_index_usage_light 'MAINDB2','UPIAC_ESCROW_EMONEYMASTER_UPDATEREMAMOUNTBYREVISEEMONEYBALANCE'
