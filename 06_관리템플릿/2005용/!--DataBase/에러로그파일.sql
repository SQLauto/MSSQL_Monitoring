--로그 파일의 개수 20으로 변경하기
EXEC master..xp_regwrite 'HKEY_LOCAL_MACHINE'
	, 'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer'
	, 'NumErrorlogs'
	, 'REG_DWORD'
	, 20

EXEC master..xp_regread 'HKEY_LOCAL_MACHINE'
	, 'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer'
	, 'NumErrorlogs'
--NumErrorlogs	20