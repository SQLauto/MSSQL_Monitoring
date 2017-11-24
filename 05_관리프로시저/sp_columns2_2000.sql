/*
	정원혁 2003.8.5.
	sp_columns보다 보기 좋은 형태로 출력변환
	참조: sp_helptext sp_columns 
    
	sysname > varchar(60)
	2005에서느는 시스템 테이블이 다름
	spt_datatype_info -> spt_values
*/
use master
go
if object_id('sp_columns2') is not null 
	drop proc sp_columns2
go
CREATE PROCEDURE sp_columns2 (
				 @table_name		nvarchar(384),
				 @table_owner		nvarchar(384) = null,
				 @table_qualifier	varchar(60) = null,
				 @column_name		nvarchar(384) = null,
				 @ODBCVer			int = 2)
AS
	DECLARE @full_table_name	nvarchar(769)
	DECLARE @table_id int

	if @ODBCVer <> 3
		select @ODBCVer = 2
	if @column_name is null /*	If column name not supplied, match all */
		select @column_name = '%'
	if @table_qualifier is not null
	begin
		if db_name() <> @table_qualifier
		begin	/* If qualifier doesn't match current database */
			raiserror (15250, -1,-1)
			return
		end
	end
	if @table_name is null
	begin	/*	If table name not supplied, match all */
		select @table_name = '%'
	end
	if @table_owner is null
	begin	/* If unqualified table name */
		SELECT @full_table_name = quotename(@table_name)
	end
	else
	begin	/* Qualified table name */
		if @table_owner = ''
		begin	/* If empty owner name */
			SELECT @full_table_name = quotename(@table_owner)
		end
		else
		begin
			SELECT @full_table_name = quotename(@table_owner) +
				'.' + quotename(@table_name)
		end
	end

	/*	Get Object ID */
	SELECT @table_id = object_id(@full_table_name)
	if ((isnull(charindex('%', @full_table_name),0) = 0) and
		(isnull(charindex('[', @table_name),0) = 0) and
		(isnull(charindex('[', @table_owner),0) = 0) and
		(isnull(charindex('_', @full_table_name),0) = 0) and
		@table_id <> 0)
	begin
		/* this block is for the case where there is no pattern
			matching required for the table name */
		
		SELECT
-- 			TABLE_QUALIFIER = convert(varchar(60),DB_NAME()),
			TABLE_OWNER = convert(varchar(60),USER_NAME(o.uid)),
			TABLE_NAME = convert(varchar(60),o.name),
			COLUMN_NAME = convert(varchar(60),c.name),
			d.DATA_TYPE,
			convert (varchar(60),case
				when t.xusertype > 255 then t.name
				else d.TYPE_NAME collate database_default
			end) TYPE_NAME,
			convert(int,case
				when d.DATA_TYPE in (6,7) then d.data_precision 		/* FLOAT/REAL */
				else OdbcPrec(c.xtype,c.length,c.xprec)
			end) "PRECISION",
			convert(int,case
				when type_name(d.ss_dtype) IN ('numeric','decimal') then	/* decimal/numeric types */
					OdbcPrec(c.xtype,c.length,c.xprec)+2
				else
					isnull(d.length, c.length)
			end) LENGTH,
			SCALE = convert(smallint, OdbcScale(c.xtype,c.xscale)),
--			d.RADIX,
			NULLABLE = convert(smallint, ColumnProperty (c.id, c.name, 'AllowsNull')),
			ORDINAL_POSITION = convert(int,
					   (
						select count(*)
						from syscolumns sc
						where sc.id     =  c.id
						  AND sc.number =  c.number
						  AND sc.colid  <= c.colid
					    )),

--			REMARKS = convert(varchar(254),null),	/* Remarks are NULL */
			COLUMN_DEF = text,
-- 			d.SQL_DATA_TYPE,
-- 			d.SQL_DATETIME_SUB,
			CHAR_OCTET_LENGTH = isnull(d.length, c.length)+d.charbin
