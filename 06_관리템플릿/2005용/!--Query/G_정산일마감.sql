-- ������ ���� �ϸ���  ���� Ȯ�� �޴��ε� ����

-- ���� �α� ���� (��Ű���� �ܰ躰 �α�)
-- 1.��ü ���� �α�
select *, datediff(hh,start_dt, end_dt) from dbo.working_close_date where seq_no = 23 

--2. �Ѵܰ� �α�
select  *, datediff(mi,start_date, isnull(end_date, getdate())) from dbo.DAILYCLOSE_JOB_LOG where seq_no  = 43

-- 1, 2, 3, 4, 5 �ܰ踦 ���� �ɸ��� ���� . �����ߴµ��� ���� �ɸ��°� ������
--  ���� sp�� �α� ���� Ȯ��
select * from  CUSTOM_LOG where work_date >= '2008-03-28' -- �������� ��¥



select *, datediff(mi,start_date, end_date) from dbo.DAILYCLOSE_JOB_LOG where seq_no = 34

select * from acctclose.dbo.close_data_log with(nolock) where reg_dt > '2008-04-09'
order by seqno

select * from acctclose.dbo.close_data_save_history with (nolock) where save_dt > '2008-04-09'
order by seqno

select * from acctclose.dbo.close_data_save_history with (nolock) where sday = '2008-04-07 00:00:00'
order by seqno

--=======================================================================
-- �������� ������ �� �� �ܰ� SP ��
--========================================================================
-- 1�ܰ�
exec dbo.up_ssis_sttl_custom_dr_save
-- 2�ܰ�
exec dbo.up_ssis_sttl_custom_convert_dr_save
-- 3�ܰ�
exec dbo.up_ssis_sttl_daily_co_comm_code
-- 4�ܰ�
exec up_ssis_gmembership_franchise_contract_mng_dr_save
-- 5�ܰ�
exec up_ssis_account_job_goods_dr_update
-- 6�ܰ�
exec up_ssis_sttl_daily_close_data_create_11
-- 7�ܰ�
exec up_ssis_sttl_daily_close_data_create_12
-- 8�ܰ�
exec up_ssis_sttl_daily_close_data_create_13
-- 9�ܰ�
exec up_ssis_sttl_co_comm_daily_create_1
-- 10�ܰ�
exec up_ssis_sttl_gsm_sell_info_create_1
-- 11�ܰ�
exec up_ssis_sttl_daily_close_data_summary_create_1
-- 12�ܰ�
exec up_ssis_sttl_daily_close_data_summary_create_2
-- 13�ܰ�
exec up_ssis_sttl_daily_close_data_create_2
-- 14 �ܰ�
exec up_ssis_sttl_daily_close_foreign_create_1

-- ��� �������� ����Ǿ��� ���� ���� �� ���� �ѹ� ���� �� �ָ� ����