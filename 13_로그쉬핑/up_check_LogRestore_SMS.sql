

/*************************************************************************  
* ���ν�����  : dbo.up_check_LogRestore_SMS 
* �ۼ�����    : 2006-11-16	������
* ����������  :  
* ����        : ��ȸ�� DB Live üũ�� SMS �޼��� �߼�
                REFER ������ SUBDB3
                ���� �ֱ� : �� ~ �� 8:54 ~ 18:54 �� ���� �Ž� 55�� ����
			    ��      8:54 ~ 12:54 ��
* ��������    :
**************************************************************************/
CREATE	PROCEDURE dbo.up_check_LogRestore_SMS
as
	declare @hour int,	@isRestore	int,	@msg varchar(50)


 	--	10���� �ð�����
 	select @hour = datepart(hh, getdate())


	--	��ȸ��DB ���� ���� üũ
	if @hour % 2 = 1
	begin
		-- Ȧ��
		EXEC @isRestore =  subdb3.dba.dbo.up_logrestore_result
		set @msg = convert(varchar(2),@hour) + '�� ��ȸ��DB(subdb3)�� ���� ������.'
	end
	else 
	begin
		-- ¦��
		EXEC @isRestore =  superdb1.dba.dbo.up_logrestore_result
		set @msg = convert(varchar(2),@hour) + '�� ��ȸ��DB(superdb1)�� ���� ������.'
	end


	-- ���� ���� ���� ��ȸ��DB�� 55�б����� �������̸� SMS �߼�
	if @isRestore = 1 
	begin
		--exec dbo.up_kidcsms_send_SMS '0162609654', @msg					-- ������
		exec dbo.up_kidcsms_send_SMS '0164436001', @msg					-- ������
		exec dbo.up_kidcsms_send_SMS '0162920001', @msg					-- �迵ȣ
		exec dbo.up_kidcsms_send_SMS '01190214129', @msg					-- ������
		exec dbo.up_kidcsms_send_SMS '0177162542', @msg					-- ����ȯ
		exec dbo.up_kidcsms_send_SMS '01071740589', @msg					-- �̻���
	end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO