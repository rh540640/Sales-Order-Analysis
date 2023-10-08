-- creating database

CREATE DATABASE sales;
USE sales;

-- creating table

CREATE TABLE Orders (
    Order_ID INT,
    Order_Date DATETIME,
    Product VARCHAR(100),
    Category VARCHAR(400),
    Street VARCHAR(100),
    City VARCHAR(50),
    State VARCHAR(2),
    Zip_Code INT,
    Quantity_Ordered INT,
    Price_Each DECIMAL(20, 10),
    Cost_Price DECIMAL(20, 10),
    Turnover DECIMAL(20, 10),
    Margin DECIMAL(20, 10)
);

# DROP TABLE Orders;

-- Loading the data

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\sales_data.csv" INTO TABLE Orders
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(Order_ID, @Order_Date, Product, Category, Street, City, State, Zip_Code, Quantity_Ordered, Price_Each, Cost_Price,	Turnover, Margin)
SET Order_Date = STR_TO_DATE(@Order_Date,'%d-%m-%Y %H:%i')
;

-- Data Preprocessing
SELECT * FROM Orders
LIMIT 10;

SELECT *
FROM Orders
WHERE Order_ID IS NULL OR Order_Date IS NULL OR Category IS NULL OR Street IS NULL OR City IS NULL OR State IS NULL OR Zip_Code IS NULL OR 
Quantity_Ordered IS NULL OR Price_Each IS NULL OR Cost_Price IS NULL OR Turnover IS NULL OR Margin IS NULL;

SELECT COUNT(*)
FROM Orders
WHERE Order_ID IS NULL OR Order_Date IS NULL OR Category IS NULL OR Street IS NULL OR City IS NULL OR State IS NULL OR Zip_Code IS NULL OR 
Quantity_Ordered IS NULL OR Price_Each IS NULL OR Cost_Price IS NULL OR Turnover IS NULL OR Margin IS NULL;

-- Data Integration

-- Add the Total Revenue column to the table

ALTER TABLE Orders
ADD Total_Revenue DECIMAL(20, 10);

UPDATE Orders
SET Total_Revenue = Quantity_Ordered * Price_Each;

-- Add Total_Cost column to the table
ALTER TABLE Orders
ADD Total_Cost DECIMAL(20, 10);
UPDATE Orders
SET Total_Cost = Quantity_Ordered * Cost_Price;

-- Add Net_Profit column to the table
ALTER TABLE Orders
ADD Net_Profit DECIMAL(20, 10);
UPDATE Orders
SET Net_Profit = Total_Revenue - Total_Cost;

-- Analysis

DESCRIBE TABLE Orders;

SELECT * FROM Orders;

-- Calculate Total_Revenue directly in the SUM function
-- Products that creates more revenue
CREATE TABLE Product_Revenue_Ranking (
    Product VARCHAR(100),
    Total_Revenue DECIMAL(20, 10),
    Product_Revenue_Rank INT
);
SELECT * FROM Orders;
INSERT INTO Product_Revenue_Ranking (Product, Total_Revenue, Product_Revenue_Rank)
SELECT
    Product,
    SUM(Total_Revenue) AS Total_Revenue,
    RANK() OVER (ORDER BY SUM(Quantity_Ordered * Price_Each) DESC) AS Product_Revenue_Rank
FROM Orders
GROUP BY Product;

SELECT O.*,
       PRR.Total_Revenue,
       PRR.Product_Revenue_Rank
FROM Orders O
JOIN Product_Revenue_Ranking PRR ON O.Product = PRR.Product;

SELECT * FROM Product_Revenue_Ranking;

-- Average Quantity Ordered per Category

CREATE TABLE Avg_Qty_Per_Ctgry(
Category VARCHAR(100),
Avg_Quantity_Ordered DECIMAL(20,10)
);

INSERT INTO Avg_Qty_Per_Ctgry(Category, Avg_Quantity_Ordered)
SELECT
    Category,
    AVG(Quantity_Ordered) AS Avg_Quantity_Ordered
