USE EMS
GO
/*************************************************************************  
* 프로시저명  : dbo.up_DBA_Insert_sp_change_list
* 작성정보    : 2007-10-30 김태환
* 관련페이지  :  
* 내용        : 변경 sp 목록 메일 발송
* 수정정보    : 
* 실행문      : EXEC dbo.up_DBA_Insert_sp_change_list '받는사람', '메일내용'
**************************************************************************/
CREATE PROC dbo.up_DBA_Insert_sp_change_list
	@strHtml			text
AS
	set nocount on

	INSERT INTO dbo.auto_backend_admin_daemon
	(
		email
	,	from_name
	,	from_email
	,	title
	,	content
	)
	VALUES
	(
		'DB@gmarket.co.kr'
	,	'DBA'
	,	'dba@gmarket.co.kr'
	,	cast(convert(char(10), getdate(), 121) as char(10)) + '일자 SP CREATE/ALTER LIST입니다.'
	,	@strHtml
	)

	IF @@ERROR = 0 AND @@ROWCOUNT = 1
	BEGIN
		RETURN 1
	END
	ELSE
	BEGIN
		RETURN -1
	END

	set nocount off


