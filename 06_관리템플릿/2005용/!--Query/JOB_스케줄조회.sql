-- ==========================
--  JOB 스케줄 현황
-- ==========================

--============================
-- SQL 2000 용
--============================
SELECT DISTINCT
       sysjobs.Originating_server As ServerName,  /* 컬럼 1  서버명 */         
       sysjobs.name AS Job ,                            /* 컬럼 2  Job Name */

       Case sysjobs.Enabled                             /* 컬럼 3  Job 사용여부 */       
         When 1 THEN '예'      
              ELSE  '아니오'       
       END AS [사용여부],       

     /*----------------------------------
       Case sysjobschedules.Enabled       
         When 1 THEN '예'      
              ELSE  '아니오'       
       END AS [예약여부],   
     ----------------------------------*/    
     
      /*-------------------------------------------------------------------------------------------------------*/
      /* Start  각 Jobs 스케줄 일정을 디코딩한다*/
      /* 컬럼 4  Job 일정 */
      /*-------------------------------------------------------------------------------------------------------*/       
        ----sysjobschedules.freq_type , freq_relative_interval , freq_interval 값의 조합              
       CASE sysjobschedules.freq_type   
        WHEN  1 THEN '한번만'    --한번만 수행할때     
        WHEN 4 THEN  '매일'       --매일 수행할때 ,      
              WHEN 8 THEN  --매 일주일마다 수행될때,   freq_Interval 값을 참조한다 (실행되는 요일 선택)
                             CASE freq_Interval         
                                   --기본 설정일       
                WHEN  1 THEN '매주 일요일'   
           WHEN  2 THEN '매주 월요일'   
           WHEN  4 THEN '매주 화요일'   
           WHEN  8 THEN '매주 수요일'   
           WHEN 16 THEN '매주 목요일'   
           WHEN 32 THEN '매주 금요일'   
           WHEN 64 THEN '매주 토요일'   
                                   --복합 설정일       
                                   WHEN 62 THEN '매주 월,화,수,목,금'
                             Else       
                                   '매주 기타 ' +  CAST( freq_Interval AS VARCHAR(3)) +  ' 일'       
   END   
        
              WHEN 16 THEN  '매월 ' +  CAST( freq_Interval AS VARCHAR(3)) +  ' 일'    --매월 수행될때, 실행되는 특정일 (1~31 일) 표시    
          WHEN 32 THEN    --매월 상대적인으로 수행될때 
                                                              --1) freq_relative_interva( 1,2,3,4 주 선택) 
                                                              --2) freq_Interval (각 주의 요일값을  참조한다)
                        -- sysjobschedules.freq_relative_interval AS freq_relative_interval,     
          CASE freq_relative_interval   --매월 상대     
                    WHEN  1 THEN  -- '매월 첫째'    
       CASE freq_Interval   --첫째의 각 요일 
             WHEN  1 THEN '매월 첫째 일요일'
             WHEN  2 THEN '매월 첫째 월요일'
             WHEN  3 THEN '매월 첫째 화요일'
             WHEN  4 THEN '매월 첫째 수요일'
             WHEN  5 THEN '매월 첫째 목요일'
             WHEN  6 THEN '매월 첫째 금요일'
             WHEN  7 THEN '매월 첫째 토요일'
             WHEN  8 THEN '매월 첫째 일'
             WHEN  9 THEN '매월 첫째 평일'
             WHEN  10 THEN '매월 첫째 주말'
                                Else     
                                       '매월 첫째 기타 ' +  CAST( freq_Interval AS VARCHAR(3)) +  ' 일'    
                         END  
                   WHEN  2 THEN  -- '매월 둘째'     
      CASE freq_Interval   ----둘째의 각 요일
             WHEN  1 THEN '매월 둘째 일요일'
             WHEN  2 THEN '매월 둘째 월요일'
             WHEN  3 THEN '매월 둘째 화요일'
             WHEN  4 THEN '매월 둘째 수요일'
             WHEN  5 THEN '매월 둘째 목요일'
             WHEN  6 THEN '매월 둘째 금요일'
             WHEN  7 THEN '매월 둘째 토요일'
             WHEN  8 THEN '매월 둘째 일'
             WHEN  9 THEN '매월 둘째 평일'
             WHEN  10 THEN '매월 둘째 주말'
                                Else     
                                       '매월 둘째 기타 ' +  CAST( freq_Interval AS VARCHAR(3)) +  ' 일'    
      END  
                  WHEN  4 THEN   --'매월 셋째'     
      CASE freq_Interval   ----세째의 각 요일
             WHEN  1 THEN '매월 셋째 일요일'
             WHEN  2 THEN '매월 셋째 월요일'
             WHEN  3 THEN '매월 셋째 화요일'
             WHEN  4 THEN '매월 셋째 수요일'
             WHEN  5 THEN '매월 셋째 목요일'
             WHEN  6 THEN '매월 셋째 금요일'
             WHEN  7 THEN '매월 셋째 토요일'
             WHEN  8 THEN '매월 셋째 일'
             WHEN  9 THEN '매월 셋째 평일'
             WHEN  10 THEN '매월 셋째 주말'
                                Else     
                                       '매월 셋째 기타 ' +  CAST( freq_Interval AS VARCHAR(3)) +  ' 일'    
      END  
                       WHEN  8 THEN   --'매월 넷째'   
       CASE freq_Interval   ----넷째의 각 요일
             WHEN  1 THEN '매월 넷째 일요일'
             WHEN  2 THEN '매월 넷째 월요일'
             WHEN  3 THEN '매월 넷째 화요일'
             WHEN  4 THEN '매월 넷째 수요일'
             WHEN  5 THEN '매월 넷째 목요일'
             WHEN  6 THEN '매월 넷째 금요일'
             WHEN  7 THEN '매월 넷째 토요일'
             WHEN  8 THEN '매월 넷째 일'
             WHEN  9 THEN '매월 넷째 평일'
             WHEN  10 THEN '매월 넷째 주말'
                                 Else     
                                       '매월 넷째 기타 ' +  CAST( freq_Interval AS VARCHAR(3)) +  ' 일'    
        END  
                                  WHEN  16 THEN  -- '매월 마지막'       
       CASE freq_Interval   
             WHEN  1 THEN '매월 마지막 일요일'
             WHEN  2 THEN '매월 마지막 월요일'
             WHEN  3 THEN '매월 마지막 화요일'
             WHEN  4 THEN '매월 마지막 수요일'
             WHEN  5 THEN '매월 마지막 목요일'
             WHEN  6 THEN '매월 마지막 금요일'
             WHEN  7 THEN '매월 마지막 토요일'
             WHEN  8 THEN '매월 마지막 일'
             WHEN  9 THEN '매월 마지막 평일'
             WHEN  10 THEN '매월 마지막 주말'
                                Else     
                                       '매월 마지막 기타 ' +  CAST( freq_Interval AS VARCHAR(3)) +  ' 일'    
      END  
      END       
        WHEN 64 THEN 'SQL Agent 가 시작될때 실행'     
  END AS [실행일정],  --sysjobs.freq_type , freq_relative_interval , freq_interval 값의 조합      

              /*----------------------------------------------------------------------*/
              /* 컬럼 5  Jobs 주기 */ 
              /* sysjobschedules.freq_subday_interval  AS freq_subday_interval  */
              /*----------------------------------------------------------------------*/
 CASE freq_subday_interval        
  WHEN  0 THEN '지정된 시각에 되풀이'      
   Else          
  CASE freq_subday_type   
    WHEN 1  THEN CAST ( freq_subday_interval AS VARCHAR(3)) + ' 지정된 시각에 되풀이'  
    WHEN 2  THEN CAST ( freq_subday_interval AS VARCHAR(3)) + ' 초 마다 되풀이'  
    WHEN 4  THEN CAST ( freq_subday_interval AS VARCHAR(3)) + ' 분 마다 되풀이'  
    WHEN 8  THEN CAST ( freq_subday_interval AS VARCHAR(3)) + ' 시간마다 되풀이'  
               END       
   END AS [되풀이주기],  --freq_subday_interval                         

       /*----------------------------------------------------------------------*/
       /* 컬럼  6  Jobs  시작시간 */ 
       /*  sysjobschedules.active_start_time   AS [시작시간],  */
       /*  시작 시간을 표준 포맷으로 변환하기( hh:mm:ss )                     */
       /*----------------------------------------------------------------------*/
      CASE LEN(sysjobschedules.active_start_time)  
          WHEN 6 THEN  --길이가 6일때 --시,분,초 로 변환
                                         SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 1, 2) + ':' +  
               SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 3, 2) + ':' +   
               SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 5, 2)  
          WHEN 5 THEN  --길이가 5일때 --시,분,초 로 변환 
                                         '0' + SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 1, 1) + ':' +  
               SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 2, 2) + ':' +   
               SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 4, 2)  
          WHEN 4 THEN   --길이가 4일때 --시,분,초 로 변환
                                         '00:' +   
               SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 1, 2) + ':' +   
               SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 3, 2)  
          WHEN 3 THEN   --길이가 3일때 --시,분,초 로 변환
                                         '00:' +   
               '0' + SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 1, 1) + ':' +   
               SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 2, 2)  
          WHEN 2 THEN   --길이가 2일때 --시,분,초 로 변환
                                         '00:' +   
               '00:' +   
               SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 1, 2)  
          WHEN 1 THEN   --길이가 1일때 --시,분,초 로 변환
                                         '00:' +   
               '00:' +   
               '0' + SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 1, 1)  
          WHEN 0 THEN   --길이가 0일때 --시,분,초 로 변환
                                         '00:' +   
               '00:' +   
               '00'  
      END   AS  [Job 시작시간],  
    
       /*----------------------------------------------------------------------*/
       /* 컬럼  7  Jobs  완료시간 */ 
       /* sysjobschedules.active_end_time    AS [완료시간] */
       /*  시작 시간을 표준 포맷으로 변환하기( hh:mm:ss )                     */
       /*----------------------------------------------------------------------*/  
      CASE LEN(sysjobschedules.active_end_time)  
          WHEN 6 THEN  --길이가 6일때 --시,분,초 로 변환
                                         SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 1, 2) + ':' +  
               SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 3, 2) + ':' +   
               SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 5, 2)  
          WHEN 5 THEN  --길이가 5일때 --시,분,초 로 변환 
                                         '0' + SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 1, 1) + ':' +  
               SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 2, 2) + ':' +   
               SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 4, 2)  
          WHEN 4 THEN   --길이가 4일때 --시,분,초 로 변환
                                         '00:' +   
               SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 1, 2) + ':' +   
               SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 3, 2)  
          WHEN 3 THEN   --길이가 3일때 --시,분,초 로 변환
                                         '00:' +   
               '0' + SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 1, 1) + ':' +   
               SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 2, 2)  
          WHEN 2 THEN   --길이가 2일때 --시,분,초 로 변환
                                         '00:' +   
               '00:' +   
               SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 1, 2)  
          WHEN 1 THEN   --길이가 1일때 --시,분,초 로 변환
                                         '00:' +   
               '00:' +   
               '0' + SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 1, 1)  
          WHEN 0 THEN   --길이가 0일때 --시,분,초 로 변환
                                         '00:' +   
               '00:' +   
               '00'  
      END   AS [Job 완료시간],
      /*-------------------------------------------------------------------------------------------------*/
      /*End  각 Jobs 스케줄 일정을 디코딩한다 */
      /*--------------------------------------------------------------------------------------------------*/ 

 

