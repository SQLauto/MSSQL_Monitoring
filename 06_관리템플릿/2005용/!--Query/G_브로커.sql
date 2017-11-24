/*현재 data 이관 관련 broker 서비스가 SSIS 와 AccountDB , PASTDB로 구성되어 구축이 완료 되었습니다.
각 세션별 작업 정보를 보시려면 다음 쿼리를
SSIS의 BrokerAdminDB에서 실행하시면됩니다. */


select sb_work_group_list_no , tr_table_mapping_no  , sum(request_count) as req_cnt , sum(complete_count) as rep_cnt , (sum(complete_count)* 100) /sum(request_count)   as 'complete_ratio(%)' , avg(duration) 'avg_duration(ms)'
from dbo.SBSessionHistory with(nolock)
group by sb_work_group_list_no , tr_table_mapping_no
