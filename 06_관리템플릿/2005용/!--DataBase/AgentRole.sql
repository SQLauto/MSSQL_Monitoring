/*----------------------------------------------------
    Date    : 2007-08-24
    Note    : Agent�� �� �� �ִ� ���� Role ����
    No.     :
*----------------------------------------------------*/
    
use [msdb]

GO

EXEC sp_addrole 'SQLAgent_Gmarket'

EXEC sp_addrolemember 'SQLAgentUserRole', 'SQLAgent_Gmarket'

EXEC sp_addrolemember 'SQLAgentReaderRole', 'SQLAgent_Gmarket'

EXEC sp_grantdbaccess 'dev' , 'dev'

EXEC sp_addrolemember 'SQLAgent_Gmarket', 'dev'

 

-- ����

-- SQLAgentUserRole, SQLAgentReaderRole �������־����������̰��Ѵ�.

-- �̵α������������ڽ��Ǽ����ڷ�Job�������ϰ����, control�Ҽ������ǷξƷ���������

 

DENY EXECUTE ON [dbo].[sp_add_job] TO [SQLAgent_Gmarket]

DENY EXECUTE ON [dbo].[sp_add_jobschedule] TO [SQLAgent_Gmarket]

DENY EXECUTE ON [dbo].[sp_add_jobserver] TO [SQLAgent_Gmarket]

DENY EXECUTE ON [dbo].[sp_add_jobstep] TO [SQLAgent_Gmarket]

 

DENY EXECUTE ON [dbo].[sp_update_jobstep] TO [SQLAgent_Gmarket]

DENY EXECUTE ON [dbo].[sp_update_jobschedule] TO [SQLAgent_Gmarket]

DENY EXECUTE ON [dbo].[sp_update_job] TO [SQLAgent_Gmarket]

 

DENY EXECUTE ON [dbo].[sp_delete_jobstep] TO [SQLAgent_Gmarket]

DENY EXECUTE ON [dbo].[sp_delete_jobschedule] TO [SQLAgent_Gmarket]

DENY EXECUTE ON [dbo].[sp_delete_job] TO [SQLAgent_Gmarket]

DENY EXECUTE ON [dbo].[sp_delete_jobserver] TO [SQLAgent_Gmarket]

DENY EXECUTE ON [dbo].[sp_delete_jobsteplog] TO [SQLAgent_Gmarket]


DENY EXECUTE ON sp_attach_schedule       TO [SQLAgent_Gmarket]
DENY EXECUTE ON sp_detach_schedule       TO [SQLAgent_Gmarket]
DENY EXECUTE ON sp_start_job           TO [SQLAgent_Gmarket]
DENY EXECUTE ON sp_stop_job            TO [SQLAgent_Gmarket]
DENY EXECUTE ON sp_addtask        TO [SQLAgent_Gmarket]
DENY EXECUTE ON sp_droptask       TO [SQLAgent_Gmarket]