FROM Orders
GROUP BY Category;

SELECT O.*, AQP.Avg_Quantity_Ordered FROM Orders O
JOIN Avg_Qty_Per_Ctgry AQP ON O.Category = AQP.Category;

SELECT * FROM Avg_Qty_Per_Ctgry;

-- Top 10 Purchasing Cities
CREATE TABLE Top_Purchasing_Cities(
City VARCHAR(100),
State VARCHAR(2),
Total_Turnover DECIMAL(20,10)
);

INSERT Top_Purchasing_Cities(City, State, Total_Turnover)
SELECT
    City, State,
    SUM(Turnover) AS Total_Turnover
FROM Orders
GROUP BY State, City
ORDER BY Total_Turnover DESC
LIMIT 10;

SELECT O.*, TPC.State, TPC.Total_Turnover FROM Orders O 
JOIN Top_Purchasing_Cities TPC ON O.City = TPC.City;

SELECT * FROM Top_Purchasing_Cities;

-- Filtering Data

-- Filter by Date Range
SELECT *
FROM Orders
WHERE Order_Date >= '2019-02-01 00:00:00' AND Order_Date <= '2019-02-01 23:59:59';

-- Filter data by Category and Minimum Quantity Ordered
SELECT *
FROM Orders
WHERE Category = 'Electronics'
    AND Quantity_Ordered >= 5;

-- Average price based on quanity of orders

SELECT Quantity_Ordered, AVG(Price_Each) AS Average_Price
FROM Orders
WHERE Quantity_Ordered >= 1
GROUP BY Quantity_Ordered
ORDER BY Quantity_Ordered ASC;

CREATE TABLE Avg_Price_on_Orders(
Quantity_Ordered INT,
Average_Price DECIMAL(18,14)
);

INSERT INTO Avg_Price_on_Orders (Quantity_Ordered, Average_Price)
VALUES
    (1, 202.36865792159096),
    (2, 12.14026418492945),
    (3, 4.68106164383562),
    (4, 3.63607940446650),
    (5, 3.27648305084746),
    (6, 3.27200000000000),
    (7, 3.06083333333333),
    (8, 2.99000000000000),
    (9, 2.99000000000000);

SELECT O.*, AP.Average_Price FROM Orders O 
JOIN Avg_Price_on_Orders AP ON O.Quantity_Ordered = AP.Quantity_Ordered;

-- Average Turnover by Category

CREATE TABLE Turnover_by_Ctgry(
Category VARCHAR(100),
Average_Category_Turnover DECIMAL(10, 2)
);

INSERT INTO Turnover_by_Ctgry(Category, Average_Category_Turnover)
SELECT Category, ROUND(AVG(Turnover), 2) AS Average_Category_Turnover FROM Orders O 
GROUP BY Category
ORDER BY Average_Category_Turnover DESC;

SELECT O.*, ATC.Average_Category_Turnover FROM Orders O 
JOIN Turnover_by_Ctgry ATC ON O.Category = ATC.Category;

SELECT * FROM Turnover_by_Ctgry;

-- Trend of net profit for each month

CREATE TABLE Revenue_by_Month(
Order_YEAR INT,
Order_Month INT,
Monthly_Revenue DECIMAL(10,2)
);
DROP TABLE Revenue_by_Month;
INSERT INTO Revenue_by_Month(Order_Year, Order_Month, Monthly_Revenue)
SELECT YEAR(Order_Date) AS Order_Year, MONTH(Order_Date) AS Order_Month, ROUND(SUM(Total_Revenue),2)
 AS Monthly_Revenue
FROM Orders
GROUP BY Order_Year, Order_Month
ORDER BY Order_Year, Order_Month;
 
SELECT * FROM Revenue_by_Month;

-- Monthly Sales Growth Rate
-- monthly sales growth rate in terms of total revenue

