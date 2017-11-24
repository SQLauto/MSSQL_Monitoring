/*----------------------------------------------------
    Date    : 2008-
    Note    :
    No.     :
*----------------------------------------------------*/
use dba
go

--====================================
-- �ӽ� ���̺� 2008/07/01 ����
--====================================
CREATE TABLE DBA_OPERATOR_TEMP
  (
    OID     INT     NOT NULL,
    HPNO    VARCHAR(15) NULL,
    EMAIL   varchar(50) NULL,
    JOBFLAG TINYINT NULL,
    DBFLAG  TINYINT NULL,
    LOGICFLAG TINYINT NULL,
    BACKUPFLAG TINYINT NULL,
    HWFLAG     TINYINT NULL,
    TEMCODE     TINYINT NULL,
    CHG_DT      DATETIME NULL
  )
----DBA��-200807-���̺�Į���ݿ���ûȮ�μ�(IT����)-10001
go
 
 -- not null �̿��� �ʵ� null �� ����
 ALTER  TABLE OperatorSimple ALTER COLUMN jobflag tinyint null 
 ALTER  TABLE OperatorSimple ALTER COLUMN hwflag tinyint null 
 ALTER  TABLE OperatorSimple ALTER COLUMN LOGICFLAG tinyint null 
 ALTER  TABLE OperatorSimple ALTER COLUMN TEMCODE tinyint null 
 ALTER  TABLE OperatorSimple ALTER COLUMN DBFLAG tinyint null
 ALTER  TABLE OperatorSimple ALTER COLUMN BACKUPFLAG tinyint null
--DBA��-200807-���̺�Į���ݿ���ûȮ�μ�(IT����)-10001
go

drop procedure up_DBA_SyncOperator
go
--DBA��-200807-���̺�Į���ݿ���ûȮ�μ�(IT����)-10001

--=========================================================
-- ���ν���
--=========================================================

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* ���ν�����  : dbo.up_dba_select_operatorsimple 
* �ۼ�����    : 2008-06-30 by choi bo ra
* ����������  :  
* ����        : OperatorSimple ���̺��� operatrNo ��ȸ
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_operatorsimple
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT operatorNo
    ,jobflag 
    ,dbFlag
    ,logicFlag 
    ,temCode
    ,backupFlag 
    ,hwFlag 
    ,changeDate
FROM DBA.dbo.OperatorSimple with (nolock)
ORDER  BY operatorNo

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* ���ν�����  : dbo.up_dba_delete_operatorsimple 
* �ۼ�����    : 2008-06-30 by choi bo ra
* ����������  :  
* ����        : ����� ���� ����
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_delete_operatorsimple
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
/* BODY */
DELETE  OperatorSimple
FROM DBA.dbo.DBA_OPERATOR_TEMP AS M WITH (NOLOCK) JOIN dbo.OperatorSimple AS O WITH (NOLOCK)
    ON M.Oid = O.operatorNo 



RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* ���ν�����  : dbo.up_dba_select_target_operatorsimple 
* �ۼ�����    : 2008-06-30 by choi bo ra
* ����������  :  
* ����        : update �ؾ��� 
                OperatorSimple ���̺��� operatrNo ��ȸ
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_target_operatorsimple
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT operatorNo, changedate
FROM DBA.dbo.OperatorSimple with (nolock)
ORDER BY operatorNo

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* ���ν�����  : dbo.up_update_operatorsimple 
* �ۼ�����    : 2008-06-30
* ����������  :  
* ����        : Ÿ���� �Ǵ� Operatorsiple ���̺� ���泻�� ����
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_update_operatorsimple
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
UPDATE dbo.OperatorSimple
SET HPNo = T.HPNO,
    Email = T.EMAIL,
    jobflag = T.JOBFLAG,
    dbFlag = T.DBFLAG,
    logicFlag = T.logicFlag,
    temCode = T.temCode,
    backupFlag = T.backupFlag,
    hwFlag = T.hwFlag,
    changedate= ISNULL(T.chg_dt,GETDATE())
FROM dbo.DBA_OPERATOR_TEMP AS T JOIN dbo.OperatorSimple AS O WITH (NOLOCK)
    ON T.Oid = O.operatorNo 

RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO