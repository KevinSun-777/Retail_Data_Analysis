-- =====================================
-- Create Database and Table_2009
-- =====================================

CREATE DATABASE data2009_db;
USE data2009_db;
CREATE TABLE retail2009 (
    Invoice VARCHAR(50),
    StockCode VARCHAR(50),
    Description VARCHAR(255),
    Quantity INT,
    Invoice_date DATETIME,
    Price DECIMAL(10,3),
    Customer_ID INT,
    Country VARCHAR(50)
);

-- =====================================
-- Create Table_2010
-- =====================================
USE data2009_db;
CREATE TABLE retail2010 (
    Invoice VARCHAR(50),
    StockCode VARCHAR(50),
    Description VARCHAR(255),
    Quantity INT,
    Invoice_date DATETIME,
    Price DECIMAL(10,3),
    Customer_ID INT,
    Country VARCHAR(50)
);
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = ON;
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SHOW VARIABLES LIKE 'secure_file_priv';
-- =====================================
-- input data_2009
-- =====================================
USE data2009_db;
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Retail_Data_2009.csv'
INTO TABLE retail2009
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- =====================================
-- Check data_2009
-- =====================================
USE data2009_db;
SELECT COUNT(*)FROM retail2009;

USE data2009_db;
Select * FROM retail2009
limit 10; 

-- =====================================
-- Input data_2010 
-- =====================================
USE data2009_db;
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Retail_Data_2010.csv'
INTO TABLE retail2010
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- =====================================
-- Check data_2010
-- =====================================
USE data2009_db;
SELECT COUNT(*)FROM retail2010;

USE data2009_db;
Select * FROM retail2010
limit 10; 
-- =====================================
-- Merge Two Tables 
-- =====================================
USE data2009_db;
CREATE TABLE retail_all AS
SELECT * FROM retail2009 
UNION ALL
Select * FROM retail2010;
-- =====================================
-- 	Check retail_all Table
-- =====================================
USE data2009_db;
SELECT count(*) FROM retail_all;
-- =====================================
-- 	Business KPI Analysis
-- =====================================
USE data2009_db;
Select round(sum(Quantity*Price),2) AS Total_Revenue,
count(invoice) AS Total_orders,
count(distinct Customer_ID) AS Total_customer,
sum(quantity) AS Total_quantity,
round(sum(Quantity*Price),2)/count(distinct invoice) AS Average_Order_Value,
round(sum(Quantity*Price),2)/count(distinct Customer_ID) AS Average_Revenue_Per_Customer
FROM retail_all;
-- =====================================
-- 	Product Analysis
-- =====================================
-- =====================================
-- 	Top 10 products by Revenue 
-- =====================================
USE data2009_db;
SELECT Description, round(sum(Quantity*Price),2) as Total_Revenue FROM retail_all
Group By description
Order By Total_Revenue DESC
Limit 10;
-- =====================================
-- 	Top 10 products by Quantity Sold
-- =====================================
USE data2009_db;
SELECT Description, count(Quantity) as Total_quantity FROM retail_all
Group By description
Order By Total_quantity DESC
Limit 10;
-- =====================================
-- 	Top 10 products by Number of Orders
-- =====================================
USE data2009_db;
SELECT Description, count(DISTINCT Invoice) as Total_invoice FROM retail_all
Group By description
Order By Total_invoice DESC
Limit 10;
-- =====================================
-- 	Top 10 products (total revenue, total quantity, average price)
-- =====================================
USE data2009_db;
SELECT Description, round(sum(Quantity*Price),2) as Total_Revenue, count(Quantity) as Total_quantity, avg(price) as Average_Price FROM retail_all
Group By description
Order By Total_Revenue DESC
Limit 10;

-- =====================================
-- 	Geographic Analysis 
-- =====================================
-- =====================================
-- 	Renvenue,orders and customer By Country
-- =====================================
USE data2009_db;
SELECT 
	Country,
	round(sum(Quantity*Price),2) as Total_Revenue,
    Count(Distinct invoice) as Total_orders,
    Count(Distinct customer_ID) as Total_customer FROM retail_all
Group By Country
Order By Total_Revenue DESC
Limit 10;

-- =====================================
-- 	Customer Analysis
-- =====================================
-- =====================================
-- 	Top 10 Customer By Revenue and order frequency
-- =====================================
USE data2009_db;
SELECT 
	DISTINCT customer_ID,
	round(sum(Quantity*Price),2) as Total_Revenue,
    COUNT(DISTINCT Invoice) AS order_frequency
    FROM retail_all
