SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 테이블명 	  : dbo.TB_CHK_DISK
* 작성정보    : 2007-12-14
* 관련페이지  :  
* 내용        : 디스크 여유 공간 정보 담는 테이블 
* 수정정보    :
**************************************************************************/
CREATE TABLE [dbo].[TB_CHK_DISK](	
     [SEQ_NO]			int	IDENTITY(1,1)  NOT NULL,
     [SVR_NM]  			sysname	   NULL,
     [DISK_NM]			varchar(50)		   NULL,
     [FREE_SPACE]		varchar(30)	   	   NULL,         
     [REG_DT]           datetime           NULL  CONSTRAINT DF__TB_CHK_DISK__REG_DT DEFAULT(getdate()), 		   --등록날짜
     CONSTRAINT [PK_TB_CHK_DISK] PRIMARY KEY NONCLUSTERED 
     (
        [SEQ_NO] 
     )ON [PRIMARY]
)ON [PRIMARY]



SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
ALTER TABLE freedisk_hist ALTER COLUMN server_nm sysname null

/****************************************************************************************
    1. 각자 장비
*****************************************************************************************/
/*************************************************************************  
* 테이블명 	  : dbo.DB_FILE_SIZE
* 작성정보    : 2009-07-30
* 관련페이지  :  
* 내용        : 장비별 디스크 총용량
* 수정정보    :
**************************************************************************/
CREATE TABLE SERVER_DISK
(
    drv_letter char(1) not null,
    capacity   int     null,
    freesize   int     null
)
-- 요청번호:25186


/*************************************************************************  
* 테이블명 	  : dbo.DB_FILE_SIZE
* 작성정보    : 2009-07-30
* 관련페이지  :  
* 내용        : DB별 파일 정보
* 수정정보    :
**************************************************************************/
CREATE TABLE DB_FILE_SIZE 
(
    
    dbname sysname,
	file_name sysname,
	file_type sysname,
	drive char(1),
	use_data decimal(10,2), --varchar(25),
	total_data_size  decimal(10,2), --varchar(25),
	smallest decimal(10,2)
)
;

/*************************************************************************  
* 테이블명 	  : dbo.TABLE_FILE_SIZE
* 작성정보    : 2009-07-30
* 관련페이지  :  
* 내용        : DB별 파일 정보
* 수정정보    :
**************************************************************************/
CREATE TABLE TABLE_FILE_SIZE 
(   
    dbname     sysname  null, 
    nbr_of_rows	int,
	data_space	decimal(15,2),
	index_space	decimal(15,2) )
;
