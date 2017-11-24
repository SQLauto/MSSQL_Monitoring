use admin
go
/*************************************************************************  
* ���ν�����  : dbo.up_dba_report_iac_trans_master
* �ۼ�����    : 2012-02-20 by choi bo ra
* ����������  :  
* ����        : �̰� ��å reporting 
* ��������    : exec up_dba_report_iac_trans_master 
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_report_iac_trans_master
	@FROM_TABLE		sysname  = null

AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */


/* BODY */
SELECT  M.seq_no, M.from_server, M.from_db, M.from_table, M.to_server, M.TO_DB, M.to_table, 
	  M.LAST_TRANS_VALUE, CASE WHEN M.STATUS = 'S' THEN '����' WHEN M.STATUS = 'P' THEN  '�̰��Ϸ�'
						 WHEN M.STATUS = 'D' THEN '������' ELSE '�Ϸ�' END AS STATUS,
	  M.LOG_SEQNO,
	  CASE WHEN M.WORK_TYPE = 'D' THEN '����' ELSE '�̰�' END AS WORK_TYPE,
	  CASE WHEN M.UNIT = 'M' THEN '��' WHEN M.unit = 'Y' THEN '��'  ELSE '��' END AS UNIT,
	  M.period, M.trans_column, M.job_name, M.P_SEQ_NO
FROM IAC_TRANS_MASTER AS M WITH (NOLOCK)
WHERE from_table  LIKE CASE WHEN @FROM_TABLE IS NULL THEN M.from_table ELSE  '%' + @FROM_TABLE + '%' END
	AND M.P_SEQ_NO = M.SEQ_NO
ORDER BY M.SEQ_NO
go
/*************************************************************************  
* ���ν�����  : dbo.up_dba_report_iac_trans_master_sub
* �ۼ�����    : 2012-02-20 by choi bo ra
* ����������  :  
* ����        : �̰� ��å reporting 
* ��������    : exec up_dba_report_iac_trans_master_sub 
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_report_iac_trans_master_sub
	@seq_no		int 

AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */


/* BODY */
	
SELECT  M.seq_no, M.from_server, M.from_db, M.from_table, M.to_server, M.TO_DB, M.to_table, 
	  M.LAST_TRANS_VALUE, CASE WHEN M.STATUS = 'S' THEN '����' WHEN M.STATUS = 'P' THEN  '�̰��Ϸ�'
						 WHEN M.STATUS = 'D' THEN '������' ELSE '�Ϸ�' END AS STATUS,
	  M.LOG_SEQNO,
	  CASE WHEN M.WORK_TYPE = 'D' THEN '����' ELSE '�̰�' END AS WORK_TYPE,  M.P_SEQ_NO
FROM IAC_TRANS_MASTER AS M WITH (NOLOCK)
WHERE M.P_SEQ_NO = @seq_no  AND M.P_SEQ_NO != M.SEQ_NO
ORDER BY M.SEQ_NO
go



/*************************************************************************  
* ���ν�����  : dbo.up_dba_report_iac_trans_master_log
* �ۼ�����    : 2012-02-20 by choi bo ra
* ����������  :  
* ����        : �̰� ��å reporting 
* ��������    : exec up_dba_report_iac_trans_master_log 
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_report_iac_trans_master_log
	@seq_no			int ,
	@START_DATE		datetime = null

AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
IF @START_DATE IS NULL 
	SET @START_DATE = CONVERT(DATETIME, CONVERT(NVARCHAR(10), GETDATE()-1, 112))

/* BODY */
SELECT LOG.seqno, log.m_seqno, log.start_date, log.end_date, datediff(mi, log.start_date,log.end_date) as min,
	   log.step_name, log.trans_start, log.trans_end, log.total_count, log.trans_count, 
	   CASE WHEN log.STATUS = 'S' THEN '����' WHEN log.STATUS = 'P' THEN  '�̰��Ϸ�'
						 WHEN log.STATUS = 'D' THEN '������' ELSE '�Ϸ�' END AS STATUS
FROM IAC_TRANS_MASTER_LOG AS LOG WITH(NOLOCK)
	JOIN IAC_TRANS_MASTER AS M WITH (NOLOCK) ON M.SEQ_NO = LOG.M_SEQNO
WHERE P_SEQ_NO = 123
	AND LOG.start_date >= @START_DATE AND LOG.start_date < DATEADD(DD,1, @START_DATE)
order by m.seq_no, log.start_date
go