CREATE TABLE Monthly_growth_by_Total_Revenue(
Order_Date DATETIME, 
Total_Revenue DECIMAl(20, 15),
Sales_Growth_Rate DECIMAL(20,15)
);

DROP TABLE Monthly_growth_by_Total_Revenue;
INSERT INTO Monthly_growth_by_Total_Revenue(Order_Date, Total_Revenue, Sales_Growth_rate) 
SELECT T1.Order_Date,
       T1.Total_Revenue,
       ROUND((T1.Total_Revenue - COALESCE(LAG(Total_Revenue) OVER (ORDER BY Order_Date), 0)) / COALESCE(LAG(Total_Revenue) OVER (ORDER BY Order_Date), 2), 
       1) AS Sales_Growth_Rate
FROM Orders T1;

SELECT * FROM Monthly_growth_by_Total_Revenue;
-- Busiest Days of the Week
-- busiest days of the week in terms of order count
CREATE TABLE busiest_day(
Day_Of_Week VARCHAR(10),
Order_Count INT
);
INSERT INTO busiest_day(Day_Of_Week, Order_Count)
SELECT DAYNAME(Order_Date) AS Day_Of_Week,
       COUNT(*) AS Order_Count
FROM Orders
GROUP BY Day_Of_Week
ORDER BY Order_Count DESC;

-- Monthly Seasonality Analysis
-- seasonal pattern by calculating the average revenue for each day of the week across months
CREATE TABLE Monthly_Seasonality_Analysis(
Day_Of_Week VARCHAR(10),
Order_Month VARCHAR(10),
Avg_Revenue DECIMAl(10,2)
); 

INSERT INTO Monthly_Seasonality_Analysis(Day_Of_Week, Order_Month, Avg_Revenue)
SELECT DAYNAME(Order_Date) AS Day_Of_Week,
       MONTHNAME(Order_Date) AS Order_Month,
       ROUND(AVG(Total_Revenue), 2) AS Avg_Revenue
FROM Orders
GROUP BY Day_Of_Week, Order_Month
ORDER BY Day_Of_Week, Order_Month;

-- Weekly Sales Comparison
-- compares the weekly sales for different years to identify patterns
CREATE TABLE Weekly_Sales(
Order_Year INT,
Order_Week INT,
Weekly_Revenue DECIMAL(10,2)
);

INSERT INTO Weekly_Sales(Order_Year, Order_Week, Weekly_Revenue)
SELECT YEAR(Order_Date) AS Order_Year,
       WEEK(Order_Date) AS Order_Week,
       ROUND(SUM(Total_Revenue), 2) AS Weekly_Revenue
FROM Orders
GROUP BY Order_Year, Order_Week
ORDER BY Order_Year, Order_Week;

-- Lag and Lead Analysis
-- LAG and LEAD functions to analyze the difference between consecutive orders

CREATE TABLE Lag_Lead_Analysis(
Order_Date DATETIME,
Total_Revenue DECIMAL(10,2),
Prev_Total_Revenue DECIMAL(10,2),
Next_Total_Revenue DECIMAL(10,2)
);

INSERT INTO Lag_Lead_Analysis(Order_Date, Total_Revenue, Prev_Total_Revenue, Next_Total_Revenue) 
SELECT Order_Date,
       ROUND(Total_Revenue, 2) AS Total_Revenue,
       ROUND(LAG(Total_Revenue) OVER (ORDER BY Order_Date), 2) AS Prev_Total_Revenue,
       ROUND(LEAD(Total_Revenue) OVER (ORDER BY Order_Date), 2) AS Next_Total_Revenue
FROM Orders;


-- Monthly Profit Analysis
-- monthly total profit for each product to identify trends and patterns

CREATE TABLE Monthly_Profit_Analysis(
Order_Year INT,
Order_Month VARCHAR(20),
Product VARCHAR(100),
Monthly_Profit DECIMAL(10,2)
);

