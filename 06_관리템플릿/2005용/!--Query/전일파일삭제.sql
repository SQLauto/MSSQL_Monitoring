-- ============================
-- �α� ���� ������ ����
-- ============================

DECLARE @fileName NVARCHAR(50)
DECLARE @preDate DATETIME
SET @preDate = DATEADD(dd, -1, GETDATE())
SET @fileName = 'DEL S:\BACKUPDB\ACCOUNTS\ACCOUNTS_TLOG_*' + convert(nvarchar(8),@preDate,112) + '*.TRN'

EXEC  xp_cmdshell @fileName