/*************************************************************************  
* 프로시저명  : dbo.object_change_hist
* 작성정보    : 2007-10-30
* 관련페이지  :  
* 내용        : HISTORY보관을 위한 적재 테이블
* 수정정보    : 
**************************************************************************/
CREATE TABLE dbo.object_change_hist
(
    SEQ_NO          INT             NOT NULL IDENTITY(1,1)      -- 등록번호
,   SP_NM           SYSNAME         NULL                        -- SP명
,   OBJ_ID          INT             NULL                        -- OBJECT ID
,   SCHEM_ID        INT             NULL                        -- 스키마ID==>SCHEMA_NAME(schem_id)로 소유자 binding
,   CREATE_DT       DATETIME        NULL                        -- 등록일
,   MODIFY_DT       DATETIME        NULL                        -- 수정일
,   REG_DT          DATETIME   NULL CONSTRAINT DF__OBJECT_CHANGE_HIST__REG_DT DEFAULT(getdate())
   CONSTRAINT PK__OBJECT_CHANGE_HIST__REG_DT PRIMARY KEY NONCLUSTERED (SEQ_NO) 
)

CREATE CLUSTERED INDEX CIDX__REG_DT
ON dbo.object_change_hist(REG_DT)