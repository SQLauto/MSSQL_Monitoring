use master
go
if exists (select name from sysobjects where name = 'sp_generate_insert_script')
begin
  drop proc sp_generate_insert_script
  print 'old version of sp_generate_insert_script dropped'
end
go

create procedure sp_generate_insert_script
                 @tablename_mask varchar(30) = NULL
as
begin
--------------------------------------------------------------------------------
-- Stored Procedure:  sp_generate_insert_script
-- Language:          Microsoft Transact SQL (7.0)
-- Author:            Inez Boone (inez.boone@xs4al.nl)
--                    working on the Sybase version of & thanks to:
--                    Reinoud van Leeuwen (reinoud@xs4all.nl)
-- Version:           1.4
-- Date:              December 6th, 2000
-- Description:       This stored procedure generates an SQL script to fill the
--                    tables in the database with their current content.
-- Parameters:        IN: @tablename_mask : mask for tablenames
-- History:           1.0 October 3rd 1998 Reinoud van Leeuwen
--                      first version for Sybase
--                    1.1 October 7th 1998 Reinoud van Leeuwen
--                      added limited support for text fields; the first 252 
--                      characters are selected.
--                    1.2 October 13th 1998 Reinoud van Leeuwen
--                      added support for user-defined datatypes
--                    1.3 August 4 2000 Inez Boone
--                      version for Microsoft SQL Server 7.0
--                      use dynamic SQL, no intermediate script
--                    1.4 December 12 2000 Inez Boone
--                      handles quotes in strings, handles identity columns
--                    1.5 December 21 2000 Inez Boone
--                      Output sorted alphabetically to assist db compares,
--                      skips timestamps
--------------------------------------------------------------------------------

-- NOTE: If, when executing in the Query Analyzer, the result is truncated, you can remedy
--       this by choosing Query / Current Connection Options, choosing the Advanced tab and
--       adjusting the value of 'Maximum characters per column'.
--       Unchecking 'Print headers' will get rid of the line of dashes.

  declare @tablename       varchar (128)
  declare @tablename_max   varchar (128)
  declare @tableid         int
  declare @columncount     numeric (7,0)
  declare @columncount_max numeric (7,0)
  declare @columnname      varchar (30)
  declare @columntype      int
  declare @string          varchar (30)
  declare @leftpart        varchar (8000)    /* 8000 is the longest string SQLSrv7 can EXECUTE */
  declare @rightpart       varchar (8000)    /* without having to resort to concatenation      */
  declare @hasident        int

  set nocount on

  -- take ALL tables when no mask is given (!)
  if (@tablename_mask is NULL)
  begin
    select @tablename_mask = '%'
  end

  -- create table columninfo now, because it will be used several times

  create table #columninfo
  (num      numeric (7,0) identity,
   name     varchar(30),
   usertype smallint)


  select name,
         id
    into #tablenames
    from sysobjects
   where type in ('U' ,'S')
     and name like @tablename_mask

  -- loop through the table #tablenames

  select @tablename_max  = MAX (name),
         @tablename      = MIN (name)
    from #tablenames

  while @tablename <= @tablename_max
  begin
    select @tableid   = id
      from #tablenames
     where name = @tablename

    if (@@rowcount <> 0)
    begin
      -- Find out whether the table contains an identity column
      select @hasident = max( status & 0x80 )
        from syscolumns
       where id = @tableid

      truncate table #columninfo

      insert into #columninfo (name,usertype)
      select name, type
        from syscolumns C
       where id = @tableid
         and type <> 37            -- do not include timestamps

      -- Fill @leftpart with the first part of the desired insert-statement, with the fieldnames

      select @leftpart = 'select ''insert into '+@tablename
      select @leftpart = @leftpart + '('

      select @columncount     = MIN (num),
             @columncount_max = MAX (num)
        from #columninfo
      
      -- 컬럼 넣기'
      while @columncount <= @columncount_max
      begin
        select @columnname = name,
               @columntype = usertype
          from #columninfo
         where num = @columncount
        if (@@rowcount <> 0)
        begin
          if (@columncount < @columncount_max)
          begin
            select @leftpart = @leftpart + @columnname + ','
          end
          else
          begin
            select @leftpart = @leftpart + @columnname + ')'  -- 마지막이면 )를 닿는다.
          end
        end

        select @columncount = @columncount + 1
      end

      select @leftpart = @leftpart + ' values('''

      -- Now fill @rightpart with the statement to retrieve the values of the fields, correctly formatted

      select @columncount     = MIN (num),
             @columncount_max = MAX (num)
        from #columninfo

      select @rightpart = ''

      while @columncount <= @columncount_max
      begin
        select @columnname = name,
               @columntype = usertype
          from #columninfo
         where num = @columncount

        if (@@rowcount <> 0)
        begin

          if @columntype in (39,47) /* char fields need quotes (except when entering NULL);
                                    *  use char(39) == ', easier readable than escaping
                                    */
          begin
            select @rightpart = @rightpart + '+'
            select @rightpart = @rightpart + 'ISNULL(' + replicate( char(39), 4 ) + '+replace(' + @columnname + ',' + replicate( char(39), 4 ) + ',' + replicate( char(39), 6) + ')+' + replicate( char(39), 4 ) + ',''NULL'')'
          end

          else if @columntype = 35 /* TEXT fields cannot be RTRIM-ed and need quotes     */
                                   /* convert to VC 1000 to leave space for other fields */
          begin
            select @rightpart = @rightpart + '+'
            select @rightpart = @rightpart + 'ISNULL(' + replicate( char(39), 4 ) + '+replace(convert(varchar(1000),' + @columnname + ')' + ',' + replicate( char(39), 4 ) + ',' + replicate( char(39), 6 ) + ')+' + replicate( char(39), 4 ) + ',''NULL'')'
          end

          else if @columntype in (58,61,111) /* datetime fields */
          begin
            select @rightpart = @rightpart + '+'
            -- GETDATE() 로 변경 by ceusee
           -- select @rightpart = @rightpart + 'GETDATE()'
           IF @columnname = 'updaterDate' OR @columnname = 'registerDate' 
                     select @rightpart = @rightpart + '''GETDATE()'''
   
             ELSE
                  select @rightpart = @rightpart + 'ISNULL(' + replicate( char(39), 4 ) + '+convert(varchar(20),' + @columnname + ')+'+ replicate( char(39), 4 ) + ',''NULL'')'
     
          end 

          else   /* numeric types */
          begin
            select @rightpart = @rightpart + '+'
            select @rightpart = @rightpart + 'ISNULL(convert(varchar(99),' + @columnname + '),''NULL'')'
          end


          if ( @columncount < @columncount_max)
          begin
            select @rightpart = @rightpart + '+'','''
          end

        end
        select @columncount = @columncount + 1
      end

    end

    select @rightpart = @rightpart + '+'')''' + ' from ' + @tablename

    -- Order the select-statements by the first column so you have the same order for
    -- different database (easy for comparisons between databases with different creation orders)
    select @rightpart = @rightpart + ' order by 1'

    -- For tables which contain an identity column we turn identity_insert on
    -- so we get exactly the same content

    if @hasident > 0
       select 'SET IDENTITY_INSERT ' + @tablename + ' ON'

    exec ( @leftpart + @rightpart )

    if @hasident > 0
       select 'SET IDENTITY_INSERT ' + @tablename + ' OFF'

    select @tablename      = MIN (name)
      from #tablenames
     where name            > @tablename
  end

end
GO

grant all on sp_generate_insert_script to public
GO

