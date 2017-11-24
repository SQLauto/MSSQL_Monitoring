-- ===========================
--  대량데이터 삭제
-- ===========================
---------------------------------------------------------------------
--300건씩 삭제
---------------------------------------------------------------------
/*
-- 좋은 방법이긴 한데 한번 더 실행된다.
SET ROWCOUNT 300
DECLARE  @RowSave 	INT

DELETE dbo.em_tran_backup_test 

SET @RowSave = @@ROWCOUNT

WHILE @RowSave = 300
BEGIN
	DELETE dbo.em_tran_backup_test
	SET @RowSave = @@ROWCOUNT  
	
	WAITFOR DELAY '00:00:00.100'
END
SET ROWCOUNT 0
*/
DECLARE @count    INT
DECLARE @rowSet   INT
SET @count = 0
SET @rowSet = 10        -- 지우려고 하는 row 개수
SELECT @count = COUNT(*) FROM dbo.JobHistory

SET ROWCOUNT @rowSet
WHILE (1 = 1)
BEGIN
    DELETE dbo.JobHistory
    IF @@ERROR <> 0 GOTO ErrorHandle

    SET @count = @count - @rowSet
    IF @count  <= 0 BREAK

    WAITFOR DELAY '00:00:00.100'
END
SET ROWCOUNT 0