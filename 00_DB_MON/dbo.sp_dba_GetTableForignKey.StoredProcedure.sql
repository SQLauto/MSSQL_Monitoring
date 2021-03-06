USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[sp_dba_GetTableForignKey]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_dba_GetTableForignKey]    
    @objname  nvarchar(256)   -- the table to check for constraints      
	,@type    char(2)    
	,@nomsg   varchar(5) = 'nomsg'  -- 'nomsg' supresses printing of TBName (sp_help)      
as      
 -- PRELIM      
 set nocount on      
      
 declare @objid   int           -- the object id of the table      
   ,@cnstdes  nvarchar(4000)-- string to build up index desc      
   ,@cnstname  sysname       -- name of const. currently under consideration      
   ,@i    int      
   ,@cnstid  int      
   ,@cnsttype  character(2)      
   ,@keys   nvarchar(2126) --Length (16*max_identifierLength)+(15*2)+(16*3)      
   ,@dbname  sysname      
      
 -- Create temp table      
 CREATE TABLE #spcnsttab      
 (      
  cnst_id   int   NOT NULL      
  ,cnst_type   nvarchar(146) collate database_default NOT NULL   -- 128 for name + text for DEFAULT      
  ,cnst_name   sysname  collate database_default NOT NULL      
  ,cnst_nonblank_name sysname  collate database_default NOT NULL      
  ,cnst_2type   character(2) collate database_default NULL      
  ,cnst_disabled  bit    NULL      
  ,cnst_notrepl  bit    NULL      
  ,cnst_delcasc  bit    NULL      
  ,cnst_updcasc  bit    NULL      
  ,cnst_keys   nvarchar(2126) collate database_default NULL -- see @keys above for length descr      
 )      
      
 -- Check to see that the object names are local to the current database.      
 select @dbname = parsename(@objname,3)      
      
 if @dbname is null      
  select @dbname = db_name()      
 else if @dbname <> db_name()      
  begin      
   raiserror(15250,-1,-1)      
   return (1)      
  end      
      
 -- Check to see if the table exists and initialize @objid.      
 select @objid = object_id(@objname)      
 if @objid is NULL      
 begin      
  raiserror(15009,-1,-1,@objname,@dbname)      
  return (1)      
 end      
      
 -- STATIC CURSOR OVER THE TABLE'S CONSTRAINTS     
 declare ms_crs_cnst cursor local static for      
  select object_id, type, name from sys.objects where parent_object_id = @objid      
   and type = @TYPE -- ('C ','PK','UQ','F ', 'D ') -- ONLY 6.5 sysconstraints objects      
  for read only      
      
 -- Now check out each constraint, figure out its type and keys and      
 -- save the info in a temporary table that we'll print out at the end.      
 open ms_crs_cnst      
 fetch ms_crs_cnst into @cnstid ,@cnsttype ,@cnstname      
 while @@fetch_status >= 0      
 begin      
      
  if @cnsttype in ('PK','UQ')      
  begin      
   -- get indid and index description      
   declare @indid smallint      
   select @indid = index_id,      
     @cnstdes = case when @cnsttype = 'PK'      
        then 'PRIMARY KEY' else 'UNIQUE' end      
        + case when index_id = 1      
        then ' (clustered)' else ' (non-clustered)' end      
   from  sys.indexes      
   where object_id = @objid and name = object_name(@cnstid)      
      
   -- Format keys string      
   declare @thiskey nvarchar(131) -- 128+3      
      
   select @keys = index_col(@objname, @indid, 1), @i = 2      
   if (indexkey_property(@objid, @indid, 1, 'isdescending') = 1)      
    select @keys = @keys  + '(-)'      
      
   select @thiskey = index_col(@objname, @indid, @i)      
   if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))      
    select @thiskey = @thiskey + '(-)'      
      
   while (@thiskey is not null)      
   begin      
    select @keys = @keys + ', ' + @thiskey, @i = @i + 1      
    select @thiskey = index_col(@objname, @indid, @i)      
    if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))      
     select @thiskey = @thiskey + '(-)'      
   end      
      
   -- ADD TO TABLE      
   insert into #spcnsttab      
    (cnst_id,cnst_type,cnst_name, cnst_nonblank_name,cnst_keys, cnst_2type)      
   values (@cnstid, @cnstdes, @cnstname, @cnstname, @keys, @cnsttype)      
  end      
      
  else      
  if @cnsttype = 'F '      
  begin      
   -- OBTAIN TWO TABLE IDs      
   declare @fkeyid int, @rkeyid int      
   select @fkeyid = parent_object_id, @rkeyid = referenced_object_id      
    from sys.foreign_keys where object_id = @cnstid      
      
   -- USE CURSOR OVER FOREIGN KEY COLUMNS TO BUILD COLUMN LISTS      
   -- (NOTE: @keys HAS THE FKEY AND @cnstdes HAS THE RKEY COLUMN LIST)      
   declare ms_crs_fkey cursor local for      
    select parent_column_id, referenced_column_id      
     from sys.foreign_key_columns where constraint_object_id = @cnstid      
   open ms_crs_fkey      
   declare @fkeycol smallint, @rkeycol smallint      
   fetch ms_crs_fkey into @fkeycol, @rkeycol      
   select @keys = col_name(@fkeyid, @fkeycol), @cnstdes = col_name(@rkeyid, @rkeycol)      
   fetch ms_crs_fkey into @fkeycol, @rkeycol      
   while @@fetch_status >= 0      
   begin      
    select @keys = @keys + ', ' + col_name(@fkeyid, @fkeycol),      
      @cnstdes = @cnstdes + ', ' + col_name(@rkeyid, @rkeycol)      
    fetch ms_crs_fkey into @fkeycol, @rkeycol      
   end      
   deallocate ms_crs_fkey      
      
   -- ADD ROWS FOR BOTH SIDES OF FOREIGN KEY      
   insert into #spcnsttab      
    (cnst_id, cnst_type,cnst_name,cnst_nonblank_name,      
     cnst_keys, cnst_disabled,      
     cnst_notrepl, cnst_delcasc, cnst_updcasc, cnst_2type)      
   values      
    (@cnstid, 'FOREIGN KEY', @cnstname, @cnstname,      
     @keys, ObjectProperty(@cnstid, 'CnstIsDisabled'),      
     ObjectProperty(@cnstid, 'CnstIsNotRepl'),      
     ObjectProperty(@cnstid, 'CnstIsDeleteCascade'),      
     ObjectProperty(@cnstid, 'CnstIsUpdateCascade'),      
     @cnsttype)      
   insert into #spcnsttab      
    (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,      
     cnst_keys,      
     cnst_2type)      
   select      
    @cnstid,' ', ' ', @cnstname,      
     'REFERENCES ' + db_name()      
      + '.' + rtrim(schema_name(ObjectProperty(@rkeyid,'schemaid')))      
      + '.' + object_name(@rkeyid) + ' ('+@cnstdes + ')',      
     @cnsttype      
  end      
      
  else      
  if @cnsttype = 'C'      
  begin      
   -- Check constraint      
   select @i = 1      
   select @cnstdes = null      
   select @cnstdes = text from syscomments where id = @cnstid and colid = @i      
      
   insert into #spcnsttab      
    (cnst_id, cnst_type ,cnst_name ,cnst_nonblank_name,      
     cnst_keys, cnst_disabled, cnst_notrepl, cnst_2type)      
   select @cnstid,      
    case when parent_column_id <> 0      
     then 'CHECK on column ' + col_name(@objid, parent_column_id)      
     else 'CHECK Table Level ' end,      
    @cnstname ,@cnstname ,substring(@cnstdes,1,2000),      
    is_disabled, is_not_for_replication,      
    @cnsttype      
   from sys.check_constraints where object_id = @cnstid      
      
   while @cnstdes is not null      
   begin      
    if @i > 1      
     insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)      
     select @cnstid,' ' ,' ' ,@cnstname ,substring(@cnstdes,1,2000), @cnsttype      
      
    if len(@cnstdes) > 2000      
     insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)      
     select @cnstid,' ' ,' ' ,@cnstname ,substring(@cnstdes,2001,2000), @cnsttype      
      
    select @i = @i + 1      
    select @cnstdes = null      
    select @cnstdes = text from syscomments where id = @cnstid and colid = @i      
   end      
  end      
      
  else      
  if (@cnsttype = 'D')      
  begin      
   select @i = 1      
   select @cnstdes = null      
   select @cnstdes = text from syscomments where id = @cnstid and colid = @i      
   insert into #spcnsttab      
    (cnst_id,cnst_type ,cnst_name ,cnst_nonblank_name ,cnst_keys, cnst_2type)      
   select @cnstid, 'DEFAULT on column ' + col_name(@objid, parent_column_id),      
    @cnstname ,@cnstname ,substring(@cnstdes,1,2000), @cnsttype      
    from sys.default_constraints where object_id = @cnstid      
      
   while @cnstdes is not null      
   begin      
    if @i > 1      
     insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)      
     select @cnstid,' ' ,' ' ,@cnstname ,substring(@cnstdes,1,2000), @cnsttype      
      
    if len(@cnstdes) > 2000      
     insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)      
     select @cnstid,' ' ,' ' ,@cnstname ,substring(@cnstdes,2001,2000), @cnsttype      
      
    select @i = @i + 1      
    select @cnstdes = null      
    select @cnstdes = text from syscomments where id = @cnstid and colid = @i      
   end      
  end      
      
  fetch ms_crs_cnst into @cnstid ,@cnsttype ,@cnstname      
 end  --of major loop      
 deallocate ms_crs_cnst      
      
 -- Find any rules or defaults bound by the sp_bind... method.      
 insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)      
 select c.rule_object_id,'RULE on column ' + c.name + ' (bound with sp_bindrule)',      
  object_name(c.rule_object_id), object_name(c.rule_object_id), m.text, 'R '      
 from sys.columns c join syscomments m on m.id = c.rule_object_id      
 where c.object_id = @objid      
      
 insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)      
 select c.default_object_id, 'DEFAULT on column ' + c.name + ' (bound with sp_bindefault)',      
  object_name(c.default_object_id),object_name(c.default_object_id), m.text, 'D '      
 from sys.columns c join syscomments m on m.id = c.default_object_id      
 where c.object_id = @objid and objectproperty(c.default_object_id, 'IsConstraint') = 0      
      
      
 -- OUTPUT RESULTS: FIRST THE OBJECT NAME (if not suppressed)      
