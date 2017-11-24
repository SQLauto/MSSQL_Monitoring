SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_ProcessKill' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_ProcessKill
GO

/**************************************************************************************************************    
SP    명 :  
작성정보: 2004-04-01 양은선  
내용     : STANDBYSQL에서 트랜잭션 로그 RESTORE 전에 사용자 프로세스 KILL  
===============================================================================  
    수정정보   
===============================================================================  
2005-11-21 박노철/kill 되는 프로세스들의 inputbuffer 를 남기는 루틴 맨 마지막 while 에 추가  
2005-11-23 박노철/kill 한 후에도 붙어있는 프로세스들 기록하도록 추가  
2006-08-17 양은선/LION, CUSTOMER, PAST DB  추가  
up_DBA_ProcessKill 'S'  
**************************************************************************************************************/   
CREATE  PROCEDURE   dbo.up_DBA_ProcessKill  
 @DB_FLAG  CHAR(1) = 'T' --'T':TIGER, 'S':SETTLE, 'E':EVENT, 'L':LION, 'C':CUSTOMER, 'P':PAST  
AS  
  
SET NOCOUNT ON   
SET ANSI_WARNINGS OFF  
  
DECLARE @TEMP TABLE (SEQNO INT IDENTITY, KILL_SQL NVARCHAR(50))  
DECLARE @KILL_SQL NVARCHAR(50)  
DECLARE @MAX_SEQNO INT, @SEQNO INT  
  
IF @DB_FLAG = 'T'  
BEGIN  
 INSERT INTO @TEMP(KILL_SQL)  
 SELECT 'KILL ' + CONVERT(VARCHAR(10), spid)   
 FROM   
 (  
  SELECT DISTINCT(spid) AS spid  
  FROM master.dbo.sysprocesses WITH (NOLOCK)   
  WHERE dbid = db_id('tiger') AND spid > 50  
 ) a  
END  
  
ELSE IF @DB_FLAG = 'S'  
BEGIN  
 INSERT INTO @TEMP(KILL_SQL)  
 SELECT 'KILL ' + CONVERT(VARCHAR(10), spid)   
 FROM   
 (  
  SELECT DISTINCT(spid) AS spid  
  FROM master.dbo.sysprocesses WITH (NOLOCK)   
  WHERE dbid = db_id('settle') AND spid > 50  
 ) a  
END  
  
ELSE IF @DB_FLAG = 'E'  
BEGIN  
 INSERT INTO @TEMP(KILL_SQL)  
 SELECT 'KILL ' + CONVERT(VARCHAR(10), spid)   
 FROM   
 (  
  SELECT DISTINCT(spid) AS spid  
  FROM master.dbo.sysprocesses WITH (NOLOCK)   
  WHERE dbid = db_id('event') AND spid > 50  
 ) a  
END  
  
ELSE IF @DB_FLAG = 'L'  
BEGIN  
 INSERT INTO @TEMP(KILL_SQL)  
 SELECT 'KILL ' + CONVERT(VARCHAR(10), spid)   
 FROM   
 (  
  SELECT DISTINCT(spid) AS spid  
  FROM master.dbo.sysprocesses WITH (NOLOCK)   
  WHERE dbid = db_id('lion') AND spid > 50  
 ) a  
END  
  
ELSE IF @DB_FLAG = 'C'  
BEGIN  
 INSERT INTO @TEMP(KILL_SQL)  
 SELECT 'KILL ' + CONVERT(VARCHAR(10), spid)   
 FROM   
 (  
  SELECT DISTINCT(spid) AS spid  
  FROM master.dbo.sysprocesses WITH (NOLOCK)   
  WHERE dbid = db_id('customer') AND spid > 50  
 ) a  
END  
  
ELSE IF @DB_FLAG = 'P'  
BEGIN  
 INSERT INTO @TEMP(KILL_SQL)  
 SELECT 'KILL ' + CONVERT(VARCHAR(10), spid)   
 FROM   
 (  
  SELECT DISTINCT(spid) AS spid  
  FROM master.dbo.sysprocesses WITH (NOLOCK)   
  WHERE dbid = db_id('past') AND spid > 50  
 ) a  
END  
  
SET @SEQNO = 0  
SELECT @MAX_SEQNO = ISNULL(MAX(SEQNO), 0) FROM @TEMP   
  
IF @MAX_SEQNO = 0 RETURN  
  
--2005/11/21 박노철  
CREATE TABLE #INPUT_BUFFER  
(   
 EVENTTYPE VARCHAR(20)  
, PARAMETERS VARCHAR(100)  
, EVENTINFO VARCHAR(256)  
)  
  
DECLARE @GET_INPUT_BUFFER_SQL VARCHAR(100)  
 ,  @SPID VARCHAR(5)  
  
INSERT INTO LOG_KILLED_PROCESS  
(EVENTTYPE, INPUTBUFFER, BEFORE_AFTER)  
VALUES  
('No Event', 'DB FLAG=' + @DB_FLAG + ', Process Kill 시작' , 'B')  
  
  
WHILE (1=1)  
BEGIN  
 SET @SEQNO = @SEQNO + 1  
 SELECT @KILL_SQL = KILL_SQL FROM @TEMP WHERE SEQNO = @SEQNO  
  
 --2005/11/21 박노철  
 --kill 하기 전에 inputbuffer 를 기록해 둠  
 SET @SPID = SUBSTRING(@KILL_SQL, CHARINDEX(' ', @KILL_SQL)+1, LEN(@KILL_SQL))  
 SET @GET_INPUT_BUFFER_SQL = 'DBCC INPUTBUFFER(' + @SPID + ')'  
  
 INSERT INTO #INPUT_BUFFER  
 EXEC(@GET_INPUT_BUFFER_SQL)  
  
  
 EXECUTE SP_EXECUTESQL  @KILL_SQL  
 IF @@ERROR <> 0 CONTINUE;  
 IF @SEQNO >= @MAX_SEQNO BREAK;  
END  
  
INSERT INTO LOG_KILLED_PROCESS  
(EVENTTYPE, INPUTBUFFER, BEFORE_AFTER)  
SELECT EVENTTYPE, EVENTINFO, 'B'  
FROM #INPUT_BUFFER  
  
INSERT INTO LOG_KILLED_PROCESS  
(EVENTTYPE, INPUTBUFFER, BEFORE_AFTER)  
VALUES  
('No Event', 'DB FLAG=' + @DB_FLAG + ', Process Kill 끝' , 'B')  
  
  
  
-------------------kill 한 후에도 붙어있는 프로세스들 기록----------------------------2005/11/23 박노철  
  
INSERT INTO LOG_KILLED_PROCESS  
(EVENTTYPE, INPUTBUFFER, BEFORE_AFTER)  
VALUES  
('No Event','DB FLAG=' + @DB_FLAG + ' , Kill 후 붙어있는 Process 기록 시작', 'B')  
  
DECLARE @TEMP2 TABLE (SEQNO INT IDENTITY, SPID VARCHAR(10))  
  
IF @DB_FLAG = 'T'  
BEGIN  
 INSERT INTO @TEMP2(SPID)  
 SELECT CONVERT(VARCHAR(10), spid)  
 FROM   
 (  
  SELECT DISTINCT(spid) AS spid  
  FROM master.dbo.sysprocesses WITH (NOLOCK)   
  WHERE dbid = db_id('tiger') AND spid > 50  
 ) a  
END  
  
ELSE IF @DB_FLAG = 'S'  
BEGIN  
 INSERT INTO @TEMP2(SPID)  
 SELECT CONVERT(VARCHAR(10), spid)   
 FROM   
 (  
  SELECT DISTINCT(spid) AS spid  
  FROM master.dbo.sysprocesses WITH (NOLOCK)   
  WHERE dbid = db_id('settle') AND spid > 50  
 ) a  
END  
  
ELSE IF @DB_FLAG = 'E'  
BEGIN  
 INSERT INTO @TEMP2(SPID)  
 SELECT CONVERT(VARCHAR(10), spid)   
 FROM   
 (  
  SELECT DISTINCT(spid) AS spid  
  FROM master.dbo.sysprocesses WITH (NOLOCK)   
  WHERE dbid = db_id('event') AND spid > 50  
 ) a  
END  
  
ELSE IF @DB_FLAG = 'L'  
BEGIN  
 INSERT INTO @TEMP(KILL_SQL)  
 SELECT 'KILL ' + CONVERT(VARCHAR(10), spid)   
 FROM   
 (  
  SELECT DISTINCT(spid) AS spid  
  FROM master.dbo.sysprocesses WITH (NOLOCK)   
  WHERE dbid = db_id('lion') AND spid > 50  
 ) a  
END  
  
ELSE IF @DB_FLAG = 'C'  
BEGIN  
 INSERT INTO @TEMP(KILL_SQL)  
 SELECT 'KILL ' + CONVERT(VARCHAR(10), spid)   
 FROM   
 (  
  SELECT DISTINCT(spid) AS spid  
  FROM master.dbo.sysprocesses WITH (NOLOCK)   
  WHERE dbid = db_id('customer') AND spid > 50  
 ) a  
END  
  
ELSE IF @DB_FLAG = 'P'  
BEGIN  
 INSERT INTO @TEMP(KILL_SQL)  
 SELECT 'KILL ' + CONVERT(VARCHAR(10), spid)   
 FROM   
 (  
  SELECT DISTINCT(spid) AS spid  
  FROM master.dbo.sysprocesses WITH (NOLOCK)   
  WHERE dbid = db_id('past') AND spid > 50  
 ) a  
END  
  
SET @SEQNO = 0  
SELECT @MAX_SEQNO = ISNULL(MAX(SEQNO), 0) FROM @TEMP2  
  
IF @MAX_SEQNO = 0 BEGIN  
 INSERT INTO LOG_KILLED_PROCESS   
 (EVENTTYPE, INPUTBUFFER, BEFORE_AFTER)  
 VALUES  
 ('No Event','DB FLAG=' + @DB_FLAG + ' , Kill 후 붙어있는 Process 없음', 'A')  
  
 DROP TABLE #INPUT_BUFFER  
  
 RETURN  
END  
  
TRUNCATE TABLE #INPUT_BUFFER  
  
WHILE (1=1)  
BEGIN  
 SET @SEQNO = @SEQNO + 1  
 SELECT @SPID = SPID FROM @TEMP2 WHERE SEQNO = @SEQNO  
 SET @GET_INPUT_BUFFER_SQL = 'DBCC INPUTBUFFER(' + @SPID + ')'  
  
 INSERT INTO #INPUT_BUFFER  
 EXEC(@GET_INPUT_BUFFER_SQL)  
  
 IF @@ERROR <> 0 CONTINUE;  
 IF @SEQNO >= @MAX_SEQNO BREAK;  
END  
  
INSERT INTO LOG_KILLED_PROCESS  
(EVENTTYPE, INPUTBUFFER, BEFORE_AFTER)  
SELECT EVENTTYPE, EVENTINFO, 'A'  
FROM #INPUT_BUFFER  
  
INSERT INTO LOG_KILLED_PROCESS  
(EVENTTYPE, INPUTBUFFER, BEFORE_AFTER)  
VALUES  
('No Event','DB FLAG=' + @DB_FLAG + ' , Kill 후 붙어있는 Process 기록 끝', 'B')  
  
  
DROP TABLE #INPUT_BUFFER

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO