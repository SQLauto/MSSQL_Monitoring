/*************************************************************************    
* 프로시저명  : dbo.up_dba_create_tb_script   
* 작성정보    : 2008-08-22  
* 관련페이지  : 안지원   
* 내용        : 테이블 이름 받아서 스크립트 생성  
                drop table sphelpcols   
* 수정정보    : 2010-04-28 by choi bo ra, col_id 기준시 drop column 되었을때  문제 있음  
        ( 컬럼 두 번 중복 생성 문제 해결)  
    파일 그룹 [] 묶기, go문 붙어 나오는 것 해결  
exec dbo.up_dba_create_tb_script 'SATISFACTION_INDEX', 'SATISFACTION_INDEX_SWITCH'  
**************************************************************************/  
CREATE PROCEDURE dbo.up_dba_create_tb_script  
   @tablename nvarchar(517),   
   @new_tablename nvarchar(517)  = null,   
   @flags int = 0,   
   @orderby nvarchar(10) = null,   
   @flags2 int = 0  
as   
 set nocount on  
   
 if @new_tablename is null set @new_tablename = @tablename  
  
   create table #sphelpcols  
      (  
      seqno       int identity(1,1),  
      col_name         nvarchar(128)   COLLATE database_default NOT NULL,  
      col_id           int                          NOT NULL,  
      col_typename     nvarchar(128)   COLLATE database_default NOT NULL,  
      col_len          int                          NOT NULL,  
      col_prec         int                          NULL,  
      col_scale        int                          NULL,  
      col_numtype      smallint                     NOT NULL,  /* For DaVinci to get sp_help-type filtering of prec/scale */  
      col_null         bit                          NOT NULL,  /* status & 8 */  
      col_identity     bit                          NOT NULL,  /* status & 128 */  
      col_defname      nvarchar(257)  COLLATE database_default NULL,      /* fully-qual'd default name, or NULL */  
      col_rulname      nvarchar(257)  COLLATE database_default NULL,      /* fully-qual'd rule name, or NULL */  
      col_basetypename nvarchar(128)   COLLATE database_default NOT NULL,  
      col_flags        int                          NULL,      /* COL_* bits */  
      col_seed         nvarchar (40)      COLLATE database_default NULL,  
      col_increment    nvarchar (40)      COLLATE database_default NULL,  
      col_dridefname   nvarchar(128)   COLLATE database_default NULL,      /* DRI DEFAULT name */  
      col_drideftext   nvarchar(128)                NULL,   
      col_iscomputed   int                          NOT NULL,  
      col_objectid     int                          NOT NULL,  /* column object id, need it to get computed text from syscomments */  
      col_NotForRepl   bit                          NOT NULL,  /* Not For Replication setting */  
      col_fulltext     bit                          NOT NULL,  /* FullTextIndex setting */  
      col_AnsiPad      bit                          NULL,      /* Ansi_Padding setting */  
      col_DOwner       nvarchar(128)   COLLATE database_default NULL,      /* non-DRI DEFAULT owner, or NULL */  
      col_DName        nvarchar(128)   COLLATE database_default NULL,      /* non-DRI DEFAULT name, or NULL */  
      col_ROwner       nvarchar(128)   COLLATE database_default NULL,      /* non-DRI RULE owner, or NULL */  
      col_RName        nvarchar(128)   COLLATE database_default NULL,      /* non-DRI RULE name, or NULL */  
      col_collation    nvarchar(128)   COLLATE database_default NULL,      /* column level collation, valid for string columns only */  
      col_isindexable  int,  
      col_language     int,  
      )  
  
  
 if @flags is null  
  select @flags = 0  
 if (@tablename = N'?')  
 begin   
  return 0  
 end  
  
 declare @objid int  
 select @objid = object_id(@tablename)  
 if (@objid is null)  
 begin  
  RAISERROR (15001, -1, -1, @tablename)  
  return 1  
 end  
  
 set nocount on  
  
    declare   
   @indid smallint, -- the index id of an index  
   @groupid int,    -- the filegroup id of an index  
   @indname sysname,  
   @groupname sysname,  
   @status int,  
   @keys nvarchar(2126), --Length (16*max_identifierLength)+(15*2)+(16*3)  
   @dbname sysname,  
   @ignore_dup_key bit,  
   @is_unique  bit,  
   @is_hypothetical bit,  
   @is_primary_key bit,  
   @is_unique_key  bit,  
   @auto_created bit,  
   @no_recompute bit  
  
  
    declare @strSqlPk       nvarchar(max)  
    declare @name           nvarchar(100)  
    declare @idx_id         nvarchar(50)  
    declare @bygroupname    nvarchar(50)  
    declare @idx_keys       nvarchar(1000)  
    declare @primary_key    varchar(30)  
    declare @filegroup  nvarchar(50)  
      
    declare @intLoopCnt int  
    declare @totalCnt   int  
   
 -- Check to see that the object names are local to the current database.  
 select @dbname = parsename(@tablename,3)  
 if @dbname is null  
  select @dbname = db_name()  
 else if @dbname <> db_name()  
  begin  
   raiserror(15250,-1,-1)  
   return (1)  
  end  
  
 -- Check to see the the table exists and initialize @objid.  
 select @objid = object_id(@tablename)  
 if @objid is NULL  
 begin  
  raiserror(15009,-1,-1,@tablename,@dbname)  
  return (1)  
 end  
  
 /* TABLE 정보 #sphelpcols에 담기 */  
 insert #sphelpcols  
  select c.name, c.colid, st.name,  
         case when bt.name in (N'nchar', N'nvarchar') then c.length/2 else c.length end,  
   ColumnProperty(@objid, c.name, N'Precision'),  
   ColumnProperty(@objid, c.name, N'Scale'),  
    -- col_numtype for DaVinci:  use sp_help-type prec/scale filtering for @flags2 & 1  
   case when (@flags2 & 1 <> 0 and bt.name in (N'tinyint',N'smallint',N'decimal',N'int',N'real',N'money',N'float',N'numeric',N'smallmoney',N'bigint'))  
     then 1 else 0 end,  
    -- Nullable  
   convert(bit, ColumnProperty(@objid, c.name, N'AllowsNull')),  
    -- Identity  
   case when (@flags & 0x40000000 = 0) then convert(bit, ColumnProperty(@objid, c.name, N'IsIdentity')) else 0 end,  
    -- Non-DRI Default (make sure it's not a DRI constraint).  
   case when (c.cdefault = 0) then null when (OBJECTPROPERTY(c.cdefault, N'IsDefaultCnst') <> 0) then null else schema_name(sysod.schema_id) + N'.' + d.name end,  
    -- Non-DRI Rule  
   case when (c.domain = 0) then null else schema_name(sysor.schema_id) + N'.' + r.name end,  
    -- Physical base datatype  
   bt.name,  
    -- Initialize flags to whether it's a length-specifiable type, or a numeric type, or 0.  
   case when st.name in (N'char',N'varchar',N'binary',N'varbinary',N'nchar',N'nvarchar') then 0x0001  
     when st.name in (N'decimal',N'numeric') then 0x0002  
     else 0 end  
     -- Will be NULL if column is not UniqueIdentifier.  
     + case isnull(ColumnProperty(@objid, c.name, N'IsRowGuidCol'), 0) when 0 then 0 else 0x0008 end,  
    -- Identity seed and increment  
  
   case when (ColumnProperty(@objid, c.name, N'IsIdentity') <> 0) then CONVERT(nvarchar(40), ident_seed(@tablename)) else null end,  
/*   case when (ColumnProperty(@objid, c.name, N'IsIdentity') <> 0) then ident_seed(@tablename) else null end,  */  
   case when (ColumnProperty(@objid, c.name, N'IsIdentity') <> 0) then CONVERT(nvarchar(40), ident_incr(@tablename)) else null end,  
/*   case when (ColumnProperty(@objid, c.name, N'IsIdentity') <> 0) then ident_incr(@tablename) else null end,  */  
  
    -- DRI Default name  
   case when (@flags & 0x0200 = 0 and c.cdefault is not null and (OBJECTPROPERTY(c.cdefault, N'IsDefaultCnst') <> 0))  
     then object_name(c.cdefault) else null end,  
    -- DRI Default text, if it does not span multiple rows (if it does, SQLDMO will go get them all).  
   case when (@flags & 0x0200 = 0 and c.cdefault is not null and (OBJECTPROPERTY(c.cdefault, N'IsDefaultCnst') <> 0))  
     then t.text else null end,  
         c.iscomputed,  
         c.id,  
    -- Not For Replication  
   convert(bit, ColumnProperty(@objid, c.name, N'IsIdNotForRepl')),  
         convert(bit, ColumnProperty(@objid, c.name, N'IsFulltextIndexed')),  
         convert(bit, ColumnProperty(@objid, c.name, N'UsesAnsiTrim')),  
    -- Non-DRI Default owner and name  
   case when (c.cdefault = 0) then null when (OBJECTPROPERTY(c.cdefault, N'IsDefaultCnst') <> 0) then null else schema_name(sysod.schema_id) end,  
   case when (c.cdefault = 0) then null when (OBJECTPROPERTY(c.cdefault, N'IsDefaultCnst') <> 0) then null else d.name end,  
    -- Non-DRI Rule owner and name  
   case when (c.domain = 0) then null else schema_name(sysor.schema_id) end,  
   case when (c.domain = 0) then null else r.name end,  
           -- column level collation  
         c.collation,  
           -- IsIndexable  
         ColumnProperty(@objid, c.name, N'IsIndexable'),  
         c.language  
  from dbo.syscolumns c  
    -- NonDRI Default and Rule filters  
   left outer join (dbo.sysobjects d join sys.all_objects sysod on d.id = sysod.object_id)  on d.id = c.cdefault  
   left outer join (dbo.sysobjects r join sys.all_objects sysor on r.id = sysor.object_id)  on r.id = c.domain  
    -- Fully derived data type name  
   join dbo.systypes st on st.xusertype = c.xusertype  
    -- Physical base data type name  
   join dbo.systypes bt on bt.xusertype = c.xtype  
    -- DRIDefault text, if it's only one row.  
   left outer join dbo.syscomments t on t.id = c.cdefault and t.colid = 1  
     and not exists (select * from dbo.syscomments where id = c.cdefault and colid = 2)      
  where c.id = @objid  
  order by c.colid  
  
 /* Convert any timestamp column to binary(8) if they asked. */  
 if (@flags & 0x80000 != 0)  
  update #sphelpcols set col_typename = N'binary', col_len = 8, col_flags = col_flags | 0x0001 where col_typename = N'timestamp'  
  
 /* Now see what our flags are, if anything. */  
 if (@flags is not null and @flags != 0)  
 begin  
  if (@flags & 0x0400 != 0)  
  begin     
   declare @typeflagmask int select @typeflagmask = (convert(int, 0x0001) + convert(int, 0x0002))  
   update #sphelpcols set col_typename = b.name,  
    -- ReInitialize flags to whether it's a length-specifiable type, or a numeric type, or 0.  
    col_flags = col_flags & ~@typeflagmask  
       + case when b.name in (N'char',N'varchar',N'binary',N'varbinary',N'nchar',N'nvarchar') then 0x0001  
        when b.name in (N'decimal',N'numeric') then 0x0002  
        else 0 end  
   from #sphelpcols c, dbo.systypes n, dbo.systypes b  
    where n.name = col_typename    --// xtype (base type) of name  
     and b.xusertype = n.xtype   --// Map it back to where it's xusertype, to get the name  
  end  
 end  
  
 /* Determine if the column is in the primary key */  
 if (@flags & 0x0200 = 0 and (OBJECTPROPERTY(@objid, N'TableHasPrimaryKey') <> 0)) begin  
  --declare @indid int  
  select @indid = indid from dbo.sysindexes i where i.id = @objid and i.status & 0x0800 <> 0  
  if (@indid is not null)  
   update #sphelpcols set col_flags = col_flags | 0x0004  
   from #sphelpcols c, dbo.sysindexkeys i  
    where i.id = @objid and i.indid = @indid and i.colid = c.col_id  
 end  
  
  
   
 /* ************************************  
        TABLE script 시작   
 ******************************************/  
 SET @intLoopCnt = 1  
   
    
 declare @colCnt int  
   
 select @colCnt = count(col_name)  
 from #sphelpcols with(nolock)   
   
 If @colCnt = 0 return   
   
 declare @strSqlHeader varchar(max)  
 declare @strSqlBody varchar(max)  
  
 set @strSqlBody = ''  
  
 SET @strSqlHeader = 'CREATE TABLE ' + @new_tablename +  CHAR(10) + '( ' + CHAR(10)  
   
 WHILE (@intLoopCnt<=@colCnt)  
   
 BEGIN  
    
  declare @col_name     nvarchar(128)  
  declare @col_typename  nvarchar(128)  
  declare @col_len     int   
  declare @col_identity       int   
  declare @col_seed           int  
  declare @col_increment      int  
  declare @col_prec   int  
  declare @col_scale   int  
  declare @col_null     nvarchar(10)  
  declare @col_dridefname     nvarchar(128)     
  declare @col_drideftext  nvarchar(128)  
  declare @col_collation   nvarchar(128)  
  declare @strSubSql    nvarchar(1000)  
  SET @strSubSql = ''  
    
 SELECT   
  @col_name =  col_name   
 , @col_typename = col_typename  
 ,  @col_len = col_len  
    ,   @col_identity = col_identity  
    ,   @col_seed  = col_seed  
    , @col_prec = col_prec  
    , @col_scale = col_scale  
    ,   @col_increment = col_increment  
 ,  @col_null =   
        CASE col_null  
            WHEN 0 THEN N' NOT NULL'  
            WHEN 1 THEN N' NULL'   
            ELSE N'NULL'  
        END   
 ,  @col_seed = col_seed   
 ,  @col_dridefname = col_dridefname  
 ,  @col_collation = col_collation   
 ,  @col_drideftext = col_drideftext  
 FROM #sphelpcols with(nolock)    
 WHERE seqno = CAST((@intLoopCnt) as int)  
   
 SET @strSubSql = @strSubSql + @col_name + ' '   
    SET @strSubSql = @strSubSql + @col_typename + ' '  
      
    --type이 문자인 column은 길이를 지정  
    IF @col_typename in ( 'char', 'varchar', 'nvarchar', 'nchar' )   
     --nvarchar(max), varchar(max)  
     IF @col_prec = -1 AND @col_len in (0, -1)  
      BEGIN  
       SET @strSubSql = @strSubSql + '(max)'               
      END        
     ELSE      
         BEGIN  
             SET @strSubSql = @strSubSql + '('  
             SET @strSubSql = @strSubSql + CAST(@col_len as varchar(10))+ ''  
             SET @strSubSql = @strSubSql + ')'    
         END   
    --numeric 인 경우 (    
    IF @col_typename = 'numeric'  
     BEGIN  
      SET @strSubSql = @strSubSql + '('  
            SET @strSubSql = @strSubSql + CAST(@col_prec as varchar(4))+ ', ' + CAST(@col_scale as varchar(4)) + ''  
            SET @strSubSql = @strSubSql + ')'    
     END       
      
    ELSE   
        BEGIN  
            SET @strSubSql = @strSubSql + ' '   
        END   
     
    IF @col_identity = 1  
        BEGIN  
            SET @strSubSql = @strSubSql + ' IDENTITY (' + CAST(@col_seed as varchar(4)) + ' , ' + CAST(@col_increment as varchar(4))  + ') '   
        END       
    ELSE  
        BEGIN  
            SET @strSubSql = @strSubSql + ' '   
        END    
      
 SET @strSubSql = @strSubSql + CAST(@col_null as varchar(10)) + ' '  
   
 IF @col_dridefname is not null      
     --SET @strSubSql = @strSubSql + ' CONSTRAINT ' + @col_dridefname + ' DEFAULT ' + @col_drideftext + ' '          
     SET @strSubSql = @strSubSql + ' CONSTRAINT ' + 'DF__' +  UPPER(@new_tablename) + '__' + UPPER(@col_name) + ' DEFAULT ' + @col_drideftext + ' '    
 ELSE   
     SET @strSubSql = @strSubSql + ' '  
           
        IF @intLoopCnt  < @colCnt --ELSE   
            BEGIN  
                SET @strSubSql = @strSubSql + ' , '  + CHAR(10)             
            END  
        SET @intLoopCnt = @intLoopCnt + 1   
  
  SET @strSqlBody = @strSqlBody + @strSubSql  
  
 END   
   
 -- filegroup  
 select  @filegroup = d.name  
 from sys.data_spaces d  
 where d.data_space_id =(select i.data_space_id from sys.indexes i where i.object_id = @objid and i.index_id < 2)  
    
     
 --print @strSqlBody  
-- select @strSqlHeader + @strSqlBody + CHAR(10) + ')'  
  
    drop table #sphelpcols  
  
      
    /* **************************************  
       인덱스 부분   
    ******************************************/  
 -- OPEN CURSOR OVER INDEXES (skip stats: bug shiloh_51196)  
 declare ms_crs_ind cursor local static for  
  
  select i.index_id, i.data_space_id, i.name,  
   i.ignore_dup_key, i.is_unique, i.is_hypothetical, i.is_primary_key, i.is_unique_constraint,  
   s.auto_created, s.no_recompute  
  from sys.indexes i join sys.stats s  
   on i.object_id = s.object_id and i.index_id = s.stats_id  
  where i.object_id = @objid  
  order by i.index_id  
 open ms_crs_ind  
 fetch ms_crs_ind into @indid, @groupid, @indname, @ignore_dup_key, @is_unique, @is_hypothetical,  
   @is_primary_key, @is_unique_key, @auto_created, @no_recompute  
  
 -- IF NO INDEX, QUIT  
 if @@fetch_status < 0  
 begin  
  deallocate ms_crs_ind  
  --raiserror(15472,-1,-1,@tablename) -- Object does not have any indexes.  
  print 'Object does not have any indexes.'  
 -- return (0)  
 end  
 else  
 begin  
   
  -- create temp table  
  CREATE TABLE #spindtab  
  (  
   seq_no              int identity(1,1) ,  
   index_name   sysname collate database_default NOT NULL,  
   index_id    int,  
   ignore_dup_key  bit,  
   is_unique    bit,  
   is_hypothetical  bit,  
   is_primary_key  bit,  
   is_unique_key   bit,  
   auto_created   bit,  
   no_recompute   bit,  
   groupname   sysname collate database_default NULL,  
   index_keys   nvarchar(2126) collate database_default NOT NULL -- see @keys above for length descr  
  )  
  
  -- Now check out each index, figure out its type and keys and  
  -- save the info in a temporary table that we'll print out at the end.  
  while @@fetch_status >= 0  
  begin  
   -- First we'll figure out what the keys are.  
   declare @i int, @thiskey nvarchar(131) -- 128+3  
           
   select @keys = index_col(@tablename, @indid, 1), @i = 2  
     
   if (indexkey_property(@objid, @indid, 1, 'isdescending') = 1)  
    select @keys = '[' +@keys  + '] DESC'          
   else   
    select @keys = '[' +@keys  + '] ASC'          
               
   select @thiskey = index_col(@tablename, @indid, @i)  
   if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))  
    select @thiskey = '[' + @thiskey + '] DESC '  
   ELSE   
    select @thiskey = '[' + @thiskey + '] ASC '  
  
   while (@thiskey is not null )  
   begin  
    select @keys = @keys + ', ' + @thiskey, @i = @i + 1  
    select @thiskey = index_col(@tablename, @indid, @i)  
    if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))  
           select @thiskey = '['+ @thiskey + '] DESC '  
    ELSE  
     select @thiskey = '['+ @thiskey + '] ASC '  
   end  
  
   select @groupname = null  
   select @groupname = name from sys.data_spaces where data_space_id = @groupid  
  
   -- INSERT ROW FOR INDEX  
   insert into #spindtab values (@indname, @indid, @ignore_dup_key, @is_unique, @is_hypothetical,  
    @is_primary_key, @is_unique_key, @auto_created, @no_recompute, @groupname, @keys)  
  
   -- Next index  
   fetch ms_crs_ind into @indid, @groupid, @indname, @ignore_dup_key, @is_unique, @is_hypothetical,  
    @is_primary_key, @is_unique_key, @auto_created, @no_recompute  
  end  
  deallocate ms_crs_ind  
  
  -- DISPLAY THE RESULTS      
  select    
    seq_no as seq_no    
   ,   case when @tablename = @new_tablename then index_name  else index_name + '_SWITCH' end as name  
   ,   case when index_id = 1 then 'clustered' else 'nonclustered' end as idx_id  
   ,   case when ignore_dup_key <> 0 then 'ignore duplicate keys' else '' end as dup  
   ,   case when is_unique <>0 then 'unique' else '' end as is_unique  
   ,   case when is_hypothetical <>0 then 'hypothetical' else '' end as is_hypothetical  
   ,   case when is_primary_key <>0 then 'primary key' else '' end as is_primary_key  
   ,   case when is_unique_key <>0 then 'unique key' else '' end as is_unique_key  
   ,   case when auto_created <>0 then 'auto create' else '' end as auto_created  
   ,   case when no_recompute <>0 then 'stats no recompute' else '' end as no_recompute  
   ,   groupname as groupname  
   ,   index_keys as index_keys  
  into #work_idx  
  from #spindtab    
  order by index_name  
  
  
  /*INDEX 스크립트*/  
  DECLARE @strIdxBody VARCHAR(max)  
  
  SELECT @totalCnt = count(index_name) FROM #spindtab WITH(NOLOCK)  
  SET @intLoopcnt = 1  
       
  --INDEX 없는 경우  
  IF @totalCnt = 0 RETURN  
  SET @strIdxBody = ''  
        
  WHILE(@intLoopcnt <= @totalCnt )  
  
  BEGIN      
  SELECT   
   @name = name   
  ,   @idx_id = idx_id  
  ,   @primary_key = is_primary_key  
  ,   @bygroupname = groupname  
  ,   @idx_keys = index_keys  
  FROM #work_idx WITH(nolock)    
  WHERE seq_no = @intLoopcnt      
  
  
  IF @primary_key = 'primary key'  
   BEGIN  
    SET @strSqlPk = 'ALTER TABLE '  + @new_tablename + ' ADD CONSTRAINT ' + @name  + + ' ' +  @primary_key + ' '  + @idx_id + ' ('   
    SET @strSqlPk = @strSqlPk + @idx_keys  
    SET @strSqlPk = @strSqlPk + ' ) ON ' + '[' + @bygroupname + '] ' + char(10) + 'GO'  
   END  
  ELSE  
   BEGIN  
    SET @strSqlPk = 'CREATE ' + @idx_id  + ' INDEX '  + @name + ' ON '  + @new_tablename + ' ('  
    SET @strSqlPk = @strSqlPk + @idx_keys  
    SET @strSqlPk = @strSqlPk + ' ) ON ' + '[' + @bygroupname + '] ' + char(10) + 'GO'   
   END  
  SET @strSqlPk = @strSqlPk + CHAR(10)  
  SET @intLoopCnt = @intLoopCnt + 1   
  SET @strIdxBody = @strIdxBody + @strSqlPk   
  
  
  END    
  
 end  
    print @strSqlHeader + @strSqlBody + CHAR(10) + ')  ON ['  + @filegroup +  + ']' + CHAR(10) + 'GO'  
    --SELECT CHAR(10)   
    print @strIdxBody  
  
  
    DROP TABLE #work_idx  
    DROP TABLE #spindtab  
  
  
SET NOCOUNT OFF  
  
  
RETURN 