-- if @nomsg <> 'nomsg'      
-- begin      
--  select 'Object Name' = @objname      
--  print ' '      
-- end      
      
 -- Now print out the contents of the temporary index table.      
 if exists (select * from #spcnsttab)      
  select      
   'constraint_type' = cnst_type,      
   'constraint_name' = cnst_name,      
   'delete_action'=      
     case      
      when cnst_name = ' ' Then ' '      
      when cnst_2type in ('F ') Then      
       case when cnst_delcasc = 1      
        Then 'Cascade' else 'No Action' end      
      else '(n/a)'      
     end,      
   'update_action'=      
     case      
      when cnst_name = ' ' Then ' '      
      when cnst_2type in ('F ') Then      
       case when cnst_updcasc = 1      
        Then 'Cascade' else 'No Action' end      
      else '(n/a)'      
     end,      
   'status_enabled' =      
     case      
      when cnst_name = ' ' Then ' '      
      when cnst_2type in ('F ','C ') Then      
       case when cnst_disabled = 1      
        then 'Disabled' else 'Enabled' end      
      else '(n/a)'      
     end,      
   'status_for_replication' =      
     case      
      when cnst_name = ' ' Then ' '      
      when cnst_2type in ('F ','C ') Then      
       case when cnst_notrepl = 1      
        Then 'Not_For_Replication' else 'Is_For_Replication' end      
      else '(n/a)'      
     end,      
   'constraint_keys' = cnst_keys      
  from #spcnsttab order by cnst_nonblank_name ,cnst_name desc      
 else  
  SELECT 'no record'      
  -- raiserror(15469,-1,-1,@objname) -- No constraints have been defined for object '%ls'.      
      
 print ' '      
    
/*      
 if exists (select * from sys.foreign_keys where referenced_object_id = @objid)      
  select      
   'Table is referenced by foreign key' =      
    db_name() + '.'      
     + rtrim(schema_name(ObjectProperty(parent_object_id,'schemaid')))      
     + '.' + object_name(parent_object_id)      
     + ': ' + object_name(object_id)      
   from sys.foreign_keys where referenced_object_id = @objid order by 1      
 else      
  raiserror(15470,-1,-1,@objname) -- No foreign keys reference table '%ls'.      
*/      
 return (0) -- sp_helpconstraint 








GO
