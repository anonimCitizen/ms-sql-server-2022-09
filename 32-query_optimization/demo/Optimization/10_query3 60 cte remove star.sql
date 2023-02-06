SET STATISTICS IO, TIME ON;

DECLARE @dt_from DATETIME2, 
	    @dt_to DATETIME2;

SET @dt_from = DATEFROMPARTS(DATEPART(yyyy,DATEADD(yy, -7, GETDATE())),01, 01); 
SET @dt_to =  DATEADD(yy,1, @dt_from);  

​
WITH Invoices AS 
(SELECT Inv.InvoiceID, Inv.InvoiceDate, Inv.BillToCustomerID, 
	Inv.CustomerID, Inv.SalespersonPersonID, Inv.OrderID, Details.StockItemID, Details.Quantity
FROM Sales.Invoices AS Inv
	JOIN Sales.InvoiceLines AS Details
		ON Inv.InvoiceID = Details.InvoiceID
WHERE Inv.InvoiceDate >= @dt_from
	 AND Inv.InvoiceDate < @dt_to)
SELECT Client.CustomerName, 
	Inv.InvoiceID, 
	Inv.InvoiceDate, 
	Item.StockItemName, 
	Inv.Quantity,
	SUM(Inv.Quantity) OVER (PARTITION BY Inv.StockItemID) AS TotalItems, 
	MAX(Inv.Quantity) OVER (PARTITION BY Inv.CustomerID) AS MaxByClient,
	PayClient.CustomerName AS BillForCustomer,
	Pack.PackageTypeName,
	People.FullName AS SalePerson,
	OrdLines.PickedQuantity
FROM Invoices AS Inv
	JOIN Sales.Customers AS Client 
		ON Client.CustomerID = Inv.CustomerID
	JOIN Application.People AS People
		ON People.PersonID = Inv.SalespersonPersonID
	JOIN Sales.Customers AS PayClient 
		ON PayClient.CustomerID = Inv.BillToCustomerID
	JOIN Warehouse.StockItems AS Item 
		ON Item.StockItemID = Inv.StockItemID
	JOIN Sales.Orders AS Ord 
		ON Ord.OrderID = Inv.OrderID
	JOIN Sales.OrderLines AS OrdLines
		ON OrdLines.OrderID = Ord.OrderID
		AND OrdLines.StockItemID = Item.StockItemID
	JOIN Warehouse.PackageTypes AS Pack
		ON Pack.PackageTypeID = OrdLines.PackageTypeID
WHERE OrdLines.PickedQuantity > 0
ORDER BY TotalItems DESC, Quantity DESC, CustomerName;

















--https://otus.ru/polls/30743/