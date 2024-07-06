-- Project  Questions
-- =======================================================================================================
-- Which unicorn companies have had the biggest return on investment?
-- How long does it usually take for a company to become a unicorn?
-- Which industries have the most unicorns? 
-- Which countries have the most unicorns? 
-- Which investors have funded the most unicorns?

-- Data Cleaning for Unicorn Companies Analytics Project
SELECT * FROM unicorn_project.unicorn_companies;
-- Verify the columns in unicorn_companies table
DESCRIBE unicorn_companies;

-- Create unicorn_info table
CREATE TABLE unicorn_infoma (
    Company VARCHAR(255),
    Industry VARCHAR(255),
    City VARCHAR(255),
    Country VARCHAR(255),
    Continent VARCHAR(255),
    `Year Founded` INT
);

-- Describe unicorn_inf table
DESCRIBE unicorn_infoma;

-- Create unicorn_finance table
CREATE TABLE unicorn_financi (
    Company VARCHAR(255),
    Valuation VARCHAR(50),
    Funding VARCHAR(50),
    `Date Joined` VARCHAR(50),
    `Select Investors` TEXT,
    Year INT,
    Month INT,
    Day INT
);

-- Describe unicorn_financi table
DESCRIBE unicorn_financi;

-- Insert data into unicorn_inf table
INSERT INTO unicorn_infoma (Company, Industry, City, Country, Continent, `Year Founded`)
SELECT Company, Industry, City, Country, Continent, `Year Founded`
FROM unicorn_companies;

-- Verify data insertion into unicorn_inf
SELECT * FROM unicorn_infoma;

-- Insert data into unicorn_finc table
INSERT INTO unicorn_financi (Company, Valuation, Funding, `Date Joined`, `Select Investors`, Year, Month, Day)
SELECT 
    Company, 
    Valuation, 
    Funding, 
    `Date Joined`, 
    `Select Investors`, 
    YEAR(STR_TO_DATE(`Date Joined`, '%Y-%m-%d')) AS Year, 
    MONTH(STR_TO_DATE(`Date Joined`, '%Y-%m-%d')) AS Month, 
    DAY(STR_TO_DATE(`Date Joined`, '%Y-%m-%d')) AS Day
FROM unicorn_companies;

-- Verify data insertion into unicorn_finc
SELECT * FROM unicorn_financi;
-- Check for duplicate company names in unicorn_infoma
SELECT Company, COUNT(Company)
FROM unicorn_infoma
GROUP BY Company
HAVING COUNT(Company) > 1;
-- Check for duplicate company names in unicorn_financi
SELECT Company, COUNT(Company) as count
FROM unicorn_financi
GROUP BY Company
HAVING COUNT(Company) > 1;



-- Rename columns in unicorn_info
ALTER TABLE unicorn_info CHANGE `Year Founded` YearFounded INT;

-- Rename columns in unicorn_finance
ALTER TABLE unicorn_finance CHANGE `Date Joined` DateJoined VARCHAR(50);
ALTER TABLE unicorn_finance CHANGE `Select Investors` SelectInvestors TEXT;

select * from unicorn_finance;
SHOW TABLES;
SELECT * FROM unicorn_info;
SELECT * FROM unicorn_finance;

-- Bolt and Fabric appear twice in both data sets. Anyway, they are in different cities / countries. 
-- Therefore, we will keep those data
-- Rename Columns in unicorn_info Table
ALTER TABLE unicorn_infoma
CHANGE COLUMN `Year Founded` YearFounded INT;

-- Rename Columns in unicorn_finance Table
ALTER TABLE unicorn_financi
CHANGE COLUMN `Date Joined` DateJoined VARCHAR(50),
CHANGE COLUMN `Select Investors` SelectInvestors TEXT;

-- verify the Changes
SELECT *
FROM unicorn_financi;

-- Add DateJoinedConverted column
ALTER TABLE unicorn_financi
ADD DateJoinedConverted DATE;

-- Convert and populate DateJoinedConverted column
SET SQL_SAFE_UPDATES = 0;
UPDATE unicorn_financi
SET DateJoinedConverted = STR_TO_DATE(DateJoined, '%Y-%m-%d');

-- Populate Year, Month, and Day columns
UPDATE unicorn_financi
SET Year = YEAR(DateJoinedConverted),
    Month = MONTH(DateJoinedConverted),
    Day = DAY(DateJoinedConverted);
-- Verify the changes
SELECT *
FROM unicorn_financi;
-- Drop rows where Funding column contain 0 or Unknown
    DELETE FROM unicorn_financi
WHERE Funding IN ('$0M', 'Unknown');

-- Select distinct values from the Funding column and order them in descending order
SELECT DISTINCT Funding
FROM unicorn_financi
ORDER BY Funding DESC;

-- Reformat currency values

-- Remove the leading '$' symbol from the Valuation and Funding columns
UPDATE unicorn_financi
SET Valuation = SUBSTRING(Valuation, 2);

UPDATE unicorn_financi
SET Funding = SUBSTRING(Funding, 2);

-- Convert 'B' and 'M' to numerical values in the Valuation column
UPDATE unicorn_financi
SET Valuation = REPLACE(REPLACE(Valuation, 'B','000000000'), 'M', '000000');

-- Convert 'B' and 'M' to numerical values in the Funding column
UPDATE unicorn_financi
SET Funding = REPLACE(REPLACE(Funding, 'B','000000000'), 'M', '000000');

-- Select all records to verify the updates
SELECT * FROM unicorn_financi;

-- Delete Unused Columns and Rename Columns

-- Drop the DateJoined column
ALTER TABLE unicorn_financi
DROP COLUMN DateJoined;

