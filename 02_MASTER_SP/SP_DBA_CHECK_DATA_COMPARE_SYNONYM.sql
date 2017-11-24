/*************************************************************************  
* 프로시저명: dbo.SP_DBA_CHECK_DATA_COMPARE
* 작성정보        : 2013-03-26 BY CHOI BO RA
* 관련페이지:  
* 내용            : 테이블 이관 후 조건 비교  
* 수정정보        : 
                           2013-06-28 서은미 unique index 또한 PK처럼 이름 변경되도록 수정
                           2013-07-04 김대경 권한체크 오류수정 ERROR_NUMBER=15330(권한이 없는 경우)
                           2013-07-09 최보라 rollback rename, 변수 초기화 추가
                           2013-07-10 노상국 INDEX 없는경우 오류 수정(index_id=0, HEAP)
                           2013-07-10 서은미 INDEX 이름에 _OLD가 있는 경우 오류 수정(replace구문에 old제거, line 133)
                           2013-07-12 최보라 스키마 바인딩 VIEW CHECK 추가
                           2013-07-25 서은미 권한 체크 try~catch source,target쪽 각각 체크하도록 오류수정
                           2015-02-17 최보라 시노님 생성 db명시
                           EXEC dbo.SP_DBA_CHECK_DATA_COMPARE 'STARDB', 'dbo', 'MOBILE_ORDER_FORM', 'STARDB', 'MOBILE_ORDER_FORM_ETAM'
**************************************************************************/
CREATE PROCEDURE [dbo].[SP_DBA_CHECK_DATA_COMPARE_SYNONYM]
         @SOURCE_DB_NAME                    SYSNAME,
         @SOURCE_DB_SCHEMA          SYSNAME,
         @SOURCE_TABLE_NAME                 SYSNAME,
         @TARGET_DB_NAME                    SYSNAME  = NULL, 
         @TARGET_TABLE_NAME                 SYSNAME  = NULL, 
         @SAMPLE                                     INT = 5

AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @DB_NAME  SYSNAME
DECLARE @STR_SQL  NVARCHAR(4000), @STR_PARM NVARCHAR(500)
DECLARE @SOURCE_FULL_OBJECT SYSNAME, @TARGET_FULL_OBJECT SYSNAME
DECLARE @SOURCE_COUNT BIGINT, @TARGET_COUNT BIGINT

/* BODY */

IF @TARGET_DB_NAME IS NULL SET @TARGET_DB_NAME = @SOURCE_DB_NAME
IF @TARGET_TABLE_NAME IS NULL SET @TARGET_TABLE_NAME = @SOURCE_TABLE_NAME + '_ETAM'

SET @SOURCE_FULL_OBJECT = @SOURCE_DB_NAME + '.' + @SOURCE_DB_SCHEMA+ '.' + @SOURCE_TABLE_NAME
SET @TARGET_FULL_OBJECT = @TARGET_DB_NAME + '.' + @SOURCE_DB_SCHEMA+ '.' + @TARGET_TABLE_NAME



-- 1. 데이터 건수 비교 
PRINT '/*** DATABASE : ' + @TARGET_DB_NAME + ' Table Name : ' + @TARGET_TABLE_NAME + ' Check Data Start ****/' 
PRINT  ''

SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0

SET @STR_SQL = 'SELECT     @SOURCE_COUNT  = SUM (CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END     ) ' + CHAR(10)
                             +'FROM ' + @SOURCE_DB_NAME + '.sys.dm_db_partition_stats ps WHERE OBJECT_ID = OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  BIGINT OUTPUT'


EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT


SET @STR_SQL ='SELECT @TARGET_COUNT  = SUM (CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END         )  ' + CHAR(10)
                           + 'FROM ' + @TARGET_DB_NAME + '.sys.dm_db_partition_stats ps WHERE OBJECT_ID = OBJECT_ID(''' + @TARGET_FULL_OBJECT +''')'
SET @STR_PARM = N'@TARGET_COUNT  BIGINT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT OUTPUT


IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
         --PRINT '--1.건수 비교 : Fault 필수 확인 '
         RAISERROR ( '--1.건수 비교 : Fault 필수 확인',  16,1)     

         SELECT '1.건수 비교 ' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT
END
ELSE 
         PRINT '--1.건수 비교 : OK '



-- 2.인덱스 건수 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL ='SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.SYS.INDEXES WHERE OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+''')'
SET @STR_PARM = N'@SOURCE_COUNT  BIGINT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT



