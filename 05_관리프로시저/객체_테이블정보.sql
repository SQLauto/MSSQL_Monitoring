CREATE PROCEDURE [dbo].[up_dba_table]      
 @tablename   varchar(1000) = NULL                  
AS                  
SET NOCOUNT ON                  
                  
DECLARE @report TABLE (                  
    seqNo        INT IDENTITY(1, 1) PRIMARY KEY,                  
    tablename    VARCHAR(50)    NOT NULL,                  
    col1         VARCHAR(300)   NOT NULL    DEFAULT(''),                  
    col2         VARCHAR(300)   NOT NULL    DEFAULT(''),                  
    col3         VARCHAR(300)   NOT NULL    DEFAULT(''),                  
    col4         VARCHAR(300)   NOT NULL    DEFAULT(''),                  
    col5         VARCHAR(300)   NOT NULL    DEFAULT(''),                  
    col6         VARCHAR(300)   NOT NULL    DEFAULT('')                  
)                  
                  
DECLARE @tableListTemp TABLE (                  
    seqNo        INT IDENTITY(1, 1),                  
    tableName    VARCHAR(100)    NOT NULL                  
)                  
                
DECLARE @tableList TABLE (                  
    seqNo        INT IDENTITY(1, 1),                  
    tableName    VARCHAR(100)    NOT NULL                  
)                  
    
IF @tableName is NOT NULL    
BEGIN    
                
 DECLARE @tbl varchar(100), @pos_from int, @pos_to int                
                 
 SELECT @pos_from = 1, @pos_to = 1                
                 
 WHILE 1 = 1                
 BEGIN                
                 
  SET @pos_to = CHARINDEX(',', @tableName, @pos_from + 1)                
                 
  if @pos_to <= 0 break                
                 
  INSERT @tableListTemp VALUES (REPLACE(SUBSTRING(@tablename, @pos_from, @pos_to - @pos_from), ' ', ''))                
                 
  SET @pos_from = @pos_to + 1                
                 
 END                
                 
 INSERT @tableListTemp VALUES(REPLACE(SUBSTRING(@tablename, @pos_from, len(@tablename)), ' ', ''))                
END    
                
DECLARE @seqNo        INT                  
DECLARE @maxSeq       INT                  
              
                  
DECLARE @table_Name  VARCHAR(100)                  
DECLARE @table_desc  VARCHAR(300)              
                
SET @seqNo = 1                  
        
IF @tablename IS NULL        
BEGIN        
        
 INSERT @tableList (tableName)                  
 SELECT                   
   o.name AS 'table name'                  
 FROM sysobjects o                  
 WHERE OBJECTPROPERTY(o.id, 'IsUserTable') = 1                  
 ORDER BY o.name  
                   
 SET  @maxSeq = @@ROWCOUNT           
        
END        
ELSE        
BEGIN        
        
 INSERT @tableList (tableName)                  
 SELECT                   
   o.name AS 'table name'                  
 FROM sysobjects o                  
  join @tableListTemp t on o.name = t.tablename                
 WHERE OBJECTPROPERTY(o.id, 'IsUserTable') = 1                  
 ORDER BY  t.seqno         
                  
 SET  @maxSeq = @@ROWCOUNT                  
        
END        
          
WHILE @seqNo <= @maxSeq                  
BEGIN                  
                  
 SELECT @table_Name = tableName FROM @tableList WHERE seqNo = @seqNo                  
                  
 SET @seqNo = @seqNo + 1                  
                
  -- 컬럼                  
 INSERT @report (tablename, col1, col3) values (@table_name, '테이블명', @table_name)                  