/*-------------------------------------------------------------------------------------------------------*/
/* 컬럼  8 최근 Jobs 종료시간 */
--sysjobServers.Last_Run_Date ,
--sysjobServers.Last_Run_Time 을 합쳐서 계산한다. 
/*-------------------------------------------------------------------------------------------------------*/ 
--마지막 실행 날짜를 표준 포맷으로 변경한다 (yyyy-mm-dd)
 CASE WHEN LEN(CAST(sysjobServers.Last_Run_Date AS VARCHAR(8))) = 8 THEN  
       SUBSTRING(CAST(sysjobServers.Last_Run_Date AS VARCHAR(8)) , 1, 4) + '-' +  
       SUBSTRING(CAST(sysjobServers.Last_Run_Date AS VARCHAR(8)) , 5, 2) + '-' +  
       SUBSTRING(CAST(sysjobServers.Last_Run_Date AS VARCHAR(8)) , 7, 2) + ' '         
                    ELSE ''  
 END      +  
 CASE WHEN LEN(CAST(sysjobServers.Last_Run_Date AS VARCHAR(8))) = 8 THEN  
       CASE LEN(sysjobServers.Last_Run_Time)   --마지막 실행시간을 표준포맷으로 변경한다 (hh:mm:ss)
         WHEN 6 THEN 
   SUBSTRING(CAST(sysjobServers.Last_Run_Time AS VARCHAR(6)), 1, 2) + ':' +  
                SUBSTRING(CAST(sysjobServers.Last_Run_Time AS VARCHAR(6)), 3, 2) + ':' +   
                SUBSTRING(CAST(sysjobServers.Last_Run_Time AS VARCHAR(6)), 5, 2)  
         WHEN 5 THEN 
   '0' + SUBSTRING(CAST(sysjobServers.Last_Run_Time AS VARCHAR(6)), 1, 1) + ':' +  
                SUBSTRING(CAST(sysjobServers.Last_Run_Time AS VARCHAR(6)), 2, 2) + ':' +   
                SUBSTRING(CAST(sysjobServers.Last_Run_Time AS VARCHAR(6)), 4, 2)  
         WHEN 4 THEN 
   '00:' +   
                SUBSTRING(CAST(sysjobServers.Last_Run_Time AS VARCHAR(6)), 1, 2) + ':' +   
                SUBSTRING(CAST(sysjobServers.Last_Run_Time AS VARCHAR(6)), 3, 2)  
         WHEN 3 THEN 
   '00:' +   
                '0' + SUBSTRING(CAST(sysjobServers.Last_Run_Time AS VARCHAR(6)), 1, 1) + ':' +   
                SUBSTRING(CAST(sysjobServers.Last_Run_Time AS VARCHAR(6)), 2, 2)  
         WHEN 2 THEN 
   '00:' +   
                '00:' +   
                SUBSTRING(CAST(sysjobServers.Last_Run_Time AS VARCHAR(6)), 1, 2)  
         WHEN 1 THEN 
   '00:' +   
                '00:' +   
                '0' + SUBSTRING(CAST(sysjobServers.Last_Run_Time AS VARCHAR(6)), 1, 1)  
         WHEN 0 THEN 
   '00:' +   
                '00:' +   
                '00'  
       END  
             ELSE ''  
 END AS  [최근 Jobs 종료시간],

