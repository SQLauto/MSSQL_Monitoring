SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_logshipping_check_status' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_logshipping_check_status
*/
/*************************************************************************  
* ���ν�����  : dbo.up_DBA_logshipping_check_status 
* �ۼ�����    : 2006-11-16	������
* ����������  :  
* ����        : ��ȸ�� DB Live üũ�� SMS �޼��� �߼�
                REFER ������ SUBDB3
                ���� �ֱ� : �� ~ �� 8:54 ~ 18:54 �� ���� �Ž� 55�� ����
			    ��      8:54 ~ 12:54 ��
* ��������    : 2007-08-12 by �ֺ���
                ���ν��� ����ȭ�� ���� �̸� ����, ���� ����
**************************************************************************/
CREATE	PROCEDURE dbo.up_DBA_logshipping_check_status
    @user_db_name       SYSNAME
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
declare @hour int,	@isRestore	char(1),	@msg varchar(50)
DECLARE @mi  int


--	10���� �ð�����
select @hour = datepart(hh, getdate())
select @mi = datepart(mi, getdate())

IF @mi > 55
BEGIN

    --	��ȸ��DB ���� ���� üũ
    if @hour % 2 = 1
    begin
    	-- Ȧ��
    	EXEC  dbo.up_DBA_logshipping_status @user_db_name , @isRestore OUTPUT
    	SET @msg = '[' + @@SERVERNAME + ']' + convert(varchar(2),@hour) + '�� ' + @user_db_name + ' ���� ������'
    end
    else 
    begin
    	-- ¦��
    	EXEC dbo.up_DBA_logshipping_status @user_db_name, @isRestore OUTPUT
    	SET @msg = '[' + @@SERVERNAME + ']' + convert(varchar(2),@hour) + '�� ' + @user_db_name + ' ���� ������'
    end
    

    
    	-- ���� ���� ���� ��ȸ��DB�� 55�б����� �������̸� SMS �߼�
    	if @isRestore = 'N' 
    	begin
    		-- ���� �������� �̸����� ��������
    		EXEC dbo.up_DBA_send_sms 1,'0164436001', @MSG					-- ������
    		EXEC dbo.up_DBA_send_sms 1,'0162920001', @MSG					-- �迵ȣ
    		EXEC dbo.up_DBA_send_sms 1,'01190214129', @MSG				-- ������
    		EXEC dbo.up_DBA_send_sms 1,'0177162542', @MSG					-- ����ȯ
    		EXEC dbo.up_DBA_send_sms 1,'0174551104', @msg
    	end
END
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
GO