SET @STR_SQL ='SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.SYS.INDEXES WHERE OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+''')'
SET @STR_PARM = N'@TARGET_COUNT  BIGINT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT OUTPUT


IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
         
         RAISERROR ( '--2.인덱스 건수 비교  : Fault 필수 확인',  16,1)     
         SELECT '2.인덱스 건수 비교' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT

         SET @STR_SQL ='SELECT NAME, TYPE_DESC , IS_PRIMARY_KEY, IS_UNIQUE FROM ' + @SOURCE_DB_NAME +'.SYS.INDEXES WHERE OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+''')'
         EXECUTE sp_executesql  @STR_SQL

         
         SET @STR_SQL ='SELECT NAME, TYPE_DESC , IS_PRIMARY_KEY, IS_UNIQUE FROM ' + @TARGET_DB_NAME +'.SYS.INDEXES WHERE OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+''')'
         EXECUTE sp_executesql  @STR_SQL

END      
ELSE 
         PRINT '--2.인덱스 건수 비교 : OK'


-- 2-1. 인덱스 이름 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
CREATE TABLE #SOURCE_INDEX_NAME 
( SOUCE_TABLE_NAME SYSNAME, SOURCE_NAME SYSNAME , SOURCE_TYPE  NVARCHAR(60), SOURCE_PRIMARY_KEY BIT, SOURCE_UNIQUE BIT )

CREATE TABLE #TARGET_INDEX_NAME 
( SEQNO INT IDENTITY(1,1)  NOT NULL, 
 TARGET_TABLE_NAME SYSNAME, TARGET_NAME SYSNAME , TARGET_TYPE NVARCHAR(60), TARGET_PRIMARY_KEY BIT, TARGET_UNIQUE BIT )


SET @STR_SQL ='INSERT INTO #SOURCE_INDEX_NAME' + CHAR(10)
                           +'SELECT ''' + @SOURCE_TABLE_NAME + ''',NAME, TYPE_DESC , IS_PRIMARY_KEY, IS_UNIQUE_CONSTRAINT FROM ' + @SOURCE_DB_NAME +'.SYS.INDEXES ' + CHAR(10)
                           + 'WHERE INDEX_ID>0 AND OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+''')'

EXECUTE sp_executesql  @STR_SQL


SET @STR_SQL ='INSERT INTO #TARGET_INDEX_NAME' + CHAR(10)
                           +'SELECT ''' + @TARGET_TABLE_NAME + ''',NAME, TYPE_DESC , IS_PRIMARY_KEY, IS_UNIQUE_CONSTRAINT FROM ' + @TARGET_DB_NAME +'.SYS.INDEXES ' + CHAR(10)
                           + 'WHERE INDEX_ID>0 AND OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+''')'
EXECUTE sp_executesql  @STR_SQL


SELECT @SOURCE_COUNT = COUNT(*)
FROM #SOURCE_INDEX_NAME AS A 
         --LEFT JOIN #TARGET_INDEX_NAME AS B ON REPLACE(A.SOURCE_NAME,'_OLD', '') = REPLACE(B.TARGET_NAME, '_ETAM', '')
         LEFT JOIN #TARGET_INDEX_NAME AS B ON A.SOURCE_NAME = REPLACE(B.TARGET_NAME, '_ETAM', '')
WHERE B.TARGET_NAME IS NULL



IF @SOURCE_COUNT > 0
BEGIN
         RAISERROR ( '--2-1.Index 이름 Check : Fault 필수 확인 ',  16,1)  
         
         SELECT A.*, B.*
         FROM #SOURCE_INDEX_NAME AS A 
                 LEFT JOIN #TARGET_INDEX_NAME AS B ON REPLACE(A.SOURCE_NAME,'_OLD', '') = REPLACE(B.TARGET_NAME, '_ETAM', '')
         WHERE B.TARGET_NAME IS NULL

END
ELSE 
         PRINT '--2-1.Index 이름 Check : OK'



-- 3. CHECK 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.check_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT  OUTPUT

SET @STR_SQL = 'SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.sys.check_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@TARGET_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT OUTPUT



IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
         
         RAISERROR ( '--3.CHECK 비교  : Fault 필수 확인 ',  16,1)  
         SELECT '3.CHECK 비교' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT

         SET @STR_SQL ='SELECT ''' + @SOURCE_TABLE_NAME + ''' AS SORUCE, NAME FROM ' + CHAR(10)
                                   + @SOURCE_DB_NAME+ '.sys.check_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
         EXECUTE sp_executesql  @STR_SQL
         
         SET @STR_SQL ='SELECT ''' + @TARGET_TABLE_NAME + ''' AS TARGET, NAME FROM ' + CHAR(10)
                                   + @TARGET_DB_NAME+ '.sys.check_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID('+ @TARGET_FULL_OBJECT+ ')'
         EXECUTE sp_executesql  @STR_SQL
         

END
ELSE 
         PRINT '--3.CHECK 비교 : OK'

-- 4.DEFAULT 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.default_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT  OUTPUT



SET @STR_SQL = 'SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.sys.default_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@TARGET_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT  OUTPUT

IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
         
         RAISERROR ( '--4.DEFAULT 비교  : Fault 필수 확인 ',  16,1)  
         SELECT '4.DEFAULT 비교' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT
         
         SET @STR_SQL ='SELECT ''' + @SOURCE_TABLE_NAME + ''' AS SORUCE, NAME FROM ' + CHAR(10)
                                   + @SOURCE_DB_NAME+ '.sys.default_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
         EXECUTE sp_executesql  @STR_SQL
         
         SET @STR_SQL ='SELECT ''' + @TARGET_TABLE_NAME + ''' AS TARGET, NAME FROM ' + CHAR(10)
                                   + @TARGET_DB_NAME+ '.sys.default_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @TARGET_FULL_OBJECT+ ''')'
         EXECUTE sp_executesql  @STR_SQL

END
ELSE 
         PRINT '--4.DEFAULT 비교 : OK'



-- 5.FK 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.foreign_keys WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT


SET @STR_SQL = 'SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.sys.foreign_keys WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@TARGET_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT  OUTPUT



IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
         
         RAISERROR ( '--5.FK 비교  : Fault 필수 확인 ',  16,1)  
         SELECT '5.FK 비교' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT
         
         SET @STR_SQL ='SELECT ''' + @SOURCE_TABLE_NAME + ''' AS SORUCE, NAME FROM ' + CHAR(10)
                                   + @SOURCE_DB_NAME+ '.sys.foreign_keys WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
         EXECUTE sp_executesql  @STR_SQL
         
         SET @STR_SQL ='SELECT ''' + @TARGET_TABLE_NAME + ''' AS TARGET, NAME FROM ' + CHAR(10)
                                   + @TARGET_DB_NAME+ '.sys.foreign_keys WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @TARGET_FULL_OBJECT+ ''')'
         EXECUTE sp_executesql  @STR_SQL

END
ELSE 
         PRINT '--5.FK 비교 : OK'

-- 6.TRIGGERS 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.triggers WHERE PARENT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT


IF @SOURCE_COUNT >0 
BEGIN 
         
         RAISERROR ( '--6.Trigger 존재: 트리거명 확인',  16,1)  

         SET @STR_SQL ='SELECT ''6.Trigger 존재, DROP/CREATE 처리'' AS STEP, NAME FROM ' + CHAR(10)
                                   + @SOURCE_DB_NAME+ '.sys.triggers WHERE PARENT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
         EXECUTE sp_executesql  @STR_SQL

END
ELSE 
         PRINT '--6.Trigger 존재 하지 않음 : OK'




-- 7.권한 CHECK
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
CREATE TABLE #HELPROTECT 
( SEQNO INT IDENTITY(1,1), OWNER SYSNAME, OBJECT SYSNAME, GRANTEE SYSNAME, GRANTOR SYSNAME, PROTECTTYPE SYSNAME, [ACTION] SYSNAME, [COLUMN] SYSNAME
)

CREATE TABLE #HELPROTECT_TARGET 
(  OWNER SYSNAME, OBJECT SYSNAME, GRANTEE SYSNAME, GRANTOR SYSNAME, PROTECTTYPE SYSNAME, [ACTION] SYSNAME, [COLUMN] SYSNAME
)

