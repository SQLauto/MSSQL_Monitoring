-- =======================================
--  sp_depends 에서 찾지 못할 경우
-- =======================================

select distinct schema_name(obj.schema_id) + '.' + obj.name as name
from sys.objects as obj with (nolock)
	inner join sys.syscomments as txt with (nolock) on obj.object_id = txt.id
where obj.type = 'P'
	and schema_name(obj.schema_id) in ('dbo', 'backend', 'goodsdaq')
	and txt.text like '%custmileh%'
order by name asc


-- 컬럼에 해당하는 객체 찾기
select distinct schema_name(obj.schema_id) + '.' + obj.name as name
from sys.objects as obj with(nolock)
inner join sys.all_columns as col on obj.object_id = col.object_id 
where type = 'U'
and col.name in ('contr_no', 'pack_no')


--=================================
--JOB에 등록되어 있는 프로시저 인지
--=================================
SELECT J.JOB_ID, J.NAME
FROM msdb.dbo.SYSJOBSTEPS AS S WITH (NOLOCK) INNER JOIN msdb.dbo.SYSJOBS AS J WITH (NOLOCK) ON S.JOB_ID = J.JOB_ID
WHERE J.ENABLED = 1 
	AND S.COMMAND LIKE (
		
		)
