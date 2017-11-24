use dba
go

CREATE TABLE DBA_REINDEX_INFO_LOG
( 
LOG_SEQ bigint   IDENTITY (1 , 1)  NOT NULL   , 
INDEX_SEQ bigint    NOT NULL   , 
ALLOC_UNIT_TYPE_DESC varchar (30)   NULL   , 
INDEX_DEPTH int    NULL   , 
INDEX_LEVEL int    NULL   , 
AVG_FRAGMENTATION_IN_PERCENT float    NULL   , 
FRAGMENT_COUNT int    NULL   , 
AVG_FRAGMENT_SIZE_IN_PAGES float    NULL   , 
PAGE_COUNT int    NULL   , 
AVG_PAGE_SPACE_USED_IN_PERCENT float    NULL   , 
RECORD_COUNT bigint    NULL   , 
GHOST_RECORD_COUNT bigint    NULL   , 
VERSION_GHOST_RECORD_COUNT bigint    NULL   , 
MIN_RECORD_SIZE_IN_BYTES int    NULL   , 
MAX_RECORD_SIZE_IN_BYTES int    NULL   , 
AVG_RECORD_SIZE_IN_BYTES decimal    NULL   , 
FORWARDED_RECORD_COUNT int    NULL   , 
COMPRESSED_PAGE_COUNT int    NULL   , 
EXEC_START_DT datetime    NULL   , 
EXEC_END_DT datetime    NULL   , 
REG_DT datetime    NOT NULL  CONSTRAINT DF__DBA_REINDEX_INFO_LOG__REG_DT DEFAULT (getdate())  , 
AUTO_YN char (1)   NULL  CONSTRAINT DF__DBA_REINDEX_INFO_LOG__AUTO_YN DEFAULT ('Y') 
)  ON [PRIMARY]
GO
ALTER TABLE DBA_REINDEX_INFO_LOG ADD CONSTRAINT PK__DBA_REINDEX_INFO_LOG__LOG_SEQ primary key clustered ([LOG_SEQ] ASC ) ON [PRIMARY] 
GO


CREATE TABLE DBA_REINDEX_MOD_META
( 
TARGET_SEQ bigint    NOT NULL   , 
DB_NAME varchar (20)   NOT NULL   , 
TABLE_NAME varchar (100)   NOT NULL   , 
INDEX_NAME varchar (300)   NOT NULL  
)  ON [PRIMARY]
GO
ALTER TABLE DBA_REINDEX_MOD_META ADD CONSTRAINT PK__DBA_REINDEX_MOD_META__TARGET_SEQ primary key clustered ([TARGET_SEQ] ASC ) ON [PRIMARY] 
GO


CREATE TABLE DBA_REINDEX_SETTINGS
( 
SETUP_SEQ bigint   IDENTITY (1 , 1)  NOT NULL   , 
DB_NAME varchar (20)   NULL   , 
TABLE_NAME varchar (100)   NULL   , 
EXCLUDE_YN char (1)   NULL   , 
REINDEX_RANK int    NULL   , 
REBUILD_THRESHOLD tinyint    NULL   , 
FILFACTOR_OPT tinyint    NULL   , 
PADINDEX_OPT varchar (3)   NULL   , 
ONLINE_OPT varchar (3)   NULL   , 
SORT_IN_TEMPDB_OPT varchar (3)   NULL   , 
MAXDOP_OPT tinyint    NULL   , 
DATA_COMPRESSION_OPT varchar (100)   NULL   , 
INDEX_SCAN_MODE varchar (20)   NULL  
)  ON [PRIMARY]
GO
ALTER TABLE DBA_REINDEX_SETTINGS ADD CONSTRAINT PK__DBA_REINDEX_SETTINGS__SETUP_SEQ primary key clustered ([SETUP_SEQ] ASC ) ON [PRIMARY] 
GO


CREATE TABLE DBA_REINDEX_SPACE
( 
id int    NOT NULL   , 
database_name nvarchar (125)   NULL   , 
table_name nvarchar (125)   NULL   , 
index_name nvarchar (125)   NULL   , 
before_dpages bigint    NULL   , 
before_reserved bigint    NULL   , 
before_used bigint    NULL   , 
before_rowcnt bigint    NULL   , 
before_rowmodctr bigint    NULL   , 
after_dpages bigint    NULL   , 
after_reserved bigint    NULL   , 
after_used bigint    NULL   , 
after_rowcnt bigint    NULL   , 
after_rowmodctr bigint    NULL   , 
start_date datetime    NULL   , 
end_date datetime    NULL   , 
duration bigint    NULL  
)  ON [PRIMARY]
GO
CREATE clustered INDEX CIDX__DBA_REINDEX_SPACE__START_DATE ON DBA_REINDEX_SPACE ([start_date] ASC ) ON [PRIMARY] 
GO



