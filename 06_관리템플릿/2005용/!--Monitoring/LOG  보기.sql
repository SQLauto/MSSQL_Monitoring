--==============================
--로그 정보 보기
--===============================
DBCC LOG (<userdbname, sysname, user_dbname>)

-- 자세히 보기
DBCC LOG (<userdbname, sysname, user_dbname>, 1)
GO


--사용법: 쿼리분석기에서 다음과 같이 입력하자.
--파라미터:
--dbid|dbname - 데이터베이스 아이디(ID) 혹은 이름
--type - 출력옵션
--0 - 최소 정보 (operation, context, transaction id) :
--기본값
--1 - 좀더 많은 정보 (plus flags, tags, row length,
--description)
--2 - 매우 자세한 정보 (plus object name, index
--name, page id, slot id)
--3 - 각 작업(operation)별 모든 정보
--4 - 각 작업(operation)별 모든 정보와 함께
--현재 트랜잭션 로그 행의 핵사 덤프(hexadecimal
--dump) 포함
---1 - 각 작업(operation)별 모든 정보와 함께
--현재 트랜잭션 로그 행의 핵사 덤프
--(hexadecimal dump)와 함께
--Checkpoint Begin, DB Version, Max XDESID
--master 데이터베이스의 트랜잭션 로그를 보기 위해서는
--아래와 같이 실행하면 된다.
--보다 상세한 MS-SQL서버의 다큐먼트 되지 않는 몇 가지
--명령어를 보고자 한다면
--http://www.sql-server-performance.com/ac_sql_
--server_2000_undocumented_dbcc.asp 요기를 참고하자.
--DBCC LOG외 몇 가지 DBCC 명령어가 더 있는데,
--DBCC LOG말고는 별로 사용할 기회가 없는 것 같다.
--예제)
    DBCC log('pubs', 0)
    DBCC log('pubs', 1)
    DBCC log('pubs', 2)
    DBCC log('pubs', 3)
    DBCC log('pubs', 4)
    DBCC log('pubs', -1)
