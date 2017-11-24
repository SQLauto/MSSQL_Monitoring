-- ===========================
-- 파일 사용현황
-- ===========================
select a.name, b.dbid, b.name, b.filename,  ((b.Size * 8) / 1024.0) as 'Size(MB)'
from dbo.sysdatabases a, dbo.sysaltfiles b with (nolock)
where a.dbid = b.dbid
        and b.dbid > 7