SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
IF EXISTS (SELECT name 
	   FROM   sysobjects
	   WHERE  name = N'up_DBA_RestoreLog' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_RestoreLog
GO

/*************************************************************************  
* ���ν�����  : dbo.up_DBA_RestoreLog 
* �ۼ�����    : 2004-08-20 ������
* ����������  :  
* ����        :
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_RestoreLog
	@DB_FLAG  CHAR(1) = 'T' --'T':TIGER, 'S':SETTLE, 'E':EVENT
AS

SET NOCOUNT ON 

DECLARE 	@SEQNO 		INT
		, 	@MAX_SEQNO	INT
		, 	@FILE_NAME		VARCHAR(200)
		, 	@FULL_PATH		VARCHAR(500)


IF @DB_FLAG = 'T'
BEGIN
	
	SELECT @SEQNO = MIN(SEQNO), @MAX_SEQNO = MAX(SEQNO) 
	FROM DBO.LOGSHIPPING_LIST  WITH (NOLOCK)
	WHERE RESTORE_Y IS NULL AND COPY_Y = 'Y'


	IF @SEQNO > 0 AND @MAX_SEQNO > 0 
	BEGIN
		WHILE (1=1)
		BEGIN
			--50�� ���Ŀ� ������ �Ϸ��� �ϸ� ���ϰ� �Ѵ�.
			--IF (DATEPART(HH,GETDATE()) > 2 AND DATEPART(HH,GETDATE()) < 22) BEGIN
			--IF DATEPART(HH,GETDATE()) > 2 BEGIN

-- 				--2006.08.04 �ּ�ó����
-- 
 				IF DATEPART(MI,GETDATE()) >= 55 BREAK;
 				IF (DATEPART(HH,GETDATE())%2) = 1 BREAK;


				--�� �κ��� �ּ�ó�����ֽð�, ���κ��� �ּ��� Ǯ���ֽʽÿ�
-- 				IF GETDATE() > '2006-08-05'
-- 				BEGIN
-- 					IF DATEPART(MI,GETDATE()) >= 55 BREAK;
--  					IF (DATEPART(HH,GETDATE())%2) = 1 BREAK;
-- 				END

			--END

			SELECT @FILE_NAME = LOG_FILE FROM DBO.LOGSHIPPING_LIST WITH (NOLOCK) WHERE SEQNO = @SEQNO
		
			IF LEN(@FILE_NAME) > 0 
			BEGIN
				SET @FULL_PATH = 'F:\subdb3backup2\tiger\' + @FILE_NAME
			
				UPDATE  DBO.LOGSHIPPING_LIST SET START_TIME=GETDATE() WHERE SEQNO = @SEQNO
			
				EXEC dbo.up_DBA_ProcessKill
			
				--RESTORE
				RESTORE LOG TIGER
				FROM DISK = @FULL_PATH
				WITH STANDBY='E:\subdb3backup\undo\tiger_undo.ldf'
				
				IF @@ERROR <> 0 
				BEGIN
					UPDATE DBO.LOGSHIPPING_LIST 
					SET ERR = @@ERROR
					WHERE SEQNO = @SEQNO
					BREAK;
				END
	
				--UPDATE LOGSHIPPING_LIST
				UPDATE DBO.LOGSHIPPING_LIST 
				SET RESTORE_Y = 'Y' 
				, 	END_TIME = GETDATE()
				, 	DURATION=DATEDIFF(SS,START_TIME, GETDATE())
				WHERE SEQNO = @SEQNO
			END
		
			SET @SEQNO = @SEQNO + 1
			IF @SEQNO > @MAX_SEQNO BREAK;
		END
	END
END

ELSE IF @DB_FLAG = 'S'
BEGIN
	
	SELECT @SEQNO = MIN(SEQNO), @MAX_SEQNO = MAX(SEQNO) 
	FROM DBO.LOGSHIPPING_LIST_SETTLE WITH (NOLOCK)
	WHERE RESTORE_Y IS NULL AND COPY_Y = 'Y'
	
	IF @SEQNO > 0 AND @MAX_SEQNO > 0 
	BEGIN
		WHILE (1=1)
		BEGIN
			SELECT @FILE_NAME = LOG_FILE FROM DBO.LOGSHIPPING_LIST_SETTLE WITH (NOLOCK) WHERE SEQNO = @SEQNO
		
			IF LEN(@FILE_NAME) > 0 
			BEGIN
				SET @FULL_PATH = 'F:\subdb3backup2\settle\' + @FILE_NAME
			
				UPDATE  DBO.LOGSHIPPING_LIST_SETTLE SET START_TIME=GETDATE() WHERE SEQNO = @SEQNO
			
				EXEC dbo.up_DBA_ProcessKill 'S'
			
				--RESTORE
				RESTORE LOG SETTLE
				FROM DISK = @FULL_PATH
				WITH STANDBY='E:\subdb3backup\undo\settle_undo.ldf'

				IF @@ERROR <> 0 
				BEGIN
					UPDATE DBO.LOGSHIPPING_LIST_SETTLE 
					SET ERR = @@ERROR
					WHERE SEQNO = @SEQNO
					BREAK;
				END
	
				--UPDATE LOGSHIPPING_LIST
				UPDATE DBO.LOGSHIPPING_LIST_SETTLE 
				SET RESTORE_Y = 'Y' 
				, 	END_TIME = GETDATE()
				, 	DURATION=DATEDIFF(SS,START_TIME, GETDATE())
				WHERE SEQNO = @SEQNO
			END
		
			SET @SEQNO = @SEQNO + 1
			IF @SEQNO > @MAX_SEQNO BREAK;
		END
	END
END


ELSE IF @DB_FLAG = 'E'
BEGIN
	
	SELECT @SEQNO = MIN(SEQNO), @MAX_SEQNO = MAX(SEQNO) 
	FROM DBO.LOGSHIPPING_LIST_EVENT WITH (NOLOCK)
	WHERE RESTORE_Y IS NULL AND COPY_Y = 'Y'
	
	IF @SEQNO > 0 AND @MAX_SEQNO > 0 
	BEGIN
		WHILE (1=1)
		BEGIN
			SELECT @FILE_NAME = LOG_FILE FROM DBO.LOGSHIPPING_LIST_EVENT WITH (NOLOCK) WHERE SEQNO = @SEQNO
		
			IF LEN(@FILE_NAME) > 0 
			BEGIN
				SET @FULL_PATH = 'F:\subdb3backup2\event\' + @FILE_NAME
			
				UPDATE  DBO.LOGSHIPPING_LIST_EVENT SET START_TIME=GETDATE() WHERE SEQNO = @SEQNO
			
				EXEC dbo.up_DBA_ProcessKill 'E'
			
				--RESTORE
				RESTORE LOG EVENT
				FROM DISK = @FULL_PATH
				WITH STANDBY='E:\subdb3backup\undo\event_undo.ldf'

				IF @@ERROR <> 0 
				BEGIN
					UPDATE DBO.LOGSHIPPING_LIST_EVENT 
					SET ERR = @@ERROR
					WHERE SEQNO = @SEQNO
					BREAK;
				END
	
				--UPDATE LOGSHIPPING_LIST
				UPDATE DBO.LOGSHIPPING_LIST_EVENT 
				SET RESTORE_Y = 'Y' 
				, 	END_TIME = GETDATE()
				, 	DURATION=DATEDIFF(SS,START_TIME, GETDATE())
				WHERE SEQNO = @SEQNO
			END
		
			SET @SEQNO = @SEQNO + 1
			IF @SEQNO > @MAX_SEQNO BREAK;
		END
	END
END

RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO