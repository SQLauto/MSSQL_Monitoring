USE MASTER
GO
create procedure sp_mon_lock2
@spid1 int = NULL,      /* server process id to check for locks */
@spid2 int = NULL       /* other process id to check for locks */
as

set nocount on
/*
** Show the locks for both parameters.
*/
declare @objid int,
   @indid int,
   @dbid int,
   @string Nvarchar(255)

CREATE TABLE #locktable
   (
   spid       smallint
   ,loginname nvarchar(20)
   ,hostname  nvarchar(30)
   ,dbid      int
   ,dbname    nvarchar(20)
   ,ObjOwner  nvarchar(128)
   ,objId     int
   ,ObjName   nvarchar(128)
   ,IndId     int
   ,IndName   nvarchar(128)
   ,Type      nvarchar(4)
   ,Resource  nvarchar(16)
   ,Mode      nvarchar(8)
   ,Status    nvarchar(5)
   )

if @spid1 is not NULL
begin
   INSERT #locktable
      (
      spid
      ,loginname
      ,hostname
      ,dbid
      ,dbname
      ,ObjOwner
      ,objId
      ,ObjName
      ,IndId
      ,IndName
      ,Type
      ,Resource
      ,Mode
      ,Status
      )
   select convert (smallint, l.req_spid)
      ,coalesce(substring (s.loginame, 1, 20),'')
      ,coalesce(substring (s.hostname, 1, 30),'')
      ,l.rsc_dbid
      ,substring (db_name(l.rsc_dbid), 1, 20)
      ,''
      ,l.rsc_objid
      ,''
      ,l.rsc_indid
      ,''
      ,substring (v.name, 1, 4)
      ,substring (l.rsc_text, 1, 16)
      ,substring (u.name, 1, 8)
      ,substring (x.name, 1, 5)
   from master.dbo.syslockinfo l,
      master.dbo.spt_values v,
      master.dbo.spt_values x,
      master.dbo.spt_values u,
      master.dbo.sysprocesses s
   where l.rsc_type = v.number
   and   v.type = 'LR'
   and   l.req_status = x.number
   and   x.type = 'LS'
   and   l.req_mode + 1 = u.number
   and   u.type = 'L'
   and   req_spid in (@spid1, @spid2)
   and   req_spid = s.spid
end
/*
** No parameters, so show all the locks.
*/
else
begin
   INSERT #locktable
      (
      spid
      ,loginname
      ,hostname
      ,dbid
      ,dbname
      ,ObjOwner
      ,objId
      ,ObjName
      ,IndId
      ,IndName
      ,Type
      ,Resource
      ,Mode
      ,Status
      )
   select convert (smallint, l.req_spid)
      ,coalesce(substring (s.loginame, 1, 20),'')
      ,coalesce(substring (s.hostname, 1, 30),'')
      ,l.rsc_dbid
      ,substring (db_name(l.rsc_dbid), 1, 20)
      ,''
      ,l.rsc_objid
      ,''
      ,l.rsc_indid
      ,''
      ,substring (v.name, 1, 4)
      ,substring (l.rsc_text, 1, 16)
      ,substring (u.name, 1, 8)
      ,substring (x.name, 1, 5)
   from master.dbo.syslockinfo l,
      master.dbo.spt_values v,
      master.dbo.spt_values x,
      master.dbo.spt_values u,
      master.dbo.sysprocesses s
   where l.rsc_type = v.number
   and   v.type = 'LR'
   and   l.req_status = x.number
   and   x.type = 'LS'
   and   l.req_mode + 1 = u.number
   and   u.type = 'L'
   and   req_spid = s.spid
   order by spID
END
DECLARE lock_cursor CURSOR
FOR SELECT dbid, ObjId, IndId FROM #locktable
  WHERE Type <>'DB' and Type <> 'FIL'

OPEN lock_cursor
FETCH NEXT FROM lock_cursor INTO @dbid, @ObjId, @IndId
WHILE @@FETCH_STATUS = 0
   BEGIN

   SELECT @string =
      'USE ' + db_name(@dbid) + char(13)
      + 'update #locktable set ObjName = name, ObjOwner = USER_NAME(uid)'
      + ' from sysobjects where id = ' + convert(varchar(32),@objid)
      + ' and ObjId = ' + convert(varchar(32),@objid)
      + ' and dbid = ' + convert(varchar(32),@dbId)

   EXECUTE (@string)

   SELECT @string =
      'USE ' + db_name(@dbid) + char(13)
      + 'update #locktable set IndName = i.name from sysindexes i '
      + ' where i.id = ' + convert(varchar(32),@objid)
      + ' and i.indid = ' + convert(varchar(32),@indid)
      + ' and ObjId = ' + convert(varchar(32),@objid)
      + ' and dbid = ' + convert(varchar(32),@dbId)
      + ' and #locktable.indid = ' + convert(varchar(32),@indid)

   EXECUTE (@string)

   FETCH NEXT FROM lock_cursor INTO @dbid, @ObjId, @IndId
   END
CLOSE lock_cursor
DEALLOCATE lock_cursor

SELECT * FROM #locktable
return (0)
-- END sp_lock2
GO
