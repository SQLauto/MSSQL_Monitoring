-- 링크드 서버 확인되어야함
/*==============================================================*/
/* DBMS name:      Microsoft SQL Server 2000                    */
/* Created on:     2007-08-04 오전 10:24:40                       */
/*==============================================================*/


--===========================================================
-- 로그 백업을 하는 장비에 실행
--===========================================================

if exists (select 1
            from  sysobjects
           where  id = object_id('dbo.LOGSHIPPING_BACKUP_LIST')
            and   type = 'U')
   drop table dbo.LOGSHIPPING_BACKUP_LIST
go


/*==============================================================*/
/* Table: LOGSHIPPING_BACKUP_LIST                               */
/*==============================================================*/
create table dbo.LOGSHIPPING_BACKUP_LIST (
   user_db_name         sysname              not null,
   seq_no               int                  not null,
   backup_no            int                  not null,
   log_file             nvarchar(200)        not null,
   backup_type          tinyint              not null constraint DK__LOGSHIPPING_BACKUP_LIST__BACKUP_TYPE default 1,
   backup_flag          tinyint              not null constraint DK__LOGSHIPPING_BACKUP_LIST__BACKUP_FLAG default 0,
   backup_start_time    datetime             null,
   backup_end_time      datetime             null,
   backup_duration      int                  not null constraint DK__LOGSHIPPING_BACKUP_LIST__BACKUP_DURATION default 0,
   delete_flag          tinyint              not null constraint DK__LOGSHIPPING_BACKUP_LIST__DELETE_FLAG default 0,
   delete_time          datetime             null,
   error_code           int                  not null constraint DK__LOGSHIPPING_BACKUP_LIST__ERROR_CODE default 0,
   copy_106             bit                  not null constraint DK__LOGSHIPPING_BACKUP_LIST__COPY_106 default 1,
   copy_117             bit                  not null constraint DK__LOGSHIPPING_BACKUP_LIST__COPY_117 default 1,
   copy_107             bit                  not null constraint DK__LOGSHIPPING_BACKUP_LIST__COPY_107 default 1,
   reg_dt               datetime             not null constraint DK__LOGSHIPPING_BACKUP_LIST__REG_DT default GETDATE()
)
go

alter table dbo.LOGSHIPPING_BACKUP_LIST
   add constraint PK_LOGSHIPPING_BACKUP_LIST primary key  (user_db_name, seq_no)
      on "PRIMARY"
go

if exists (select 1
            from  sysindexes
           where  id    = object_id('dbo.LOGSHIPPING_BACKUP_LIST')
            and   name  = 'IDX__LOGISHIPPING_BACKUP_LIST__BACKUP_FLAG'
            and   indid > 0
            and   indid < 255)
   drop index dbo.LOGSHIPPING_BACKUP_LIST.IDX__LOGISHIPPING_BACKUP_LIST__BACKUP_FLAG
go

/*==============================================================*/
/* Index: IDX__LOGISHIPPING_BACKUP_LIST__BACKUP_FLAG            */
/*==============================================================*/
create  index IDX__LOGISHIPPING_BACKUP_LIST__BACKUP_FLAG on dbo.LOGSHIPPING_BACKUP_LIST (
backup_flag ASC
)
on "PRIMARY"
go


--======================================================
-- 복원하는 장비에 생성
---=====================================================

if exists (select 1
            from  sysobjects
           where  id = object_id('dbo.LOGSHIPPING_RESTORE_LIST')
            and   type = 'U')
   drop table dbo.LOGSHIPPING_RESTORE_LIST
go

