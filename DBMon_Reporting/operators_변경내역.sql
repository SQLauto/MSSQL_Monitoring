
[GMKT2008]
-- tiger
up_DBA_contr_monitoring

-- dba
dbo.up_DBA_send_sms_byTeam
dbo.up_DBA_TruncateTransactionLog

[PASTDB]
-- monitoring
up_DBA_monitoring_get_contr_total_yesterday

-- dba
dbo.up_DBA_send_sms_byTeam


[ACCOUNTDB]
dbo.up_dba_monitor_dailyclose

[ADMINDB1]
-- dba
dbo.up_DBA_cacl_Restore_time
dbo.up_DBA_send_sms_byTeam

[ADMINDB2]
-- dba
up_DBA_send_sms_byTeam


--	직접 입력
INSERT INTO contentsdb.KT_SMS.dbo.smscli_tbl_etc(tran_phone, tran_callback, tran_msg ,tran_status, corp_reserved4 )   
SELECT hp_no , '1004', @pMessage, '1', '4098'




exec contentsdb.SMS_ADMIN.dbo.up_DBA_send_short_msg  '01020480438', @msg
exec contentsdb.SMS_ADMIN.dbo.up_DBA_send_short_msg  'DBA', @msg
10	system alert	DB시스템경고
20	db backup alert	db backup 경고
30	job alert	job 경고
40	business alert	업무 경고
99	ALL alert	모든경고

INSERT INTO contentsdb.KT_SMS.dbo.smscli_tbl_etc(tran_phone, tran_callback, tran_msg ,tran_status, corp_reserved4 )   
SELECT hp_no , '1004', @pMessage, '1', '4098'

