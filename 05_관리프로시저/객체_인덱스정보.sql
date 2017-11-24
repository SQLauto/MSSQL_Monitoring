/**  
* Create        : spyo  
* SP Name       : dbo.procedure_name  
* Purpose       :   
* Modification Memo :  
**/  
CREATE PROCEDURE [dbo].[up_dba_index]  
    @tablename          nvarchar(100) = NULL,  
    @type               int           = 0  
AS  
/* COMMON DECLARE */  
SET NOCOUNT ON  
  
DECLARE @report TABLE (  
    seqNo        INT IDENTITY(1, 1),  
    tablename    NVARCHAR(50)    NOT NULL,  
    col1         NVARCHAR(300)   NOT NULL    DEFAULT(''),  
    col2         NVARCHAR(300)   NOT NULL    DEFAULT(''),  
    col3         NVARCHAR(300)   NOT NULL    DEFAULT(''),  
    col4         NVARCHAR(300)   NOT NULL    DEFAULT(''),  
    col5         NVARCHAR(300)   NOT NULL    DEFAULT(''),  
    col6         NVARCHAR(300)   NOT NULL    DEFAULT('')  
)  
  
DECLARE @tableList TABLE (  
    seqNo        INT IDENTITY(1, 1),  
    tableName    NVARCHAR(50)    NOT NULL  
)  
  
DECLARE @seqNo        INT  
DECLARE @maxSeq       INT  
  
DECLARE @table_Name     NVARCHAR(50)  
  
SET @seqNo = 1  
  
DECLARE @tmp TABLE (seq int)  
  
INSERT @tmp VALUES (0)  
INSERT @tmp VALUES (1)  
INSERT @tmp VALUES (2)  
  
INSERT @tableList (tableName)  
SELECT   
     o.name AS 'table name'  
FROM sysobjects o  
WHERE OBJECTPROPERTY(o.id, 'IsUserTable') = 1  
    AND NULLIF(@tablename, o.name) IS NULL  
ORDER BY  o.name  
  
SET  @maxSeq = @@IDENTITY  
  
DECLARE @empty varchar(1)  
DECLARE @des1 varchar(35)  
DECLARE @des2 varchar(35)  
DECLARE @des4 varchar(35)  
DECLARE @des32 varchar(35)  
DECLARE @des64 varchar(35)  
DECLARE @des2048 varchar(35)  
DECLARE @des4096 varchar(35)  
DECLARE @des8388608 varchar(35)  
DECLARE @des16777216 varchar(35)  
  
SET @empty = ''  
SELECT @des1 = name FROM master.dbo.spt_values WHERE type = 'I' AND number = 1    
SELECT @des2 = name FROM master.dbo.spt_values WHERE type = 'I' AND number = 2    
SELECT @des4 = name FROM master.dbo.spt_values WHERE type = 'I' AND number = 4    
SELECT @des32 = name FROM master.dbo.spt_values WHERE type = 'I' AND number = 32    
SELECT @des64 = name FROM master.dbo.spt_values WHERE type = 'I' AND number = 64    
SELECT @des2048 = name FROM master.dbo.spt_values WHERE type = 'I' AND number = 2048    
SELECT @des4096 = name FROM master.dbo.spt_values WHERE type = 'I' AND number = 4096    
SELECT @des8388608 = name FROM master.dbo.spt_values WHERE type = 'I' AND number = 8388608    
SELECT @des16777216 = name FROM master.dbo.spt_values WHERE type = 'I' AND number = 16777216    
  
