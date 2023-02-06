

insert into [WideWorldImportersDW].[Fact].[Sale]
(		[Sale Key]
      ,[City Key]
      ,[Customer Key]
      ,[Bill To Customer Key] 
      ,[Stock Item Key]
      ,[Invoice Date Key]
--      ,[Delivery Date Key] дата должна быть в заказе [Sales].[Orders]
      ,[Salesperson Key]
      ,[WWI Invoice ID]
--      ,[Description] есть [Comments] но он другой размерности. Есть в [Sales].[InvoiceLines]
--      ,[Package] в [Sales].[OrderLines] должно быть преобразование из [PackageTypeID] в [Package]
      ,[Quantity]
      ,[Unit Price]
--      ,[Tax Rate]	=	InvoiceLines.[TaxRate]
--      ,[Total Excluding Tax] =   InvoiceLines.[TaxAmount]
--      ,[Tax Amount] =  InvoiceLines.[TaxAmount]
--      ,[Profit] = InvoiceLines.[LineProfit]
--      ,[Total Including Tax] =(InvoiceLines.[TaxAmount]*InvoiceLines.[Quantity])
--      ,[Total Dry Items] - высушенные
--      ,[Total Chiller Items] - охлажденный
--      ,[Lineage Key] - ключ происхождения данных
)
select odr.[OrderID], cus.DeliveryCityID, odr.CustomerID, inv.BillToCustomerID, ln.StockItemID,
inv.InvoiceDate, odr.SalespersonPersonID, inv.InvoiceID, ln.[Quantity], ln.[UnitPrice] 
from [WideWorldImporters].[Sales].[Orders] odr 
inner join [WideWorldImporters].[Sales].[OrderLines] ln on ln.OrderId = odr.OrderID
inner join [WideWorldImporters].[Sales].[Customers] cus on cus.CustomerID = odr.CustomerID
inner join [WideWorldImporters].[Sales].[Invoices] inv on inv.OrderID = odr.OrderID
--Inner join [WideWorldImporters].[Sales].[InvoiceLines] invln on invln.InvoiceID = inv.InvoiceID не хватает связи по OderLineId
