/*************************************************************************  
* 프로시저명: dbo.up_dba_select_noused_target_index_log
* 작성정보	: 2015-03-02 by choi bo ra
* 관련페이지:  
* 내용		:  noused_target_index 테이블 작업 전 매일 갱신

* 수정정보	: EXEC up_dba_select_noused_target_index_log 'G', 'E'
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_noused_target_index_log
	@site_gn  char(1) = 'G', 
	@process_type  char(1) -- 'S' 시작 , 'E' 완료
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/

SELECT REG_DATE FROM NOUSED_TARGET_INDEX_LOG with(nolock) WHERE SITE_GN = @SITE_GN AND PROCESS_TYPE =@PROCESS_TYPE

go



/*************************************************************************  
* 프로시저명: dbo.up_dba_select_noused_target_index
* 작성정보	: 2015-03-02 by choi bo ra
* 관련페이지:  
* 내용		:  NOUSED_TARGET_INDEX 대상 SELECT

* 수정정보	: EXEC up_dba_select_noused_target_index 'G', '2015-03-11'
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_noused_target_index
	 @SITE_GN  CHAR(1) = 'G',
	 @REG_DATE		DATE, 
	 @DEL_PROC_TARGET CHAR(1) = 'Y'
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
SELECT I.*
FROM NOUSED_TARGET_INDEX AS I WITH(NOLOCK) 
	JOIN SERVERINFO AS S WITH(NOLOCK)  ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
WHERE I.REG_DATE = @REG_DATE
	AND I.DEL_PROC_TARGET = @DEL_PROC_TARGET
	AND S.site_gn = @SITE_GN
ORDER BY I.SERVER_ID, I.DATABASE_NAME, I.OBJECT_NAME, I.INDEX_NAME


go


/*************************************************************************  
* 프로시저명: dbo.up_dba_select_noused_target_index_his
* 작성정보	: 2015-03-02 by choi bo ra
* 관련페이지:  
* 내용		:  NOUSED_TARGET_INDEX 대상 SELECT

* 수정정보	: EXEC up_dba_select_noused_target_index_his 'G'
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_noused_target_index_his
	 @SITE_GN  CHAR(1) = 'G'
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
SELECT  i.REG_DATE, i.SERVER_ID, i.DATABASE_NAME, COUNT(*) AS count,
		sum(CASE WHEN I.DEL_PROC_TARGET = 'Y' THEN size ELSE 0  end ) /1024  AS EXPECTANCY_SIZE_MB, 
		sum(CASE WHEN I.DEL_YN = 'Y' THEN size ELSE 0 END  ) /1024 AS EXECUTION_SIZE_MB
FROM NOUSED_TARGET_INDEX AS I WITH(NOLOCK) 
	JOIN SERVERINFO AS S WITH(NOLOCK)  ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
WHERE I.DEL_PROC_TARGET = 'Y'
	AND S.site_gn = @SITE_GN
GROUP BY i.REG_DATE, i.SERVER_ID, i.DATABASE_NAME
ORDER BY I.REG_DATE

go

/*************************************************************************  
* 프로시저명: dbo.up_dba_select_noused_target_index_his
* 작성정보	: 2015-03-02 by choi bo ra
* 관련페이지:  
* 내용		:  NOUSED_TARGET_INDEX 대상 SELECT

* 수정정보	: EXEC up_dba_noused_target_index_his 'G', 'Y', 0
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_noused_target_index_his
	 @SITE_GN  CHAR(1) = 'G', 
	 @DEL_PROC_TARGET CHAR(1) = 'Y', 
	 @SERVER_id int 
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
SELECT  i.REG_DATE, S.server_name,
		COUNT(CASE WHEN I.DEL_PROC_TARGET = 'Y' THEN 1 ELSE 0  end )  AS EXPECTANCY_COUNT, 
		COUNT(CASE WHEN I.DEL_YN = 'Y' THEN 1 ELSE 0 END  )  AS EXECUTION_COUNT,
		sum(CASE WHEN I.DEL_PROC_TARGET = 'Y' THEN size ELSE 0  end ) /1024  AS EXPECTANCY_SIZE_MB, 
		sum(CASE WHEN I.DEL_YN = 'Y' THEN size ELSE 0 END  ) /1024 AS EXECUTION_SIZE_MB
FROM NOUSED_TARGET_INDEX AS I WITH(NOLOCK) 
	JOIN SERVERINFO AS S WITH(NOLOCK)  ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
WHERE @DEL_PROC_TARGET = 'Y' AND S.site_gn = @SITE_GN
	and i.server_id = case when @server_id = 0 then i.server_id else @server_id end
GROUP BY i.REG_DATE, S.server_name
ORDER BY I.REG_DATE

go


/*************************************************************************  
* 프로시저명: dbo.up_dba_select_noused_target_procedure
* 작성정보	: 2015-03-02 by choi bo ra
* 관련페이지:  
* 내용		:  미사용 객체가 참조하는 sp

* 수정정보	: EXEC up_dba_select_noused_target_procedure 
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_select_noused_target_procedure
	 @ref_type char(1) = 'I', 
	 @seq_no	 bigint  
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
select REF_TYPE, SEQNO, REG_DATE, SCRIPT_NO, SERVER_ID, DATABASE_NAME, OBJECT_ID, OBJECT_NAME, CALL_ACML_DAY, UNUSED_DAY, SYNC_CALL_ACML_DAY, UPD_DATE
from noused_target_procedure with(nolock) 
where ref_type = @ref_type 
	and SEQNO= @seq_no

go





/*************************************************************************  
* 프로시저명: dbo.up_dba_select_noused_target_index_his
* 작성정보	: 2015-03-02 by choi bo ra
* 관련페이지:  
* 내용		:  NOUSED_TARGET_INDEX 대상 SELECT

* 수정정보	: EXEC up_dba_select_noused_target_index_his 'G'
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_noused_target_index_log
	 @SITE_GN  CHAR(1) = 'G',
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
SELECT  i.REG_DATE, i.SERVER_ID, i.DATABASE_NAME, COUNT(*) AS count,
		sum(CASE WHEN I.DEL_PROC_TARGET = 'Y' THEN size ELSE 0  end ) /1024  AS EXPECTANCY_SIZE_MB, 
		sum(CASE WHEN I.DEL_YN = 'Y' THEN size ELSE 0 END  ) /1024 AS EXECUTION_SIZE_MB
FROM NOUSED_TARGET_INDEX AS I WITH(NOLOCK) 
	JOIN SERVERINFO AS S WITH(NOLOCK)  ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
WHERE I.REG_DATE = @REG_DATE
	AND I.DEL_PROC_TARGET = @DEL_PROC_TARGET
	AND S.site_gn = @SITE_GN
GROUP BY i.REG_DATE, i.SERVER_ID, i.DATABASE_NAME
ORDER BY I.REG_DATE

go



/*************************************************************************  
* 프로시저명: dbo.up_dba_disable_index
* 작성정보	: 2015-04-02 by choi bo ra
* 관련페이지:  
* 내용		:  NOUSED_TARGET_INDEX 대상 SELECT

* 수정정보	: EXEC up_dba_disable_index 'G', '2015-03-11'
			EXEC up_dba_disable_index 'G', '2015-03-11', 161
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_disable_index
	 @SITE_GN  CHAR(1) = 'G',
	 @reg_date	date , 
	 @server_id int =0
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/

select   'use ' + database_name + ';  exec sp_rename ''' + object_name + '.' + index_name + ''', ''unused_' +  index_name + '''; alter index unused_' + index_name +  ' on ' + object_name  + ' disable' as script, 
	 *
from NOUSED_TARGET_INDEX as I  with(nolock)
	join serverinfo as s with(nolock)  on i.server_id = s.server_id and s.use_yn = 'Y'

where s.site_gn = @site_gn
 and i.reg_date = @reg_date
 and i.del_proc_target = 'Y'
 and s.server_id = case when @server_id = 0 then s.server_id else @server_id end


