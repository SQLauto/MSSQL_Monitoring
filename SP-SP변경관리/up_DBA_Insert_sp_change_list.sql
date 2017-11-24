USE EMS
GO
/*************************************************************************  
* ���ν�����  : dbo.up_DBA_Insert_sp_change_list
* �ۼ�����    : 2007-10-30 ����ȯ
* ����������  :  
* ����        : ���� sp ��� ���� �߼�
* ��������    : 
* ���๮      : EXEC dbo.up_DBA_Insert_sp_change_list '�޴»��', '���ϳ���'
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
	,	cast(convert(char(10), getdate(), 121) as char(10)) + '���� SP CREATE/ALTER LIST�Դϴ�.'
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