-- INSERT @report (tablename, col1) values (@table_name, '테이블 설명')                
              
 SET @table_desc = ''              
              
 SELECT @table_desc = ISNULL(CONVERT(varchar(300), value), '') FROM ::fn_listextendedproperty('MS_Description', 'user', 'dbo', 'table', @table_name, default, default)              
              
 INSERT @report (tablename, col1, col3)              
 VALUES (@table_name, '테이블 설명', isnull(@table_desc, ''))              
                  
 INSERT @report (tablename) values (@table_name)                  
 INSERT @report (tablename, col1) values (@table_name, 'COLUMN')                  
 INSERT @report (tablename, col1, col2, col3, col4, col5, col6) VALUES (@table_name, '순번', 'COLUMN 명 (영)', 'COLUMN 명 (한)', 'Data Type', 'NULL 여부', 'IDENTITY 유형(Y)')                  
         
    INSERT @report (tableName, col1, col2, col3, col4, col5, col6)                  
    SELECT                   
        OBJECT_NAME(id),                   
  colid,                  
        name,              
        '', --ISNULL((SELECT TOP 1 CONVERT(varchar(300), value) FROM ::fn_listextendedproperty('MS_Description', 'user', 'dbo', 'table', @table_name, 'column', NULL) WHERE objname = A.name), '') collate Korean_Wansung_CI_AS,              
        type_name(xusertype) + CASE WHEN xusertype IN (SELECT xusertype FROM systypes WHERE name IN ('nchar', 'nvarchar')) THEN '(' + CONVERT(VARCHAR, length / 2) + ')'                  
                                    WHEN xusertype IN (SELECT xusertype FROM systypes WHERE name IN ('varchar', 'char', 'binary')) THEN '(' + CONVERT(VARCHAR, length) + ')'                  
                                    WHEN xusertype IN (SELECT xusertype FROM systypes WHERE name IN ('numeric')) THEN '(' + CONVERT(varchar, xprec) + ', ' + CONVERT(varchar, xscale) + ')'  
                                    ELSE ''  
                               END,                  
        case when isnullable = 0 then 'NOT NULL' else 'NULL' end,                  
  case when (COLUMNPROPERTY(id, name, N'IsIdentity') <> 0) then 'Y' else '' end                  
    FROM syscolumns A                  
    WHERE id = OBJECT_ID(@table_name) ORDER BY colid                   
                  
 INSERT @report (tablename) values (@table_name)                  
                
                
 -- 인덱스                 
 INSERT @report (tablename, col1) values (@table_name, 'INDEX')                  
 INSERT @report (tablename, col1, col2, col4, col5, col6) values (@table_name, '순번', 'INDEX 컬럼', 'CLUSTERED 여부(Y)', 'PK 여부(Y)', 'UNIQUE 여부(Y)')                  
                 
 INSERT @report (tablename, col1, col2, col4, col5, col6)                  
 SELECT @table_name, convert(varchar(20), indid),                  
  ISNULL(index_col(@table_name, indid, 1), '') + ISNULL(', ' + index_col(@table_name, indid, 2), '') + ISNULL(', ' + index_col(@table_name, indid, 3), '') + ISNULL(', ' + index_col(@table_name, indid, 4), ''),                  
  case when (status & 16) <> 0 then 'Y' else '' end,                  
  case when (status & 2048) <> 0 then 'Y' else '' end,                  
  case when (status & 2) <> 0 then 'Y' else '' end                  
 FROM sysindexes                   
 WHERE id = OBJECT_ID(@table_name) AND indid > 0 AND indid < 255 AND (status & 64) = 0                     
  
 INSERT @report (tablename) values (@table_name)                  
  
 -- DEFAULT                
 IF ((SELECT COUNT(*) FROM sysobjects WHERE parent_obj = OBJECT_ID(@table_name) and xtype = 'D') > 0)        
 BEGIN                
  
 INSERT @report (tablename, col1) values (@table_name, 'DEFAULT')                  
 INSERT @report (tablename, col1, col2, col3) values (@table_name, '순번', 'COLUMN 명', 'DEFAULT 값')        
  
 -- (숫자) 일 때 음수로 인식하는 버그 해결을 위해            
 /*  
 INSERT @report (tablename, col1, col2, col3)                
 SELECT @table_name, d.parent_column_id, COL_NAME(d.parent_object_id, d.parent_column_id), '= "' + CONVERT(varchar(300), c.text) + '"'            
 FROM sys.default_constraints d        
 JOIN syscomments c on d.object_id = c.id        
 WHERE d.parent_object_id = OBJECT_ID(@table_name)        
 */  
   
 INSERT @report (tablename, col1, col2, col3)                
 SELECT @table_name, c.colid,  ISNULL(COL_NAME(c.id, c.colid), 'TABLE LEVEL'), '= "' + CONVERT(varchar(300), m.text) + '"'  
 FROM sysobjects o  
  JOIN sysconstraints c ON o.id = c.constid  
  JOIN syscomments m ON o.id = m.id  
 WHERE o.xtype = 'D' and o.parent_obj = OBJECT_ID(@table_Name)   
  
 INSERT @report (tablename) values (@table_name)              
   END                
  
 -- CHECK                
 IF EXISTS (SELECT TOP 1 * FROM sysobjects WHERE parent_obj = OBJECT_ID(@table_name) and xtype = 'C')                
 BEGIN                
  
 INSERT @report (tablename, col1) values (@table_name, 'CHECK')                  
 INSERT @report (tablename, col1, col2, col3) values (@table_name, '순번', 'COLUMN 명', 'CHECK 값')                  
  
/*                
 INSERT @report (tablename, col1, col2, col3)                
 SELECT @table_name, d.parent_column_id, ISNULL(COL_NAME(d.parent_object_id, d.parent_column_id), 'TABLE LEVEL'), '= "' + CONVERT(varchar(300), c.text) + '"'            
 FROM sys.check_constraints d        
 JOIN syscomments c on d.object_id = c.id        
 WHERE d.parent_object_id = OBJECT_ID(@table_name)    
 */   
   
 INSERT @report (tablename, col1, col2, col3)                
 SELECT @table_name, c.colid,  ISNULL(COL_NAME(c.id, c.colid), 'TABLE LEVEL'), '= "' + CONVERT(varchar(300), m.text) + '"'  
 FROM sysobjects o  
  JOIN sysconstraints c ON o.id = c.constid  
  JOIN syscomments m ON o.id = m.id  
 WHERE o.xtype = 'C' and o.parent_obj = OBJECT_ID(@table_Name)  
  
 INSERT @report (tablename) values (@table_name)                
       
 END                
  
 INSERT @report (tablename, col1) values (@table_name, '테이블종료')                
 INSERT @report (tablename) values (@table_name)                
 INSERT @report (tablename) values (@table_name)                
                  
END                  
                   
SELECT col1, col2, col3, col4, col5, col6 FROM @report                  
ORDER BY seqNo  