BEGIN TRY
         SET @SOURCE_COUNT = 0
         SET @STR_SQL= 'USE ' + @SOURCE_DB_NAME + CHAR(10)
                           + 'EXEC SP_HELPROTECT ' + @SOURCE_TABLE_NAME  

         INSERT INTO #HELPROTECT
         EXEC(@STR_SQL)

         SET @SOURCE_COUNT =@@ROWCOUNT 

END TRY 
BEGIN CATCH
         IF ERROR_NUMBER() = 15330 SET @SOURCE_COUNT = 0
END CATCH

BEGIN TRY
         SET @TARGET_COUNT = 0

         SET @STR_SQL= 'USE ' + @TARGET_DB_NAME + CHAR(10)
                           + 'EXEC SP_HELPROTECT ' + @TARGET_TABLE_NAME 

         INSERT INTO #HELPROTECT_TARGET
         EXEC(@STR_SQL)
         SET @TARGET_COUNT =@@ROWCOUNT
END TRY 
BEGIN CATCH
         IF ERROR_NUMBER() = 15330 SET @TARGET_COUNT = 0      
END CATCH

IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
         
         RAISERROR ( '--7.권한 CHECK : Fault , 권한 생성 ',  16,1)  
         SELECT '7.권한 CHECK' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT
         PRINT ''
         
         DECLARE @I  INT
         SET @I =1
         SET @STR_SQL = ''
         WHILE ( @I <= @SOURCE_COUNT)
         BEGIN
                  
                  SELECT @STR_SQL = @STR_SQL+ 'USE ' + @TARGET_DB_NAME + CHAR(10) 
                                              + 'GRANT ' + [ACTION] + ' ON OBJECT::' + @TARGET_TABLE_NAME + ' TO ' + GRANTEE + CHAR(10)
                  FROM #HELPROTECT WHERE SEQNO = @I

                  SET @I = @I + 1
         END

         PRINT @STR_SQL
         


END
ELSE 
         PRINT '--7.권한 CHECK : OK'

-- 8.컬럼수 비교
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.COLUMNS WHERE OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT

SET @STR_SQL = 'SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.sys.COLUMNS WHERE OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@TARGET_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT OUTPUT 



IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
         
         RAISERROR ( '--8.컬럼수 비교  : Fault 필수 확인 ',  16,1)  

         SELECT '8.컬럼수 비교' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT

         SET @STR_SQL ='SELECT ' + @SOURCE_TABLE_NAME + ' AS SORUCE, NAME FROM ' + CHAR(10)
                                   + @SOURCE_DB_NAME+ '.sys.COLUMNS WHERE OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
         EXECUTE sp_executesql  @STR_SQL
         
         SET @STR_SQL ='SELECT ' + @TARGET_TABLE_NAME + ' AS TARGET, NAME FROM ' + CHAR(10)
                                   + @TARGET_DB_NAME+ '.sys.COLUMNS WHERE OBJECT_ID= OBJECT_ID('''+ @TARGET_FULL_OBJECT+ ''')'
         EXECUTE sp_executesql  @STR_SQL

END
ELSE 
         PRINT '--8.컬럼수 비교 : OK'



-- 9.VIEW 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.views WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'
EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT


IF @SOURCE_COUNT >0 
BEGIN 
         
         RAISERROR ( '--9.VIEW 존재 : VIEW 명 확인',  16,1)  
         SET @STR_SQL ='SELECT ''9.VIEW 존재,ALTER 처리'' AS STEP, NAME FROM ' + CHAR(10)
                                   + @SOURCE_DB_NAME+ '.sys.views WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'


         EXECUTE sp_executesql  @STR_SQL

END
ELSE 
         PRINT '--9.VIEW 존재 하지 않음 : OK'

-- 9-1 스미마 바인딩 된 VIEW
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.sql_dependencies ' + CHAR(10)
                           + 'WHERE referenced_major_id = OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''') AND CLASS > 0 AND IS_SELECTED = 1 ' + CHAR(10)
                           + ' AND OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''') <> OBJECT_ID '
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT

