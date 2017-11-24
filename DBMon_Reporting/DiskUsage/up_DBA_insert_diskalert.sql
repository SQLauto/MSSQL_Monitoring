/*IF EXISTS (SELECT name 
              FROM   sysobjects 
              WHERE  name = N'up_dba_insert_diskalert' 
              AND              type = 'P')
    DROP PROCEDURE  up_dba_insert_diskalert
*/

/*************************************************************************  
* 프로시저명  : dbo.up_dba_insert_diskalert 
* 작성정보    : 2008-01-14 by 안지원
* 관련페이지  :  
* 내용        :
* 수정정보    : 2008-01-17 by choi bo ra
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_insert_diskalert
	AS
BEGIN
SET NOCOUNT ON

CREATE TABLE #t1 (
	seqno		TINYINT 	identity(1,1)	PRIMARY KEY
,	drv_letter 	CHAR(1)
,	drv_space_mb INT
)

INSERT INTO #t1 EXEC master.dbo.xp_fixeddrives

insert into freedisk_hist
( server_nm, drive, freemb, log_time )
select @@servername, drv_letter, drv_space_mb, getdate()
from #t1

DROP table #t1


END 

RETURN

