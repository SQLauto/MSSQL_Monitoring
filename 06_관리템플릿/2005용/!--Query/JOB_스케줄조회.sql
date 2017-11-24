-- ==========================
--  JOB ������ ��Ȳ
-- ==========================

--============================
-- SQL 2000 ��
--============================
SELECT DISTINCT
       sysjobs.Originating_server As ServerName,  /* �÷� 1  ������ */         
       sysjobs.name AS Job ,                            /* �÷� 2  Job Name */

       Case sysjobs.Enabled                             /* �÷� 3  Job ��뿩�� */       
         When 1 THEN '��'      
              ELSE  '�ƴϿ�'       
       END AS [��뿩��],       

     /*----------------------------------
       Case sysjobschedules.Enabled       
         When 1 THEN '��'      
              ELSE  '�ƴϿ�'       
       END AS [���࿩��],   
     ----------------------------------*/    
     
      /*-------------------------------------------------------------------------------------------------------*/
      /* Start  �� Jobs ������ ������ ���ڵ��Ѵ�*/
      /* �÷� 4  Job ���� */
      /*-------------------------------------------------------------------------------------------------------*/       
        ----sysjobschedules.freq_type , freq_relative_interval , freq_interval ���� ����              
       CASE sysjobschedules.freq_type   
        WHEN  1 THEN '�ѹ���'    --�ѹ��� �����Ҷ�     
        WHEN 4 THEN  '����'       --���� �����Ҷ� ,      
              WHEN 8 THEN  --�� �����ϸ��� ����ɶ�,   freq_Interval ���� �����Ѵ� (����Ǵ� ���� ����)
                             CASE freq_Interval         
                                   --�⺻ ������       
                WHEN  1 THEN '���� �Ͽ���'   
           WHEN  2 THEN '���� ������'   
           WHEN  4 THEN '���� ȭ����'   
           WHEN  8 THEN '���� ������'   
           WHEN 16 THEN '���� �����'   
           WHEN 32 THEN '���� �ݿ���'   
           WHEN 64 THEN '���� �����'   
                                   --���� ������       
                                   WHEN 62 THEN '���� ��,ȭ,��,��,��'
                             Else       
                                   '���� ��Ÿ ' +  CAST( freq_Interval AS VARCHAR(3)) +  ' ��'       
   END   
        
              WHEN 16 THEN  '�ſ� ' +  CAST( freq_Interval AS VARCHAR(3)) +  ' ��'    --�ſ� ����ɶ�, ����Ǵ� Ư���� (1~31 ��) ǥ��    
          WHEN 32 THEN    --�ſ� ����������� ����ɶ� 
                                                              --1) freq_relative_interva( 1,2,3,4 �� ����) 
                                                              --2) freq_Interval (�� ���� ���ϰ���  �����Ѵ�)
                        -- sysjobschedules.freq_relative_interval AS freq_relative_interval,     
          CASE freq_relative_interval   --�ſ� ���     
                    WHEN  1 THEN  -- '�ſ� ù°'    
       CASE freq_Interval   --ù°�� �� ���� 
             WHEN  1 THEN '�ſ� ù° �Ͽ���'
             WHEN  2 THEN '�ſ� ù° ������'
             WHEN  3 THEN '�ſ� ù° ȭ����'
             WHEN  4 THEN '�ſ� ù° ������'
             WHEN  5 THEN '�ſ� ù° �����'
             WHEN  6 THEN '�ſ� ù° �ݿ���'
             WHEN  7 THEN '�ſ� ù° �����'
             WHEN  8 THEN '�ſ� ù° ��'
             WHEN  9 THEN '�ſ� ù° ����'
             WHEN  10 THEN '�ſ� ù° �ָ�'
                                Else     
                                       '�ſ� ù° ��Ÿ ' +  CAST( freq_Interval AS VARCHAR(3)) +  ' ��'    
                         END  
                   WHEN  2 THEN  -- '�ſ� ��°'     
      CASE freq_Interval   ----��°�� �� ����
             WHEN  1 THEN '�ſ� ��° �Ͽ���'
             WHEN  2 THEN '�ſ� ��° ������'
             WHEN  3 THEN '�ſ� ��° ȭ����'
             WHEN  4 THEN '�ſ� ��° ������'
             WHEN  5 THEN '�ſ� ��° �����'
             WHEN  6 THEN '�ſ� ��° �ݿ���'
             WHEN  7 THEN '�ſ� ��° �����'
             WHEN  8 THEN '�ſ� ��° ��'
             WHEN  9 THEN '�ſ� ��° ����'
             WHEN  10 THEN '�ſ� ��° �ָ�'
                                Else     
                                       '�ſ� ��° ��Ÿ ' +  CAST( freq_Interval AS VARCHAR(3)) +  ' ��'    
      END  
                  WHEN  4 THEN   --'�ſ� ��°'     
      CASE freq_Interval   ----��°�� �� ����
             WHEN  1 THEN '�ſ� ��° �Ͽ���'
             WHEN  2 THEN '�ſ� ��° ������'
             WHEN  3 THEN '�ſ� ��° ȭ����'
             WHEN  4 THEN '�ſ� ��° ������'
             WHEN  5 THEN '�ſ� ��° �����'
             WHEN  6 THEN '�ſ� ��° �ݿ���'
             WHEN  7 THEN '�ſ� ��° �����'
             WHEN  8 THEN '�ſ� ��° ��'
             WHEN  9 THEN '�ſ� ��° ����'
             WHEN  10 THEN '�ſ� ��° �ָ�'
                                Else     
                                       '�ſ� ��° ��Ÿ ' +  CAST( freq_Interval AS VARCHAR(3)) +  ' ��'    
      END  
                       WHEN  8 THEN   --'�ſ� ��°'   
       CASE freq_Interval   ----��°�� �� ����
             WHEN  1 THEN '�ſ� ��° �Ͽ���'
             WHEN  2 THEN '�ſ� ��° ������'
             WHEN  3 THEN '�ſ� ��° ȭ����'
             WHEN  4 THEN '�ſ� ��° ������'
             WHEN  5 THEN '�ſ� ��° �����'
             WHEN  6 THEN '�ſ� ��° �ݿ���'
             WHEN  7 THEN '�ſ� ��° �����'
             WHEN  8 THEN '�ſ� ��° ��'
             WHEN  9 THEN '�ſ� ��° ����'
             WHEN  10 THEN '�ſ� ��° �ָ�'
                                 Else     
                                       '�ſ� ��° ��Ÿ ' +  CAST( freq_Interval AS VARCHAR(3)) +  ' ��'    
        END  
                                  WHEN  16 THEN  -- '�ſ� ������'       
       CASE freq_Interval   
             WHEN  1 THEN '�ſ� ������ �Ͽ���'
             WHEN  2 THEN '�ſ� ������ ������'
             WHEN  3 THEN '�ſ� ������ ȭ����'
             WHEN  4 THEN '�ſ� ������ ������'
             WHEN  5 THEN '�ſ� ������ �����'
             WHEN  6 THEN '�ſ� ������ �ݿ���'
             WHEN  7 THEN '�ſ� ������ �����'
             WHEN  8 THEN '�ſ� ������ ��'
             WHEN  9 THEN '�ſ� ������ ����'
             WHEN  10 THEN '�ſ� ������ �ָ�'
                                Else     
                                       '�ſ� ������ ��Ÿ ' +  CAST( freq_Interval AS VARCHAR(3)) +  ' ��'    
      END  
      END       
        WHEN 64 THEN 'SQL Agent �� ���۵ɶ� ����'     
  END AS [��������],  --sysjobs.freq_type , freq_relative_interval , freq_interval ���� ����      

              /*----------------------------------------------------------------------*/
              /* �÷� 5  Jobs �ֱ� */ 
              /* sysjobschedules.freq_subday_interval  AS freq_subday_interval  */
              /*----------------------------------------------------------------------*/
 CASE freq_subday_interval        
  WHEN  0 THEN '������ �ð��� ��Ǯ��'      
   Else          
  CASE freq_subday_type   
    WHEN 1  THEN CAST ( freq_subday_interval AS VARCHAR(3)) + ' ������ �ð��� ��Ǯ��'  
    WHEN 2  THEN CAST ( freq_subday_interval AS VARCHAR(3)) + ' �� ���� ��Ǯ��'  
    WHEN 4  THEN CAST ( freq_subday_interval AS VARCHAR(3)) + ' �� ���� ��Ǯ��'  
    WHEN 8  THEN CAST ( freq_subday_interval AS VARCHAR(3)) + ' �ð����� ��Ǯ��'  
               END       
   END AS [��Ǯ���ֱ�],  --freq_subday_interval                         

       /*----------------------------------------------------------------------*/
       /* �÷�  6  Jobs  ���۽ð� */ 
       /*  sysjobschedules.active_start_time   AS [���۽ð�],  */
       /*  ���� �ð��� ǥ�� �������� ��ȯ�ϱ�( hh:mm:ss )                     */
       /*----------------------------------------------------------------------*/
      CASE LEN(sysjobschedules.active_start_time)  
          WHEN 6 THEN  --���̰� 6�϶� --��,��,�� �� ��ȯ
                                         SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 1, 2) + ':' +  
               SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 3, 2) + ':' +   
               SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 5, 2)  
          WHEN 5 THEN  --���̰� 5�϶� --��,��,�� �� ��ȯ 
                                         '0' + SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 1, 1) + ':' +  
               SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 2, 2) + ':' +   
               SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 4, 2)  
          WHEN 4 THEN   --���̰� 4�϶� --��,��,�� �� ��ȯ
                                         '00:' +   
               SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 1, 2) + ':' +   
               SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 3, 2)  
          WHEN 3 THEN   --���̰� 3�϶� --��,��,�� �� ��ȯ
                                         '00:' +   
               '0' + SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 1, 1) + ':' +   
               SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 2, 2)  
          WHEN 2 THEN   --���̰� 2�϶� --��,��,�� �� ��ȯ
                                         '00:' +   
               '00:' +   
               SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 1, 2)  
          WHEN 1 THEN   --���̰� 1�϶� --��,��,�� �� ��ȯ
                                         '00:' +   
               '00:' +   
               '0' + SUBSTRING(CAST(sysjobschedules.active_start_time AS VARCHAR(6)), 1, 1)  
          WHEN 0 THEN   --���̰� 0�϶� --��,��,�� �� ��ȯ
                                         '00:' +   
               '00:' +   
               '00'  
      END   AS  [Job ���۽ð�],  
    
       /*----------------------------------------------------------------------*/
       /* �÷�  7  Jobs  �Ϸ�ð� */ 
       /* sysjobschedules.active_end_time    AS [�Ϸ�ð�] */
       /*  ���� �ð��� ǥ�� �������� ��ȯ�ϱ�( hh:mm:ss )                     */
       /*----------------------------------------------------------------------*/  
      CASE LEN(sysjobschedules.active_end_time)  
          WHEN 6 THEN  --���̰� 6�϶� --��,��,�� �� ��ȯ
                                         SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 1, 2) + ':' +  
               SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 3, 2) + ':' +   
               SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 5, 2)  
          WHEN 5 THEN  --���̰� 5�϶� --��,��,�� �� ��ȯ 
                                         '0' + SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 1, 1) + ':' +  
               SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 2, 2) + ':' +   
               SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 4, 2)  
          WHEN 4 THEN   --���̰� 4�϶� --��,��,�� �� ��ȯ
                                         '00:' +   
               SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 1, 2) + ':' +   
               SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 3, 2)  
          WHEN 3 THEN   --���̰� 3�϶� --��,��,�� �� ��ȯ
                                         '00:' +   
               '0' + SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 1, 1) + ':' +   
               SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 2, 2)  
          WHEN 2 THEN   --���̰� 2�϶� --��,��,�� �� ��ȯ
                                         '00:' +   
               '00:' +   
               SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 1, 2)  
          WHEN 1 THEN   --���̰� 1�϶� --��,��,�� �� ��ȯ
                                         '00:' +   
               '00:' +   
               '0' + SUBSTRING(CAST(sysjobschedules.active_end_time AS VARCHAR(6)), 1, 1)  
          WHEN 0 THEN   --���̰� 0�϶� --��,��,�� �� ��ȯ
                                         '00:' +   
               '00:' +   
               '00'  
      END   AS [Job �Ϸ�ð�],
      /*-------------------------------------------------------------------------------------------------*/
      /*End  �� Jobs ������ ������ ���ڵ��Ѵ� */
      /*--------------------------------------------------------------------------------------------------*/ 

 

