SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* 프로시저명  : dbo.up_dba_select_minmax_emsseqno 
* 작성정보    : 2008-06-13 by choi bo ra
* 관련페이지  :  
* 내용        : ems 발송해야할 min , max seq_no 값
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_minmax_emsseqno
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @minSeqno INT, @maxSeqNo INT, @loopCount INT

/* BODY */

SELECT @minSeqNo= ISNULL(MIN(SeqNo),0), @maxSeqNo= ISNULL(MAX(SeqNo),0)
FROM dbo.EMSSendMaster
WHERE sendFlag = 1 -- 발송 전
IF @@ERROR <> 0  RETURN

IF ((@maxSeqNo - @minSeqNo) + 1 ) > 100  SET @loopCount = ((@maxSeqNo - @minSeqNo) + 1 ) % 100        --100건씩 처리
	ELSE SET @loopCount = 1

SELECT @minSeqNo as minSeqNo, @maxSeqNo as maxSeqNo, @loopCount as loopCount


RETURN	
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO