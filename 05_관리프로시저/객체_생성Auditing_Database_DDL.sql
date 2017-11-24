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

		--테이블명이 RULE에 맞지 않는 경우 
		--TMP_자기팀이름_개인계정_YYYYMMDD
		IF RIGHT(@ObjectName,8) <> @YYYYMMDD --생성날짜
		BEGIN
			
			RAISERROR (N'TMP_자기팀이름_개인계정_YYYYMMDD 규칙에 맞지 않음 (_YYYYMMDD)- %s.', -- Message text.
             10, -- Severity,
             1, -- State,
             @ObjectName
			 ); 
			
			ROLLBACK;
			RETURN;
		END 
			
		IF LEFT(@ObjectName,4) <> 'TMP_'
		BEGIN 
			RAISERROR (N'TMP_자기팀이름_개인계정_YYYYMMDD 규칙에 맞지 않음  (TMP_)- %s.', -- Message text.
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