/*-------------------------------------------------------------------------------------------------------*/
/* �÷�  8 �ֱ� Jobs ����ð� */
--sysjobServers.Last_Run_Date ,
--sysjobServers.Last_Run_Time �� ���ļ� ����Ѵ�. 
/*-------------------------------------------------------------------------------------------------------*/ 
--������ ���� ��¥�� ǥ�� �������� �����Ѵ� (yyyy-mm-dd)
 CASE WHEN LEN(CAST(sysjobServers.Last_Run_Date AS VARCHAR(8))) = 8 THEN  
       SUBSTRING(CAST(sysjobServers.Last_Run_Date AS VARCHAR(8)) , 1, 4) + '-' +  
       SUBSTRING(CAST(sysjobServers.Last_Run_Date AS VARCHAR(8)) , 5, 2) + '-' +  
       SUBSTRING(CAST(sysjobServers.Last_Run_Date AS VARCHAR(8)) , 7, 2) + ' '         
                    ELSE ''  
 END      +  
 CASE WHEN LEN(CAST(sysjobServers.Last_Run_Date AS VARCHAR(8))) = 8 THEN  
       CASE LEN(sysjobServers.Last_Run_Time)   --������ ����ð��� ǥ���������� �����Ѵ� (hh:mm:ss)
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
 END AS  [�ֱ� Jobs ����ð�],

