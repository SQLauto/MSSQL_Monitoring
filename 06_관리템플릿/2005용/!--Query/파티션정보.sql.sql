--============================================
-- 파티션 테이블 확인 프로시저
--============================================
EXEC up_DBA_partition_list    -- 파티션 된 테이블 목록 확인 가능

DECLARE @object_name sysname
EXEC up_DBA_helptable_partition @object_name  -- 테이블 하나의 상세 정보


-- 전체 파티션된 테이블의 범위 정보 DBA 데이터 베이스에 있음
USE DBA
GO

EXEC up_DBA_select_partition_table_info