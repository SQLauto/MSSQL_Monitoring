USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_memory_grant_ms_loop]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--매 1초 단위로 아래 스크립트가 수행되어야 하며 그 결과를 테이블이나 파일 형태로 수집해 주시면 됩니다. 
/*************************************************************************  
* 프로시저명  : dbo.up_mon_collect_memory_grant_loop
* 작성정보    : 2013-06-21 서은미
* 관련페이지  : 
* 내용        : memory grant query collect
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_collect_memory_grant_ms_loop] 
	@loop_cnt INT = 120
AS
/* COMMON DECLARE */
SET NOCOUNT ON
DECLARE @i INT = 1
/* USER DECLARE */

/* BODY */
while (@i<=@loop_cnt)
begin
    exec dbo.up_mon_collect_memory_grant_ms
	--print convert(varchar(10), @i) + ' : memory grant executed'
	set @i = @i+1
	waitfor delay '00:00:01'
end 

GO