/*-------------------------------------------------------------------------------------------------------*/
/* �÷� 9 �ֱ� Job �ҿ�ð�  */
/* �ֱ� Jobs �������� �˼� ������ �ҿ�ð��� ������� �ʴ´�. */
/*-------------------------------------------------------------------------------------------------------*/ 
CASE   WHEN  sysjobServers.Last_Run_Date <> 0 THEN '(' +  CAST( sysjobServers.Last_Run_Duration  AS VARCHAR(10)) + ')'
            ELSE '' 
END [�ֱ� Job �ҿ�ð�]  ,

/*-------------------------------------------------------------------------------------------------------*/
/* Job ��������*/
/*-------------------------------------------------------------------------------------------------------*/ 
--sysjobServers.Last_Run_OutCome ,
CASE sysjobServers.Last_Run_OutCome
       WHEN 0 THEN '����'  
       WHEN 1 THEN '����'  
       WHEN 3 THEN '��ҵ�'  
       WHEN 5 THEN '�˼�����'  
       ELSE CAST( sysjobServers.Last_Run_OutCome  AS VARCHAR(10))  
END   AS  [��������]
       
FROM     (( sysjobs  Left  JOIN  sysjobschedules ON sysjobs.job_id = sysjobschedules.job_id)
               Left Join sysjobServers On sysjobs.job_id =sysjobservers.job_id)
