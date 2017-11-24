-- 디비몬의 정산 일마감  내역 확인 메뉴로도 가능

-- 정산 로그 쿼리 (패키지의 단계별 로그)
-- 1.전체 마감 로그
select *, datediff(hh,start_dt, end_dt) from dbo.working_close_date where seq_no = 23 

--2. 한단계 로그
select  *, datediff(mi,start_date, isnull(end_date, getdate())) from dbo.DAILYCLOSE_JOB_LOG where seq_no  = 43

-- 1, 2, 3, 4, 5 단계를 오래 걸리지 않음 . 실행했는데도 오래 걸리는것 같으면
--  정산 sp의 로그 진행 확인
select * from  CUSTOM_LOG where work_date >= '2008-03-28' -- 마감일자 날짜



select *, datediff(mi,start_date, end_date) from dbo.DAILYCLOSE_JOB_LOG where seq_no = 34

select * from acctclose.dbo.close_data_log with(nolock) where reg_dt > '2008-04-09'
order by seqno

select * from acctclose.dbo.close_data_save_history with (nolock) where save_dt > '2008-04-09'
order by seqno

select * from acctclose.dbo.close_data_save_history with (nolock) where sday = '2008-04-07 00:00:00'
order by seqno

--=======================================================================
-- 수동으로 돌려야 할 때 단계 SP 명
--========================================================================
-- 1단계
exec dbo.up_ssis_sttl_custom_dr_save
-- 2단계
exec dbo.up_ssis_sttl_custom_convert_dr_save
-- 3단계
exec dbo.up_ssis_sttl_daily_co_comm_code
-- 4단계
exec up_ssis_gmembership_franchise_contract_mng_dr_save
-- 5단계
exec up_ssis_account_job_goods_dr_update
-- 6단계
exec up_ssis_sttl_daily_close_data_create_11
-- 7단계
exec up_ssis_sttl_daily_close_data_create_12
-- 8단계
exec up_ssis_sttl_daily_close_data_create_13
-- 9단계
exec up_ssis_sttl_co_comm_daily_create_1
-- 10단계
exec up_ssis_sttl_gsm_sell_info_create_1
-- 11단계
exec up_ssis_sttl_daily_close_data_summary_create_1
-- 12단계
exec up_ssis_sttl_daily_close_data_summary_create_2
-- 13단계
exec up_ssis_sttl_daily_close_data_create_2
-- 14 단계
exec up_ssis_sttl_daily_close_foreign_create_1

-- 모두 수동으로 실행되었을 때는 정산 재 마감 한번 실행 해 주면 좋음