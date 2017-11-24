/*----------------------------------------------------
    Date    : 2007-08-24
    Note    : Agent을 볼 수 있는 권한 Role 설정
    No.     :
*----------------------------------------------------*/
    
use [msdb]

GO

-- 1. 롤 하나 생성
EXEC sp_addrole 'SQLAgent_Gmarket'   -- 공식 명칭입니다. 롤을 하나 생성합니다. 


--2. 생성된 롤에 기존 롤 승계
-- 생성된 롤에 SQL 기본 role인 SQLAgentUserRole, SQLAgentReaderRole을 포함 시킵니다. 
-- SQLAgentUserRole : 자신이 생성한 작업만 볼 수 있고 수정할 수 있습니다. 
--  --> 이것만 부여되면 다른 권한이 접근해서 생성한 작업을 볼 수 업습니다. 
-- SQLAgentReaderRole : SQLAgentUserRole 뿐 아니라 사용가능한 다중 서버랑 모든 작업들의 속성을 볼 수 있습니다. 
--  --> 이 롤은 다른 권한이 생성한 작업을 수정하거나 실행 중지할 수 없지만 자신이 만든 job은 수정/시작/중지할 수
--      있습니다. 

EXEC sp_addrolemember 'SQLAgentUserRole', 'SQLAgent_Gmarket'  

EXEC sp_addrolemember 'SQLAgentReaderRole', 'SQLAgent_Gmarket'


 

-- 3. 제한

-- SQLAgentUserRole, SQLAgentReaderRole 권한을주어서모든목록을보이게한다.
-- 이두권한이있으면자신의소유자로Job을생성하고삭제, control할수있으므로아래내역제거
-- 로컬 작업도 수정/삭제/시작/중지 등을 못하고 단시 기록보기 , 속성 보기, 일정보기, 작업보기 권한만
-- 주기 위해 아래 권한을 제거 합니다.
 

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



--4. 유저에 롤 권한 주기

EXEC sp_grantdbaccess 'dev' , 'dev'  -- msdb에 접근을 해야 합니다.

EXEC sp_addrolemember 'SQLAgent_Gmarket', 'dev'