-- =================================
--  인덱스 조각화
-- =================================

-- 인덱스 조각화 상태 확인
DBCC SHOWCONTIG ('TB명', 'IX명') [WITH FAST]

-- 테이블 조각화 확인
DBCC SHOWCONTIG ('TB명') [WITH FAST]