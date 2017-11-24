/********************************************
   실시간 관리용 프로시저 관리 테이블
   양사의 DBA, DBADMIN에 생성
*********************************************/

CREATE TABLE  dbo.DBA_MON
(
    seq_no      int identity(1,1) not null,
    sp_name     sysname,
    parameter   nvarchar(300),
    sp_desc     nvarchar(300),
    reg_id      nvarchar(10),
    sp_type     tinyint      null,
    class       nvarchar(20) not null,
    priority    nvarchar(20) not null,
    
   CONSTRAINT PK__DBA_MON__SEQ_NO PRIMARY  KEY NONCLUSTERED (seq_no) ON [PRIMARY]
 ) ON [PRIMARY]
 
 CREATE CLUSTERED INDEX CIDX__DBA_MON__CLASS__PRIORITY ON DBA_MON (CLASS, PRIORITY)
 ;
 
insert into DBA_MON(seq_no,sp_name,parameter,sp_desc,reg_id,sp_type,class,priority) values(1,'sp_mon_execute','@iswaitfor=0, @plan=0','현재 실행 중인 쿼리 (sys.dm_exec_requests) ','ceusee',1,'cpu',1)
insert into DBA_MON(seq_no,sp_name,parameter,sp_desc,reg_id,sp_type,class,priority) values(10,'dbcc opentran','','활성트랜잭션','ceusee',0,'connection',1)
insert into DBA_MON(seq_no,sp_name,parameter,sp_desc,reg_id,sp_type,class,priority) values(11,'dbcc sqlperf(''logspace'')','','Log Space Used','ceusee',0,'db',3)
insert into DBA_MON(seq_no,sp_name,parameter,sp_desc,reg_id,sp_type,class,priority) values(12,'dbcc loginfo','','Log VLF','ceusee',0,'db',3)
insert into DBA_MON(seq_no,sp_name,parameter,sp_desc,reg_id,sp_type,class,priority) values(13,'sp_mon_change_procedure','@duration=60','기간 동안 변경된 프로시져 리스트','seolee',1,'etc',3)
insert into DBA_MON(seq_no,sp_name,parameter,sp_desc,reg_id,sp_type,class,priority) values(2,'sp_mon_con_byhost',NULL,'host별 connection','seolee',1,'cpu',1)
insert into DBA_MON(seq_no,sp_name,parameter,sp_desc,reg_id,sp_type,class,priority) values(3,'sp_mon_blocking',NULL,'블로킹 정보, is_blocker = 1 블로킹 유발','ceusee',1,'connection',1)
insert into DBA_MON(seq_no,sp_name,parameter,sp_desc,reg_id,sp_type,class,priority) values(4,'sp_mon_top_cpu','@row_count=15, @delay_time=''00:00:02''','기간동안 CPU높은 쿼리','ceusee',1,'cpu',1)
insert into DBA_MON(seq_no,sp_name,parameter,sp_desc,reg_id,sp_type,class,priority) values(5,'sp_mon_tempuse','@type=0','tempdb 사용 쿼리','seolee',1,'memory',2)
insert into DBA_MON(seq_no,sp_name,parameter,sp_desc,reg_id,sp_type,class,priority) values(6,'sp_mon_logjob','@durtion=60','오래 실행중인 JOB 내역','ceusee',1,'job',2)
insert into DBA_MON(seq_no,sp_name,parameter,sp_desc,reg_id,sp_type,class,priority) values(7,'sp_mon_replication_perf','','복제-배포자 성능','seolee',1,'service',2)
insert into DBA_MON(seq_no,sp_name,parameter,sp_desc,reg_id,sp_type,class,priority) values(8,'sp_mon_replication_status','','복제-배포자 상태','ceusee',1,'service',2)
insert into DBA_MON(seq_no,sp_name,parameter,sp_desc,reg_id,sp_type,class,priority) values(9,'sp_mon_mirroring_status','','미러링-연결 상태','ceusee',1,'service',2)