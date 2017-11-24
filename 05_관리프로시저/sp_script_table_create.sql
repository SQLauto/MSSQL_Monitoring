/**********************************************************************************
 *** ���ν����� : sp_script_table_create
 *** ��      �� : �ش� ���̺� ���� ��ũ��Ʈ ����
 *** ��  ��  �� : �̼�ǥ
 *** ��  ��  �� : 2009-11-20
 *** parameter 
   @tableName : ���̺��
   @str     : ��� ��ũ��Ʈ

 *** ���� 
 -- 1. ���̺��� �޽��� â�� ���
 DECLARE @str NVARCHAR(4000)
 SET @str = ''
 EXEC sp_script_table_create @tableName = '���̺��', @script = @str OUTPUT
 PRINT @str
 
 -- 2. ���̺��� ��� â�� ���̺� ���·� ���
 EXEC sp_script_table_create '���̺��'
 *** Update ����
   2009-11-23 
	- dmv (sys.table��) �� ������� �ʰ� ���� 2000 ����� ���� ���
	- sp_bindefault �� default ���ǵ� �κп����� ���������� ����(type ��ü�� �ٲ�, rollback)
	- script �� column ���̿� ���� ���������� ����\
	- check ���ǿ� ���� ��ũ��Ʈ �߰�
**********************************************************************************/
CREATE PROCEDURE dbo.sp_script_table_create      
 @tableName  varchar(255) = NULL,        
 @script nvarchar(4000) = NULL OUTPUT,
 @option char(1) = NULL     
AS          
SET NOCOUNT ON          
BEGIN

IF @option = 'H'
BEGIN

