/*****************************************************************************************************************   
. 작 성 자: 전세환   
. 작 성 일: 2015-02-02   
. 유지보수: GmarketDBA팀 전세환   
. 기능구분: DB 전체 Index 정보 수집
. 실행예제    
  - exec UP_DBA_COLLECT_INDEX_ALL_DBs
*****************************************************************************************************************   
변경내역:   
        수정일자        수정구분        수정자        수정내용   
==========================================================================   
       2015-02-02                    전세환        신규생성 
	   2015-07-14					 최보라		  offline , unused 제거
*****************************************************************************************************************/  
ALTER PROCEDURE dbo.UP_DBA_COLLECT_INDEX_ALL_DBs
	@SERVER_NAME nvarchar(800)
AS
BEGIN
	SET NOCOUNT ON  

	DECLARE @currDB SYSNAME 

	IF @SERVER_NAME = 'GCENTERDB'
	BEGIN
		DECLARE DBs CURSOR READ_ONLY
		FOR
			SELECT  name
				FROM sys.databases A WITH(NOLOCK) 
				WHERE ( name not like '%DBMON%'  and name not like '%unused%' and name != 'storage')
					and database_id > 4
						AND NAME NOT IN (select dbname from tb_Sync_DB with(nolock))
						AND NAME NOT IN ( SELECT dbname FROM DBLIST WITH(NOLOCK) WHERE RESTORE_HOW = 'RESTORE')
					  and state = 0 -- online
					  and user_access =0 -- MULTI_USER
				ORDER BY NAME


				
	END
	ELSE IF @SERVER_NAME = 'GACCOUNTDB'
	BEGIN
		DECLARE DBs CURSOR READ_ONLY
		FOR
			SELECT  name
				FROM sys.databases A WITH(NOLOCK) 
				WHERE ( name not like '%DBMON%'  and name not like '%unused%' and name != 'storage')
					and database_id > 4
					-- 싱크서버에서도 사용되는지 확인 해야 함
					  AND NAME NOT IN (select dbname from tb_Sync_DB with(nolock))
					  and state = 0 -- online
					  and user_access =0 -- MULTI_USER
				ORDER BY NAME 
	END
	ELSE
	BEGIN
		DECLARE DBs CURSOR READ_ONLY
		FOR
			   SELECT  name
				FROM	sys.databases 
				WHERE ( name not like '%DBMON%'  and name not like '%unused%')
					  and database_id > 4
					  and state = 0 -- online
					  and user_access =0 -- MULTI_USER
				ORDER BY NAME 
	END


	OPEN DBs

	FETCH NEXT FROM DBs INTO @currDB
	WHILE ( @@fetch_status <> -1 ) 
		BEGIN

			EXEC DBA..UP_DBA_COLLECT_INDEX_DETAIL @currDB
			
			SELECT @currDB
			FETCH NEXT FROM DBs INTO @currDB
		END

	CLOSE DBs
	DEALLOCATE DBs
END





