-- =========================
--  ���� ���� Ȯ��
-- ========================
--���� ����
select serverproperty('servername') as ServerName
,serverproperty('machinename') as machinename
,serverproperty('instancename') as instancename
,serverproperty('edition') as edition
,serverproperty('productversion') as productversion
,serverproperty('productlevel') as productlevel