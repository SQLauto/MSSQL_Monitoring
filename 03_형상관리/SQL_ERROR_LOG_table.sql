declare @pf_time1 datetime
declare @pf_time2 datetime
declare @pf_time3 datetime
declare @pf_time4 datetime
declare @pf_time5 datetime
declare @pf_time6 datetime
 
set @pf_time1 = convert(datetime, convert(char(10), getdate() + 10, 121), 121)
set @pf_time2 = convert(datetime, convert(char(10), getdate() + 20, 121), 121)
set @pf_time3 = convert(datetime, convert(char(10), getdate() + 30, 121), 121)
set @pf_time4 = convert(datetime, convert(char(10), getdate() + 40, 121), 121)
set @pf_time5 = convert(datetime, convert(char(10), getdate() + 50, 121), 121)
set @pf_time6 = convert(datetime, convert(char(10), getdate() + 60, 121), 121)
  
CREATE PARTITION FUNCTION PF__SQL_ERROR_LOG__LOG_DATE (datetime)  
AS RANGE RIGHT FOR VALUES (@pf_time1, @pf_time2, @pf_time3, @pf_time4, @pf_time5, @pf_time6)
go
  
CREATE PARTITION SCHEME PS__SQL_ERROR_LOG__LOG_DATE  
AS PARTITION PF__SQL_ERROR_LOG__LOG_DATE ALL TO ([PRIMARY])  
go

CREATE TABLE  SQL_ERROR_LOG
(
	seq_no int identity (1,1) not null, 
	server_id	 int not null,
	instance_id int not null,
	log_type varchar(15) null, 
	log_date datetime,
	process_info nvarchar(100),
	log_text  nvarchar(1000)
 , constraint PK__SQL_ERROR_LOG__LOG_DATE PRIMArY KEY NONCLUSTERED (log_date, seq_no) with (DATA_compression = PAGE) 
	ON PS__SQL_ERROR_LOG__LOG_DATE (log_date)
) ON PS__SQL_ERROR_LOG__LOG_DATE (log_date)

CREATE INDEX IDX__SQL_ERROR_LOG__SERVER_ID  ON  SQL_ERROR_LOG  ( server_id, instance_id)
 with (DATA_compression = PAGE)
	ON PS__SQL_ERROR_LOG__LOG_DATE (log_date)


CREATE TABLE  SWITCH_SQL_ERROR_LOG
(
	seq_no int identity (1,1) not null, 
	server_id	 int not null,
	instance_id int not null,
	log_type varchar(15) null, 
	log_date datetime,
	process_info nvarchar(100),
	log_text  nvarchar(1000)
, constraint PK__SWITCH_SQL_ERROR_LOG__LOG_DATE PRIMArY KEY NONCLUSTERED (log_date, seq_no) with (DATA_compression = PAGE) 

) 

CREATE INDEX IDX__SWITCH_SQL_ERROR_LOG__SERVER_ID ON  SQL_ERROR_LOG   ( server_id, instance_id) with (DATA_compression = PAGE)
