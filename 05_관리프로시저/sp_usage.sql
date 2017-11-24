USE master
GO
IF OBJECT_ID('dbo.sp_usage') IS NOT NULL
  DROP PROC dbo.sp_usage
GO
CREATE PROCEDURE dbo.sp_usage 
			  -- Required parameters
			  @objectname sysname=NULL,
			  @desc sysname=NULL,

			  -- Optional parameters
			  @parameters varchar(8000)=NULL,
			  @returns varchar(8000)='(None)',
			  @example varchar(8000)=NULL,
			  @author sysname=NULL,
			  @email sysname='(none)',
	  		  @version sysname=NULL,
			  @revision sysname='0',
			  @datecreated smalldatetime=NULL,
			  @datelastchanged smalldatetime=NULL
/*


Object: sp_usage
Description: Provides usage information for stored procedures and descriptions of other types of objects

Usage: sp_usage @objectname="ObjectName", @desc="Description of object"
		   	[, @parameters="param1,param2..."]
			[, @example="Example of usage"]
			[, @author="Object author"]
			[, @email="Author email"]
			[, @version="Version number or info"]
			[, @revision="Revision number or info"]
			[, @datecreated="Date created"]
			[, @datelastchanged="Date last changed"]

Returns: (None)

Created by: Ken Henderson. Email: khen@khen.com

Version: 3.1

Example: sp_usage @objectname="sp_who", @desc="Returns a list of currently running jobs", @parameters=[@loginname]

Created: 1992-04-03.  Last changed: 1999-07-01.

*/
AS
SET NOCOUNT ON
IF (@objectname+@desc IS NULL) GOTO Help

PRINT 'Object: '+@objectname
PRINT 'Description: '+@desc

IF (OBJECTPROPERTY(OBJECT_ID(@objectname),'IsProcedure')=1)
OR   (OBJECTPROPERTY(OBJECT_ID(@objectname),'IsExtendedProc')=1)
OR   (OBJECTPROPERTY(OBJECT_ID(@objectname),'IsReplProc')=1) 
OR   (LOWER(LEFT(@objectname,3))='sp_') BEGIN -- Special handling for system procedures
  PRINT CHAR(13)+'Usage: '+@objectname+' '+@parameters
  PRINT CHAR(13)+'Returns: '+@returns
END

IF (@author IS NOT NULL)
  PRINT CHAR(13)+'Created by: '+@author+'. Email: '+@email
IF (@version IS NOT NULL)
  PRINT CHAR(13)+'Version: '+@version+'.'+@revision
IF (@example IS NOT NULL)
  PRINT CHAR(13)+'Example: '+@example
IF (@datecreated IS NOT NULL) BEGIN  -- Crop time if it's midnight
  DECLARE @datefmt varchar(8000), @dc varchar(30), @lc varchar(30)
  SET @dc=CONVERT(varchar(30), @datecreated, 120)
  SET @lc=CONVERT(varchar(30), @datelastchanged, 120)
  PRINT CHAR(13)+'Created: '+CASE DATEDIFF(ss,CONVERT(char(8),@datecreated,108),'00:00:00') WHEN 0 THEN LEFT(@dc,10) ELSE @dc END
+'.  Last changed: '+CASE DATEDIFF(ss,CONVERT(char(8),@datelastchanged,108),'00:00:00') WHEN 0 THEN LEFT(@lc,10) ELSE @lc END+'.'
END

RETURN 0

Help:
EXEC sp_usage @objectname='sp_usage',		-- Recursive call
  	   @desc='Provides usage information for stored procedures and descriptions of other types of objects',
	   @parameters='@objectname="ObjectName", @desc="Description of object"
	   	[, @parameters="param1,param2..."]
		[, @example="Example of usage"]
		[, @author="Object author"]
		[, @email="Author email"]
		[, @version="Version number or info"]
		[, @revision="Revision number or info"]
		[, @datecreated="Date created"]
		[, @datelastchanged="Date last changed"]',
	   @example='sp_usage @objectname="sp_who", @desc="Returns a list of currently running jobs", @parameters=[@loginname]',
	   @author='Ken Henderson',
	   @email='khen@khen.com',
	   @version='3', @revision='1',
	   @datecreated='4/3/92', @datelastchanged='7/1/99'
RETURN -1

GO