PRINT '-- PROC NAME : sp_script_table_create'
PRINT '-- PARAMETER'
PRINT '     @tableName : table name'
PRINT '     @script : output script'
PRINT '-- EXAMPLE'
PRINT '     DECLARE @str NVARCHAR(4000)'
PRINT '     SET @str = '''''
PRINT '     EXEC sp_script_table_create @tableName = ''���̺��'', @script = @str OUTPUT'
PRINT '     PRINT @str'
RETURN
END

          
DECLARE @maxIndex INT, @seqIndex INT    

DECLARE @colnameLen INT, @coltypeLen INT    
          
DECLARE @indexName varchar(256), @indextype tinyint, @isClustered nvarchar(20)          
DECLARE @indexcol1 NVARCHAR(28)          
DECLARE @indexcol2 NVARCHAR(28)          
DECLARE @indexcol3 NVARCHAR(28)          
DECLARE @indexcol4 NVARCHAR(28)          
DECLARE @indexcol5 NVARCHAR(28)          
DECLARE @indexcol6 NVARCHAR(28)          
        
DECLARE @defaultValue varchar(255), @defaultColumn varchar(255)        
DECLARE @strDefault  NVARCHAR(4000)

DECLARE @checkValue	varchar(255), @checkColumn varchar(255)
DECLARE @strCheck NVARCHAR(4000)
          
DECLARE @strIndex        NVARCHAR(4000)          
        
DECLARE @scriptList TABLE (          
    seqNo             INT IDENTITY(1, 1),          
    script            NVARCHAR(4000)     NOT NULL          
)          
          
DECLARE @tableStruct TABLE (
    tablename            NVARCHAR(50)    NOT NULL,          
    columnid             INT             NOT NULL,          
    columnname           NVARCHAR(255)    NOT NULL,          
    columntype           NVARCHAR(255)    NOT NULL,          
    nullable             TINYINT         NOT NULL,          
    defaultVal           NVARCHAR(255)    NULL,          
    isCheck              TINYINT         NULL,          
    isIdentity           TINYINT         NULL          
)          
          
DECLARE @indexStruct TABLE (          
    seqNo               INT IDENTITY(1, 1),          
    indexname           NVARCHAR(100)     NOT NULL,          
    indextype           TINYINT          NOT NULL,        -- 1 : PK, 2 : INX          
    isClustered         NVARCHAR(20)     NOT NULL,          
    col1                NVARCHAR(28)     NULL,          
    col2                NVARCHAR(28)     NULL,          
    col3                NVARCHAR(28)     NULL,          
    col4                NVARCHAR(28)     NULL,          
    col5                NVARCHAR(28)     NULL,          
    col6                NVARCHAR(28)     NULL          
)          
        
DECLARE @defaultStruct TABLE (        
 seqNo    INT IDENTITY(1, 1),        
 defaultColumn  NVARCHAR(28) NOT NULL,        
 defaultValue  NVARCHAR(300) NOT NULL        
)        
        
DECLARE @checkStruct TABLE (        
 seqNo    INT IDENTITY(1, 1),        
 checkColumn  NVARCHAR(28) NOT NULL,        
 checkValue  NVARCHAR(300) NOT NULL        
)                
          
IF NOT EXISTS (SELECT * FROM sysobjects where type = 'U' and name = @tableName)          
BEGIN          
 raiserror('�������� �ʴ� ���̺��Դϴ�.', 16, 1)                 
 RETURN          
END          
          
INSERT @tableStruct (tablename, columnid, columnname, columntype, nullable, defaultVal, isCheck, isIdentity)          
SELECT          
    OBJECT_NAME(c.id),          
    c.colid,          
    c.name,          
    CASE WHEN xusertype IN (SELECT xusertype FROM systypes WHERE name IN ('nchar', 'nvarchar')) THEN type_name(xusertype) + '(' + CONVERT(NVARCHAR(60), length / 2) + ')'           
         WHEN xusertype IN (SELECT xusertype FROM systypes WHERE name IN ('binary', 'varchar', 'char')) THEN type_name(xusertype) + '(' + CONVERT(NVARCHAR(60), length) + ')'          
         ELSE type_name(xusertype) END,          
    c.isnullable,          
    cm.text,          
    CASE WHEN o.name IS NULL THEN 0 ELSE 1 END,          
    CASE WHEN (COLUMNPROPERTY(c.id, c.name, N'IsIdentity') <> 0) THEN 1 ELSE 0 END          
FROM syscolumns c          
    LEFT JOIN syscomments cm ON c.cdefault = cm.id           
    LEFT JOIN (SELECT * FROM sysobjects WHERE xtype = 'C ') o ON c.id = o.parent_obj AND c.name = col_name(o.parent_obj, info)          
WHERE c.id = OBJECT_ID(@tableName)          
ORDER BY c.colid

SELECT @colnameLen = MAX(LEN(columnname)), @coltypeLen = MAX(LEN(columntype)) FROM @tableStruct
          
INSERT @scriptList (script) VALUES ('CREATE TABLE dbo.' + @tableName + ' (')          
          
INSERT @scriptList (script)          
SELECT           
  CASE WHEN columnId = 1 THEN ' ' ELSE ',' END + ' '          
+ LEFT(columnName + space(@colnameLen), @colnameLen) + ' '           
+ LEFT(columnType + space(@coltypeLen), @coltypeLen)           
+ CASE WHEN nullable = 1 THEN ' NULL     ' ELSE ' NOT NULL ' END         
+ CASE WHEN isIdentity = 1 THEN 'IDENTITY(1, 1)' ELSE '' END AS script          
FROM @tableStruct          
ORDER BY columnId          
          
INSERT @scriptList (script) VALUES (')')          
INSERT @scriptList (script) VALUES ('')          
          
INSERT @indexStruct (indexname, indextype, isClustered, col1, col2, col3, col4, col5, col6)          
SELECT name,           
    CASE WHEN status & 2048 <> 0 THEN 1 ELSE 2 END,           
    CASE WHEN status & 16 <> 0 THEN 'CLUSTERED' ELSE 'NONCLUSTERED' END,          
    index_col(OBJECT_NAME(id), indid, 1),           
    index_col(OBJECT_NAME(id), indid, 2),           
    index_col(OBJECT_NAME(id), indid, 3),          
    index_col(OBJECT_NAME(id), indid, 4),          
    index_col(OBJECT_NAME(id), indid, 5),          
    index_col(OBJECT_NAME(id), indid, 6)          
FROM sysindexes WHERE id = OBJECT_ID(@tableName) AND indid > 0 AND indid < 255 AND (status & 64) = 0           
ORDER BY indid          
          
SET @maxIndex = @@ROWCOUNT          
          
SET @seqIndex = 1          
          
WHILE @seqIndex <= @maxIndex          
BEGIN          
    SELECT @indexname = indexname, @indextype = indextype, @isClustered = isClustered, @indexcol1 = col1, @indexcol2 = col2, @indexcol3 = col3, @indexcol4 = col4, @indexcol5 = col5, @indexcol6 = col6          
    FROM @indexStruct WHERE seqNo = @seqindex           
          
    IF @indextype = 1        -- Primary key          
    BEGIN          
                  
        SET @strIndex = 'ALTER TABLE dbo.' + @tableName + ' ADD CONSTRAINT PK_' + @tableName          
                      + ' PRIMARY KEY ' +  @isClustered + ' ('          
                      + @indexcol1 + ISNULL(', ' + @indexcol2, '') + ISNULL(', ' + @indexcol3, '')           
                      + ISNULL(', ' + @indexcol4, '') + ISNULL(', ' + @indexcol5, '') + ISNULL(', ' + @indexcol6, '') + ')'          
          
        INSERT @scriptList (script) VALUES (@strIndex)          
        INSERT @scriptList (script) VALUES ('')          
          
    END          
    ELSE          
    BEGIN        
        SET @strIndex = 'CREATE ' + CASE WHEN @isClustered = 'CLUSTERED' THEN 'CLUSTERED' ELSE '' END + ' INDEX ' + CASE WHEN @isClustered = 'CLUSTERED' THEN 'C' ELSE '' END + 'IDX'          
                      + ISNULL('_' + @indexcol1, '') + ISNULL('__' + @indexcol2, '') + ISNULL('__' + @indexcol3, '')           
                 + ISNULL('__' + @indexcol4, '') + ISNULL('__' + @indexcol5, '') + ISNULL('__' + @indexcol6, '')           
                      + ' ON dbo.' + @tableName + ' ('          
                      + @indexcol1 + ISNULL(', ' + @indexcol2, '') + ISNULL(', ' + @indexcol3, '')           
                      + ISNULL(', ' + @indexcol4, '') + ISNULL(', ' + @indexcol5, '') + ISNULL(', ' + @indexcol6, '') + ')'          
          
        INSERT @scriptList (script) VALUES (@strIndex)          
        INSERT @scriptList (script) VALUES ('')          
          
    END          
          
    SET @seqIndex = @seqIndex + 1          
          
END          

/*	���� ���        
INSERT @defaultStruct (defaultColumn, defaultValue)
SELECT COL_NAME(o.parent_obj, s.colid), CONVERT(varchar(300), c.text)
FROM sysobjects o
	JOIN sysconstraints s on o.id = s.constid
	join syscomments c on o.id = c.id
WHERE IsDefaultCnst 
  AND o.parent_obj = OBJECT_ID(@tableName)
*/

INSERT @defaultStruct (defaultColumn, defaultValue)
SELECT c.name, CONVERT(varchar(300), m.text)
FROM syscolumns c left join syscomments m on m.id = c.cdefault
WHERE OBJECTPROPERTY(c.cdefault, 'IsDefaultCnst') = 1
  AND c.id = OBJECT_ID(@tableName)

SET @maxIndex = @@ROWCOUNT   

/* sp_binddefault �� ���ǵ� ���� ����
INSERT @defaultStruct (defaultColumn, defaultValue)
SELECT c.name, 
	   RIGHT(RTRIM(CONVERT(varchar(300), m.text)), LEN(RTRIM(CONVERT(varchar(300), m.text))) - CHARINDEX('AS', RTRIM(CONVERT(varchar(300), m.text))) - 2)
FROM syscolumns c join syscomments m on m.id = c.cdefault
WHERE OBJECTPROPERTY(c.cdefault, 'IsConstraint') = 0
  AND c.id = OBJECT_ID(@tableName)
  
SET @maxIndex = @maxIndex + @@ROWCOUNT
*/
          
SET @seqIndex = 1          
        
WHILE @seqIndex <= @maxIndex          
BEGIN        
        
 SELECT @defaultColumn = defaultColumn, @defaultValue = defaultValue FROM @defaultStruct        
 WHERE seqNo = @seqindex           
         
 SET @seqIndex = @seqIndex + 1        
         
 SET @strDefault = 'ALTER TABLE ' + @tableName + ' ADD CONSTRAINT DFLT_' + @tableName + '_' + @defaultColumn        
     + ' DEFAULT ' + @defaultValue + ' FOR ' + @defaultColumn        
             
 INSERT @scriptList (script) VALUES (@strDefault)          
 INSERT @scriptList (script) VALUES ('')           
        
END        

INSERT @checkStruct (checkColumn, checkValue)
SELECT ISNULL(COL_NAME(o.parent_obj, s.colid), ''), CONVERT(varchar(300), c.text)
FROM sysobjects o
	JOIN sysconstraints s on o.id = s.constid
	join syscomments c on o.id = c.id
WHERE OBJECTPROPERTY(o.id, 'IsCheckCnst') = 1
  AND o.parent_obj = OBJECT_ID(@tableName)
ORDER BY 1
    
SET @maxIndex = @@ROWCOUNT  
SET @seqIndex = 1  

WHILE @seqIndex <= @maxIndex
BEGIN

 SELECT @checkColumn = checkColumn, @checkValue = checkValue FROM @checkStruct WHERE seqNo = @seqIndex
 
 SET @strCheck = 'ALTER TABLE ' + @tableName + ' WITH NOCHECK ADD CONSTRAINT CHK_' + @tableName + '_' 
			   + CASE WHEN @checkColumn = '' THEN CONVERT(varchar, @seqIndex) ELSE @checkColumn END
			   + ' CHECK ' + @checkValue
 
 INSERT @scriptList (script) VALUES (@strCheck)          
 INSERT @scriptList (script) VALUES ('')
 
 SET @seqIndex = @seqIndex + 1   

END

IF @script IS NULL    
 SELECT script FROM @scriptList    
ELSE    
BEGIN    
          
 SELECT @maxIndex = COUNT(*) FROM @scriptList        
         
 SET @seqIndex = 1          
         
 WHILE @seqIndex <= @maxIndex        
 BEGIN        
         
  SELECT @script = @script + CHAR(13) + CHAR(10) + script FROM @scriptList WHERE seqno = @seqindex        
         
  SET @seqIndex = @seqIndex + 1        
         
 END        
    
END    
          
END 