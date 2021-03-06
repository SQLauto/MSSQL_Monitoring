USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_batch_delete_query_plan]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*************************************************************************  
* 프로시저명  : dbo.up_mon_batch_delete_query_plan
* 작성정보    : 2010-06-01 한달 전 데이터 삭제
* 관련페이지  : 
* 내용        : 
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_batch_delete_query_plan] 
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @row_count int

/* BODY */

SET rowcount  1000

delete from DB_MON_QUERY_PLAN  where reg_date < dateadd(m ,-1 ,getdate())

set @row_count = @@ROWCOUNT

WHILE (@row_count = 1000)
begin
        delete from DB_MON_QUERY_PLAN  where reg_date < dateadd(m ,-1 ,getdate())
        
        if @@ROWCOUNT < 1000 break;
        
        WAITFOR DELAY '00:00:00.5'
     
end

SET rowcount  0

RETURN

GO
