use master
go

/**************************************************************************************************************  
SP    명 : dbo.up_DBA_OnOffLine_DB_ALL
작성정보 : 2008-06-23 김태환
내용	 : 현재 사용중인 USER DB에 대한 ON/OFFLINE처리
사용법   : ONLINE  ==> EXEC dbo.up_DBA_OnOffLine_DB_ALL @mode = 'ON'
		   OFFLINE ==> EXEC dbo.up_DBA_OnOffLine_DB_ALL @mode = 'OFF'
===============================================================================
				수정정보 
2008-10-02 db 추가 ccmng , basket , eagledb , chglog
2009-01-28 최보라 alter database로 변경
===============================================================================

**************************************************************************************************************/ 
CREATE  PROCEDURE   dbo.up_DBA_OnOffLine_DB_ALL
	@mode			varchar(10)
AS

	SET NOCOUNT ON 
	SET ANSI_WARNINGS OFF

	DECLARE @TEMP TABLE (SEQNO INT IDENTITY, offline_sql nvarchar(300))
	DECLARE @OFFLINE_SQL NVARCHAR(300)
	DECLARE @MAX_SEQNO INT, @SEQNO INT


	--OFFLINE 모드 설정
	IF @mode = 'ON'
	BEGIN
		SET @mode = 'ONLINE'
	END
	ELSE
	BEGIN
--		EXEC dbo.up_DBA_ProcessKill_ALL

		SET @mode = 'OFFLINE'
     END
     
     INSERT INTO @TEMP(offline_sql)
	 SELECT	'ALTER DATABASE ' + name + ' SET ' + @mode + ' WITH ROLLBACK IMMEDIATE'
	 FROM sys.databases WITH (NOLOCK) 
	 WHERE name in ('TIGER', 'LION', 'SETTLE', 'EVENT', 'CUSTOMER' , 'CCMNG','EAGLEDB' , 'CHGLOG','BASKET')
	
	
	
	SET @SEQNO = 0
	SELECT @MAX_SEQNO = ISNULL(MAX(SEQNO), 0) FROM @TEMP 

	IF @MAX_SEQNO = 0 RETURN

	WHILE (1=1)
	BEGIN
		SET @SEQNO = @SEQNO + 1

		SELECT @OFFLINE_SQL = offline_sql FROM @TEMP WHERE SEQNO = @SEQNO
		BEGIN TRY
			EXECUTE SP_EXECUTESQL @OFFLINE_SQL
		END TRY
		BEGIN CATCH
			--NO ACTIOIN 
		END CATCH

		IF @@ERROR <> 0 CONTINUE;
		IF @SEQNO >= @MAX_SEQNO BREAK;
	END

	SET NOCOUNT OFF






