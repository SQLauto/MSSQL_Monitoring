
CREATE TABLE CODE_MASTER
(
    code_master_id      int  not null, 
    code_master_type    nvarchar(50)  not null,
    code_master_desc   nvarchar(500) null,
    reg_dt              datetime     constraint DF__CODE_MASTER__REG_DT DEFAULT (getdate()),
    chg_dt datetime null,
   CONSTRAINT PK__CODE_MASTER__CODE_MASTER_ID  PRIMARY KEY CLUSTERED (code_master_id) 
) ON [JOBMNG_DATA_FG1]


CREATE TABLE CODE_DETAIL
(
    code_master_id      int  not null,
    code_id             int not null,
    code_value          nvarchar(50) not null,
    code_desc           nvarchar(500) null,
    reg_dt              datetime     constraint DF__CODE_DETAIL__REG_DT DEFAULT (getdate()),
    chg_dt datetime null,
 CONSTRAINT PK__CODE_DETAIL__CODE_MASTER_ID__CODE_ID PRIMARY KEY CLUSTERED (code_master_id, code_id)
) ON [JOBMNG_DATA_FG1]

INSERT INTO CODE_MASTER  (code_master_id, code_master_type, code_master_desc, reg_dt, chg_dt)
values (1, 'ALERT Type Code', 'DB,시스템 경고성 문자,메일발송 코드', getdate(), getdate())

insert into code_detail(code_master_id, code_id, code_value, code_desc, reg_dt, chg_dt)
values (1, 10, 'system alert', 'DB시스템경고', getdate(), getdate())
insert into code_detail(code_master_id, code_id, code_value, code_desc, reg_dt, chg_dt)
values (1, 20, 'db backup alert', 'db backup 경고', getdate(), getdate())
insert into code_detail(code_master_id, code_id, code_value, code_desc, reg_dt, chg_dt)
values (1, 30, 'job alert', 'job 경고', getdate(), getdate())
insert into code_detail(code_master_id, code_id, code_value, code_desc, reg_dt, chg_dt)
values (1, 40, 'business alert', '업무 경고', getdate(), getdate())
insert into code_detail(code_master_id, code_id, code_value, code_desc, reg_dt, chg_dt)
values (1, 99, 'ALL alert', '모든경고', getdate(), getdate())
