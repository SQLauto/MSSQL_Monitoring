-- ===========================
--  �뷮������ ����
-- ===========================
---------------------------------------------------------------------
--300�Ǿ� ����
---------------------------------------------------------------------
/*
-- ���� ����̱� �ѵ� �ѹ� �� ����ȴ�.
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
SET @rowSet = 10        -- ������� �ϴ� row ����
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