/*==============================================================*/
/* Table: LOGSHIPPING_RESTORE_LIST                              */
/*==============================================================*/
create table dbo.LOGSHIPPING_RESTORE_LIST (
   user_db_name         sysname              not null,
   seq_no               int                  not null,
   backup_no            int                  not null,
   log_file             nvarchar(200)        not null,
   copy_flag            tinyint              not null constraint DF__LOGSHIPPING_RESTORE_LIST__COPY_FLAG default 0,
   copy_end_time        datetime             null,
   restore_type         smallint             not null constraint DF__LOGSHIPPING_RESTORE_LIST__RESTORE_TYPE default 1,
   restore_flag         smallint             not null constraint DF__LOGSHIPPING_RESTORE_LIST__RESTORE_FLAG default 0,
   restore_start_time   datetime             null,
   restore_end_time     datetime             null,
   restore_duration     int                  not null constraint DF__LOGSHIPPING_RESTORE_LIST__RESTORE_DURATION default 0,
   delete_flag          tinyint              not null constraint DF__LOGSHIPPING_RESTORE_LIST__DELETE_FLAG default 0,
   delete_time          datetime             null,
   error_code           int                  not null constraint DF__LOGSHIPPING_RESTORE_LIST__ERROR_CODE default 0,
   reg_dt               datetime             not null constraint DF__LOGSHIPPING_RESTORE_LIST__REG_DT default GETDATE()
)
go

alter table dbo.LOGSHIPPING_RESTORE_LIST
   add constraint PK_LOGSHIPPING_RESTORE_LIST primary key  (user_db_name, seq_no)
      on "PRIMARY"
go

if exists (select 1
            from  sysindexes
           where  id    = object_id('dbo.LOGSHIPPING_RESTORE_LIST')
            and   name  = 'IDX__LOGISHIPPING_RESTORE_LIST__RESTORE_FLAG'
            and   indid > 0
            and   indid < 255)
   drop index dbo.LOGSHIPPING_RESTORE_LIST.IDX_IDX__LOGISHIPPING_RESTORE_LIST__RESTORE_FLAG
go

/*==============================================================*/
/* Index: IDX_IDX__LOGISHIPPING_RESTORE_LIST__RESTORE_FLAG      */
/*==============================================================*/
create   index IDX__LOGISHIPPING_RESTORE_LIST__RESTORE_FLAG on dbo.LOGSHIPPING_RESTORE_LIST (
restore_flag ASC
)
on "PRIMARY"
go



--INSERT INTO LOGSHIPPING_RESTORE_LIST
--SELECT 'SETTLE', seqno, 0, log_file, 
--        CASE  WHEN copy_y = 'Y' THEN 1
--              WHEN copy_y = 'N' THEN 2
--              WHEN copy_y is null THEN 0
--        END copy_flag,
--        copy_end_time,
--        CASE WHEN backup_type = 'N' THEN 1
--             WHEN backup_type = 'L' THEN 2
--        END restore_type,
--        CASE  WHEN restore_y = 'Y' THEN 1
--              WHEN restore_y = 'N' THEN 2
--              WHEN restore_y is null THEN 0
--        END restore_flag,
--        start_time , end_time, duration, 
--        CASE  WHEN delete_y = 'Y' THEN 1
--              WHEN delete_y = 'N' THEN 2
--              WHEN delete_y is null THEN 0
--        END delete_y,
--        delete_time, isnull(err, 0), copy_end_time
--FROM logshipping_list_settle


-- Main에 실행
--INSERT INTO dbo.logshipping_backup_list
--SELECT  'SETTLE', seqno, 0, log_file, 2, 
--        CASE WHEN backup_y = 'Y' THEN 1
--             WHEN backup_y = 'N' THEN 2
--             WHEN backup_y IS NULL THEN 0
--        END backup_flag,
--        backup_start_time, backup_end_time, isnull(backup_duration,0),
--        CASE WHEN delete_y = 'Y' THEN 1
--            WHEN delete_y = 'N' THEN 2
--            WHEN delete_y IS NULL THEN 0
--        END delete_flag, delete_time, isnull(err, 0),
--        1,1,1, reg_dt
--FROM dbo.backup_List_settle