--==============================
--�α� ���� ����
--===============================
DBCC LOG (<userdbname, sysname, user_dbname>)

-- �ڼ��� ����
DBCC LOG (<userdbname, sysname, user_dbname>, 1)
GO


--����: �����м��⿡�� ������ ���� �Է�����.
--�Ķ����:
--dbid|dbname - �����ͺ��̽� ���̵�(ID) Ȥ�� �̸�
--type - ��¿ɼ�
--0 - �ּ� ���� (operation, context, transaction id) :
--�⺻��
--1 - ���� ���� ���� (plus flags, tags, row length,
--description)
--2 - �ſ� �ڼ��� ���� (plus object name, index
--name, page id, slot id)
--3 - �� �۾�(operation)�� ��� ����
--4 - �� �۾�(operation)�� ��� ������ �Բ�
--���� Ʈ����� �α� ���� �ٻ� ����(hexadecimal
--dump) ����
---1 - �� �۾�(operation)�� ��� ������ �Բ�
--���� Ʈ����� �α� ���� �ٻ� ����
--(hexadecimal dump)�� �Բ�
--Checkpoint Begin, DB Version, Max XDESID
--master �����ͺ��̽��� Ʈ����� �α׸� ���� ���ؼ���
--�Ʒ��� ���� �����ϸ� �ȴ�.
--���� ���� MS-SQL������ ��ť��Ʈ ���� �ʴ� �� ����
--��ɾ ������ �Ѵٸ�
--http://www.sql-server-performance.com/ac_sql_
--server_2000_undocumented_dbcc.asp ��⸦ ��������.
--DBCC LOG�� �� ���� DBCC ��ɾ �� �ִµ�,
--DBCC LOG����� ���� ����� ��ȸ�� ���� �� ����.
--����)
    DBCC log('pubs', 0)
    DBCC log('pubs', 1)
    DBCC log('pubs', 2)
    DBCC log('pubs', 3)
    DBCC log('pubs', 4)
    DBCC log('pubs', -1)
