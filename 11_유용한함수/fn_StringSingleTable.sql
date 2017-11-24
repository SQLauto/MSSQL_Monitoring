SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
IF EXISTS (SELECT name 
	   FROM   sysobjects
	   WHERE  name = N'fn_StringSingleTable' 
	   AND 	  type = 'TF')
    DROP FUNCTION  fn_StringSingleTable
GO

/*************************************************************************  
* 프로시저명  : dbo.fn_StringSingleTable 
* 작성정보    : 2007-07-19 by ceusee(choi bo ra)
* 관련페이지  :  
* 내용        : 문자열 입력받으면 구분자로 구분하여 테이블 반환
* 수정정보    :
**************************************************************************/
CREATE FUNCTION dbo.fn_StringSingleTable
(    @list VARCHAR(8000)
    , @delimiter    VARCHAR(2) )
RETURNS @StingSingle TABLE (IndexNo int identity, Value varchar(100))
BEGIN
    DECLARE    @iPosStart    INT,
        @iPosEnd    int,
        @iLenDelim    tinyint,
        @iExit        tinyint,
        @vcStr        varchar(100)

    SET @iPosStart = 1
    SET @iPosEnd = 1
    SET @iLenDelim = LEN(@delimiter)

    SET @iExit = 0

    -- 모든 항목을 검색할 때까지 루트 처리
    WHILE @iExit = 0
    BEGIN
        -- 구분문자를 기준으로 다음 항목의 위치 검색
        SET @iPosEnd = CHARINDEX(@delimiter, @list, @iPosStart)

        IF @iPosEnd <= 0
        BEGIN
            SET @iPosEnd = LEN(@list) + 1
            SET @iExit = 1
        END

        -- 아래 @vcStr은 필요한 경우 LTRIM, RTRIM을 적용해야 한다.
        SET @vcStr = SUBSTRING(@list, @iPosStart, @iPosEnd - @iPosStart)

        -- 테이블 변수에 저장
        INSERT INTO @StingSingle (Value) VALUES (@vcStr)

        -- 다음 검색 위치로 이동
        SET @iPosStart = @iPosEnd + @iLenDelim
    END

    RETURN
END
GO