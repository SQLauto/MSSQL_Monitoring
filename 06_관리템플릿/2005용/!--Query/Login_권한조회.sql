/*-----------------------------------------------

       로그인해서서버권한, 데이버베이스권한조회

-------------------------------------------------*/

--======================
--1. 서버수준의권한
--======================

select  spr.name, spr.type_desc,
             spr.default_database_name, spr.default_language_name,
             spm.class_desc, spm.permission_name, spm.state_desc,
             suser_name(srm.role_principal_id) as server_role_name
from sys.server_principals as spr with (nolock)
       inner join sys.server_permissions as spm (nolock) on spm.grantee_principal_id = spr.principal_id
       left join sys.server_role_members as srm with (nolocK) on spr.name = suser_name(srm.member_principal_id)
where spr.type in ('S','U','C', 'K','R')
       --and spr.name = 'dba'  -- 유저로하나찾기
order by spr.type,spr.name



-- 유저하나의role member 보기
select suser_name(role_principal_id), suser_name(member_principal_id)
from sys.server_role_members where member_principal_id = suser_id('dba')



--====================================
--2 DB별권한
--====================================

use testdb
go

select dpr.name, dpr.type_desc, dpr.default_schema_name,
	          dpm.class_desc,
	          case  when dpm.major_id = 0 then 'ALL' else obj.name end as object_name,
             dpm.permission_name, dpm.state_desc
from sys.database_principals as dpr with (nolock)
       inner join sys.database_permissions as dpm with (nolock) on dpr.principal_id = dpm.grantee_principal_id
       left outer join sys.all_objects as obj with (nolock) on dpm.major_id = obj.object_id
--where dpr.name = 'dba' -- 하나의유저찾기
order by dpr.type, dpr.name

   

-- 유저의role member 보기
select dpr.name, dpr.type_desc, dpr.default_schema_name,
       user_name(drm.member_principal_id) as user_name, drm.member_principal_id,
       user_name(drm.role_principal_id) as role_name,drm.role_principal_id
from  sys.database_principals as dpr with (nolock)
       inner join sys.database_permissions as dpm with (nolock) on dpr.principal_id = dpm.grantee_principal_id 
       inner join sys.database_role_members drm with (nolock)  on dpr.principal_id = drm.member_principal_id
where dpr.type <> 'R' -- DATABASE_ROLE

