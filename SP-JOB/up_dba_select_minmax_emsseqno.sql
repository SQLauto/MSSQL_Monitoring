SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* ���ν�����  : dbo.up_dba_select_minmax_emsseqno 
* �ۼ�����    : 2008-06-13 by choi bo ra
* ����������  :  
* ����        : ems �߼��ؾ��� min , max seq_no ��
* ��������    :
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
WHERE sendFlag = 1 -- �߼� ��
IF @@ERROR <> 0  RETURN

IF ((@maxSeqNo - @minSeqNo) + 1 ) > 100  SET @loopCount = ((@maxSeqNo - @minSeqNo) + 1 ) % 100        --100�Ǿ� ó��
	ELSE SET @loopCount = 1

SELECT @minSeqNo as minSeqNo, @maxSeqNo as maxSeqNo, @loopCount as loopCount


RETURN	
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO