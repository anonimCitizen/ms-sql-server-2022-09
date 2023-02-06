SET STATISTICS IO, TIME ON;

DECLARE @dt_from DATETIME2, 
	    @dt_to DATETIME2;

SET @dt_from = DATEFROMPARTS(DATEPART(yyyy,DATEADD(yy, -7, GETDATE())),01, 01); 
SET @dt_to =  DATEADD(yy,1, @dt_from);  

​

SELECT Client.CustomerName, 
	Inv.InvoiceID, 
	Inv.InvoiceDate, 
	Item.StockItemName, 
	Details.Quantity,
	SUM(Details.Quantity) OVER (PARTITION BY Details.StockItemID) AS TotalItems, 
	MAX(Details.Quantity) OVER (PARTITION BY Inv.CustomerID) AS MaxByClient,
	PayClient.CustomerName AS BillForCustomer,
	Pack.PackageTypeName,
	People.FullName AS SalePerson--,
	--OrdLines.PickedQuantity
FROM Sales.Invoices AS Inv
	JOIN Sales.InvoiceLines AS Details
		ON Inv.InvoiceID = Details.InvoiceID
	JOIN Sales.Customers AS PayClient 
		ON PayClient.CustomerID = Inv.BillToCustomerID
	JOIN Sales.Customers AS Client 
		ON Client.CustomerID = Inv.CustomerID
	JOIN Application.People AS People
		ON People.PersonID = Inv.SalespersonPersonID
	JOIN Warehouse.StockItems AS Item 
		ON Item.StockItemID = Details.StockItemID
	--JOIN Sales.Orders AS Ord 
	--	ON Ord.OrderID = Inv.OrderID
	--JOIN Sales.OrderLines AS OrdLines
	--	ON OrdLines.OrderID = Ord.OrderID
	--	AND OrdLines.StockItemID = Item.StockItemID
	JOIN Warehouse.PackageTypes AS Pack
		ON Pack.PackageTypeID = Details.PackageTypeID
WHERE Inv.InvoiceDate >= @dt_from
	 AND Inv.InvoiceDate < @dt_to; 
	 --AND OrdLines.PickedQuantity > 0
--ORDER BY TotalItems DESC, Quantity DESC, CustomerName;


/*
SELECT Inv.InvoiceDate, Ord.OrderDate, Datediff(dd,Inv.InvoiceDate, Ord.OrderDate) AS diff, *
FROM Sales.Invoices AS Inv
	JOIN Sales.InvoiceLines AS Details
		ON Inv.InvoiceID = Details.InvoiceID
	JOIN Sales.Orders AS Ord 
		ON Ord.OrderID = Inv.OrderID
	JOIN Sales.OrderLines AS OrdLines
		ON OrdLines.OrderID = Ord.OrderID
		AND OrdLines.StockItemID = Details.StockItemID
WHERE OrdLines.PickedQuantity != Details.Quantity
ORDER BY diff
*/





