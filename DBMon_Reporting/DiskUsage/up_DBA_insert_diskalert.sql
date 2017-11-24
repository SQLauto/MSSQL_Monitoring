/*IF EXISTS (SELECT name 
              FROM   sysobjects 
              WHERE  name = N'up_dba_insert_diskalert' 
              AND              type = 'P')
    DROP PROCEDURE  up_dba_insert_diskalert
*/

/*************************************************************************  
* ���ν�����  : dbo.up_dba_insert_diskalert 
* �ۼ�����    : 2008-01-14 by ������
* ����������  :  
* ����        :
* ��������    : 2008-01-17 by choi bo ra
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

