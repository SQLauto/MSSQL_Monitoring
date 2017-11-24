-- =========================
-- 테이블 모든 목록
-- =========================

-- =============================
-- SQL 2000용
-- =============================

declare @tab varchar(256)
declare tabinfo cursor for

select name from sysobjects where xtype='u' order by name --사용자 정의 테이블

open tabinfo
fetch from tabinfo into @tab
    while @@fetch_status=0
        begin
            select @tab,
                syscolumns.name,
                ISNULL(value, '') as FLD_DESC,
                systypes.name,
                syscolumns.length,
                case isnullable when 0 then 'NOT NULL' else 'NULL'
                end 'Nullable'
            from
                syscolumns,
                systypes,
                ::fn_listextendedproperty (NULL, 'user', 'dbo', 'table',
                @tab, 'column', default)
            where
                syscolumns.id=object_id(@tab)
                and syscolumns.xusertype =systypes.xusertype
                and syscolumns.name *= objname
            order by colid
            
            fetch from tabinfo into @tab
        end
close tabinfo
deallocate tabinfo