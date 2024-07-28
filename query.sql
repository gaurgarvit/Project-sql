-- Task 2: Exploratory Data Analysis
-- 1.Summary of Active vs Closed Accounts:
SELECT "ACCOUNT_STATUS", COUNT(*) AS Account_Count
FROM TRANSACTION_LINE
GROUP BY "ACCOUNT_STATUS";

-- 2. Breakdown of Account Types and Their Current Balances:
SELECT "ACCOUNT_CATEGORY", SUM("ACCOUNT_BALANCE") AS Total_Balance
FROM TRANSACTION_LINE
GROUP BY "ACCOUNT_CATEGORY";

-- 3. Analysis of Loan Amounts vs. Account Balances:
SELECT "ACCOUNT_CATEGORY", SUM("SANCTIONED_AMOUNT") AS Total_Loan_Amount, SUM("ACCOUNT_BALANCE") AS Total_Balance
FROM TRANSACTION_LINE
GROUP BY "ACCOUNT_CATEGORY";

-- 4.Overview of the Closure Percentages for Different Loan Types by Ownership Type:
SELECT "ACCOUNT_CATEGORY", "OWNERSHIP_TYPE", 
       COUNT(*) AS Total_Accounts,
       SUM(CASE WHEN "ACCOUNT_STATUS" = 'Closed' THEN 1 ELSE 0 END) AS Closed_Accounts,
       (SUM(CASE WHEN "ACCOUNT_STATUS" = 'Closed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS Closure_Percentage
FROM TRANSACTION_LINE
GROUP BY "ACCOUNT_CATEGORY", "OWNERSHIP_TYPE";


-- Task 3: Creating required additional variables & Customer Segmentations
-- 1.Segmenting Customers Based on FICO Scores and Account Categories
SELECT "FICO_SCORE", "ACCOUNT_CATEGORY", COUNT(*) AS Customer_Count
FROM TRANSACTION_LINE
GROUP BY "FICO_SCORE", "ACCOUNT_CATEGORY";

-- 2.Product Usage Segmentation:
SELECT
    t."ACCOUNT_CATEGORY",
    COUNT(DISTINCT t."CUSTOMER_ID") AS customer_count
FROM
    TRANSACTION_LINE t
GROUP BY
    t."ACCOUNT_CATEGORY"
ORDER BY
    customer_count DESC;

-- 3. Account Activity Segmentation:

SELECT
    t."ACCOUNT_STATUS",
    COUNT(DISTINCT t."CUSTOMER_ID") AS customer_count
FROM
    TRANSACTION_LINE t
GROUP BY
    t."ACCOUNT_STATUS"
ORDER BY
    customer_count DESC;

-- Task 4: Cross-Selling Opportunities & Cohort Analysis
-- 1. Cohort Analysis:
-- Creating a cohort based on account opening month and year
WITH customer_accounts AS (
	SELECT
		"CUSTOMER_ID",
		ARRAY_AGG(DISTINCT "ACCOUNT_CATEGORY" ORDER by "ACCOUNT_CATEGORY") AS account_types,
		COUNT(DISTINCT "ACCOUNT_CATEGORY") AS num_account_types,
		ROUND(AVG("FICO_SCORE"), 2) AS avg_fico_score,
		SUM("ACCOUNT_BALANCE") AS total_balance,
		MAX("TENURE_MONTHS") AS max_tenure
	FROM
		transaction_line tl
	GROUP BY
		1
)
SELECT
	account_types,
	COUNT(*) AS combination_count
FROM
	customer_accounts ca
GROUP BY
	1
ORDER BY
	2 DESC;


-- 2.1. Cross-Selling Opportunities:
SELECT
    "CUSTOMER_ID",
    STRING_AGG("ACCOUNT_CATEGORY", ', ') AS ACCOUNT_COMBINATIONS
FROM
    TRANSACTION_LINE
GROUP BY
    "CUSTOMER_ID"
HAVING
    COUNT(DISTINCT "ACCOUNT_CATEGORY") > 1;


-- 2.2. Predict Likely Next Products:
WITH "CustomerProductPattern" AS (
    SELECT "CUSTOMER_ID", 
           "ACCOUNT_CATEGORY", 
           ROW_NUMBER() OVER (PARTITION BY "CUSTOMER_ID" ORDER BY "OPENING_DATE") AS "ORDER_OF_ACQUISITION"
    FROM "transaction_line"
)
SELECT CPP1."ACCOUNT_CATEGORY" AS "CURRENT_PRODUCT", 
       CPP2."ACCOUNT_CATEGORY" AS "NEXT_LIKELY_PRODUCT", 
       COUNT(*) AS "FREQUENCY"
FROM "CustomerProductPattern" CPP1
JOIN "CustomerProductPattern" CPP2 ON CPP1."CUSTOMER_ID" = CPP2."CUSTOMER_ID" AND CPP1."ORDER_OF_ACQUISITION" + 1 = CPP2."ORDER_OF_ACQUISITION"
GROUP BY CPP1."ACCOUNT_CATEGORY", CPP2."ACCOUNT_CATEGORY"
ORDER BY "FREQUENCY" DESC;