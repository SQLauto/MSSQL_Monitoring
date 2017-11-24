-- =======================================
--  sp_depends ���� ã�� ���� ���
-- =======================================

select distinct schema_name(obj.schema_id) + '.' + obj.name as name
from sys.objects as obj with (nolock)
	inner join sys.syscomments as txt with (nolock) on obj.object_id = txt.id
where obj.type = 'P'
	and schema_name(obj.schema_id) in ('dbo', 'backend', 'goodsdaq')
	and txt.text like '%custmileh%'
order by name asc


-- �÷��� �ش��ϴ� ��ü ã��
select distinct schema_name(obj.schema_id) + '.' + obj.name as name
from sys.objects as obj with(nolock)
inner join sys.all_columns as col on obj.object_id = col.object_id 
where type = 'U'
and col.name in ('contr_no', 'pack_no')


--=================================
--JOB�� ��ϵǾ� �ִ� ���ν��� ����
--=================================
SELECT J.JOB_ID, J.NAME
FROM msdb.dbo.SYSJOBSTEPS AS S WITH (NOLOCK) INNER JOIN msdb.dbo.SYSJOBS AS J WITH (NOLOCK) ON S.JOB_ID = J.JOB_ID
WHERE J.ENABLED = 1 
	AND S.COMMAND LIKE (
		
		)
