/***************************************************************/
-------------GROUP PROJECT QUERIES------------------------------
/***************************************************************/
--Need 5 easy, 8 medium, and 7 hard problems
--	use AdventureWorks2014;
--	use AdventureWorksDW2014;
--	use Northwinds2019TSQLV5;
--at least one from each of these
--easy = at least 2 tables joined
--medium = 2-3 tables, built in sql functions/group by summarization
--hard = 3 or more tables, custom scalar functions + built in funcs/group by summarization
--EASY--
--1
--Return all customers who made orders on January 1, 2015.
USE Northwinds2020TSQLV6

SELECT Customer.CustomerId
	,OrderId
	,OrderDate
FROM Sales.[Order]
INNER JOIN Sales.Customer ON [Order].CustomerId = Customer.CustomerId
WHERE OrderDate = '2015-01-01';

--2
--Return all shippers who shipped to customers in the UK(WORST PERFORMING SIMPLE)
USE Northwinds2020TSQLV6

SELECT DISTINCT Shipper.ShipperId
	,Customer.CustomerId
FROM Sales.Shipper
	,Sales.Customer
	,Sales.[Order]
WHERE CustomerCountry = 'UK'
	AND [Order].CustomerId = Customer.CustomerId
	AND [Order].ShipperId = Shipper.ShipperId

--3)
--Return the price of each product a customer ordered.(USING ADVENTURE WORKS2017)
USE AdventureWorks2017

SELECT CustomerId
	,ProductId
	,UnitPrice
FROM Sales.SalesOrderDetail AS od
	,Sales.SalesOrderHeader AS oh
WHERE oh.SalesOrderId = od.SalesOrderId

--4)Return products that are worth more than one hundred dollars.(WHY ARE SAME PRODUCTS DIFF PRICES?)
USE Northwinds2020TSQLV6

SELECT DISTINCT ProductId
	,UnitPrice
FROM Sales.OrderDetail
WHERE UnitPrice > 100;

--5)Return FirstName, LastName, BirthDate, and ProductKeys from the first ten results of the 
--  cartesian product of dbo.ProspectiveBuyer and dbo.FactProductInventory.
USE AdventureWorksDW2017

SELECT DISTINCT TOP (10) FirstName
	,LastName
	,BirthDate
	,ProductKey
FROM dbo.ProspectiveBuyer
CROSS JOIN dbo.FactProductInventory

--MEDIUM------------------------------------------------------------------------------------------------------------
--1)Return the top three most common countries that customers who ordered are from(CHECK?)
USE Northwinds2020TSQLV6

SELECT TOP (3) COUNT(Customer.CustomerId) AS custnum
	,CustomerCountry
FROM Sales.Customer
INNER JOIN Sales.[Order] ON Customer.CustomerId = [Order].CustomerId
GROUP BY CustomerCountry
ORDER BY custnum DESC

--2)Return Shippers who did not deliver on the end of the month(WORST MEDIUM: COULD HAVE INNER JOINED)
USE Northwinds2020TSQLV6

SELECT Shipper.ShipperId
	,ShipToDate
FROM Sales.Shipper
	,Sales.[Order]
WHERE Shipper.ShipperId = [Order].Shipperid
	AND ShipToDate != EOMONTH(ShipToDate)

--3) Return the last date of activity for each shipper(CHECK)
USE Northwinds2020TSQLV6

SELECT Shipper.ShipperId
	,ShipToDate
FROM Sales.Shipper
	,Sales.[Order]
GROUP BY Shipper.ShipperId
	,ShipToDate
HAVING ShipToDate = MAX(ShipToDate)

--4)In orders with discounts, return how many items were on sale.
USE Northwinds2020TSQLV6

SELECT o.OrderId
	,ProductId
	,DiscountPercentage
	,COUNT(DiscountPercentage) OVER (PARTITION BY o.OrderId) AS NumOfDiscounts
FROM Sales.[Order] AS o
INNER JOIN Sales.OrderDetail AS od ON o.OrderId = od.orderid
WHERE DiscountPercentage > 0.0
GROUP BY o.OrderId
	,ProductId
	,DiscountPercentage
ORDER BY o.OrderId

--5)Return Employee's Area Code and Country, including only employees who serviced orders.
USE Northwinds2020TSQLV6