IF @SOURCE_COUNT >0 
BEGIN 
         
           
         SET @STR_SQL ='SELECT DISTINCT ''9.스미카 바인딩 VIEW 존재,ALTER 처리'' AS STEP, NAME' + CHAR(10)
                                   + 'FROM ' + @SOURCE_DB_NAME + '.sys.sql_dependencies AS D JOIN ' + @SOURCE_DB_NAME + '.SYS.OBJECTS AS O ON D.OBJECT_ID = O.OBJECT_ID ' + CHAR(10)
                                   + 'WHERE D.referenced_major_id = OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''') AND D.CLASS > 0 AND D.IS_SELECTED = 1 ' + CHAR(10)
                                   + ' AND OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''') <> D.OBJECT_ID '
         EXECUTE sp_executesql  @STR_SQL

         RAISERROR ( '--9-1.스미카 바인딩 VIEW 존재 : VIEW 명 확인',  16,1)

END
ELSE 
         PRINT '--9-1. 스미카 바인딩 VIEW 존재 하지 않음 : OK'



--10.통계 확인 '
PRINT ''
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.stats WHERE OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')  and user_created =1'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'


EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT

SET @STR_SQL = 'SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.sys.stats WHERE OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+ ''')  and user_created =1'
SET @STR_PARM = N'@TARGET_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT OUTPUT


IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
         
         RAISERROR ( '--10.통계 확인  : Fault 필수 확인 ',  16,1)  

         SELECT '10.통계 확인' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT

         SET @STR_SQL ='SELECT ' + @SOURCE_TABLE_NAME + ' AS SORUCE, NAME FROM ' + CHAR(10)
                                    + @SOURCE_DB_NAME+ '.sys.stats WHERE OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
                                   + ' and user_created =1'

         EXECUTE sp_executesql  @STR_SQL
         
         SET @STR_SQL ='SELECT ' + @TARGET_TABLE_NAME + ' AS TARGET, NAME FROM ' + CHAR(10)
                                   + @TARGET_DB_NAME+ '.sys.stats WHERE OBJECT_ID= OBJECT_ID('''+ @TARGET_FULL_OBJECT+ ''')'
                                   + ' and user_created =1'

         EXECUTE sp_executesql  @STR_SQL

END
ELSE 
         PRINT '--10.통계 확인 : OK'




PRINT '/****11.DATA CHECK : 쿼리 실행, 틀린 DATA 결과 나옴  *************************/'
PRINT ''

EXEC DBO.SP_DBA_CHECK_DATA_COMPARE_SCRIPT @SOURCE_DB_NAME, @SOURCE_DB_SCHEMA, 
          @SOURCE_TABLE_NAME, @TARGET_DB_NAME, @TARGET_TABLE_NAME, @SAMPLE


-- 12. 최종 확인 SP_RENAME 스크립트.
PRINT '/**** SP_RENAME  *************************/'
PRINT 'USE ' + @SOURCE_DB_NAME + ';'
PRINT 'EXEC SP_RENAME ''' + @SOURCE_DB_SCHEMA + '.' + @SOURCE_TABLE_NAME + ''',''' + 'UNUSED_' + @SOURCE_TABLE_NAME + ''''

PRINT ''

PRINT '/**** SYNONYM  *************************/'
PRINT 'USE ' + @SOURCE_DB_NAME + ';'
PRINT 'CREATE SYNONYM ' + @SOURCE_DB_SCHEMA + '.' + @SOURCE_TABLE_NAME + ' FOR ' + @TARGET_DB_NAME + '.' + @SOURCE_DB_SCHEMA + '.' + @TARGET_TABLE_NAME

PRINT ''
PRINT ''
-- 13. RENAME 원복
PRINT '/**** Rollback SYNONYM  *************************/'
PRINT 'DROP SYNONYM ' + @SOURCE_DB_SCHEMA + '.' + @SOURCE_TABLE_NAME
PRINT ''

PRINT '/**** Rollback SP_RENAME  ************************/'
PRINT  'EXEC SP_RENAME ''' + @SOURCE_DB_SCHEMA + '.' + 'UNUSED_' + @SOURCE_TABLE_NAME + ''', ''' + @SOURCE_TABLE_NAME + ''''
PRINT 'USE ' + @TARGET_DB_NAME + ';'
PRINT  'EXEC SP_RENAME ''' + @SOURCE_DB_SCHEMA + '.' + @TARGET_TABLE_NAME + ''', ''' + 'UNUSED_' + @SOURCE_TABLE_NAME + ''''
PRINT ''


PRINT '*/'


