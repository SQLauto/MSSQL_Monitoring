SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'sp_dba_syscacheobject' 
	   AND 	  type = 'P')
    DROP PROCEDURE  sp_dba_syscacheobject
GO

/**
* Create        : choi bora(ceusee)
* SP Name       : dbo.sp_dba_syscacheobject
* Purpose       : syscacheobejct ���̺� ��ȸ�ؼ� ĳ������ ���Ǵ� ����, ���ν��� ã��
* E-mail        : ceusee@gmail.com
* Create date   : 2007-06-22
* Return Code   :
* Modification Memo :
������ ����ɶ��� Compiled Plan �Ŀ� Executable Plan �̷�����. 
Compiled Plan �� ���� �Ͼ�ٴ� ���� recompiled�� �Ͼ�ٴ� ���̴�. 
**/
CREATE PROCEDURE dbo.sp_dba_syscacheobject
    @dbanme         sysname = null
AS
/* COMMON DECLARE */
SET NOCOUNT ON
DECLARE @errCode        INT


/* USER DECLARE */

/* BODY */
if @dbanme is not null
begin
    select bucketid, dbid, db_name(dbid) as dbname, sql,
        cacheobjtype, objtype, objid,
        dbidexec, usecounts, refcounts, pagesused, setopts, sqlbytes
    from master..syscacheobjects with (nolock)
    where objtype <> 'Systab'
        and dbid = db_id(@dbanme)
    order by dbid, usecounts desc, objid
end
else
begin
    select bucketid, dbid, db_name(dbid) as dbname, sql,
        cacheobjtype, objtype, objid,
        dbidexec, usecounts, refcounts, pagesused, setopts, sqlbytes
    from master..syscacheobjects with (nolock)
    where objtype <> 'Systab' 
    order by dbid, usecounts desc, objid
end

if @@ERROR <> 0 RETURN -1
RETURN

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


grant all on sp_dba_syscacheobject to public
GO