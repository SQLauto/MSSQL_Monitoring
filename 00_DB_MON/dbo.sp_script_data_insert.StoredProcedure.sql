USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[sp_script_data_insert]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/**********************************************************************************    
 *** 프로시져명 : sp_script_data_insert    
 *** 목      적 : 해당 테이블 생성 스크립트 추출    
 *** 작  성  자 : 이성표    
 *** 작  성  일 : 2009-11-20    
 *** parameter     
   @tableName : 테이블명    
   @str     : 출력 스크립트    
    
 *** 예제     
 -- 1. 테이블을 메시지 창에 출력    
 DECLARE @str VARCHAR(8000)    
 SET @str = ''    
 EXEC sp_script_table_c @tableName = '테이블명', @script = @str OUTPUT    
 PRINT @str    
     
 -- 2. 테이블을 결과 창에 테이블 형태로 출력    
 EXEC sp_script_table_c '테이블명'    
 *** Update 내역    
   2009-11-23     
 - dmv (sys.table명) 을 사용하지 않고 기존 2000 방식의 쿼리 사용    
 - sp_bindefault 로 default 정의된 부분에서도 정상적으로 적용(type 자체가 바뀜, rollback)    
 - script 가 column 길이에 따라 유동적으로 생성\    
 - check 조건에 대한 스크립트 추가    
**********************************************************************************/    
CREATE PROCEDURE [dbo].[sp_script_data_insert]    
 @tableName  varchar(255) = NULL,            
 @default bit = 1,    
 @identity bit = 0,    
 @where varchar(300) = '',    
 @maxcnt int = 10000,    
 @option char(1) = NULL    
AS              
SET NOCOUNT ON              
BEGIN    
    
IF @option = 'H'    
BEGIN    
    
 PRINT '-- PROC NAME : sp_script_data_insert'    
 PRINT '-- PARAMETER'    
 PRINT '    @tableName : table name'    
 PRINT '    @default'    
 PRINT '      0 : default 비포함'    
 PRINT '      1 : default 포함(기본값)'    
 PRINT '    @identity'    
 PRINT '      0 : identity 비포함(기본값)'    
 PRINT '      1 : identity 포함(SET IDENTITY_INSERT ON 으로 처리)'    
 PRINT '    @where : 추출 제약 조건(예 @where = ''WHERE SEQNO <= 100)'''    
 PRINT '-- EXAMPLE'    
 PRINT '    EXEC sp_script_data_insert @tableName = ''테이블명'', @default = 1, @identity = 0, @where = ''WHERE SEQNO <= 100'''    
 RETURN    
END    
    
/*** 선언 부분 ***/    
DECLARE @tableStruct TABLE (    
 seq      INT    IDENTITY(1,1) PRIMARY KEY,    
    columnid             INT             NOT NULL,              
    columnname           VARCHAR(255)   NOT NULL,              
    columntype           VARCHAR(255)   NOT NULL,              
    nullable             TINYINT         NOT NULL,              
    isDefault            TINYINT         NULL,              
    isIdentity           TINYINT         NULL              
)    
    
DECLARE @scriptStruct TABLE (    
 seq     INT IDENTITY(1, 1) PRIMARY KEY,    
 script    VARCHAR(MAX)    
)    
    
DECLARE @insStr VARCHAR(max)    
DECLARE @columnname VARCHAR(255), @columntype VARCHAR(255)    
DECLARE @isIdentity TINYINT, @isDefault TINYINT    
DECLARE @SEQ INT, @MAXSEQ INT    
    
DECLARE @valueStr VARCHAR(max)    
DECLARE @fullStr VARCHAR(max)    
DECLARE @script VARCHAR(max)    
    
    
/*** 실제 코딩 부분 ***/    
    
-- 테이블 존재 여부 체크    
IF NOT EXISTS (SELECT * FROM sysobjects where type = 'U' and name = @tableName)              
BEGIN            
    
 DECLARE @errScript varchar(1000)    
 SET @errScript = '[' + @tableName + '] 은 존재하지 않는 테이블입니다.'    
 raiserror(@errScript, 16, 1)                     
 RETURN              
END       
    
-- 테이블 구조 추출    
INSERT @tableStruct (columnid, columnname, columntype, nullable, isDefault, isIdentity)              
SELECT              
    c.colid,              
    c.name,              
    CASE WHEN xtype IN (SELECT xtype FROM systypes WHERE name IN ('nchar', 'nvarchar')) THEN type_name(xtype) + '(' + CONVERT(VARCHAR(60), length / 2) + ')'               
         WHEN xtype IN (SELECT xtype FROM systypes WHERE name IN ('binary', 'varchar', 'char')) THEN type_name(xtype) + '(' + CONVERT(VARCHAR(60), length) + ')'              
         ELSE type_name(xtype) END,              
    c.isnullable,    
    CASE WHEN OBJECTPROPERTY(c.cdefault, 'IsDefaultCnst') = 1 OR OBJECTPROPERTY(c.cdefault, 'IsDefault') = 1 THEN 1 ELSE 0 END,    
    CASE WHEN (COLUMNPROPERTY(c.id, c.name, N'IsIdentity') <> 0) THEN 1 ELSE 0 END              
