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
SP    �� :  
�ۼ�����: 2004-04-01 ������  
����     : STANDBYSQL���� Ʈ����� �α� RESTORE ���� ����� ���μ��� KILL  
===============================================================================  
    ��������   
===============================================================================  
2005-11-21 �ڳ�ö/kill �Ǵ� ���μ������� inputbuffer �� ����� ��ƾ �� ������ while �� �߰�  
2005-11-23 �ڳ�ö/kill �� �Ŀ��� �پ��ִ� ���μ����� ����ϵ��� �߰�  
2006-08-17 ������/LION, CUSTOMER, PAST DB  �߰�  
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
  
--2005/11/21 �ڳ�ö  
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
('No Event', 'DB FLAG=' + @DB_FLAG + ', Process Kill ����' , 'B')  
  
  
WHILE (1=1)  
BEGIN  
 SET @SEQNO = @SEQNO + 1  
 SELECT @KILL_SQL = KILL_SQL FROM @TEMP WHERE SEQNO = @SEQNO  
  
 --2005/11/21 �ڳ�ö  
 --kill �ϱ� ���� inputbuffer �� ����� ��  
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
('No Event', 'DB FLAG=' + @DB_FLAG + ', Process Kill ��' , 'B')  
  
  
  
-------------------kill �� �Ŀ��� �پ��ִ� ���μ����� ���----------------------------2005/11/23 �ڳ�ö  
  
INSERT INTO LOG_KILLED_PROCESS  
(EVENTTYPE, INPUTBUFFER, BEFORE_AFTER)  
VALUES  
('No Event','DB FLAG=' + @DB_FLAG + ' , Kill �� �پ��ִ� Process ��� ����', 'B')  
  
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
 ('No Event','DB FLAG=' + @DB_FLAG + ' , Kill �� �پ��ִ� Process ����', 'A')  
  
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
('No Event','DB FLAG=' + @DB_FLAG + ' , Kill �� �پ��ִ� Process ��� ��', 'B')  
  
  
DROP TABLE #INPUT_BUFFER

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO