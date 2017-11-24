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
* ���ν�����  : dbo.fn_StringSingleTable 
* �ۼ�����    : 2007-07-19 by ceusee(choi bo ra)
* ����������  :  
* ����        : ���ڿ� �Է¹����� �����ڷ� �����Ͽ� ���̺� ��ȯ
* ��������    :
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

    -- ��� �׸��� �˻��� ������ ��Ʈ ó��
    WHILE @iExit = 0
    BEGIN
        -- ���й��ڸ� �������� ���� �׸��� ��ġ �˻�
        SET @iPosEnd = CHARINDEX(@delimiter, @list, @iPosStart)

        IF @iPosEnd <= 0
        BEGIN
            SET @iPosEnd = LEN(@list) + 1
            SET @iExit = 1
        END

        -- �Ʒ� @vcStr�� �ʿ��� ��� LTRIM, RTRIM�� �����ؾ� �Ѵ�.
        SET @vcStr = SUBSTRING(@list, @iPosStart, @iPosEnd - @iPosStart)

        -- ���̺� ������ ����
        INSERT INTO @StingSingle (Value) VALUES (@vcStr)

        -- ���� �˻� ��ġ�� �̵�
        SET @iPosStart = @iPosEnd + @iLenDelim
    END

    RETURN
END
GO