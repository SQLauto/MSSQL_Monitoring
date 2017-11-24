/*���� data �̰� ���� broker ���񽺰� SSIS �� AccountDB , PASTDB�� �����Ǿ� ������ �Ϸ� �Ǿ����ϴ�.
�� ���Ǻ� �۾� ������ ���÷��� ���� ������
SSIS�� BrokerAdminDB���� �����Ͻø�˴ϴ�. */


select sb_work_group_list_no , tr_table_mapping_no  , sum(request_count) as req_cnt , sum(complete_count) as rep_cnt , (sum(complete_count)* 100) /sum(request_count)   as 'complete_ratio(%)' , avg(duration) 'avg_duration(ms)'
from dbo.SBSessionHistory with(nolock)
group by sb_work_group_list_no , tr_table_mapping_no
