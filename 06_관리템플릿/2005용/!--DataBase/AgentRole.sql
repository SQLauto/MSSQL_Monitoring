/*----------------------------------------------------
    Date    : 2007-08-24
    Note    : Agent을 볼 수 있는 권한 Role 설정
    No.     :
*----------------------------------------------------*/
    
use [msdb]

GO

EXEC sp_addrole 'SQLAgent_Gmarket'

EXEC sp_addrolemember 'SQLAgentUserRole', 'SQLAgent_Gmarket'

EXEC sp_addrolemember 'SQLAgentReaderRole', 'SQLAgent_Gmarket'

EXEC sp_grantdbaccess 'dev' , 'dev'

EXEC sp_addrolemember 'SQLAgent_Gmarket', 'dev'

 

-- 제한

-- SQLAgentUserRole, SQLAgentReaderRole 권한을주어서모든목록을보이게한다.

-- 이두권한이있으면자신의소유자로Job을생성하고삭제, control할수있으므로아래내역제거

 

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

