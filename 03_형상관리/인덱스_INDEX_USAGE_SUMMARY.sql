CREATE TABLE INDEX_USAGE_SUMMARY
( 
seq_no		bigint identity not null,
reg_date date    not NULL   , 
server_id int    NOT NULL   , 
database_name sysname   not  NULL   , 
object_id int    NOT NULL   , 
object_name nvarchar (256)   not  NULL   , 
index_cnt int    not NULL   , 

user_select bigint    NULL   , -- sum seek, scan,lookups 차이의 누적치 , 그런데 index의 sum 이니까. sum의 누적치  
user_updates bigint    NULL   , 
user_day_select_ bigint NULL, 
user_day_update bigint NULL, 

system_select bigint null, 
system_update bigint null, 
system_day_select_ bigint NULL, 
system_day_update bigint NULL, 

last_user_select datetime    NULL   , 
last_user_update datetime    NULL   , 
last_system_select datetime null, 
last_system_update  datetime null, 
unused_day int

)  ON [PRIMARY]
GO
CREATE clustered INDEX CIDX__INDEX_USAGE_SUMMARY__REG_DATE__SERVER_ID ON INDEX_USAGE_SUMMARY ([reg_date] ASC, SERVER_ID ) ON [PRIMARY] 
GO
ALTER TABLE INDEX_USAGE_SUMMARY ADD CONSTRAINT PK__INDEX_USAGE_SUMMARY__SEQ_NO   PRIMARY KEY NONCLUSTERED ( SEQ_NO ) 
GO
