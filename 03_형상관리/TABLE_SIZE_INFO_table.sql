USE [ADMIN]

GO

CREATE PARTITION FUNCTION PF__TABLESIZEINFO__REG_DT(DATE)

AS RANGE RIGHT

FOR VALUES (

    '2010-01-01',

    '2010-06-01',

    '2011-01-01',

    '2011-07-01',

    '2012-01-01',

    '2012-07-01',

    '2013-01-01',

    '2013-07-01'

   )

GO

 

 

use admin

go

 

--1-2 파티션스키마생성

CREATE PARTITION SCHEME  PS__TABLESIZEINFO__REG_DT

AS PARTITION PF__TABLESIZEINFO__REG_DT

TO

(

    [PRIMARY],

    [PRIMARY],

    [PRIMARY],

    [PRIMARY],

    [PRIMARY],

    [PRIMARY],

    [PRIMARY],

    [PRIMARY],

    [PRIMARY] 

 

 

)

GO

 

 

CREATE TABLE [dbo].[TABLE_SIZE_INFO](

           [seq] [int] IDENTITY(1,1) NOT NULL,

           [server_id] [int] NOT NULL,

           [instance_id] [int] NULL,

           [db_id] [int] NOT NULL,

           [rank] [int] NOT NULL,

           [object_id] [int] ,

           [schema_name] [nvarchar](128), 

           [table_name] [nvarchar](128), 

           [Row_count] [bigint], 

           [Reserved] [bigint], 

           [data] [bigint],

           [index_size] [bigint],

           [unused] [bigint],

           [reg_dt] [datetime] NOT NULL

           CONSTRAINT [PK__TABLESIZEINFO__RET_DT_SEQ_NO] PRIMARY KEY NONCLUSTERED 

(   

           [reg_dt], seq

) ON  PS__TABLESIZEINFO__REG_DT(REG_DT) 

) ON PS__TABLESIZEINFO__REG_DT(REG_DT) 

 

 

 

 

    

--테이블압축걸기

ALTER TABLE TABLESIZEINFO

REBUILD WITH (DATA_COMPRESSION = PAGE);

GO

 

--압축확인하기

--압축확인data_compression_desc 컬럼에PAGE로보임.

select * from sys.partitions where object_id = object_id ('TABLESIZEINFO')