Group By Customer_ID
Order By Total_Revenue DESC
Limit 10;
-- =====================================
-- 	Average Spend per Customer
-- =====================================
USE data2009_db;
SELECT
    ROUND(
        SUM(Quantity * Price) /
        COUNT(DISTINCT Customer_ID),
    2) AS Average_Spend_Per_Customer
FROM retail_all
WHERE Customer_ID;
-- =====================================
-- 	Customer purchased only one time
-- =====================================
SELECT
    COUNT(*) AS One_Time_Customers
FROM (
    SELECT
        Customer_ID
    FROM retail_all
    WHERE Customer_ID 
    GROUP BY Customer_ID
    HAVING COUNT(DISTINCT Invoice) = 1
) t;
-- =====================================
-- 	Customer purchased more than one time
-- =====================================
SELECT
    COUNT(*) AS Repeat_customer
FROM (
    SELECT
        Customer_ID
    FROM retail_all
    WHERE Customer_ID 
    GROUP BY Customer_ID
    HAVING COUNT(DISTINCT Invoice) > 1
) t;

-- =====================================
-- 	RFM Analysis_Create Table
-- =====================================
CREATE TABLE rfm_customer AS
SELECT
    Customer_ID,

    DATEDIFF(
        (SELECT MAX(Invoice_date) FROM retail_all),
        MAX(Invoice_date)
    ) AS Recency,

    COUNT(DISTINCT Invoice) AS Frequency,

    ROUND(SUM(Quantity * Price), 2) AS Monetary

FROM retail_all
WHERE Customer_ID IS NOT NULL
GROUP BY Customer_ID;
-- =====================================
-- 	check table 
-- =====================================
SELECT *
FROM rfm_customer
LIMIT 20;
-- =====================================
-- 	check RFM
-- =====================================
SELECT
    MIN(Recency) AS min_recency,
    ROUND(AVG(Recency), 2) AS avg_recency,
    MAX(Recency) AS max_recency,
    
    MIN(Frequency) AS min_frequency,
    ROUND(AVG(Frequency), 2) AS avg_frequency,
    MAX(Frequency) AS max_frequency,
    
    MIN(Monetary) AS min_monetary,
    ROUND(AVG(Monetary), 2) AS avg_monetary,
    MAX(Monetary) AS max_monetary
FROM rfm_customer;
-- =====================================
-- 	Create Customer Segement
-- =====================================
CREATE TABLE customer_segment AS
SELECT
    Customer_ID,
    Recency,
    Frequency,
    Monetary,
    CASE
        WHEN Recency <= (SELECT AVG(Recency) FROM rfm_customer)
             AND Frequency >= (SELECT AVG(Frequency) FROM rfm_customer)
             AND Monetary >= (SELECT AVG(Monetary) FROM rfm_customer)
        THEN 'Champions'

        WHEN Recency <= (SELECT AVG(Recency) FROM rfm_customer)
             AND Frequency >= (SELECT AVG(Frequency) FROM rfm_customer)
        THEN 'Loyal Customers'

        WHEN Recency > (SELECT AVG(Recency) FROM rfm_customer)
             AND Monetary >= (SELECT AVG(Monetary) FROM rfm_customer)
        THEN 'At Risk'

        WHEN Recency > (SELECT AVG(Recency) FROM rfm_customer)
             AND Frequency < (SELECT AVG(Frequency) FROM rfm_customer)
             AND Monetary < (SELECT AVG(Monetary) FROM rfm_customer)
        THEN 'Lost Customers'

        ELSE 'Others'
    END AS Segment
FROM rfm_customer;
-- =====================================
-- 	Check Segements
-- =====================================
SELECT
    Segment,
    COUNT(*) AS customer_count
FROM customer_segment
GROUP BY Segment
ORDER BY customer_count DESC;
-- =====================================
-- 	How much revenue and revnue per customer for each segaement
-- =====================================
SELECT
    Segment,
    COUNT(*) AS customer_count,
    ROUND(SUM(Monetary), 2) AS total_revenue,
    ROUND(AVG(Monetary), 2) AS avg_revenue_per_customer
FROM customer_segment
GROUP BY Segment
ORDER BY total_revenue DESC;


