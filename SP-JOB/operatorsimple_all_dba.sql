/*----------------------------------------------------
    Date    : 2008-
    Note    :
    No.     :
*----------------------------------------------------*/
use dba
go

--====================================
-- 임시 테이블 2008/07/01 생성
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
----DBA팀-200807-테이블칼럼반영요청확인서(IT전용)-10001
go
 
 -- not null 이였던 필드 null 로 변경
 ALTER  TABLE OperatorSimple ALTER COLUMN jobflag tinyint null 
 ALTER  TABLE OperatorSimple ALTER COLUMN hwflag tinyint null 
 ALTER  TABLE OperatorSimple ALTER COLUMN LOGICFLAG tinyint null 
 ALTER  TABLE OperatorSimple ALTER COLUMN TEMCODE tinyint null 
 ALTER  TABLE OperatorSimple ALTER COLUMN DBFLAG tinyint null
 ALTER  TABLE OperatorSimple ALTER COLUMN BACKUPFLAG tinyint null
--DBA팀-200807-테이블칼럼반영요청확인서(IT전용)-10001
go

drop procedure up_DBA_SyncOperator
go
--DBA팀-200807-테이블칼럼반영요청확인서(IT전용)-10001

--=========================================================
-- 프로시저
--=========================================================

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* 프로시저명  : dbo.up_dba_select_operatorsimple 
* 작성정보    : 2008-06-30 by choi bo ra
* 관련페이지  :  
* 내용        : OperatorSimple 테이블의 operatrNo 조회
* 수정정보    :
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
* 프로시저명  : dbo.up_dba_delete_operatorsimple 
* 작성정보    : 2008-06-30 by choi bo ra
* 관련페이지  :  
* 내용        : 퇴사한 직원 삭제
* 수정정보    :
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
* 프로시저명  : dbo.up_dba_select_target_operatorsimple 
* 작성정보    : 2008-06-30 by choi bo ra
* 관련페이지  :  
* 내용        : update 해야할 
                OperatorSimple 테이블의 operatrNo 조회
* 수정정보    :
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
* 프로시저명  : dbo.up_update_operatorsimple 
* 작성정보    : 2008-06-30
* 관련페이지  :  
* 내용        : 타켓이 되는 Operatorsiple 테이블에 변경내역 저장
* 수정정보    :
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