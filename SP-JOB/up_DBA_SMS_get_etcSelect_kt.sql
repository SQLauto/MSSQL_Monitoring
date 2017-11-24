/*************************************************************************      
* 프로시저명  : dbo.up_DBA_SMS_get_etcSelect_kt  
* 작성정보    : 2008-08-27    
* 관련페이지  : 인성환    
* 내용        : KT SMS전송- 기타 관련     
* 수정정보    : CRM DB로 이전     
**************************************************************************/    
CREATE  PROCEDURE dbo.up_DBA_SMS_get_etcSelect_kt    
AS     
     
 SET NOCOUNT ON    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
     
 DECLARE @miniid int     
 DECLARE @maxiid int     
    
 SELECT @miniid = isnull(min(iid),0),@maxiid = isnull(max(iid),0) FROM dbo.SMSMSG_ETC with(nolock, index=IDX__SMSMSG_ETC__DT_YN) WHERE reg_dt > dateadd(dd, -3, getdate()) and send_yn = 'N' and sendmsg is not null       
    
 --원본테이블에서 SMS실제발송테이블로 들어가는 데이터들의 iid값을 임시테이블에 업데이트     
 IF @miniid <> 0 and @maxiid <> 0     
 BEGIN    
  UPDATE dbo.SMSMSG_CHK_SENDYN    
  SET     
    min_iid = @miniid    
   , max_iid = @maxiid    
  WHERE tb_name = 'ETC'      
      
 END    
    
 BEGIN     
  SELECT     
    rtrim(ltrim(convert( varchar(15), replace(hp_no,'-','')))) COLLATE Korean_Wansung_CS_AS as hp_no 
   ,  '160701001004' COLLATE Korean_Wansung_CS_AS  as origin    
   ,  convert( varchar(15), send_no) COLLATE Korean_Wansung_CS_AS as send_no  
   ,  '1' COLLATE Korean_Wansung_CS_AS as proc_status  
   ,  rsrv_dt as reserve_date    
   ,  isnull(sendmsg,'') COLLATE Korean_Wansung_CS_AS  as sendmsg  
   ,  flow_no    
   ,  pack_no    
   ,  contr_no    
   ,  reg_id COLLATE Korean_Wansung_CS_AS as reg_id      
   , cust_no COLLATE Korean_Wansung_CS_AS as cust_no     
  FROM dbo.SMSMSG_ETC with(nolock)    
  WHERE iid >= @miniid    
    AND iid <= @maxiid    
      
 END     
    
 SET NOCOUNT OFF 

