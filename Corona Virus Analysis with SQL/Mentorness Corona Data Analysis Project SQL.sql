USE [Mentorness SQL]
SELECT * FROM [Corona Virus Dataset]

-- Data cleaning 
-- Check text column for inconsistency

SELECT *
FROM [Corona Virus Dataset]
WHERE PATINDEX('%[^a-zA-Z ]%', Province) > 0 OR PATINDEX('%[^a-zA-Z ]%', [Country/Region]) > 0;

SELECT Province, [Country/Region]
FROM [Corona Virus Dataset]
WHERE PATINDEX('%[^a-zA-Z ]%', Province) > 0 OR PATINDEX('%[^a-zA-Z ]%', [Country/Region]) > 0
GROUP BY Province, [Country/Region];

-- remove * from Taiwan* 

UPDATE [Corona Virus Dataset]
SET Province = REPLACE(Province, '*', '')
WHERE Province = 'Taiwan*';

UPDATE [Corona Virus Dataset]
SET [Country/Region] = REPLACE([Country/Region], '*', '')
WHERE [Country/Region] = 'Taiwan*';

-- further data cleaning

-- Check for non-numeric values in numeric column
SELECT *
FROM [Corona Virus Dataset]
WHERE ISNUMERIC(Latitude) = 0 OR ISNUMERIC(Longitude) = 0 OR ISNUMERIC(Confirmed) = 0 OR ISNUMERIC(Deaths) = 0 OR ISNUMERIC(Recovered) = 0;

-- non found

-- Check for non-date values in date column

SELECT Date
FROM [Corona Virus Dataset]
WHERE TRY_CONVERT(DATE, Date) IS NULL;

-- clean up incorrect date entries

UPDATE [Corona Virus Dataset]
SET Date = CASE 
WHEN CHARINDEX('/', Date) > 0 THEN TRY_CONVERT(DATE, Date, 103)
ELSE TRY_CONVERT(DATE, Date, 105)
END;

-- convert columns to right data type

ALTER TABLE [Corona Virus Dataset]
ALTER COLUMN Confirmed FLOAT;

ALTER TABLE [Corona Virus Dataset]
ALTER COLUMN Deaths FLOAT;

ALTER TABLE [Corona Virus Dataset]
ALTER COLUMN Recovered FLOAT;

ALTER TABLE [Corona Virus Dataset]
ALTER COLUMN Date DATE;


-- To avoid any errors, check missing value / null value 
-- Q1. Write a code to check NULL values

DECLARE @TableName NVARCHAR(255) = 'Corona Virus Dataset';

DECLARE @SqlQuery NVARCHAR(MAX);