SELECT DISTINCT hr.EmployeeId
	,EmployeeCountry
	,REPLACE(SUBSTRING(EmployeePhoneNumber, 2, 3), ')', '') AS AreaCode
FROM HumanResources.Employee AS hr
INNER JOIN Sales.[Order] AS o ON hr.EmployeeId = o.EmployeeId

--6)Return The total amount spent by each US customer.
USE Northwinds2020TSQLV6

SELECT DISTINCT c.CustomerId
	,SUM(UnitPrice * Quantity) OVER (PARTITION BY c.CustomerId) AS total
FROM Sales.[Order] AS o
	,Sales.OrderDetail AS od
	,Sales.Customer AS c
WHERE o.OrderId = od.OrderId
	AND c.CustomerId = o.CustomerId
	AND CustomerCountry = 'USA'
GROUP BY c.CustomerId
	,o.OrderId
	,od.UnitPrice
	,od.Quantity

--8) Return how many customers from each country bought product 12.
USE Northwinds2020TSQLV6

SELECT COUNT(o.CustomerId) AS custCount
	,CustomerCountry
FROM Sales.Customer AS c
INNER JOIN Sales.[Order] AS o ON o.CustomerId = c.CustomerId
INNER JOIN Sales.OrderDetail AS od ON od.OrderId = o.OrderId
WHERE Productid = 12
GROUP BY CustomerCountry

--7)Return the difference between the current date and the last date a customer bought a specific product in years.
SELECT CustomerId
	,ProductId
	,OrderDate
	,GETDATE() AS currDate
	,DATEDIFF(year, OrderDate, GETDATE()) AS diff
FROM Sales.[Order]
	,Sales.OrderDetail
WHERE [Order].OrderId = OrderDetail.OrderId
ORDER BY CustomerId

--HARD-------------------------------------------------------------------------------------------------------------
--1)Return each employee's total profit from sales.(fixed)
USE Northwinds2020TSQLV6

DROP FUNCTION

IF EXISTS dbo.GetEmployeeProfit;
GO
	CREATE FUNCTION dbo.GetEmployeeProfit (
		@unitprice AS INT
		,@quantity AS INT
		)
	RETURNS INT
	AS
	BEGIN
		DECLARE @ans AS INT = SUM(@unitprice * @quantity)

		RETURN @ans
	END
GO

SELECT hr.EmployeeId
	,SUM(dbo.GetEmployeeProfit(UnitPrice, Quantity)) AS Profit
FROM Sales.OrderDetail AS od
INNER JOIN Sales.[Order] AS o ON od.OrderId = o.OrderId
INNER JOIN HumanResources.Employee AS hr ON o.EmployeeId = hr.EmployeeId
GROUP BY hr.EmployeeId
ORDER BY hr.EmployeeId

--2) Return all customers, and if they ordered, return orders shipped by shippers with an area code of 503(WORST COMP,
																								--COULD HAVE MADE MORE
																								--EFFICIENT VARCHAR)
DROP FUNCTION

IF EXISTS dbo.GetAreaCode;
GO
	CREATE FUNCTION dbo.GetAreaCode (@number VARCHAR(24))
	RETURNS VARCHAR(24)
	AS
	BEGIN
		DECLARE @ans AS VARCHAR(24) = SUBSTRING(@number, 2, 3)

		RETURN @ans
	END
GO

SELECT c.CustomerId
	,o.OrderId
FROM Sales.Customer AS c
LEFT OUTER JOIN Sales.[Order] AS o ON c.CustomerId = o.CustomerId
LEFT OUTER JOIN Sales.Shipper AS s ON o.ShipperId = s.ShipperId
WHERE dbo.GetAreaCode(PhoneNumber) = '503'
	OR OrderId IS NULL

--3) Return the return the customer's ID, company name, the product ID of their purchase, the date ordered,
--   and return the customer ID as a hexadecimal.
DROP FUNCTION

IF EXISTS dbo.BitString;
GO
	CREATE FUNCTION dbo.BitString (@value AS INT)
	RETURNS BINARY (4)
	AS
	BEGIN
		DECLARE @ans AS BINARY (4) = CAST(@value AS BINARY (4))

		RETURN @ans
	END
GO

