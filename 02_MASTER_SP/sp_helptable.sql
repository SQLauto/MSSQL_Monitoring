USE master
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'sp_helptable' 
	   AND 	  type = 'P')
    DROP PROCEDURE  sp_helptable
GO

/**  
* Create        : choi bo ra(ceusee)  
* SP Name       : dbo.sp_helptable  
* Purpose       : sp_hlep 중에 필요한 부분만 사용  
* E-mail        : ceusee@gmail.com  
* Create date   : 2007-05-09  
* Return Code   :  
    0 : Success.   
    4000 : Fail.  
    4003 : Record Not Find.  
* Modification Memo :  
-- 테이블 정보  
Name    Owner    Type  Filegroup   rows  reserved  data  index unused Create Date  
  
-- 인덱스 정보  
index_name  index_Keys PK clusted(Y/N) Unique(Y/N) fillfactor Filegroup  
  
-- indetity  
identity seed  increment  
  
-- 컬럼 정보  
column_name  type  Cmputed  Length Prec Scale Nullable  
  
-- 제약조건  
sp_helpconstraint warehouse01   나오는 결과  
**/  
CREATE PROCEDURE dbo.sp_helptable  
    @objectName     NVARCHAR(776) = NULL  
AS  
/* COMMON DECLARE */  
SET NOCOUNT ON  
DECLARE @errCode        INT  
  
/* USER DECLARE */  

-- TABLE DECLARE 
create table #spt_space_temp 
( 
 objid       int default 0, 
 name        nvarchar(128) null,  
 rows        int null,  
 reserved    nvarchar(18) null,  
 data        nvarchar(18) null,  
 indexp        nvarchar(18) null,  
 unused        nvarchar(18) null  
)  


create table #spt_filegroup_temp  
(  
    file_group nvarchar(128) null  
)  

declare @no varchar(35), @yes varchar(35), @none varchar(35)  
declare @dbname sysname, @objid int, @type char(2)  
  
-- INDEX DECLARE  
declare @indid smallint, @groupid smallint, @indname sysname, @groupname sysname,   
        @status int, @keys nvarchar(2126), @fill_factor tinyint,  @thiskey nvarchar(131)  
declare @empty varchar(1) select @empty = ''  
declare @des1   varchar(35), -- 35 matches spt_values  
  @des2   varchar(35),  
  @des4   varchar(35),  
  @des16          varchar(35),  
  @des32   varchar(35),  
  @des64   varchar(35),  
  @des2048  varchar(35),  
  @des4096  varchar(35),  
  @des8388608  varchar(35),  
  @des16777216 varchar(35)  
    
-- INDENTITY DECLARE  
declare @colname sysname  
  
-- COLUMN DECLARE  
declare @numtypes nvarchar(80)  
select @numtypes = N'tinyint,smallint,decimal,int,real,money,float,numeric,smallmoney'  
  
-- CONSTRAINT DECLARE  
declare  @cnstdes  nvarchar(4000), -- string to build up index desc  
   @cnstname  sysname,       -- name of const. currently under consideration  
   @i    int,  
   @cnstid  int,  
   @cnsttype  character(2)  
  
IF @objectName IS NULL   
begin  
    EXEC sp_help NULL  
    RETURN  
end  
-- OBTAIN DISPLAY STRINGS FROM spt_values UP FRONT --  
select @no = name from master.dbo.spt_values where type = 'B' and number = 0  
select @yes = name from master.dbo.spt_values where type = 'B' and number = 1  
select @none = name from master.dbo.spt_values where type = 'B' and number = 2  
  
-- Make sure the @objname is local to the current database.  
select @dbname = parsename(@objectname,3)  
  
if @dbname is not null and @dbname <> db_name()  
begin  
 raiserror(15250,-1,-1)  
 return (-1)  
end  
-- obejct check   
select @objid = id, @type = xtype  from sysobjects  where id = object_id(@objectname)    
if @objid = null   
begin  
      raiserror(15009,-1,-1,@objectname,@dbname)  
      return (-1)  
