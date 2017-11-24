/*==============================================================================  
  작성자 : 김태환  
  작성일 : 2007-03-05  
  수정일 : 2007-12-25 김태환 JOB에 정의된 DURATION을 초과한 경우 중지 
           2008-06-13 최보라, DBA팀 문자 
  용  도  : LONG RUN JOB MONITORING SP  
=============================================================================*/  
ALTER PROCEDURE dbo.up_DBA_check_long_run_job_list  
AS  
    set nocount on
    set transaction isolation level read uncommitted   
  
    declare @runing_cnt         smallint         -- 임계치 설정된 job이 돌고 있는 개수
    declare @sms_msg            varchar(80)      -- 메세지
    declare @intcnt             smallint         -- 대상건  
    declare @intloopcnt         smallint         -- loop count  
    declare @msg                varchar(100)     -- 중지 메세지  
    declare @stop_job_id        uniqueidentifier -- 중지할 job id  
    declare @stop_job_name      varchar(100)     -- job name  
    declare @stop_job_duration  smallint         -- 수행시간  

    declare @job_list table  
    (  
        job_id  uniqueidentifier
    ,    seq_no  int not null identity(1,1)
    ,   job_name varchar(100) not null  
    ,   duration  int not null  
    )  
  
    ------------------------------------------------------  
    -- 현재 실행중인 JOB중 1시간이 경과한 JOB목록 생성  
    ------------------------------------------------------  
    INSERT INTO DBA.DBO.LONG_RUN_JOB_HISTORY(JOB_ID, DURATION)   
    SELECT job_id, datediff(mi, sp.login_time, getdate())  
      FROM master.dbo.sysprocesses as sp with (nolock)
     INNER JOIN dba.dbo.jobs as jb with (nolock, index(IDX__JOBS__MONITORING_YN)) ON substring(sp.program_name,32,32)= jb.job_id_char  
     WHERE jb.monitoring_yn = 'Y' 
       AND (jb.kill_yn = 'Y' OR jb.kill_yn = 'A')
       AND jb.kill_duration < datediff(mi, sp.login_time, getdate())  

    SET @runing_cnt = @@ROWCOUNT  
  
    IF @runing_cnt > 0  
    BEGIN  
        INSERT INTO @job_list(job_id, job_name, duration)  
        SELECT jb.job_id, jb.job_name, datediff(mi, sp.login_time, getdate())  
          FROM master.dbo.sysprocesses as sp with (nolock)
         INNER JOIN dba.dbo.jobs as jb with (nolock, index(IDX__JOBS__MONITORING_YN)) ON substring(sp.program_name,32,32)= jb.job_id_char  
         WHERE jb.monitoring_yn = 'Y' 
           AND (jb.kill_yn = 'Y' OR jb.kill_yn = 'A')
           AND jb.kill_duration < datediff(mi, sp.login_time, getdate())
  
        SELECT @intCnt = count(*)  FROM @job_list  
  
        -- LOOP 변수  
        SET @intLoopCnt = 1  
  
        IF @intCnt > 0  
        BEGIN  
            WHILE (1=1)  
            BEGIN  
                IF @intLoopCnt > @intCnt BREAK;  
         
                SELECT @stop_job_name = job_name, @stop_job_duration = duration  
                  FROM @job_list  
                 WHERE seq_no = @intLoopCnt  
    
                -- JOB중지  
                EXEC msdb.dbo.sp_stop_job @job_name = @stop_job_name, @server_name = @@servername  
    
                IF @@ERROR = 0  
                BEGIN  
                    SET @msg = '[' + @@servername + '] ' + LEFT(@stop_job_name, 10) + '...' + '이 실행중지 되었습니다. DURATION='+cast(@stop_job_duration as varchar) + '분'  
                    
                    INSERT INTO SMS.KIDC_SMS.DBO.SMSCLI_TBL_02(DESTINATION, ORIGINATOR, CALLBACK, CALLBACKURL, BODY,PROC_STATUS, TELESERVICE_ID )   
                    SELECT HPNO, '160701001001', '15665701', '', @MSG, '1' , '4098' 
                    FROM DBO.OPERATORSIMPLE WITH (NOLOCK) WHERE temcode = 1  --DBA만
                    
                    --EMS 발송
                    INSERT INTO [211.115.74.45].EMS.dbo.AUTO_DBA_JOB (email, cust_nm, title, content1, content2, content3, content4, content5)
                    SELECT  distinct opt.email, opt.operatorName
                        			,('JOB' + '['+ @@servername + ']: ' + lo.job_name + '이/가 KILL 됨') AS title
                        			,('JOB' + '['+ @@servername + ']: ' + lo.job_name + '이/가 KILL 됨') AS content1
                        			,opt.operatorName as content2
                        			,convert(nvarchar(10), lo.duration) + 'min' as content3
                        			,'백업단계' as content4
                        			,'백업이 오래 실행되어 자동 KILL을 합니다.' as content5
                    FROM  @job_list AS lo 
                    	JOIN dbo.OperatorSimple AS opt WITH (NOLOCK) ON 1 = 1
                    WHERE lo.seq_no = @intLoopCnt and opt.temCode = 1
                    
                    
   
                END  
                ELSE  
                BEGIN  
                    SET @msg = '[' + @@servername + '] LONG RUN JOB 모니터링 실패..!!'  
                    
                     insert into SMS.kidc_sms.dbo.smscli_tbl_02(destination, originator, callback, callbackURL, body,proc_status, teleservice_id )   
                     SELECT HPNO, '160701001001', '15665701', '', @MSG, '1' , '4098' 
                    FROM DBO.OPERATORSIMPLE WITH (NOLOCK) WHERE temcode = 1  --DBA만
                    
              
                  
                END  

                SET @intLoopCnt = @intLoopCnt + 1  
            END  
        END  
    END  
   
    ------------------  
    -- Begin Section 5  
    ------------------  
    IF @runing_cnt > 0  
    BEGIN  
        SET @sms_msg = '[' + @@servername + '] 제한시간 이상 실행중인 JOB이 ' + cast(@runing_cnt as varchar)+ '건 있습니다.'   
   
        SELECT HPNO, '160701001001', '15665701', '', @MSG, '1' , '4098' 
        FROM DBO.OPERATORSIMPLE WITH (NOLOCK) WHERE temcode = 1  --DBA만
    END  
  
    SET NOCOUNT OFF  