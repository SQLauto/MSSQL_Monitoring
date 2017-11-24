/*IF EXISTS (SELECT name 
              FROM   sysobjects 
              WHERE  name = N'up_DBA_syscache_stats_list' 
              AND              type = 'P')
    DROP PROCEDURE  procedure_name
*/

/*************************************************************************  
* ���ν�����  : dbo.up_DBA_syscache_stats_list
* �ۼ�����    : 2007-11-07
* �ۼ��ڸ� 	  : ������
* ����������  : dbmon  
* ����        : MAIN/TIGER/dbo.SYSCACHE_EXEC_STATS ������ �������� 
* �󼼳���    : �˻�����1-1) ��¥
				�˻�����1-2) DB�� 
				��������2-1) ȣ��Ǽ� - usecounts
				��������2-2) IO�ð� - total_physical_reads + total_logical_reads + total_logical_writes  
* exec dbo.up_DBA_syscache_stats_list 'TIGER', 2, '2007-11-14'
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_syscache_stats_list
    @strWhere			varchar(100),		-- �˻� Ű���� (DB��)  
    @strOrder			int			,		-- ����
	@toDay				char(10)			-- ��¥ 
AS
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
/* COMMON DECLARE */
	DECLARE @stDate			datetime
	DECLARE @edDate			datetime
	
/* USER DECLARE */
	DECLARE @strSql			nvarchar(2000)
	DECLARE @retCd 			int
	DECLARE @sOrder			varchar(300)
	DECLARE @sWhere 		varchar(300)	

	SET @sOrder = ''
	SET @sWhere = ''
	SET @stDate = CONVERT(char(10), @toDay  , 121) + ' 00:00:00.000'
	SET @edDate = CONVERT(char(10), @toDay  , 121) + ' 23:59:59.999'	
	SET @retCd = 0 	

/* BODY */
/*SET @strSql = N'SELECT reg_dt, objid, objname, usecounts, execution_count, plan_generation_num ,total_elapsed_time , avg_elapsed_time,total_worker_time,avg_worker_time, total_logical_reads ,avg_physical_reads,cacheobjtype ,objtype,seq_no ,total_physical
_r
eads
			FROM dbo.SYSCACHE_EXEC_STATS WITH(NOLOCK) 
			WHERE reg_dt >= ''' + CONVERT(char(10), @stDate, 121) + ''' AND reg_dt < '''+ CONVERT(char(10),@edDate, 121) + ''''

*/
--�˻������� �ִ� ��� 
IF @strWhere <> ''
BEGIN 
	IF @strOrder = 2
		BEGIN
			SELECT 
				reg_dt
			,	objid
			,	objname
			,	usecounts
			,	execution_count
			,	plan_generation_num 
			,	total_elapsed_time 
			,	avg_elapsed_time
			,	total_worker_time
			,	avg_worker_time
			,	total_logical_reads 
			,	avg_physical_reads
			,	cacheobjtype
			,	objtype
			,	seq_no 
			,	total_physical_reads
			, (total_physical_reads + total_logical_reads + total_logical_writes) as total
			FROM dbo.SYSCACHE_EXEC_STATS WITH(NOLOCK) 
			WHERE reg_dt >= @stDate  AND reg_dt < @edDate
			AND dbname = @strWhere
			ORDER BY total_elapsed_time DESC			
			print '1'
		END 
	ELSE IF @strOrder = 3
		BEGIN
			SELECT 
				reg_dt
			,	objid
			,	objname
			,	usecounts
			,	execution_count
			,	plan_generation_num 
			,	total_elapsed_time 
			,	avg_elapsed_time
			,	total_worker_time
			,	avg_worker_time
			,	total_logical_reads 
			,	avg_physical_reads
			,	cacheobjtype
			,	objtype
			,	seq_no 
			,	total_physical_reads
			, (total_physical_reads + total_logical_reads + total_logical_writes) as total
			FROM dbo.SYSCACHE_EXEC_STATS WITH(NOLOCK) 
			WHERE reg_dt >= @stDate  AND reg_dt < @edDate
			AND dbname = @strWhere
			ORDER BY (total_physical_reads + total_logical_reads + total_logical_writes) DESC			
			print '2'
		END 

	ELSE
		BEGIN
			SELECT 
				reg_dt
			,	objid
			,	objname
			,	usecounts
			,	execution_count
			,	plan_generation_num 
			,	total_elapsed_time 
			,	avg_elapsed_time
			,	total_worker_time
			,	avg_worker_time
			,	total_logical_reads 
			,	avg_physical_reads
			,	cacheobjtype
			,	objtype
			,	seq_no 
			,	total_physical_reads
			, (total_physical_reads + total_logical_reads + total_logical_writes) as total
			FROM dbo.SYSCACHE_EXEC_STATS WITH(NOLOCK) 
			WHERE reg_dt >= @stDate  AND reg_dt < @edDate
			AND dbname = @strWhere
			ORDER BY usecounts DESC			
			print '3'
		END 
END 

--�˻������� ���� ��� 
ELSE
BEGIN
	IF @strOrder = 2
		BEGIN
			SELECT 
				reg_dt
			,	objid
			,	objname
			,	usecounts
			,	execution_count
			,	plan_generation_num 
			,	total_elapsed_time 
			,	avg_elapsed_time
			,	total_worker_time
			,	avg_worker_time
			,	total_logical_reads 
			,	avg_physical_reads
			,	cacheobjtype
			,	objtype
			,	seq_no 
			,	total_physical_reads
			, (total_physical_reads + total_logical_reads + total_logical_writes) as total
			FROM dbo.SYSCACHE_EXEC_STATS WITH(NOLOCK) 
			WHERE reg_dt >= @stDate  AND reg_dt < @edDate			
			ORDER BY total_elapsed_time DESC
			print '4'
		END 
	ELSE IF @strOrder = 3
		BEGIN
			SELECT 
				reg_dt
			,	objid
			,	objname
			,	usecounts
			,	execution_count
			,	plan_generation_num 
			,	total_elapsed_time 
			,	avg_elapsed_time
			,	total_worker_time
			,	avg_worker_time
			,	total_logical_reads 
			,	avg_physical_reads
			,	cacheobjtype
			,	objtype
			,	seq_no 
			,	total_physical_reads
			, (total_physical_reads + total_logical_reads + total_logical_writes) as total
			FROM dbo.SYSCACHE_EXEC_STATS WITH(NOLOCK) 
			WHERE reg_dt >= @stDate  AND reg_dt < @edDate			
			ORDER BY (total_physical_reads + total_logical_reads + total_logical_writes) DESC
			print '5'
		END 
	ELSE
		BEGIN
			SELECT 
				reg_dt
			,	objid
			,	objname
			,	usecounts
			,	execution_count
			,	plan_generation_num 
			,	total_elapsed_time 
			,	avg_elapsed_time
			,	total_worker_time
			,	avg_worker_time
			,	total_logical_reads 
			,	avg_physical_reads
			,	cacheobjtype
			,	objtype
			,	seq_no 
			,	total_physical_reads
			, (total_physical_reads + total_logical_reads + total_logical_writes) as total
			FROM dbo.SYSCACHE_EXEC_STATS WITH(NOLOCK) 
			WHERE reg_dt >= @stDate  AND reg_dt < @edDate			
			ORDER BY usecounts DESC
			print '6'
		END 

END

SET @retCd = @@ERROR
IF @retCd  <> 0 RETURN 

SET NOCOUNT OFF