SET @SqlQuery = (
    SELECT 
        'SELECT ''' + COLUMN_NAME + ''' AS ColumnName, COUNT(*) AS NullCount FROM ' +'['+ @TableName + ']'+' WHERE [' + COLUMN_NAME + '] IS NULL UNION ALL '
    FROM 
        INFORMATION_SCHEMA.COLUMNS 
    WHERE 
        TABLE_NAME = @TableName
    FOR XML PATH('')
);

SET @SqlQuery = LEFT(@SqlQuery, LEN(@SqlQuery) - 10);

EXEC sp_executesql @SqlQuery;

--Q2. If NULL values are present, update them with zeros for all columns. 

-- Answer: No nulls found


-- Q3. check total number of rows

SELECT COUNT (*) AS TOTAL_ROW_COUNT
FROM [Corona Virus Dataset]

-- Q4. Check what is start_date and end_date
-- Answer start_date

SELECT MIN (Date) AS start_date
FROM [Corona Virus Dataset];


-- Answer end_date

SELECT MAX (Date) AS end_date
FROM [Corona Virus Dataset];

-- Q5. Number of month present in dataset

SELECT COUNT(DISTINCT (FORMAT(Date, 'MM-yyyy'))) AS number_of_months
FROM [Corona Virus Dataset];


-- Q6. Find monthly average for confirmed, deaths, recovered

SELECT 
    FORMAT(Date, 'MM-yyyy') AS Month, 
    ROUND(AVG(Confirmed), 2) AS Average_Confirmed, 
    ROUND(AVG(Deaths), 2) AS Average_Deaths, 
    ROUND(AVG(Recovered), 2) AS Average_Recovered
FROM 
    [Corona Virus Dataset]
GROUP BY 
    FORMAT(Date, 'MM-yyyy');


-- Q7. Find most frequent value for confirmed, deaths, recovered each month 

-- most frequent value for confirmed each month
WITH
ConfirmedCounts AS (
    SELECT 
        FORMAT(Date, 'MM-yyyy') AS Month,
        Confirmed,
        COUNT(*) AS CountConfirmed
    FROM [Corona Virus Dataset]
    GROUP BY FORMAT(Date, 'MM-yyyy'), Confirmed
),

RankedCounts AS (
    SELECT 
        Month, 
        Confirmed, 
        CountConfirmed,
        ROW_NUMBER() OVER (PARTITION BY Month ORDER BY CountConfirmed DESC) AS rank
    FROM ConfirmedCounts
)

SELECT Month, Confirmed
FROM RankedCounts
WHERE rank = 1;

-- most frequent value for deaths each month
WITH
DeathsCounts AS (
    SELECT 
        FORMAT(Date, 'MM-yyyy') AS Month,
        Deaths,
        COUNT(*) AS CountDeath
    FROM [Corona Virus Dataset]
    GROUP BY FORMAT(Date, 'MM-yyyy'), Deaths
),

RankedCounts AS (
    SELECT 
        Month, 
        Deaths, 
        CountDeath,
        ROW_NUMBER() OVER (PARTITION BY Month ORDER BY CountDeath DESC) AS rank
    FROM DeathsCounts
)

SELECT Month, Deaths
FROM RankedCounts
WHERE rank = 1;


-- most frequent value for recovered each month
WITH
RecoveredCounts AS (
    SELECT 
        FORMAT(Date, 'MM-yyyy') AS Month,
        Recovered,
        COUNT(*) AS CountRecovered
    FROM [Corona Virus Dataset]
    GROUP BY FORMAT(Date, 'MM-yyyy'), Recovered

),

RankedCounts AS (
    SELECT 
        Month, 
        Recovered, 
        CountRecovered,
        ROW_NUMBER() OVER (PARTITION BY Month ORDER BY CountRecovered DESC) AS rank
    FROM RecoveredCounts
)

SELECT Month, Recovered
FROM RankedCounts
WHERE rank = 1;

-- Q8. Find minimum values for confirmed, deaths, recovered per year

SELECT 
	FORMAT(Date, 'yyyy') AS Year,
	MIN(Confirmed) AS Minimum_Confirmed, MIN(Deaths) AS Minimum_Deaths, MIN(Recovered) AS Minimum_Recovered
FROM [Corona Virus Dataset]
GROUP BY FORMAT(Date, 'yyyy')

-- Q9. Find maximum values of confirmed, deaths, recovered per year

SELECT 
	FORMAT(Date, 'yyyy') AS Year,
	MAX(Confirmed)  AS Maximum_Confirmed, MAX(Deaths)  AS Maximum_Deaths, MAX(Recovered)  AS Maximum_Recovered
FROM [Corona Virus Dataset]
GROUP BY FORMAT(Date, 'yyyy')


-- Q10. The total number of case of confirmed, deaths, recovered each month

SELECT 
	FORMAT(Date, 'MM-yyyy') AS Month,
	SUM(Confirmed)  AS Total_Confirmed, SUM(Deaths)  AS Total_Deaths, SUM(Recovered)  AS Total_Recovered
FROM [Corona Virus Dataset]
GROUP BY FORMAT(Date, 'MM-yyyy')

-- Q11. Check how corona virus spread out with respect to confirmed case
--      (Eg.: total confirmed cases, their average, variance & STDEV )

SELECT 
    SUM(Confirmed) AS Total_Confirmed, 
    ROUND(AVG(Confirmed), 2) AS Mean_Confirmed, 
    ROUND(VARP(Confirmed), 2) AS Variance_Confirmed, 
    ROUND(STDEV(Confirmed), 2) AS STDEV_Confirmed
FROM 
    [Corona Virus Dataset];


-- Q12. Check how corona virus spread out with respect to death case per month
--      (Eg.: total confirmed cases, their average, variance & STDEV )

SELECT 
    FORMAT(Date, 'MM-yyyy') AS Month, 
    SUM(Deaths) AS Total_Deaths, 
    ROUND(AVG(Deaths), 2) AS Mean_Deaths, 
    ROUND(VARP(Deaths), 2) AS Variance_Deaths, 
    ROUND(STDEV(Deaths), 2) AS STDEV_Deaths
FROM 
    [Corona Virus Dataset]
GROUP BY 
    FORMAT(Date, 'MM-yyyy');


-- Q13. Check how corona virus spread out with respect to recovered case
--      (Eg.: total confirmed cases, their average, variance & STDEV )

SELECT 
    SUM(Recovered) AS Total_Recovered, 
    ROUND(AVG(Recovered), 2) AS Mean_Recovered, 
    ROUND(VARP(Recovered), 2) AS Variance_Recovered, 
    ROUND(STDEV(Recovered), 2) AS STDEV_Recovered
FROM 
    [Corona Virus Dataset];


-- Q14. Find Country having highest number of the Confirmed case

SELECT TOP 1 [Country/Region], SUM (Confirmed) AS TotalConfirmed
FROM [Corona Virus Dataset]
GROUP BY [Country/Region]
ORDER BY SUM (Confirmed) DESC

-- Q15. Find Country having lowest number of the death case


SELECT TOP 1 [Country/Region], SUM (Deaths) AS TotalRecovered
FROM [Corona Virus Dataset]
GROUP BY [Country/Region]
ORDER BY SUM (Deaths) ASC

-- Q16. Find top 5 countries having highest recovered case

SELECT TOP 5 [Country/Region], SUM (Recovered) AS TotalRecovered
FROM [Corona Virus Dataset]
GROUP BY [Country/Region]
ORDER BY SUM (Recovered) DESC