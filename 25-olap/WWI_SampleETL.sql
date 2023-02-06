insert into [WideWorldImportersDW].[Fact].[Sale]

select  --identity as [Sale Key]
		inv.InvoiceID as [WWI Invoice ID]
		,inv.[InvoiceDate] as [Invoice Date Key]
		,invln.Description as [Description]
		--,invln.[PackageTypeID] as [Package] --ETL преобразование упаковки
		,invln.[Quantity] as [Quantity]
		,invln.[UnitPrice] as [Unit Price]
		,invln.TaxRate as [Tax Rate]
		--, as [Total Excluding Tax] --ETL вычесть налог = (invln.[Quantity] * invln.[UnitPrice])- invln.[TaxAmount]
		,invln.[TaxAmount] as [Tax Amount]
		--, as [Profit]				--ETL COST - invln.[Quantity] * invln.[UnitPrice]
		-- , as [Total Including Tax] -- ETL плюс налог = (invln.[Quantity] * invln.[UnitPrice])+ invln.[TaxAmount]
		--, as [Total Dry Items] -- ETL
		-- , as [Total Chiller Items] ETL
		-- , as [Lineage Key] --ETL спрвочник источников данных
from [WideWorldImporters].[Sales].[Invoices] inv
join [WideWorldImporters].[Sales].[InvoiceLines] invln 
on invln.InvoiceID = inv.InvoiceID


select * from [WideWorldImportersDW].Fact.Sale