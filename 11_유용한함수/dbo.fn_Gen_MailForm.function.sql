/****** ??:  UserDefinedFunction [dbo].[fn_Gen_MailForm]    ???? ??: 06/21/2007 15:33:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--DROP  FUNCTION [dbo].fn_Gen_MailForm

CREATE  FUNCTION [dbo].fn_Gen_MailForm(
	@strTitle			varchar(200), 
	@strOpNm		varchar(50), 
	@strRunTime		varchar(20), 
	@strMessage		varchar(2000),
	@strStep			varchar(20)
)
RETURNS varchar(7000)
AS
BEGIN

	DECLARE	@strMail		varchar(7000)

	SET @strMail = '<html>'
	SET @strMail = @strMail + '<head></head>'
	SET @strMail = @strMail + '<body marginwidth=0 marginheight=0 topmargin=0 leftmargin=0>'
	SET @strMail = @strMail + '<table width=100% cellpadding=0 cellspacing=0 border=0>'
	SET @strMail = @strMail + '<tr>'
	SET @strMail = @strMail + '	<td height=30>&nbsp;</td>'
	SET @strMail = @strMail + '</tr>'
	SET @strMail = @strMail + '<tr>'
	SET @strMail = @strMail + '	<td align=left>'
	SET @strMail = @strMail + '	<table width=600 cellpadding=0 cellspacing=0 border=0 style=font-size:14px;font-name:??;>'
	SET @strMail = @strMail + '	<tr>'
	SET @strMail = @strMail + '		<td><b>? JOB ?? ?????.</b></td>'
	SET @strMail = @strMail + '	</tr>'
	SET @strMail = @strMail + '	</table>'
	SET @strMail = @strMail + '	</td>'
	SET @strMail = @strMail + '</tr>'
	SET @strMail = @strMail + '<tr>'
	SET @strMail = @strMail + '	<td align=left>'
	SET @strMail = @strMail + '	<table width=600 cellpadding=2 cellspacing=0 border=1 bordercolorlight=#CCCCCC bordercolordark=#FFFFFF style=font-size:12px;font-name:??;>'
	SET @strMail = @strMail + '	<tr>'
	SET @strMail = @strMail + '		<td width=100 height=25 bgcolor=#C0C0C0 align=center><b>??</b></td>'
	SET @strMail = @strMail + '		<td width=500 bgcolor=#FFFFFF align=left><@TITLE@></td>'
	SET @strMail = @strMail + '	</tr>'
	SET @strMail = @strMail + '	<tr>'
	SET @strMail = @strMail + '		<td bgcolor=#C0C0C0 align=center><b>???</b></td>'
	SET @strMail = @strMail + '		<td bgcolor=#FFFFFF align=left><@OP_NM@></td>'
	SET @strMail = @strMail + '	</tr>'
	SET @strMail = @strMail + '	<tr>'
	SET @strMail = @strMail + '		<td bgcolor=#C0C0C0 align=center><b>????</b></td>'
	SET @strMail = @strMail + '		<td bgcolor=#FFFFFF align=left><@EXECUTE_TIME@></td>'
	SET @strMail = @strMail + '	</tr>'
	SET @strMail = @strMail + '	<tr>'
	SET @strMail = @strMail + '		<td bgcolor=#C0C0C0 align=center><b>??</b></td>'
	SET @strMail = @strMail + '		<td bgcolor=#FFFFFF align=left><@STEP@></td>'
	SET @strMail = @strMail + '	</tr>'
	SET @strMail = @strMail + '	<tr>'
	SET @strMail = @strMail + '		<td bgcolor=#C0C0C0 align=center><b>???</b></td>'
	SET @strMail = @strMail + '		<td bgcolor=#FFFFFF align=left><@MESSAGE@></td>'
	SET @strMail = @strMail + '	</tr>'
	SET @strMail = @strMail + '	</table>'
	SET @strMail = @strMail + '	</td>'
	SET @strMail = @strMail + '</tr>'
	SET @strMail = @strMail + '</table>'
	SET @strMail = @strMail + '</body>'
	SET @strMail = @strMail + '</html>'

	-- ?? ???
	SET @strMail = REPLACE(@strMail, '<@TITLE@>', @strTitle)

	-- ??? ???
	SET @strMail = REPLACE(@strMail, '<@OP_NM@>', @strOpNm)

	-- ????
	SET @strMail = REPLACE(@strMail, '<@EXECUTE_TIME@>', @strRunTime)
	
	-- ????
	SET @strMail = REPLACE(@strMail, '<@STEP@>', @strStep)

	-- ?? ???
	SET @strMail = REPLACE(@strMail, '<@MESSAGE@>', @strMessage)

	RETURN @strMail

END




GO