CREATE TABLE DBA_REINDEX_TARGET
( 
id int   IDENTITY (1 , 1)  NOT NULL   , 
table_name nvarchar (128)   NULL   , 
database_id smallint    NULL   , 
database_name nvarchar (128)   NULL   , 
object_id int    NULL   , 
index_id int    NULL   , 
index_name nvarchar (128)   NULL   , 
partition_number int    NULL   , 
index_type_desc nvarchar (60)   NULL   , 
alloc_unit_type_desc nvarchar (60)   NULL   , 
index_depth tinyint    NULL   , 
index_level tinyint    NULL   , 
avg_fragmentation_in_percent float    NULL   , 
fragment_count bigint    NULL   , 
avg_fragment_size_in_pages float    NULL   , 
page_count bigint    NULL   , 
avg_page_space_used_in_percent float    NULL   , 
record_count bigint    NULL   , 
ghost_record_count bigint    NULL   , 
version_ghost_record_count bigint    NULL   , 
min_record_size_in_bytes int    NULL   , 
max_record_size_in_bytes int    NULL   , 
avg_record_size_in_bytes float    NULL   , 
forwarded_record_count bigint    NULL   , 
reg_date datetime    NOT NULL  CONSTRAINT DF__DBA_REINDEX_TARGET__REG_DATE DEFAULT (getdate())  , 
execute_status char (1)   NULL   , 
rebuild_date datetime    NULL  
)  ON [PRIMARY]
GO
ALTER TABLE DBA_REINDEX_TARGET ADD CONSTRAINT PK__DBA_REINDEX_1_TARGET primary key clustered ([id] ASC, [reg_date] ASC  ) ON [PRIMARY] 
GO



CREATE TABLE DBA_REINDEX_TARGET_LIST
( 
TARGET_SEQ bigint   IDENTITY (1 , 1)  NOT NULL   , 
DB_NAME varchar (20)   NULL   , 
TABLE_NAME varchar (100)   NULL   , 
INDEX_NAME varchar (300)   NULL   , 
SETUP_SEQ bigint    NULL   , 
INDEX_SEQ bigint    NULL   , 
LOG_SEQ bigint    NULL   , 
EXEC_SCRIPT nvarchar (3000)   NULL   , 
PAST_AVG_FRAGMENTATION_IN_PERCENT float    NULL   , 
PAST_FRAGMENT_COUNT int    NULL   , 
PAST_AVG_FRAGMENT_SIZE_IN_PAGES float    NULL   , 
PAST_PAGE_COUNT int    NULL   , 
PAST_AVG_PAGE_SPACE_USED_IN_PERCENT float    NULL   , 
PAST_RECORD_COUNT bigint    NULL   , 
PAST_INDEX_SIZE_KB bigint    NULL   , 
CURRENT_AVG_FRAGMENTATION_IN_PERCENT float    NULL   , 
CURRENT_FRAGMENT_COUNT int    NULL   , 
CURRENT_AVG_FRAGMENT_SIZE_IN_PAGES float    NULL   , 
CURRENT_PAGE_COUNT int    NULL   , 
CURRENT_AVG_PAGE_SPACE_USED_IN_PERCENT float    NULL   , 
CURRENT_RECORD_COUNT bigint    NULL   , 
CURRENT_INDEX_SIZE_KB bigint    NULL   , 
EXEC_START_DT datetime    NULL   , 
EXEC_END_DT datetime    NULL   , 
PERCENTAGE float    NULL   , 
REG_DT datetime    NOT NULL  CONSTRAINT DF__DBA_REINDEX_TARGET_LIST__REG_DT DEFAULT (getdate())  , 
AUTO_YN char (1)   NULL  CONSTRAINT DF__DBA_REINDEX_TARGET_LIST__AUTO_YN DEFAULT ('Y')  , 
MOD tinyint    NULL  
)  ON [PRIMARY]
GO
ALTER TABLE DBA_REINDEX_TARGET_LIST ADD CONSTRAINT PK__DBA_REINDEX_TARGET_LIST__TARGET_SEQ primary key clustered ([TARGET_SEQ] ASC ) ON [PRIMARY] 
GO



CREATE TABLE DBA_REINDEX_TOTAL_LIST
( 
INDEX_SEQ bigint   IDENTITY (1 , 1)  NOT NULL   , 
DB_NAME varchar (100)   NOT NULL   , 
SCHEMA_NAME varchar (50)   NOT NULL   , 
TABLE_NAME varchar (100)   NOT NULL   , 
INDEX_NAME varchar (300)   NOT NULL   , 
OBJECT_ID bigint    NOT NULL   , 
INDEX_ID bigint    NOT NULL   , 
PARTITION_NUMBER int    NULL   , 
INDEX_TYPE tinyint    NOT NULL   , 
INDEX_TYPE_DESC varchar (100)   NOT NULL   , 
ISUNIQUE bit    NULL   , 
DISABLED_YN char (1)   NULL   , 
HYPOTHETICAL_YN char (1)   NULL   , 
ROW_COUNT bigint    NULL   , 
INDEX_SIZE_KB bigint    NULL   , 
REG_DT datetime    NOT NULL  CONSTRAINT DF__DBA_REINDEX_TOTAL_LIST__REG_DT DEFAULT (getdate())  , 
CHG_DT datetime    NOT NULL  CONSTRAINT DF__DBA_REINDEX_TOTAL_LIST__CHG_DT DEFAULT (getdate())  , 
UNUSED_INDEX_SIZE_KB bigint    NULL  
)  ON [PRIMARY]
GO
ALTER TABLE DBA_REINDEX_TOTAL_LIST ADD CONSTRAINT PK__DBA_REINDEX_TOTAL_LIST__INDEX_SEQ primary key clustered ([INDEX_SEQ] ASC ) ON [PRIMARY] 
GO



CREATE TABLE REINDEX_INDEX_PROCESS
( 
DB nvarchar (256)   NULL   , 
TABLE_NAME nvarchar (128)   NULL   , 
INDEX_NAME nvarchar (128)   NULL   , 
ROWS bigint    NOT NULL   , 
NEW_ROWS bigint    NOT NULL   , 
DIFF_ROWS bigint    NULL   , 
PARTITION_NUMBER int    NOT NULL   , 
DATA_COMPRESSION_DESC nvarchar (60)   NULL  
)  ON [PRIMARY]
GO