--,
-- 			IS_NULLABLE = convert(varchar(254),
-- 				substring('NO YES',(ColumnProperty (c.id, c.name, 'AllowsNull')*3)+1,3)),
-- 			SS_DATA_TYPE = c.type
		FROM
			sysobjects o,
			master.dbo.spt_values d,
			systypes t,
			syscolumns c
			LEFT OUTER JOIN syscomments m on c.cdefault = m.id
				AND m.colid = 1
		WHERE
			o.id = @table_id
			AND c.id = o.id
			AND t.xtype = d.ss_dtype
			AND c.length = isnull(d.fixlen, c.length)
			AND (d.ODBCVer is null or d.ODBCVer = @ODBCVer)
			AND (o.type not in ('P', 'FN', 'TF', 'IF') OR (o.type in ('TF', 'IF') and c.number = 0))
			AND isnull(d.AUTO_INCREMENT,0) = isnull(ColumnProperty (c.id, c.name, 'IsIdentity'),0)
			AND c.xusertype = t.xusertype
			AND c.name like @column_name
		ORDER BY ORDINAL_POSITION
	end
	else
	begin
		/* this block is for the case where there IS pattern
			matching done on the table name */

		if @table_owner is null /*	If owner not supplied, match all */
			select @table_owner = '%'

		SELECT
			TABLE_QUALIFIER = convert(varchar(60),DB_NAME()),
			TABLE_OWNER = convert(varchar(60),USER_NAME(o.uid)),
			TABLE_NAME = convert(varchar(60),o.name),
			COLUMN_NAME = convert(varchar(60),c.name),
			d.DATA_TYPE,
			convert (varchar(60),case
				when t.xusertype > 255 then t.name
				else d.TYPE_NAME collate database_default
			end) TYPE_NAME,
			convert(int,case
				when d.DATA_TYPE in (6,7) then d.data_precision 		/* FLOAT/REAL */
				else OdbcPrec(c.xtype,c.length,c.xprec)
			end) "PRECISION",
			convert(int,case
				when type_name(d.ss_dtype) IN ('numeric','decimal') then	/* decimal/numeric types */
					OdbcPrec(c.xtype,c.length,c.xprec)+2
				else
					isnull(d.length, c.length)
			end) LENGTH,
			SCALE = convert(smallint, OdbcScale(c.xtype,c.xscale)),
			d.RADIX,
			NULLABLE = convert(smallint, ColumnProperty (c.id, c.name, 'AllowsNull')),
			REMARKS = convert(varchar(254),null),	/* Remarks are NULL */
			COLUMN_DEF = text,
			d.SQL_DATA_TYPE,
			d.SQL_DATETIME_SUB,
			CHAR_OCTET_LENGTH = isnull(d.length, c.length)+d.charbin,
			ORDINAL_POSITION = convert(int,
					   (
						select count(*)
						from syscolumns sc
						where sc.id     =  c.id
						  AND sc.number =  c.number
						  AND sc.colid  <= c.colid
					    ))
-- 			IS_NULLABLE = convert(varchar(254),
-- 				rtrim(substring('NO YES',(ColumnProperty (c.id, c.name, 'AllowsNull')*3)+1,3))),
--			SS_DATA_TYPE = c.type
		FROM
			sysobjects o,
			master.dbo.spt_datatype_info d,
			systypes t,
			syscolumns c
			LEFT OUTER JOIN syscomments m on c.cdefault = m.id
				AND m.colid = 1
		WHERE
			o.name like @table_name
			AND user_name(o.uid) like @table_owner
			AND o.id = c.id
			AND t.xtype = d.ss_dtype
			AND c.length = isnull(d.fixlen, c.length)
			AND (d.ODBCVer is null or d.ODBCVer = @ODBCVer)
			AND (o.type not in ('P', 'FN', 'TF', 'IF') OR (o.type in ('TF', 'IF') and c.number = 0))
			AND isnull(d.AUTO_INCREMENT,0) = isnull(ColumnProperty (c.id, c.name, 'IsIdentity'),0)
			AND c.xusertype = t.xusertype
			AND c.name like @column_name
		ORDER BY 2, 3, 17
	end
go
go 
grant all on sp_columns2 to public
go
use pubs
go 
sp_columns2 sales