SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/**************************************************************************************************************  
SP    �� : master.dbo.sp_opentranBlocker
�ۼ�����: 2005-04-18 ������
���������� :
����	    : open_tran = 1�ε� select�� ������ blocking�� �����ϴ��� ����͸�
===============================================================================
				�������� 
===============================================================================

**************************************************************************************************************/ 
create procedure dbo.sp_opentranBlocker
AS 

SET NOCOUNT ON

SELECT open_tran, 'KILL ' + CONVERT(VARCHAR(5), spid) AS killStr, 'DBCC INPUTBUFFER(' + CONVERT(VARCHAR(5), spid) + ')' AS bufStr
, spid, blocked, waittype, lastwaittype, hostname, cmd
FROM master..sysprocesses
WHERE open_tran = 1 AND status = 'sleeping' AND cmd = 'awaiting command' AND hostname LIKE 'GOODSDAQ%' AND loginame = 'goodsdaq'



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