SELECT o.CustomerId
	,CustomerCompanyName
	,ProductId
	,OrderDate
	,dbo.BitString(o.CustomerId) AS BitString
FROM Sales.Customer AS c
INNER JOIN Sales.[Order] AS o ON c.CustomerId = o.CustomerId
INNER JOIN Sales.OrderDetail AS od ON o.OrderId = od.OrderId

--4) Return all customers, and for those that ordered, the average price they spent per order (FIXED)
USE Northwinds2020TSQLV6

DROP FUNCTION

IF EXISTS dbo.AperO 
GO
	CREATE FUNCTION dbo.AperO (
		@spent AS INT
		,@numorders AS INT
		)
	RETURNS INT
	AS
	BEGIN
		DECLARE @ans AS INT = @spent / @numorders

		RETURN @ans
	END
GO

SELECT c.CustomerId
	,dbo.AperO(SUM(UnitPrice * Quantity), COUNT(o.OrderId)) AS AvgPricePerOrder
FROM Sales.Customer AS c
LEFT OUTER JOIN Sales.[Order] AS o ON c.CustomerId = o.CustomerId
LEFT OUTER JOIN Sales.OrderDetail AS od ON o.OrderId = od.OrderId
GROUP BY c.CustomerId
ORDER BY c.CustomerId

--5) Return the Total dollar amount of the three greatest transactions, as well as the customer serviced(FIXED)
USE Northwinds2020TSQLV6

DROP FUNCTION

IF EXISTS dbo.GetEmployeeProfit;
GO
	CREATE FUNCTION dbo.GetEmployeeProfit (
		@unitprice AS MONEY
		,@quantity AS SMALLINT
		)
	RETURNS INT
	AS
	BEGIN
		DECLARE @ans AS MONEY = SUM(@unitprice * @quantity)

		RETURN @ans
	END
GO

SELECT TOP (3) c.CustomerId
	,SUM(dbo.GetEmployeeProfit(UnitPrice, Quantity)) AS Total
FROM Sales.Customer AS c
INNER JOIN Sales.[Order] AS o ON c.CustomerId = o.CustomerId
INNER JOIN Sales.OrderDetail AS od ON o.OrderId = od.OrderId
GROUP BY c.CustomerId
ORDER BY Total DESC

--6)  Return customer, shipper, order IDS and original price for orders that were on discount.
USE Northwinds2020TSQLV6

DROP FUNCTION

IF EXISTS dbo.OrgPrice 
GO
	CREATE FUNCTION dbo.OrgPrice (
		@price AS MONEY
		,@percent AS FLOAT
		)
	RETURNS MONEY
	AS
	BEGIN
		DECLARE @ans AS MONEY = ROUND(@price / (1 - @percent), 2)

		RETURN @ans
	END
GO

SELECT o.OrderId
	,CustomerId
	,Shipper.ShipperId
	,dbo.OrgPrice(UnitPrice, DiscountPercentage)
FROM Sales.OrderDetail AS od
INNER JOIN Sales.[Order] AS o ON od.OrderId = o.OrderId
INNER JOIN Sales.Shipper ON o.ShipperId = Shipper.ShipperId

--7)Return Orders that were shipped to a country in which the employee who serviced the order and(FIXED)
--  the recieving customer both reside.
USE Northwinds2020TSQLV6

DROP FUNCTION

IF EXISTS dbo.SharedCountry;
GO
	CREATE FUNCTION dbo.SharedCountry (
		@custid AS INT
		,@empid AS INT
		,@country AS VARCHAR(100)
		)
	RETURNS VARCHAR(100)
	AS
	BEGIN
		DECLARE @ans AS VARCHAR(100) = CONCAT (
				'Customer '
				,@custid
				,' and Employee '
				,@empid
				,' are both from '
				,@country
				)

		RETURN @ans
	END
GO

SELECT DISTINCT OrderId
	,o.CustomerId
	,o.EmployeeId
	,dbo.SharedCountry(o.CustomerId, hr.EmployeeId, c.CustomerCountry) AS ShCountry
FROM Sales.Customer AS c
INNER JOIN Sales.[Order] AS o ON c.CustomerId = o.CustomerId
INNER JOIN HumanResources.Employee AS hr ON o.EmployeeId = hr.EmployeeId
WHERE CustomerCountry = EmployeeCountry





