end  
  
  
if  @type in ('U', 'S')  
begin  
  
    /**************************************************************************************  
        TABLE Information  
        Name    Owner    Type  Filegroup   rows  reserved  data  index unused Create Date  
    ****************************************************************************************/  
    DECLARE @strSql nvarchar(50)
    SET @strSql = N'exec sp_spaceused ' + @objectname

    insert #spt_space_temp(name,rows,reserved,data,indexp,unused)
    exec sp_executesql @strSql
    
    -- tempdb와 생성된 DB와의 collate 가 틀릴 경우를 대비해서
    --update #spt_space_temp set objid = @objid
  
    SET @strSql = N'exec sp_objectfilegroup ' + convert(nvarchar, @objid) 
    insert #spt_filegroup_temp
    exec sp_executesql @strSql

    select o.name, user_name(o.uid) as owner, substring(v.name, 5,31) as type,  
            (select file_group from #spt_filegroup_temp) as filegroup,   
            t.rows, t.reserved, t.data, t.indexp, t.unused, o.crdate as create_date  
    from sysobjects as o join master.dbo.spt_values as v on o.xtype = substring(v.name,1,2) collate SQL_Latin1_General_CP1_CI_AS  
           join #spt_space_temp t on o.name = t.name collate SQL_Latin1_General_CP1_CI_AS
    where o.id = @objid and v.type = 'O9T' 

  
   /***************************************************************************  
    INDEX Information  
    index_name  index_Keys PK clusted(Y/N) Unique(Y/N) fillfactor Filegroup   
   ****************************************************************************/ 
  DECLARE @count  INT
  SET @count = 0
  select  @count = count(indid) from sysindexes  
   where id = @objid and indid > 0 and indid < 255 and (status & 64)=0 
  
  IF @count = 0 
  BEGIN
	SELECT 'No Index Information' AS [Index_name]
  END
  ELSE
  BEGIN
    
        -- OPEN CURSOR OVER INDEXES  
     declare ms_crs_ind cursor local static for  
      select indid, groupid, name, status, OrigFillFactor from sysindexes  
       where id = @objid and indid > 0 and indid < 255 and (status & 64)=0 order by indid  
       
     open ms_crs_ind  
     fetch ms_crs_ind into @indid, @groupid, @indname, @status, @fill_factor  
      
         -- IF NO INDEX, QUIT  
         if @@fetch_status < 0  
         begin  
          deallocate ms_crs_ind  
          raiserror(15472,-1,-1) --'Object does not have any indexes.'  
         end  
           
         -- create temp table  
         create table #spindtab  
         (  
          index_name   sysname collate database_default NOT NULL,  
          stats    int,  
          groupname   sysname collate database_default NOT NULL,  
          index_keys   nvarchar(2126) collate database_default NOT NULL,   
          fill_factor         tinyint  
         )   
  
              
            -- Now check out each index, figure out its type and keys and  
         -- save the info in a temporary table that we'll print out at the end.  
         while @@fetch_status >= 0  
         begin  
           
          select @keys = index_col(@objectname, @indid, 1), @i = 2  
          
          if (indexkey_property(@objid, @indid, 1, 'isdescending') = 1)  
              select @keys = @keys  + '(-)'  
          
            select @thiskey = index_col(@objectname, @indid, @i)  
            
          if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))  
           select @thiskey = @thiskey + '(-)'  
          
                while (@thiskey is not null )  
          begin  
           select @keys = @keys + ', ' + @thiskey, @i = @i + 1  
           select @thiskey = index_col(@objectname, @indid, @i)  
           if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))  
            select @thiskey = @thiskey + '(-)'  
             end  
                declare @sql nvarchar(100)  
                set @sql = N'select @groupname_t= groupname from sysfilegroups where groupid = '+ convert(nvarchar,@groupid)  
                  
                execute sp_executesql @sql, N'@groupname_t sysname output', @groupname_t = @groupname output  
                -- INSERT ROW FOR INDEX  
          insert into #spindtab values (@indname, @status, @groupname, @keys, @fill_factor)  
      
          -- Next index  
          fetch ms_crs_ind into @indid, @groupid, @indname, @status, @fill_factor  
         end  
         deallocate ms_crs_ind  
  
         -- Type Value  
         select @des1 = name from master.dbo.spt_values where type = 'I' and number = 1  
            select @des2 = name from master.dbo.spt_values where type = 'I' and number = 2  
            select @des4 = name from master.dbo.spt_values where type = 'I' and number = 4  
            select @des16 = name from master.dbo.spt_values where type = 'I' and number = 16  
            select @des32 = name from master.dbo.spt_values where type = 'I' and number = 32  
            select @des64 = name from master.dbo.spt_values where type = 'I' and number = 64  
            select @des2048 = name from master.dbo.spt_values where type = 'I' and number = 2048  
            select @des4096 = name from master.dbo.spt_values where type = 'I' and number = 4096  
            select @des8388608 = name from master.dbo.spt_values where type = 'I' and number = 8388608  
            select @des16777216 = name from master.dbo.spt_values where type = 'I' and number = 16777216  
           
         select index_name, index_keys,  
                    case when (stats & 2048) <> 0 then @des2048 else @empty end as 'PK',  
                    case when (stats & 16) <> 0 then @des16 else @empty end as 'Clustered',  
                    case when (stats & 2) <> 0 then @des2 else 'no' end as 'Unique',  
                    fill_factor,groupname,  
                    case when (stats & 1)<>0 then ', '+@des1 else @empty end  
                    + case when (stats & 4)<>0 then ', '+@des4 else @empty end  
                    + case when (stats & 64)<>0 then ', '+@des64 else case when (stats & 32)<>0 then ', '+@des32 else @empty end end  
                    + case when (stats & 4096)<>0 then ', '+@des4096 else @empty end  
                    + case when (stats & 8388608)<>0 then ', '+@des8388608 else @empty end  
              + case when (stats & 16777216)<>0 then ', '+@des16777216 else @empty end as 'Etc'  
           from #spindtab  
    END
    /****************************************************  
     indetity  
     identity seed  increment  
    *****************************************************/  
    select @colname  = name from syscolumns where id = @objid and colstat & 1 = 1  
    select  
    'Identity'    = isnull(@colname,'No identity column defined.'),  
    'Seed'     = ident_seed(@objectName),  
    'Increment'    = ident_incr(@objectName),  
    'Curr Identity'         = ident_current(@objectName),  
    'Not For Replication' = ColumnProperty(@objid, @colname, 'IsIDNotForRepl')  
      
    /************************************************************  
      COLUMN Information  
      column_name  type  Cmputed  Length Prec Scale Nullable  
    *************************************************************/  
      
    select  
   'Column_name'   = name,  
   'Type'     = type_name(xusertype),  
   'Computed'    = case when iscomputed = 0 then @no else @yes end,  
   'Length'    = convert(int, length),  
   'Prec'     = case when charindex(type_name(xtype), @numtypes) > 0  
          then convert(char(5),ColumnProperty(id, name, 'precision'))  
          else '     ' end,  
   'Scale'     = case when charindex(type_name(xtype), @numtypes) > 0  
          then convert(char(5),OdbcScale(xtype,xscale))  
          else '     ' end,  
   'Nullable'    = case when isnullable = 0 then @no else @yes end  
    from syscolumns where id = @objid and number = 0 order by colid  
      
    /**************************************************************  
      -- 제약조건  
      sp_helpconstraint warehouse01   나오는 결과  
    ***************************************************************/  
      
    create table #spcnsttab  
 (  
  cnst_id   int   NOT NULL  
  ,cnst_type   nvarchar(146) collate database_default NULL   -- 128 for name + text for DEFAULT  
  ,cnst_name   sysname  collate database_default NOT NULL  
  ,cnst_nonblank_name sysname  collate database_default NOT NULL  
  ,cnst_2type   character(2) collate database_default NULL  
  ,cnst_disabled  bit    NULL  
  ,cnst_notrepl  bit    NULL  
  ,cnst_delcasc  bit    NULL  
  ,cnst_updcasc  bit    NULL  
  ,cnst_keys   nvarchar(2126) collate database_default NULL -- see @keys above for length descr  
 )  
 declare ms_crs_cnst cursor local static for  
  select id, xtype, name from sysobjects where parent_obj = @objid  
   and xtype in ('C ','F ', 'D ')   
  for read only  
    -- Now check out each constraint, figure out its type and keys and  
 -- save the info in a temporary table that we'll print out at the end.  
 open ms_crs_cnst  
    fetch ms_crs_cnst into @cnstid ,@cnsttype ,@cnstname  
 while @@fetch_status >= 0  
 begin  
        if @cnsttype = 'F '  
  begin  
   -- OBTAIN TWO TABLE IDs  
   declare @fkeyid int, @rkeyid int  
   select @fkeyid = fkeyid, @rkeyid = rkeyid from sysreferences where constid = @cnstid  
  
   -- USE CURSOR OVER FOREIGN KEY COLUMNS TO BUILD COLUMN LISTS  
   -- (NOTE: @keys HAS THE FKEY AND @cnstdes HAS THE RKEY COLUMN LIST)  
   declare ms_crs_fkey cursor local for select fkey, rkey from sysforeignkeys where constid = @cnstid  
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
      + '.' + rtrim(user_name(ObjectProperty(@rkeyid,'ownerid')))  
      + '.' + object_name(@rkeyid) + ' ('+@cnstdes + ')',  
     @cnsttype  
  end  
        else if @cnsttype = 'C '  
  begin  
   select @i = 1  
   select @cnstdes = text from syscomments where id = @cnstid and colid = @i  
   while @cnstdes is not null  
   begin  
    if @i=1  
     -- Check constraint  
     insert into #spcnsttab  
      (cnst_id, cnst_type ,cnst_name ,cnst_nonblank_name,  
       cnst_keys, cnst_disabled, cnst_notrepl, cnst_2type)  
     select @cnstid,  
      case when info = 0 then 'CHECK Table Level '  
       else 'CHECK on column ' + col_name(@objid ,info) end,  
      @cnstname ,@cnstname ,substring(@cnstdes,1,2000),  
      ObjectProperty(@cnstid, 'CnstIsDisabled'),  
      ObjectProperty(@cnstid, 'CnstIsNotRepl'),  
      @cnsttype  
     from sysobjects where id = @cnstid  
    else  
     insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)  
     select @cnstid,' ' ,' ' ,@cnstname ,substring(@cnstdes,1,2000), @cnsttype  
  
    if len(@cnstdes) > 2000  
     insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)  
     select @cnstid,' ' ,' ' ,@cnstname ,substring(@cnstdes,2001,2000), @cnsttype  
  
    select @cnstdes = null  
    select @i = @i + 1  
    select @cnstdes = text from syscomments where id = @cnstid and colid = @i  
   end  
  end  
        else if @cnsttype = 'D '  
  begin  
   select @i = 1  
   select @cnstdes = text from syscomments where id = @cnstid and colid = @i  
   while @cnstdes is not null  
   begin  
    if @i=1  
     insert into #spcnsttab  
      (cnst_id,cnst_type ,cnst_name ,cnst_nonblank_name ,cnst_keys, cnst_2type)  
     select @cnstid, 'DEFAULT on column ' + col_name(@objid ,info),  
      @cnstname ,@cnstname ,substring(@cnstdes,1,2000), @cnsttype  
     from sysobjects where id = @cnstid  
    else  
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
      
    insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)  
 select c.domain,'RULE on column ' + c.name + ' (bound with sp_bindrule)',  
  object_name(c.domain), object_name(c.domain), text, 'R '  
 from syscolumns c, syscomments m  
 where c.id = @objid and m.id = c.domain and ObjectProperty(c.domain, 'IsRule') = 1  
  
   
    insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)  
 select c.cdefault, 'DEFAULT on column ' + c.name + ' (bound with sp_bindefault)',  
  object_name(c.cdefault),object_name(c.cdefault), text, 'D '  
 from syscolumns c,syscomments m  
 where c.id = @objid and m.id = c.cdefault and ObjectProperty(c.cdefault, 'IsConstraint') = 0  
  
    -- Now print out the contents of the temporary index table.  
 if exists (select * from #spcnsttab)  
  select  
   'constraint_type' = cnst_type,  
   'constraint_name' = cnst_name,  
   'delete_action'=  
     CASE  
      When cnst_name = ' ' Then ' '  
      When cnst_2type in ('F ') Then  
       CASE When cnst_delcasc = 1  
        Then 'Cascade' else 'No Action' end  
      Else '(n/a)'  
     END,  
   'update_action'=  
     CASE  
      When cnst_name = ' ' Then ' '  
      When cnst_2type in ('F ') Then  
       CASE When cnst_updcasc = 1  
        Then 'Cascade' else 'No Action' end  
      Else '(n/a)'  
     END,  
   'status_enabled' =  
     CASE  
      When cnst_name = ' ' Then ' '  
      When cnst_2type in ('F ','C ') Then  
       CASE When cnst_disabled = 1  
        then 'Disabled' else 'Enabled' end  
      Else '(n/a)'  
     END,  
   'status_for_replication' =  
     CASE  
      When cnst_name = ' ' Then ' '  
      When cnst_2type in ('F ','C ') Then  
       CASE When cnst_notrepl = 1  
        Then 'Not_For_Replication' else 'Is_For_Replication' end  
      Else '(n/a)'  
     END,  
   'constraint_keys' = cnst_keys  
  from #spcnsttab order by cnst_nonblank_name ,cnst_name desc  
 else  
  raiserror(15469,-1,-1) --'No constraints have been defined for this object.'  
   
 if exists (select * from sysreferences where rkeyid = @objid)  
  select  
   'Table is referenced by foreign key' =  
    db_name() + '.'  
     + rtrim(user_name(ObjectProperty(fkeyid,'ownerid')))  
     + '.' + object_name(fkeyid)  
     + ': ' + object_name(constid)  
   from sysreferences where rkeyid = @objid order by 1  
-- else  
--  raiserror(15470,-1,-1) --'No foreign keys reference this table.'  

drop table #spt_filegroup_temp
drop table #spt_space_temp
      
end  
else -- ETC Type  
    EXEC sp_help @objectname  
         
RETURN  
  
ERRORHANDLER:  
BEGIN  
    RETURN   
END   
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant all on sp_helptable to public