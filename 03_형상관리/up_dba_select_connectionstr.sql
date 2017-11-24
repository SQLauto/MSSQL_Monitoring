/*************************************************************************  
* 프로시저명  : dbo.up_dba_select_connectionstr 
* 작성정보    : 2010-02-03 by 노상국
* 관련페이지  :  
* 내용        :
* 수정정보    : 2010-02-16 by choi bo ra, 수집을 유형에 따른 서버 정보 옵션
**************************************************************************/
CREATE procedure up_dba_select_connectionstr 
    @site           nvarchar(15),
    @type           nvarchar(10)
as

set nocount on
if @type = 'INFO'
BEGIN
    
    select s.server_id, s.server_name,  i.instance_id, i.instance_name, s.server_public_ip, i.instance_port
    from dbo.SERVERINFO s	with(nolock) join dbo.INSTANCE i with(nolock)
        on s.server_id = i.server_id
    where i.suzip_yn = 'Y' and  ((@site is null AND s.site_gn = s.site_gn ) or  s.site_gn = @site)
END
ELSE IF @type = 'MONITRONG'
BEGIN
    select s.server_id, s.server_name,  i.instance_id, i.instance_name, s.server_public_ip, i.instance_port
    from dbo.SERVERINFO s	with(nolock) join dbo.INSTANCE i with(nolock)
        on s.server_id = i.server_id
    where i.monitor_yn = 'Y' and  ((@site is null AND s.site_gn = s.site_gn ) or  s.site_gn = @site)
END
ELSE IF @type = 'JOB'
BEGIN
    select s.server_id, s.server_name,  i.instance_id, i.instance_name, s.server_public_ip, i.instance_port
    from dbo.SERVERINFO s	with(nolock) join dbo.INSTANCE i with(nolock)
        on s.server_id = i.server_id
    where i.job_monitor_yn = 'Y' and  ((@site is null AND s.site_gn = s.site_gn ) or  s.site_gn = @site)
END


return