/*-------------------------------------------------------------------------------------------------------*/
/* 컬럼 9 최근 Job 소요시간  */
/* 최근 Jobs 실행일을 알수 없으면 소요시간을 출력하지 않는다. */
/*-------------------------------------------------------------------------------------------------------*/ 
CASE   WHEN  sysjobServers.Last_Run_Date <> 0 THEN '(' +  CAST( sysjobServers.Last_Run_Duration  AS VARCHAR(10)) + ')'
            ELSE '' 
END [최근 Job 소요시간]  ,

/*-------------------------------------------------------------------------------------------------------*/
/* Job 성공여부*/
/*-------------------------------------------------------------------------------------------------------*/ 
--sysjobServers.Last_Run_OutCome ,
CASE sysjobServers.Last_Run_OutCome
       WHEN 0 THEN '실패'  
       WHEN 1 THEN '성공'  
       WHEN 3 THEN '취소됨'  
       WHEN 5 THEN '알수없음'  
       ELSE CAST( sysjobServers.Last_Run_OutCome  AS VARCHAR(10))  
END   AS  [성공여부]
       
FROM     (( sysjobs  Left  JOIN  sysjobschedules ON sysjobs.job_id = sysjobschedules.job_id)
               Left Join sysjobServers On sysjobs.job_id =sysjobservers.job_id)
WHERE  sysjobs.Enabled = 1


-- ==============================
-- Job 시간 확인
-- ==============================
select
--	J.job_id
	J.job_name
,	CASE S.freq_type WHEN 1 THEN '한번만'
			WHEN 4 THEN '매일'
			WHEN 8 THEN '매주'
			WHEN 16 THEN '매월'
			WHEN 32 THEN '매월 상대적'
			WHEN 64 THEN 'SQL Server Agent가 시작될때 실행' 
	END as freq_type 
--,	S.active_start_date as '시작일'
--,	S.active_end_date as '종료일'
,	right('00000' + cast(S.active_start_time as varchar), 6) as '시작시간'
,	right('00000' + cast(S.active_end_time as varchar), 6) as '끝시간'
--,	CASE S.freq_type WHEN 1 THEN 
,	S.freq_interval
,	S.freq_subday_interval
from dba.dbo.jobs J JOIN msdb.dbo.sysjobschedules S WITH (NOLOCK) ON J.job_id = S.job_id
where J.enabled = 1
and S.active_start_date < convert(char(8), getdate(), 112)
and S.active_end_date > convert(char(8), getdate(), 112)
and S.freq_subday_interval = 10
order by right('00000' + cast(S.active_start_time as varchar), 6) asc