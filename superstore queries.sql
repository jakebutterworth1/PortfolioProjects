/* Superstore data exploration showcasing syntax and use cases for: Aggregate Functions, Joins, CTE, Subqueries, Temp Tables, Window functions, Stored Procedures */


-- IGNORE --
SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

-- TABLES USED --
SELECT *
FROM PortfolioProject2.customers

SELECT *
FROM PortfolioProject2.orders

SELECT *
FROM PortfolioProject2.returns

SELECT *
FROM PortfolioProject2.managers


-- 1. Aggregate Functions --
-- total products available --
SELECT 
    COUNT(DISTINCT product_name) AS products
FROM portfolioproject2.orders;


-- total products available in each category **** --
SELECT 
	category,
    COUNT(DISTINCT product_name) AS products
FROM PortfolioProject2.orders
GROUP BY category;


-- number of orders, gorss profit and sales for each month in 2017 **** --
SELECT 
	MONTH(order_date) AS month,
    YEAR(order_date) AS year,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales),1) AS gross_sales,
    ROUND(SUM(profit),1) AS gross_profit
FROM portfolioproject2.orders
WHERE YEAR(order_date) = '2017'
GROUP BY MONTH(order_date)
ORDER BY MONTH(order_date) ASC;


-- ordering previous query by gross profit descending to determine seasonal trends --
SELECT 
	MONTH(order_date) AS month,
    YEAR(order_date) AS year,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales),1) AS gross_sales,
    ROUND(SUM(profit),1) AS gross_profit
FROM portfolioproject2.orders
WHERE YEAR(order_date) = '2017'
GROUP BY MONTH(order_date)
ORDER BY ROUND(SUM(profit),1) DESC;


-- top 10 best selling products **** -
SELECT 
	product_name,
    SUM(quantity) AS UnitsSold 
FROM portfolioproject2.orders
GROUP BY product_name
ORDER BY UnitsSold DESC
LIMIT 10;


-- top 10 slowest selling products  -- 
SELECT 
	product_name,
    SUM(quantity) AS UnitsSold 
FROM portfolioproject2.orders
GROUP BY product_name
ORDER BY UnitsSold ASC
LIMIT 10;


-- top 10 products for 2017 **** --
SELECT 
	product_name,
    YEAR(order_date) AS YearSegment,
    SUM(quantity) AS UnitsSold 
FROM portfolioproject2.orders
WHERE YEAR(order_date) = '2017'
GROUP BY product_name
ORDER BY UnitsSold DESC
LIMIT 10;


-- number of orders per country in 2017 from highest to lowest **** --
SELECT 
	country,
	YEAR(order_date) AS YearSegment,
	COUNT(DISTINCT order_id) AS TotalOrders
FROM portfolioproject2.customers
WHERE YEAR(order_date) = '2017'
GROUP BY country
ORDER BY COUNT(DISTINCT order_id) DESC;


-- customer segmentation by location --
SELECT 
	DISTINCT customer_id,
	customer_name,
    country
FROM portfolioproject2.customers
GROUP BY customer_name, country;


-- count of existing customers by country **** --
SELECT 
	COUNT(DISTINCT customer_id) AS NumOfCust,
    country
FROM portfolioproject2.customers
GROUP BY country
ORDER BY NumOfCust DESC;


-- 2. joins -- 
-- customer purchasing behaviour for 2017 highest to lowest --
SELECT 
	YEAR(c.order_date) AS YearSegment,
	c.customer_id,
    c.customer_name,
    c.country,
    c.segment,
    ROUND(SUM(o.sales),1) AS total_purchases
FROM portfolioproject2.customers AS c
LEFT JOIN portfolioproject2.orders AS o
ON c.order_id = o.order_id
WHERE YEAR(c.order_date) = '2017'
GROUP BY c.customer_name
ORDER BY SUM(o.sales) DESC;


-- % of orders returned --
SELECT 
	COUNT(DISTINCT C.order_id) AS total_orders,
    COUNT(DISTINCT r.order_id) AS total_returns,
    ROUND(COUNT(DISTINCT r.order_id) / COUNT(DISTINCT C.order_id),2)*100 AS percent_returned
FROM portfolioproject2.customers AS c
JOIN portfolioproject2.returns r
ON c.region = r.region;


-- top 3 performing regions and their respective managers **** --
SELECT 
	DISTINCT m.person,
    c.region,
    ROUND(SUM(o.sales),2) AS totalsales
FROM portfolioproject2.managers AS m
LEFT JOIN portfolioproject2.customers AS c
ON m.region = c.region 
LEFT JOIN portfolioproject2.orders AS o
ON c.order_id = o.order_id
WHERE YEAR(o.order_date) = '2017'
GROUP BY c.region
ORDER BY totalsales desc
LIMIT 3;


-- semi join creating customer segments based on product a category --
SELECT DISTINCT order_id, customer_name
FROM portfolioproject2.customers
WHERE order_id IN (
SELECT order_id
FROM portfolioproject2.orders
WHERE sub_category = 'tables'
)

-- grouping orders into 2 groups based on order priority --
SELECT
	o.order_id,
    CASE WHEN order_priority IN ('High', 'Critical') THEN 'Priority' END AS group1,
    CASE WHEN order_priority IN ('Low', 'Medium') THEN 'Non-Priority' END AS group2,
    c.ship_mode
FROM portfolioproject2.orders AS o
RIGHT JOIN portfolioproject2.customers AS c
ON o.order_id = c.order_id;



-- 3. CTE --
-- average amount spent per transaction each year between 2010 and 2022 from highest to lowest **** -- 
WITH SumOrders AS (
SELECT 
	DISTINCT order_id,
	YEAR(order_date) AS YearDate,
    SUM(sales) AS SumOfSales
FROM portfolioproject2.orders
GROUP BY order_id, YEAR(order_date)
HAVING YearDate BETWEEN '2010' AND '2022'
ORDER BY YearDate DESC
)
SELECT ROUND(AVG(SumOrders.sumofsales),2) AS AvOrderAmount, SumOrders.YearDate
FROM SumOrders
GROUP BY SumOrders.YearDate
ORDER BY AvOrderAmount DESC;


-- using cte to determine the most common shipping type for each country, then filtering for the number of countries in whcih first class account for at least 30% of the shipping --
WITH ship_type AS (
	SELECT 
		country,
		COUNT(ship_mode) AS total_count,
		ROUND(COUNT(CASE WHEN ship_mode = 'First Class' THEN 1 END) / COUNT(ship_mode),2)*100 AS first_class_perc,
		ROUND(COUNT(CASE WHEN ship_mode = 'Second Class' THEN 1 END) / COUNT(ship_mode),2)*100 AS second_class_perc,
		ROUND(COUNT(CASE WHEN ship_mode = 'Standard Class' THEN 1 END) / COUNT(ship_mode),2)*100 AS standard_class_perc,
		ROUND(COUNT(CASE WHEN ship_mode = 'Same Day' THEN 1 END) / COUNT(ship_mode),2)*100 AS same_day_perc
	FROM portfolioproject2.customers
    GROUP BY country 
)
SELECT COUNT(country)
FROM ship_type
WHERE first_class_perc > 30;



-- 4. Subqueries --
-- fidning the percentage decrease in staple sales over time --
SELECT ROUND((firstsub.unitssold - secondsub.unitssold) / (firstsub.unitssold),1)*100 AS percentage
FROM (
SELECT 
	product_name,
    YEAR(order_date) AS YearSegment,
    SUM(quantity) AS UnitsSold 
FROM portfolioproject2.orders
WHERE YEAR(order_date) = '2012' AND product_name = 'Staples'
GROUP BY product_name
ORDER BY UnitsSold DESC
) AS firstsub,
(
SELECT 
	product_name,
    YEAR(order_date) AS YearSegment,
    SUM(quantity) AS UnitsSold 
FROM portfolioproject2.orders
WHERE YEAR(order_date) = '2017' AND product_name = 'Staples'
GROUP BY product_name
ORDER BY UnitsSold DESC
) AS secondsub;


-- finding the percentage increase in overall orders from 2016-2017 --
SELECT firstsub.Orders16, secondsub.Orders17, (secondsub.Orders17 - firstsub.Orders16) / (firstsub.Orders16)*100 AS percentage
FROM (
SELECT 
    YEAR(order_date) AS YearSegment,
    COUNT(DISTINCT order_id) AS Orders16
FROM portfolioproject2.orders
WHERE YEAR(order_date) = '2016'
) AS firstsub,
(
SELECT 
    YEAR(order_date) AS YearSegment,
    COUNT(DISTINCT order_id) AS Orders17
FROM portfolioproject2.orders
WHERE YEAR(order_date) = '2017'
) AS secondsub;


-- average amount spent per transaction each year betwwen 2010 and 2022 --
SELECT ROUND(AVG(sub.sumofsales),2) AS AvOrderAmount, sub.YearDate
FROM (
SELECT 
	DISTINCT order_id,
	YEAR(order_date) AS YearDate,
    SUM(sales) AS SumOfSales
FROM portfolioproject2.orders
GROUP BY order_id, YEAR(order_date)
HAVING YearDate BETWEEN '2010' AND '2022'
ORDER BY YearDate DESC
) AS sub
GROUP BY sub.YearDate
ORDER BY AvOrderAmount DESC;


-- average shipping cost for orders in Ireland --
SELECT AVG(sub.shipping)
FROM (
SELECT 
	DISTINCT c.order_id,
	c.city,
    o.shipping_cost AS shipping
FROM portfolioproject2.customers as c
left join portfolioproject2.orders as o 
on c.order_id = o.order_id
where c.city = 'Dublin'
GROUP BY c.order_id
) as sub;


-- correlated subquery in WHERE showing infromtion on all products that were returned --
SELECT	
	order_id,
    product_id,
    product_name
FROM portfolioproject2.orders AS o
WHERE EXISTS (
	SELECT 
		region,
        returned
	FROM portfolioproject2.returns AS r
    WHERE r.order_id = o.order_id
    );
    
    
    
-- 5. TEMP TABLES --
-- creating a temp table containing a list of customer names, the country in which they reside the total orders per country -- 
CREATE TEMPORARY TABLE order_count AS
SELECT customer_name, country, COUNT(DISTINCT order_id) AS total_orders
FROM portfolioproject2.customers AS c
GROUP BY customer_name

SELECT *
FROM order_count


-- temp table containing customer info and product category --
CREATE TEMPORARY TABLE cust_product
SELECT 
	c.customer_id,
	c.customer_name,
    o.sub_category AS ordered_from
FROM portfolioproject2.customers AS c
JOIN portfolioproject2.orders AS o
ON c.order_id = o.order_id;

SELECT *
FROM cust_product


-- updated temp table to show category and not subcategory -- 
INSERT INTO cust_product (ordered_from)
SELECT o.category
FROM portfolioproject2.orders AS o


-- temp table containing customer and order info on orders that were returned --
CREATE TEMPORARY TABLE returns_customers
SELECT 
	c.order_id,
    c.order_date,
    c.customer_name,
    c.segment,
    c.country,
    r.region,
    r.returned
FROM portfolioproject2.customers AS c
JOIN portfolioproject2.returns AS r
ON c.order_id = r.order_id; 


-- filtering on the temp table for returns from france --
SELECT * 
FROM returns_customers
WHERE country = 'France'
GROUP BY order_id


-- 6. Window Function --
-- total orders for each product -- 
SELECT 
	DISTINCT product_name,
    SUM(quantity) OVER(PARTITION BY product_name) AS order_amount 
FROM portfolioproject2.orders
ORDER BY order_amount DESC



-- 7. Basic Stored Procedure -- 
-- stored procedure containing customer info --
DELIMITER $$

CREATE PROCEDURE GetCustomerInfo()
BEGIN
    SELECT 
        customer_id,
        customer_name,
        country,
        region
    FROM portfolioproject2.customers;
END $$

DELIMITER ;

CALL GetCustomerInfo;


-- stored procedure limited by country --
DELIMITER $$

CREATE PROCEDURE GetCustomerInfo1(IN country_c TEXT)
BEGIN
    SELECT 
        customer_id,
        customer_name,
        country,
        region
    FROM portfolioproject2.customers
    WHERE country = country_c;
END $$

DELIMITER ;

CALL GetCustomerInfo1('Ireland')

-- dropping stored procedure --
DROP PROCEDURE GetCustomerInfo1


-- stored procedure using join to limit by category of product --
DELIMITER $$

CREATE PROCEDURE OrderInfocat(IN category_o TEXT)
BEGIN 
	SELECT 
		c.customer_id,
		c.customer_name,
        c.country,
        o.product_name,
        o.category
	FROM portfolioproject2.customers AS c
    LEFT JOIN portfolioproject2.orders AS o 
    ON c.order_id = o.order_id
    WHERE o.category = category_o;
END $$

DELIMITER ;
        
CALL OrderInfocat('Technology')

DROP PROCEDURE OrderInfocat


-- limiting by 2 --
DELIMITER $$

CREATE PROCEDURE OrderInfo(IN category1 TEXT, IN category2 TEXT)
BEGIN 
	SELECT 
		c.customer_id,
		c.customer_name,
        c.country,
        o.product_name,
        o.category
	FROM portfolioproject2.customers AS c
    LEFT JOIN portfolioproject2.orders AS o 
    ON c.order_id = o.order_id
    WHERE o.category IN (category1, category2)
    ORDER BY customer_name, category;
END $$

DELIMITER ;

CALL OrderInfo('Office Supplies', 'Furniture')

-- END --











