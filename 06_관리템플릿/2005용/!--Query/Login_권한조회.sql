/*-----------------------------------------------

       �α����ؼ���������, ���̹����̽�������ȸ

-------------------------------------------------*/

--======================
--1. ���������Ǳ���
--======================

select  spr.name, spr.type_desc,
             spr.default_database_name, spr.default_language_name,
             spm.class_desc, spm.permission_name, spm.state_desc,
             suser_name(srm.role_principal_id) as server_role_name
from sys.server_principals as spr with (nolock)
       inner join sys.server_permissions as spm (nolock) on spm.grantee_principal_id = spr.principal_id
       left join sys.server_role_members as srm with (nolocK) on spr.name = suser_name(srm.member_principal_id)
where spr.type in ('S','U','C', 'K','R')
       --and spr.name = 'dba'  -- �������ϳ�ã��
order by spr.type,spr.name



-- �����ϳ���role member ����
select suser_name(role_principal_id), suser_name(member_principal_id)
from sys.server_role_members where member_principal_id = suser_id('dba')



--====================================
--2 DB������
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
--where dpr.name = 'dba' -- �ϳ�������ã��
order by dpr.type, dpr.name

   

-- ������role member ����
select dpr.name, dpr.type_desc, dpr.default_schema_name,
       user_name(drm.member_principal_id) as user_name, drm.member_principal_id,
       user_name(drm.role_principal_id) as role_name,drm.role_principal_id
from  sys.database_principals as dpr with (nolock)
       inner join sys.database_permissions as dpm with (nolock) on dpr.principal_id = dpm.grantee_principal_id 
       inner join sys.database_role_members drm with (nolock)  on dpr.principal_id = drm.member_principal_id
where dpr.type <> 'R' -- DATABASE_ROLE

