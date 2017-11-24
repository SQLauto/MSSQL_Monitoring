SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/**************************************************************************************************************  
SP    명 : master.dbo.sp_opentranBlocker
작성정보: 2005-04-18 양은선
관련페이지 :
내용	    : open_tran = 1인데 select인 쿼리가 blocking을 유발하는지 모니터링
===============================================================================
				수정정보 
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
