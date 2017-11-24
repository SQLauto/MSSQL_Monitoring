SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
IF EXISTS (SELECT name 
	   FROM   sysobjects
	   WHERE  name = N'up_DBA_Diskalert' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_Diskalert
GO

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_Diskalert 
* 작성정보    : 2007-
* 관련페이지  :  
* 내용        :
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_Diskalert
	@RESULT	VARCHAR(1023) OUTPUT
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


/* generate the message */

--IF (SELECT count(*) from #t1 WITH (NOLOCK)) > 0 and len(@rcpt) > 0 --check there is some data and a recipient
IF (SELECT COUNT(*) FROM #t1 WITH (NOLOCK)) > 0  --CHECK THERE IS SOME DATA AND A RECIPIENT
BEGIN
	DECLARE @msg 	VARCHAR(400)
	,	@dletter 		VARCHAR(5)
	,	@dspace 	INT	
	, 	@seqno		TINYINT
	,	@max_seqno TINYINT

	SET @msg = LEFT('≪ DISK FREE [' + @@servername + '] ≫'+SPACE(30), 30) + '<br>' + CHAR(13) + CHAR(10)

	SELECT @seqno = MIN(seqno), @max_seqno = MAX(seqno) from #t1 WITH (NOLOCK)

	while(1=1)
	begin 
		SELECT @dletter = drv_letter, @dspace = drv_space_mb  from #t1 WITH (NOLOCK) WHERE seqno = @seqno
		SET @msg =  @msg + @dletter + ': ' + CONVERT(VARCHAR, @dspace / 1024) --put the vars INTo a msg
				+ 'GB '+'<br>'

		IF @seqno >= @max_seqno BREAK;
		SET @seqno = @seqno + 1
	END
END

SET @RESULT = @msg
RETURN

END
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO