create procedure sp_blockinglocks2   
as  
set nocount on  
 select  DISTINCT convert (smallint, l1.req_spid) As spid,   
  l1.rsc_dbid As dbid,   
  l1.rsc_objid As ObjId,  
  l1.rsc_indid As IndId,  
  substring (v.name, 1, 4) As Type,  
  substring (l1.rsc_text, 1, 16) as Resource,  
  substring (u.name, 1, 8) As Mode,  
  substring (x.name, 1, 5) As Status  
 from  master.dbo.syslockinfo l1,  
  master.dbo.syslockinfo l2,  
  master.dbo.spt_values v,  
  master.dbo.spt_values x,  
  master.dbo.spt_values u  
 where          l1.rsc_type = v.number  
   and v.type = 'LR'  
   and l1.req_status = x.number  
   and x.type = 'LS'  
   and l1.req_mode + 1 = u.number  
   and u.type = 'L'  
   and l1.rsc_type <>2 /* not a DB lock */  
   and l1.rsc_dbid = l2.rsc_dbid  
   and l1.rsc_bin = l2.rsc_bin  
                        and l1.rsc_objid = l2.rsc_objid   
   and l1.rsc_indid = l2.rsc_indid   
   and l1.req_spid <> l2.req_spid  
   and l1.req_status <> l2.req_status  
   --and (l1.req_spid in (select blocked from master..sysprocesses)  
   -- or l2.req_spid in (select blocked from master..sysprocesses))  
 order by substring (l1.rsc_text, 1, 16), substring (x.name, 1, 5)   
return (0) -- sp_blockinglocks 