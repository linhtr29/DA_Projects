-- OVERVIEW TABLES
SELECT *
FROM Products;

SELECT *
FROM [Returns];

SELECT *
FROM Sales_2016;

SELECT *
FROM Sales_2017;

-- QUESTION 1: CALCULATE THE RETURN RATE BY PRODUCT IN 2016 & 2017
-- Create temporary table for total sales 2016 & 2017:
WITH Sales_Total
AS (
    SELECT *
    FROM Sales_2016
    
    UNION
    
    SELECT *
    FROM Sales_2017
    )
SELECT s.ProductKey
    , CAST(SUM(r.Return_Total) * 1.0 / SUM(s.Order_Total) AS DECIMAL(5, 2)) AS Return_rate -- Create the formula to calculate the return rate
    , s.Order_Total
    , r.Return_Total
FROM (
    SELECT ProductKey -- Get the total order quantity by Product in 2016 and 2017
        , SUM(OrderQuantity) AS Order_Total
    FROM Sales_Total
    GROUP BY ProductKey
    ) AS s
JOIN (
    SELECT ProductKey -- Get the total return quantity by Product in 2016 and 2017
        , SUM(ReturnQuantity) AS Return_Total
    FROM [Returns]
    WHERE YEAR(ReturnDate) >= 2016
    GROUP BY ProductKey
    ) AS r
    ON s.ProductKey = r.ProductKey
GROUP BY s.ProductKey
    , s.Order_Total
    , r.Return_Total
ORDER BY Return_rate DESC;

-- QUESTION 2: CALCULATE THE RETURN RATE AND RETURN VALUE BY PRODUCT IN 2016
SELECT s.ProductKey
    , p.ProductName
    , p.ProductPrice
    , OrderQty
    , ReturnQty
    , CAST(ReturnQty * 1.0 / OrderQty AS DECIMAL(5, 2)) AS ReturnRate -- Calculate the return rate
    , CAST(ReturnQty * ProductPrice AS DECIMAL(10, 2)) AS ReturnValue -- Calculate the return value
FROM (
    SELECT ProductKey -- Get total return quantity by product in 2016
        , SUM(ReturnQuantity) AS ReturnQty
    FROM [Returns]
    WHERE YEAR(ReturnDate) = 2016
    GROUP BY ProductKey
    ) AS r
JOIN (
    SELECT ProductKey -- Get total order quantity by product in 2016
        , SUM(orderquantity) AS OrderQty
    FROM Sales_2016
    GROUP BY ProductKey
    ) AS s
    ON r.ProductKey = s.ProductKey
JOIN (
    SELECT ProductKey
        , ProductName
        , ProductPrice
    FROM Products
    ) AS p
    ON s.ProductKey = p.ProductKey
ORDER BY ReturnRate DESC
    , ReturnValue DESC;

-- QUESTION 3: NUMBER OF ORDERS PER MONTH IN 2016
SELECT COUNT(DISTINCT OrderNumber) AS NumberOfOrder
    , MONTH(OrderDate) AS OrderMonth
FROM Sales_2016
GROUP BY MONTH(OrderDate)
ORDER BY 2;

-- QUESTION 4: TOP 5 PRODUCT MODELS BY REVENUE IN 2016
SELECT TOP 5 p.ModelName
    , round(SUM(p.productprice * s.orderquantity), 2) AS Total
FROM Products AS p
JOIN Sales_2016 AS s
    ON p.ProductKey = s.ProductKey
GROUP BY p.ModelName
ORDER BY Total DESC;

-- QUESTION 5: CALCULATE REVENUE MTD IN 2016
SELECT *
    , SUM(rev.Month_Revenue) OVER (
        ORDER BY OrderMonth
        ) AS Revenue_MTD
FROM (
    SELECT MONTH(s.OrderDate) AS OrderMonth
        , ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS Month_Revenue
    FROM Sales_2016 AS s
    LEFT JOIN Products AS p
        ON s.ProductKey = p.ProductKey
    GROUP BY MONTH(s.OrderDate)
    ) AS rev;

-- QUESTION 6: TOP 3 PRODUCTS WITH HIGHEST ORDERED QUANTITY PER MONTH IN 2016 (INCLUDE PRODUCTS WITH EQUAL ORDERED QUANTITY)
SELECT *
FROM (
    SELECT MONTH(s.OrderDate) AS OrderMonth     -- Get the Order Month
        , p.ProductName                         
        , SUM(s.OrderQuantity) AS Qty
        , RANK() OVER (
            PARTITION BY MONTH(s.OrderDate) ORDER BY SUM(s.OrderQuantity) DESC
            ) AS Ranking                        -- Get the ranking by Order Quantity
    FROM Products AS p
    JOIN Sales_2016 AS s
        ON p.ProductKey = s.ProductKey
    GROUP BY p.ProductName
        , MONTH(s.OrderDate)
    ) AS t
WHERE Ranking <= 3;                             -- Get top 3 Products

