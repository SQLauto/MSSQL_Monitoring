-- =========================
--  서버 정보 확인
-- ========================
--서버 정보
select serverproperty('servername') as ServerName
,serverproperty('machinename') as machinename
,serverproperty('instancename') as instancename
,serverproperty('edition') as edition
,serverproperty('productversion') as productversion
,serverproperty('productlevel') as productlevel