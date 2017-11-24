CREATE TRIGGER [UP_DDL_AUDITING_TMP_TABLE]
ON DATABASE
AFTER CREATE_TABLE 
AS

BEGIN
	SET NOCOUNT ON;
	
	DECLARE @EventData XML = EVENTDATA();
	DECLARE @ORIGINAL_LOGIN NVARCHAR(255);
	DECLARE @ObjectName NVARCHAR(255);
	DECLARE @YYYYMMDD CHAR(8);

	SET @YYYYMMDD = CONVERT(VARCHAR(8), GETDATE(), 112);
	SET @ORIGINAL_LOGIN = EVENTDATA().value('(/EVENT_INSTANCE/LoginName)[1]','varchar(max)') 
	SET @ObjectName = EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]','varchar(max)') 


	IF ( @ORIGINAL_LOGIN = 'dba_ssis' OR @ORIGINAL_LOGIN = 'sa'
		OR @ORIGINAL_LOGIN  = 'AUCT_DOM\AUCTDBA00' )
		return 
	
	
	IF @ORIGINAL_LOGIN  like 'pd1_%' 
			or @ORIGINAL_LOGIN  like 'ad1_%' 
			or @ORIGINAL_LOGIN  like 'od1_%' 
			or @ORIGINAL_LOGIN  like 'dw_%' 
			or @ORIGINAL_LOGIN  like 'sl_%' 
			or @ORIGINAL_LOGIN  like 'is_%' 
			or @ORIGINAL_LOGIN  like 'da_%' 
			or @ORIGINAL_LOGIN  like 'dba_%'

	BEGIN 
		--select 'check start'

		--���̺���� RULE�� ���� �ʴ� ��� 
		--TMP_�ڱ����̸�_���ΰ���_YYYYMMDD
		IF RIGHT(@ObjectName,8) <> @YYYYMMDD --������¥
		BEGIN
			
			RAISERROR (N'TMP_�ڱ����̸�_���ΰ���_YYYYMMDD ��Ģ�� ���� ���� (_YYYYMMDD)- %s.', -- Message text.
             10, -- Severity,
             1, -- State,
             @ObjectName
			 ); 
			
			ROLLBACK;
			RETURN;
		END 
			
		IF LEFT(@ObjectName,4) <> 'TMP_'
		BEGIN 
			RAISERROR (N'TMP_�ڱ����̸�_���ΰ���_YYYYMMDD ��Ģ�� ���� ����  (TMP_)- %s.', -- Message text.
             10, -- Severity,
             1, -- State,
             @ObjectName
			 ); 

			ROLLBACK;
			RETURN;
		END 				
			

	END 
	
END
GO