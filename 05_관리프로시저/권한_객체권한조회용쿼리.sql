/*----------------------------------------------------
    Date    : 2007-08-30
    Note    : user에 해당하는 객체에 권한 정보 내역 TRAC 작업
              내역을 어떻게 보는지 궁금해서
    No.     :
*----------------------------------------------------*/
    


declare @p1 int
set @p1=434
exec sp_prepexec @p1 output,N'@P1 varchar(8),@P2 varchar(8)',N'UPDATE "tax"."DBO"."X_INVOICE_TBL" set "ISPOSTING" = ''1''  WHERE "INVDATE"=@P1 AND "INVSEQ"=@P2','20070828','00001689'
select @p1


-- 1. 사용자 계정 확인
select s.*, l.name as login from sysusers s with(nolock) left join master..syslogins l on  s.sid=l.sid where s.uid= 5

-- 2. db_owner 확인
select u.name, u.uid from sysmembers m with(nolock ) left join sysusers u on m.groupuid= u.uid where m.memberuid = 5

select s.*, l.name as login from sysusers s with(nolock) left join master..syslogins l on  s.sid=l.sid where s.uid= 5


--3. 코드 페이지
select c.name,c.description from master.dbo.syscharsets c where c.id = convert(tinyint, databasepropertyex ( db_name() , 'sqlcharset'))  set quoted_identifier off 

select convert(sysname, serverproperty(N'servername'))

SELECT ISNULL(SUSER_SNAME(), SUSER_NAME())

SELECT ISNULL(SUSER_SNAME(), SUSER_NAME())


-- 4. 확인 작업

select s.*, l.name as login from sysusers s with(nolock) left join master..syslogins l on  s.sid=l.sid where s.uid= 6

select u.name, u.uid from sysmembers m with(nolock ) left join sysusers u on m.groupuid= u.uid where m.memberuid = 6
select name, owner = schema_name(schema_id), xtype=type, id=object_id from sys.objects o where type in ('AF', 'P', 'PC', 'FN', 'FS', 'FT', 'SN', 'IF', 'TF', 'U', 'V') and o.name not like N'#%'  and o.name not like 'dt[_]%' and (OBJECTPROPERTY(o.object_id, N'IsSystemTable') = 0)  order by name, owner

select a = o.name, b = user_name(o.uid), action, protecttype from dbo.sysobjects o left join dbo.sysprotects p on o.id = p.id, master.dbo.spt_values a where (( p.action in (193, 197) and ((p.columns & 1) = 1) ) or ( p.action in (195, 196, 224, 26) )) and (convert(tinyint, substring( isnull(p.columns, 0x01), a.low, 1)) & a.high != 0) and a.type = N'P' and a.number = 0 and p.uid = 6  and o.name not like 'dt[_]%' and (OBJECTPROPERTY(o.id, N'IsSystemTable') = 0) 