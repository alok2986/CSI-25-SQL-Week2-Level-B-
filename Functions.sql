Functions
1. Date Format Function (MM/DD/YYYY)
CREATE FUNCTION dbo.FormatDateMMDDYYYY
(
    @InputDate DATETIME
)
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN CONVERT(VARCHAR(10), @InputDate, 101);
END;
GO

-- Example usage:
-- SELECT dbo.FormatDateMMDDYYYY('2006-11-21 23:34:05.920') AS FormattedDate;

2. Date Format Function (YYYYMMDD)
CREATE FUNCTION dbo.FormatDateYYYYMMDD
(
    @InputDate DATETIME
)
RETURNS CHAR(8)
AS
BEGIN
    RETURN CONVERT(CHAR(8), @InputDate, 112);
END;
GO

-- Example usage:
-- SELECT dbo.FormatDateYYYYMMDD('2006-11-21 23:34:05.920') AS FormattedDate;