-- Rename DateJoinedConverted to DateJoined
ALTER TABLE unicorn_financi
CHANGE DateJoinedConverted DateJoined DATE;

-- Select all records to verify the changes
SELECT * FROM unicorn_financi;

-- Data Exploration for Unicorn Companies Analytics Project
 -- Select all records from unicorn_info and unicorn_finance tables
 SELECT *
FROM unicorn_infoma
ORDER BY 1 ASC;

SELECT *
FROM unicorn_financi
ORDER BY 1 ASC;

-- Select all records from unicorn_finance table
SELECT *
FROM unicorn_financi
ORDER BY 1 ASC;

-- Total Unicorn Companies
WITH UnicornCom AS (
    SELECT 
        inf.Company, 
        inf.Industry, 
        inf.City, 
        inf.Country, 
        inf.Continent, 
        fin.Valuation, 
        fin.Funding, 
        inf.YearFounded AS YearFounded, 
        fin.Year, 
        fin.SelectInvestors AS SelectInvestors
    FROM 
        unicorn_infoma AS inf
    INNER JOIN 
        unicorn_financi AS fin 
    ON 
        inf.Company = fin.Company
)
SELECT COUNT(1) AS Unicorn
FROM UnicornCom
WHERE (Year - YearFounded) >= 0;


-- Total Countries
WITH UnicornCom (Company, Industry, City, Country, Continent, Valuation, Funding, YearFounded, Year, SelectInvestors) AS
    (SELECT inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
            fin.Year, fin.SelectInvestors
    FROM unicorn_infoma AS inf
    INNER JOIN unicorn_financi AS fin 
        ON inf.Company = fin.Company)
SELECT COUNT(DISTINCT Country) AS Country
FROM UnicornCom
WHERE (Year - YearFounded) >= 0;
-- Which unicorn companies have had the biggest return on investment?
SELECT Company, (CONVERT(Valuation, SIGNED) - CONVERT(Funding, SIGNED)) / CONVERT(Funding, SIGNED) AS Roi
FROM unicorn_financi
ORDER BY Roi DESC
LIMIT 10;
-- How long does it usually take for a company to become a unicorn?
-- Find average years to become a unicorn
WITH UnicornCom (Company, Industry, City, Country, Continent, Valuation, Funding, YearFounded, Year, SelectInvestors) AS
    (SELECT inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
            fin.Year, fin.SelectInvestors
    FROM unicorn_infoma AS inf
    INNER JOIN unicorn_financi AS fin 
        ON inf.Company = fin.Company)
        
SELECT ROUND(AVG(Year - YearFounded)) AS AverageYear
FROM UnicornCom;
 -- On average it takes 6 years to become a unicorn company
-- Details on how long it takes for the companies to become a unicorn
WITH UnicornCom (Company, YearFounded, Year) AS
    (SELECT inf.Company, inf.YearFounded, fin.Year
    FROM unicorn_infoma AS inf
    INNER JOIN unicorn_financi AS fin 
        ON inf.Company = fin.Company)
SELECT (Year - YearFounded) AS UnicornYear, COUNT(*) AS Frequency
FROM UnicornCom
WHERE (Year - YearFounded) >= 0
GROUP BY (Year - YearFounded)
ORDER BY Frequency DESC
LIMIT 10;
-- Number of unicorn companies within each industry
WITH UnicornCom (Company, Industry, YearFounded, Year) AS
    (SELECT inf.Company, inf.Industry, inf.YearFounded, fin.Year
    FROM unicorn_infoma AS inf
    INNER JOIN unicorn_financi AS fin 
        ON inf.Company = fin.Company)
SELECT Industry, COUNT(*) AS Frequency
FROM UnicornCom
WHERE (Year - YearFounded) >= 0
GROUP BY Industry
ORDER BY Frequency DESC;

-- Number of unicorn companies within each country
WITH UnicornCom AS (
    SELECT inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
           fin.Year, fin.SelectInvestors
    FROM unicorn_infoma AS inf
    INNER JOIN unicorn_financi AS fin 
        ON inf.Company = fin.Company
)
SELECT Country, COUNT(*) AS Frequency
FROM UnicornCom
WHERE (Year - YearFounded) >= 0
GROUP BY Country
ORDER BY Frequency DESC;
-- Number of unicorn companies within each country and their shares
WITH UnicornCom AS (
    SELECT inf.Company, inf.Industry, inf.City, inf.Country, inf.Continent, fin.Valuation, fin.Funding, inf.YearFounded, 
           fin.Year, fin.SelectInvestors
    FROM unicorn_infoma AS inf
    INNER JOIN unicorn_financi AS fin 
        ON inf.Company = fin.Company
)
SELECT Country, COUNT(*) AS Frequency, 
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM UnicornCom), 2) AS Percentage
FROM UnicornCom
WHERE (Year - YearFounded) >= 0
GROUP BY Country
ORDER BY Frequency DESC
LIMIT 10;

 -- Which investors have funded the most unicorns?
SELECT *
FROM unicorn_financi
ORDER BY 1 ASC;

-- Replace ', ' with ',' in the SelectInvestors column
UPDATE unicorn_financi
SET SelectInvestors = REPLACE(SelectInvestors, ', ', ',');

-- Select investors and count their occurrences
SELECT Investor AS Investors, COUNT(*) AS UnicornsInvested 
FROM (
    SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(SelectInvestors, ',', numbers.n), ',', -1)) AS Investor
    FROM (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    ) numbers
    INNER JOIN unicorn_financi
    ON CHAR_LENGTH(SelectInvestors) - CHAR_LENGTH(REPLACE(SelectInvestors, ',', '')) >= numbers.n - 1
) AS investors_split
GROUP BY Investor  
ORDER BY UnicornsInvested DESC 
LIMIT 10;

