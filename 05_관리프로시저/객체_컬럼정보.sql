CReATE PROCEDURE [dbo].[up_dba_column]   
    @tablename          varchar(100) = NULL,  
    @type               int           = 0  
AS  
/* COMMON DECLARE */  
SET NOCOUNT ON  
  
DECLARE @report TABLE (  
    seqNo        INT IDENTITY(1, 1),  
    tablename    VARCHAR(50)    NOT NULL,  
    col1         VARCHAR(300)   NOT NULL    DEFAULT(''),  
    col2         VARCHAR(300)   NOT NULL    DEFAULT(''),  
    col3         VARCHAR(300)   NOT NULL    DEFAULT(''),  
    col4         VARCHAR(300)   NOT NULL    DEFAULT(''),  
    col5         VARCHAR(300)   NOT NULL    DEFAULT(''),  
    col6         VARCHAR(300)   NOT NULL    DEFAULT('')  
)  
  
DECLARE @tableList TABLE (  
    seqNo        INT IDENTITY(1, 1),  
    tableName    VARCHAR(50)    NOT NULL  
)  
  
DECLARE @seqNo        INT  
DECLARE @maxSeq       INT  
  
DECLARE @table_Name     VARCHAR(50)  
  
SET @seqNo = 1  
  
  
INSERT @tableList (tableName)  
SELECT   
     o.name AS 'table name'  
FROM sysobjects o  
WHERE OBJECTPROPERTY(o.id, 'IsUserTable') = 1  
    AND NULLIF(@tablename, o.name) IS NULL  
ORDER BY  o.name  
  
SET  @maxSeq = @@IDENTITY  
  
  
IF @type = 0                 -- 엑셀 문서용  
BEGIN  
  
    INSERT @report (tableName, col1, col2, col3) --, col4, col5)   
 VALUES ('table name', 'column name', 'type', 'null') --, 'domain', 'definition')  
  
    WHILE @seqNo <= @maxSeq  
    BEGIN  
        SELECT @table_Name = tableName FROM @tableList WHERE seqNo = @seqNo  
      
        SET @seqNo = @seqNo + 1  
      
      
        INSERT @report (tableName, col1, col2, col3)  
        SELECT   
            OBJECT_NAME(id),   
            name,   
            type_name(xusertype) + CASE WHEN xusertype IN (SELECT xusertype FROM systypes WHERE name IN ('nchar', 'nvarchar')) THEN '(' + CONVERT(VARCHAR, length / 2) + ')'  
                                        WHEN xuserType IN (SELECT xusertype FROM systypes WHERE name IN ('varchar', 'char', 'binary')) THEN '(' + CONVERT(vARCHAR, length) + ')'  
                                        ELSE ''   
                                   END,  
            case when isnullable = 0 then 'N' else 'Y' end   
--            ISNULL((SELECT CONVERT(VARCHAR, value) FROM ::fn_listextendedproperty('domain', 'user', 'dbo', 'table', @table_name, 'column', NULL) WHERE objname = A.name), ''),  
--            ISNULL((SELECT CONVERT(VARCHAR, value) FROM ::fn_listextendedproperty('definition', 'user', 'dbo', 'table', @table_name, 'column', NULL) WHERE objname = A.name), '')  
        FROM syscolumns A  
        WHERE id = OBJECT_ID(@table_name) ORDER BY colid  
      
    END  
  
END  
ELSE IF @type = 1                -- 워드 리포트 작성용  
BEGIN  
    WHILE @seqNo <= @maxSeq  
    BEGIN  
        SELECT @table_Name = tableName FROM @tableList WHERE seqNo = @seqNo  
      
        SET @seqNo = @seqNo + 1  
  
        INSERT @report (tableName, col1, col2, col3) --, col4, col5)   
  VALUES ('table name', 'column name', 'type', 'null') --, 'domain', 'definition')      
      
        INSERT @report (tableName, col1, col2, col3)  
        SELECT   
            OBJECT_NAME(id),   
            name,   
            type_name(xusertype) + CASE WHEN xusertype IN (SELECT xusertype FROM systypes WHERE name IN ('nchar', 'nvarchar')) THEN '(' + CONVERT(NVARCHAR, length / 2) + ')'  
                                        WHEN xuserType IN (SELECT xusertype FROM systypes WHERE name IN ('varchar', 'char', 'binary')) THEN '(' + CONVERT(NVARCHAR, length) + ')'  
                                        ELSE ''   
                                   END,  
            case when isnullable = 0 then 'N' else 'Y' end   
--            ISNULL((SELECT CONVERT(NVARCHAR, value) FROM ::fn_listextendedproperty('domain', 'user', 'dbo', 'table', @table_name, 'column', NULL) WHERE objname = A.name), ''),  
--            ISNULL((SELECT CONVERT(NVARCHAR, value) FROM ::fn_listextendedproperty('definition', 'user', 'dbo', 'table', @table_name, 'column', NULL) WHERE objname = A.name), '')  
        FROM syscolumns A  
        WHERE id = OBJECT_ID(@table_name) ORDER BY colid  
  
        INSERT @report (tableName) VALUES ('')  
      
    END  
  
END  
  
  
SELECT tablename, col1, col2, col3, col4, col5, col6 FROM @report  
ORDER BY seqNo  
  
  
RETURN (0)  