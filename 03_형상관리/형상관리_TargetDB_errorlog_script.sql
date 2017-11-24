use dba
go

/*************************************************************************  
* 프로시저명  : dbo.up_mon_collect_read_errorlog
* 작성정보    : 2010-04-16 by choi bo ra
* 관련페이지  : 
* 내용        : 장비의 에러로그 수집
* 수정정보    : exec dbo.up_mon_collect_read_errorlog 1 ,1
**************************************************************************/
CREATE PROCEDURE dbo.up_mon_collect_read_errorlog 
		@server_id				int,
		@instance_id			int
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET FMTONLY OFF
/* USER DECLARE */
DECLARE @from_dt			nvarchar(16)
DECLARE @to_dt				nvarchar(16)


SET @from_dt = convert(nvarchar(14), dateadd(hh, -1, getdate()), 121) + '00'
SET @to_dt = convert(nvarchar(14), getdate(), 121) + '00'


/* BODY */
CREATE TABLE #ERROR_LOG 
(
	 type  			char(1),
	 log_date		datetime,
	 process_info	nvarchar(100),
	 log_text		nvarchar(2000)
)

-- sql log 수집

INSERT INTO #ERROR_LOG  (log_date, process_info, log_text)
exec xp_readerrorlog 0, 1, null, null,@from_dt,@to_dt,'asc'

UPDATE #ERROR_LOG SET type = 'S' 

-- agent log 수집

INSERT INTO #ERROR_LOG  (log_date, process_info, log_text)
exec xp_readerrorlog 0, 2, null, null,@from_dt,@to_dt,'asc'

UPDATE #ERROR_LOG SET type = 'A'  where type != 'S'


SELECT @server_id as server_id, @instance_id as instance_id,type, log_date, process_info, left(log_text,1000) as log_text FROM #ERROR_LOG

RETURN
go