WHERE  sysjobs.Enabled = 1


-- ==============================
-- Job �ð� Ȯ��
-- ==============================
select
--	J.job_id
	J.job_name
,	CASE S.freq_type WHEN 1 THEN '�ѹ���'
			WHEN 4 THEN '����'
			WHEN 8 THEN '����'
			WHEN 16 THEN '�ſ�'
			WHEN 32 THEN '�ſ� �����'
			WHEN 64 THEN 'SQL Server Agent�� ���۵ɶ� ����' 
	END as freq_type 
--,	S.active_start_date as '������'
--,	S.active_end_date as '������'
,	right('00000' + cast(S.active_start_time as varchar), 6) as '���۽ð�'
,	right('00000' + cast(S.active_end_time as varchar), 6) as '���ð�'
--,	CASE S.freq_type WHEN 1 THEN 
,	S.freq_interval
,	S.freq_subday_interval
from dba.dbo.jobs J JOIN msdb.dbo.sysjobschedules S WITH (NOLOCK) ON J.job_id = S.job_id
where J.enabled = 1
and S.active_start_date < convert(char(8), getdate(), 112)
and S.active_end_date > convert(char(8), getdate(), 112)
and S.freq_subday_interval = 10
order by right('00000' + cast(S.active_start_time as varchar), 6) asc