IF @type = 0        -- 엑셀 문서용  
BEGIN  
  
    INSERT @report (tableName, col1, col2, col3) VALUES ('table name', 'index name', 'type', 'keys')  
  
    WHILE @seqNo <= @maxSeq  
    BEGIN  
        SELECT @table_Name = tableName FROM @tableList WHERE seqNo = @seqNo  
      
        SET @seqNo = @seqNo + 1  
      
        INSERT @report (tableName, col1, col2, col3)   
        SELECT tablename AS 'table name', indexname AS 'index name', LEFT(indexdesc, LEN(indexdesc) - 1) AS 'index description', keys   
        FROM  
            (  
            SELECT OBJECT_NAME(id) AS tablename,   
                  indid,   
                  name AS indexname,  
                  case when (status & 2048) <> 0 then @des2048 + ', ' else @empty end    
                + case when (status & 16) <> 0 then 'clustered, ' else 'nonclustered, ' end    
                + case when (status & 1) <> 0 then @des1 + ', ' else @empty end    
                + case when (status & 2) <> 0 then @des2 + ', ' else @empty end    
                + case when (status & 4) <> 0 then @des4 + ', ' else @empty end    
                + case when (status & 64) <> 0 then @des64 + ', ' else case when (status & 32) <> 0 then ', ' + @des32 else @empty end end    
                + case when (status & 4096) <> 0 then @des4096 + ', ' else @empty end    
                + case when (status & 8388608) <> 0 then @des8388608 + ', ' else @empty end    
                + case when (status & 16777216) <> 0 then @des16777216 + ', ' else @empty end AS indexdesc,  
                ISNULL(index_col(@table_name, indid, 1), '') + ISNULL(', ' + index_col(@table_name, indid, 2), '') + ISNULL(', ' + index_col(@table_name, indid, 3), '') + ISNULL(', ' + index_col(@table_name, indid, 4), '') AS 'keys'  
            FROM sysindexes WHERE id = OBJECT_ID(@table_name) AND indid > 0 AND indid < 255 AND (status & 64) = 0   
            ) A  
        ORDER BY indid  
      
      
    END  
END  
ELSE IF @type = 1        -- 워드 리포트 작성용  
BEGIN  
      
    WHILE @seqNo <= @maxSeq  
    BEGIN  
        SELECT @table_Name = tableName FROM @tableList WHERE seqNo = @seqNo  
      
        SET @seqNo = @seqNo + 1          
  
        INSERT @report (tableName, col1, col2)  
        SELECT tablename,   
               CASE WHEN T.seq = 0 THEN 'key name'  
                    WHEN T.seq = 1 THEN 'type'  
                    WHEN T.seq = 2 THEN 'keys'  
                    ELSE ''  
               END,  
               CASE WHEN T.seq = 0 THEN indexname  
                    WHEN T.seq = 1 THEN LEFT(indexdesc, LEN(indexdesc) - 1)  
                    WHEN T.seq = 2 THEN keys  
                    ELSE ''  
               END  
        FROM  
            (  
            SELECT OBJECT_NAME(id) AS tablename,   
                  indid,   
                  name AS indexname,  
                  case when (status & 2048) <> 0 then @des2048 + ', ' else @empty end    
                + case when (status & 16) <> 0 then 'clustered, ' else 'nonclustered, ' end    
                + case when (status & 1) <> 0 then @des1 + ', ' else @empty end    
                + case when (status & 2) <> 0 then @des2 + ', ' else @empty end    
                + case when (status & 4) <> 0 then @des4 + ', ' else @empty end    
                + case when (status & 64) <> 0 then @des64 + ', ' else case when (status & 32) <> 0 then ', ' + @des32 else @empty end end    
                + case when (status & 4096) <> 0 then @des4096 + ', ' else @empty end    
                + case when (status & 8388608) <> 0 then @des8388608 + ', ' else @empty end    
                + case when (status & 16777216) <> 0 then @des16777216 + ', ' else @empty end AS indexdesc,  
                ISNULL(index_col(@table_name, indid, 1), '') + ISNULL(', ' + index_col(@table_name, indid, 2), '') + ISNULL(', ' + index_col(@table_name, indid, 3), '') + ISNULL(', ' + index_col(@table_name, indid, 4), '') AS 'keys'  
            FROM sysindexes WHERE id = OBJECT_ID(@table_name) AND indid > 0 AND indid < 255 AND (status & 64) = 0   
            ) A  
            CROSS JOIN @tmp T  
        ORDER BY indid  
  
    END  
  
END  
  
SELECT tableName, col1, col2, col3, col4, col5, col6 FROM @report  
ORDER BY seqNo  
  
  
RETURN (0)  