/*************************************************************************  
* ���ν�����  : dbo.object_change_hist
* �ۼ�����    : 2007-10-30
* ����������  :  
* ����        : HISTORY������ ���� ���� ���̺�
* ��������    : 
**************************************************************************/
CREATE TABLE dbo.object_change_hist
(
    SEQ_NO          INT             NOT NULL IDENTITY(1,1)      -- ��Ϲ�ȣ
,   SP_NM           SYSNAME         NULL                        -- SP��
,   OBJ_ID          INT             NULL                        -- OBJECT ID
,   SCHEM_ID        INT             NULL                        -- ��Ű��ID==>SCHEMA_NAME(schem_id)�� ������ binding
,   CREATE_DT       DATETIME        NULL                        -- �����
,   MODIFY_DT       DATETIME        NULL                        -- ������
,   REG_DT          DATETIME   NULL CONSTRAINT DF__OBJECT_CHANGE_HIST__REG_DT DEFAULT(getdate())
   CONSTRAINT PK__OBJECT_CHANGE_HIST__REG_DT PRIMARY KEY NONCLUSTERED (SEQ_NO) 
)

CREATE CLUSTERED INDEX CIDX__REG_DT
ON dbo.object_change_hist(REG_DT)