INSERT INTO Monthly_Profit_Analysis(Order_Year, Order_Month, Product, Monthly_Profit)
SELECT YEAR(Order_Date) AS OrderYear,
       MONTHNAME(Order_Date) AS OrderMonth,
       Product,
       ROUND(SUM(Net_Profit), 2) AS Monthly_Profit
FROM Orders
GROUP BY OrderYear, OrderMonth, Product
ORDER BY OrderYear, OrderMonth, Monthly_Profit DESC;

-- Seasonal Analysis
-- Analyze how product profits vary across different seasons or quarters of the year. 
-- This can help you allocate resources and marketing efforts more effectively.

CREATE TABLE Seasonal_Analysis(
Order_Year INT,
Order_Quarter INT,
Product VARCHAR(50),
Quarterly_Profit DECIMAL(10,2)
);

INSERT INTO Seasonal_Analysis(Order_Year, Order_Quarter, Product, Quarterly_Profit)
SELECT YEAR(Order_Date) AS Order_Year,
       QUARTER(Order_Date) AS Order_Quarter,
       Product,
       ROUND(SUM(Net_Profit), 2) AS Quarterly_Profit
FROM Orders
GROUP BY Order_Year, Order_Quarter, Product
ORDER BY Order_Year, Order_Quarter, Quarterly_Profit DESC;

-- Top Profitable Products
-- Identify the top N products with the highest average profit over a specified time period. 
-- This will guide your focus on the most lucrative products.

CREATE TABLE Profitable_Products(
Product VARCHAR(50),
Avg_Profit DECIMAl(10,2)
);

INSERT INTO Profitable_Products(Product, Avg_Profit)
SELECT Product,
       ROUND(AVG(Net_Profit), 2) AS Avg_Profit
FROM Orders
WHERE Order_Date BETWEEN '2019-01-01' AND '2019-12-31'
GROUP BY Product
ORDER BY Avg_Profit DESC
LIMIT 10;

-- Year-over-Year Growth:
-- Compare the profit growth of products year over year to determine which products are showing consistent improvement.

CREATE TABLE Year_Over_Year_Growth(
Product VARCHAR(50),
Order_Year INT,
Yearly_Profit DECIMAl(10,2)
);

INSERT INTO Year_Over_Year_Growth(Product, Order_Year, Yearly_Profit)
SELECT Product,
       YEAR(Order_Date) AS OrderYear,
       ROUND(SUM(Net_Profit), 2) AS Yearly_Profit
FROM Orders
GROUP BY Product, OrderYear
ORDER BY Product, OrderYear;

-- Profit Margin Analysis
-- Analyze the products with the highest profit margins to understand which products yield the most profit in proportion to revenue.

CREATE TABLE Profit_Margin_Analysis(
Product VARCHAR(50),
Avg_Profit_Margin DECIMAL(10, 2)
);

INSERT INTO Profit_Margin_Analysis(Product, Avg_Profit_Margin)
SELECT Product,
       ROUND(AVG(Margin), 2) AS Avg_Profit_Margin
FROM Orders
GROUP BY Product
ORDER BY Avg_Profit_Margin DESC;

SHOW TABLES;

SELECT * FROM orders;
SELECT * FROM avg_price_on_orders;
SELECT * FROM avg_qty_per_ctgry;
SELECT * FROM busiest_day;
SELECT * FROM lag_lead_analysis;
SELECT * FROM monthly_growth_by_total_revenue;
SELECT * FROM monthly_profit_analysis;
SELECT * FROM monthly_seasonality_analysis;
SELECT * FROM product_revenue_ranking;
SELECT * FROM profit_margin_analysis;
SELECT * FROM profitable_products;
SELECT * FROM revenue_by_month;
SELECT * FROM seasonal_analysis;
SELECT * FROM top_purchasing_cities;
SELECT * FROM turnover_by_ctgry;
SELECT * FROM weekly_sales;
SELECT * FROM year_over_year_growth;