FROM syscolumns c              
WHERE c.id = OBJECT_ID(@tableName)              
ORDER BY c.colid    
    
/*** INSERT 문 만들기 ***/    
SET @MAXSEQ = @@ROWCOUNT    
SET @SEQ = 1    
SET @insStr = '''INSERT ' + @tableName + ' ('    
    
WHILE @SEQ <= @MAXSEQ    
BEGIN    
    
 SELECT @columnname = columnname, @isDefault = isDefault, @isIdentity = isIdentity FROM @tableStruct WHERE SEQ = @SEQ    
     
 IF NOT (@isDefault = 1 AND @default = 0) AND NOT (@isIdentity = 1 AND @identity = 0)    
 BEGIN    
     
  SET @insStr = @insStr + @columnname    
  SET @insStr = @insStr + ', '    
    
 END    
    
 SET @SEQ = @SEQ + 1    
    
END    
    
SET @insStr = LEFT(@insStr, LEN(@insStr) - 1) + ') '    
    
SET @insStr = @insStr     
--PRINT @insStr    
    
/*** SELECT 문 만들기  (INSERT 문 만들기에 같이 작업할 수도 있으나 복잡해져서 그냥 따로 작업)***/    
SET @SEQ = 1    
SET @valueStr = ' VALUES ('    
    
WHILE @SEQ <= @MAXSEQ    
BEGIN    
    
 SELECT @columnname = columnname, @columntype = columntype, @isDefault = isDefault, @isIdentity = isIdentity FROM @tableStruct WHERE SEQ = @SEQ    
    
 IF NOT (@isDefault = 1 AND @default = 0) AND NOT (@isIdentity = 1 AND @identity = 0)    
 BEGIN    
    
  IF @columntype LIKE '%CHAR%' OR @columntype LIKE '%text%' -- Character 유형일 경우    
  BEGIN    
   SET @valueStr = @valueStr + ''' + CASE WHEN ' + @columnname + ' IS NULL THEN ''NULL'' ELSE '''''''' + REPLACE(' + @columnname + ', '''''''', '''''''''''') + '''''''' END + '', '    
  END    
  ELSE IF @columntype LIKE '%date%'    
  BEGIN    
   SET @valueStr = @valueStr + ''' + CASE WHEN ' + @columnname + ' IS NULL THEN ''NULL'' ELSE '''''''' + CONVERT(CHAR(23), ' + @columnname + ', 121) + '''''''' END + '', '    
  END    
  ELSE     
  BEGIN    
   SET @valueStr = @valueStr + ''' + CASE WHEN ' + @columnname + ' IS NULL THEN ''NULL'' ELSE + CONVERT(VARCHAR(255), ' + @columnname + ') END + '', '    
  END    
    
 END    
    
 SET @SEQ = @SEQ + 1    
    
END    
    
-- IDENTITY 출력일 때 SET IDENTITY_INSERT ON 옵션 추가    
IF @identity = 1 AND EXISTS (SELECT * FROM @tableStruct WHERE isIdentity = 1)    
 INSERT @scriptStruct (script) VALUES ('SET IDENTITY_INSERT ' + @tablename + ' ON')    
    
-- 추출할 쿼리문 생성    
SET @fullStr = @insStr + LEFT(@valueStr, LEN(@valueStr) - 2) + ''')'''    
    
SET @fullStr = 'SELECT TOP ' + CONVERT(VARCHAR, @maxcnt) + ' '  + @fullStr + ' FROM ' + @tablename + ' WITH (NOLOCK) '    
    
IF REPLACE(@where, ' ', '') LIKE 'WHERE%' SET @fullStr = @fullStr + @where    
    
INSERT @scriptStruct (script) EXEC (@fullStr)    
    
-- IDENTITY 출력일 때 SET IDENTITY_INSERT ON 옵션 추가    
IF @identity = 1 AND EXISTS (SELECT * FROM @tableStruct WHERE isIdentity = 1)    
 INSERT @scriptStruct (script) VALUES ('SET IDENTITY_INSERT ' + @tablename + ' OFF')    
    
SELECT @MAXSEQ = MAX(SEQ) FROM @scriptStruct    
SET @SEQ = 1    
    
-- 쿼리 PRINT    
WHILE @SEQ <= @MAXSEQ     
BEGIN    
 SELECT @script = script FROM @scriptStruct WHERE SEQ = @SEQ    
     
 PRINT @script    
     
 SET @SEQ = @SEQ + 1    
    
END    
    
END 
GO
