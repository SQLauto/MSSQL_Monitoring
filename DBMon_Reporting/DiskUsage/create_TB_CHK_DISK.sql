SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* ���̺�� 	  : dbo.TB_CHK_DISK
* �ۼ�����    : 2007-12-14
* ����������  :  
* ����        : ��ũ ���� ���� ���� ��� ���̺� 
* ��������    :
**************************************************************************/
CREATE TABLE [dbo].[TB_CHK_DISK](	
     [SEQ_NO]			int	IDENTITY(1,1)  NOT NULL,
     [SVR_NM]  			sysname	   NULL,
     [DISK_NM]			varchar(50)		   NULL,
     [FREE_SPACE]		varchar(30)	   	   NULL,         
     [REG_DT]           datetime           NULL  CONSTRAINT DF__TB_CHK_DISK__REG_DT DEFAULT(getdate()), 		   --��ϳ�¥
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
    1. ���� ���
*****************************************************************************************/
/*************************************************************************  
* ���̺�� 	  : dbo.DB_FILE_SIZE
* �ۼ�����    : 2009-07-30
* ����������  :  
* ����        : ��� ��ũ �ѿ뷮
* ��������    :
**************************************************************************/
CREATE TABLE SERVER_DISK
(
    drv_letter char(1) not null,
    capacity   int     null,
    freesize   int     null
)
-- ��û��ȣ:25186


/*************************************************************************  
* ���̺�� 	  : dbo.DB_FILE_SIZE
* �ۼ�����    : 2009-07-30
* ����������  :  
* ����        : DB�� ���� ����
* ��������    :
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
* ���̺�� 	  : dbo.TABLE_FILE_SIZE
* �ۼ�����    : 2009-07-30
* ����������  :  
* ����        : DB�� ���� ����
* ��������    :
**************************************************************************/
CREATE TABLE TABLE_FILE_SIZE 
(   
    dbname     sysname  null, 
    nbr_of_rows	int,
	data_space	decimal(15,2),
	index_space	decimal(15,2) )
;
