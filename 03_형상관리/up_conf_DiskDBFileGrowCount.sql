/*************************************************************************    
* ���ν�����  : dbo.up_conf_DiskDBFileGrowCount 
* �ۼ�����    : 2010-09-30 by ������ Disk ����  
* ����������  :   
* ����       :   
* ��������    : 2012-09-28 by choi bo ra ����Ʈ ������ ���� site_gn �� �߰�  
**************************************************************************/  
CREATE PROCEDURE dbo.up_conf_DiskDBFileGrowCount
	@server_id int 
set nocount on
declare @disk nvarchar(100)
declare @str nvarchar(1000)
declare @reg_date date

set @disk = ''
select  @disk =  @disk + ',' + '[' + letter + ']'   from disk_size where server_id = @server_id
set @disk = substring (@disk, 2, len(@disk))

select top 1  @reg_date = reg_dt from DATABASE_FILE_LIST where server_id = @server_id order by reg_dt desc

set @str = '
	      SELECT *  ' + char(10)
		 + 'FROM ( ' + char(10)
		 + 'SELECT  F.REG_DT, D.DB_NAME,  ' + char(10)
		+ '		LEFT(FILE_FULL_NAME, 1) AS LETTER, ' + char(10)
		+ '		ISNULL(SUM(CASE WHEN GROWTH > 0 AND MAX_SIZE < 0 AND FILE_ID !=2  AND F.DB_ID >4  THEN 1 ELSE 0  END), 0) AS [DB_GROWTH COUNT]   ' + char(10)
		+ '	FROM DATABASE_FILE_LIST  AS F  ' + char(10)
		+ '	JOIN  DATABASE_LIST_TODAY AS D ON F.DB_ID = D.DB_ID  AND F.SERVER_ID = D.SERVER_ID  ' + char(10)
		+ '	WHERE F.SERVER_ID =' + CONVERT(NVARCHAR(4),@SERVER_ID) + ' AND F.REG_DT ='''+ convert(nvarchar(10),@reg_date, 121) + '''  ' + char(10)
		+ '	GROUP BY F.REG_DT, D.DB_NAME,  LEFT(FILE_FULL_NAME, 1)  ' + char(10)
		+ '  ) AA  ' + char(10)
		+ 'PIVOT  ' + char(10)
		+ '(  ' + char(10)
		+ '	 MAX([DB_GROWTH COUNT])  ' + char(10)
		+ '	FOR LETTER IN (' + @disk + ')' + char(10)
		+ ') AS PVT  ' + char(10)
print @str
EXECUTE sp_executesql @str
go