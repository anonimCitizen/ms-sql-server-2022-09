-- To allow advanced options to be changed.  
EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  

SELECT @@SERVERNAME
--
-- truncate table sales.InvoiceLinesYears;
-- сделаем через bulk insert, т.к. в таблице Sales.InsvoiceLines нет поля с датой для секционирования
exec master..xp_cmdshell 'bcp "SELECT [InvoiceLineID] ,L.[InvoiceID],I.[InvoiceDate],[StockItemID],[Description] ,[PackageTypeID], [Quantity], [UnitPrice], [TaxRate] ,[TaxAmount] ,[LineProfit],[ExtendedPrice],L.[LastEditedBy],L.[LastEditedWhen] FROM [WideWorldImporters].Sales.Invoices AS I	JOIN [WideWorldImporters].Sales.InvoiceLines AS L ON I.InvoiceID = L.InvoiceID" queryout "d:\1\mssql\InvoiceLines.txt" -T -w -t "@eu&$" -S VIC-PC\MSSQLSERVER17'

exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.Invoices" out  "d:\1\mssql\Invoices.txt" -T -w -t "@eu&$" -S VIC-PC\MSSQLSERVER17'

--зальем данные в наши партиционированные таблицы
DECLARE 
	@path VARCHAR(256),
	@FileName VARCHAR(256),
	@onlyScript BIT, 
	@query	nVARCHAR(MAX),
	@dbname VARCHAR(255),
	@batchsize INT
	
	SELECT @dbname = DB_NAME();
	SET @batchsize = 1000;

	/*******************************************************************/
	/*******************************************************************/
	/******Change for path and file name*******************************/
	SET @path = 'd:\1\mssql\';
	SET @FileName = 'InvoiceLines.txt';
	/*******************************************************************/
	/*******************************************************************/
	/*******************************************************************/

	SET @onlyScript = 0;
	
	BEGIN TRY

		IF @FileName IS NOT NULL
		BEGIN
			SET @query = 'BULK INSERT ['+@dbname+'].[Sales].[InvoiceLinesYears]
				   FROM "'+@path+@FileName+'"
				   WITH 
					 (
						BATCHSIZE = '+CAST(@batchsize AS VARCHAR(255))+', 
						DATAFILETYPE = ''widechar'',
						FIELDTERMINATOR = ''@eu&$'',
						ROWTERMINATOR =''\n'',
						KEEPNULLS,
						TABLOCK        
					  );'

			PRINT @query

			IF @onlyScript = 0
				EXEC sp_executesql @query 
			PRINT 'Bulk insert '+@FileName+' is done, current time '+CONVERT(VARCHAR, GETUTCDATE(),120);
		END;
	END TRY

	BEGIN CATCH
		SELECT   
			ERROR_NUMBER() AS ErrorNumber  
			,ERROR_MESSAGE() AS ErrorMessage; 

		PRINT 'ERROR in Bulk insert '+@FileName+' , current time '+CONVERT(VARCHAR, GETUTCDATE(),120);

	END CATCH
	
select Count(*) AS InvoiceLines from [Sales].[InvoiceLinesYears];
GO



DECLARE 
	@path VARCHAR(256),
	@FileName VARCHAR(256),
	@onlyScript BIT, 
	@query	nVARCHAR(MAX),
	@dbname VARCHAR(255),
	@batchsize INT
	
	SELECT @dbname = DB_NAME();
	SET @batchsize = 1000;
	SET @onlyScript = 0
	/*******************************************************************/
	/*******************************************************************/
	/******Change for path and file name*******************************/
	SET @path = 'd:\1\mssql\';
SET @FileName = 'Invoices.txt';
BEGIN TRY

		IF @FileName IS NOT NULL
		BEGIN
			SET @query = 'BULK INSERT ['+@dbname+'].[Sales].[InvoicesYears]
				   FROM "'+@path+@FileName+'"
				   WITH 
					 (
						BATCHSIZE = '+CAST(@batchsize AS VARCHAR(255))+', 
						DATAFILETYPE = ''widechar'',
						FIELDTERMINATOR = ''@eu&$'',
						ROWTERMINATOR =''\n'',
						KEEPNULLS,
						TABLOCK        
					  );'

			PRINT @query

			IF @onlyScript = 0
				EXEC sp_executesql @query 
			PRINT 'Bulk insert '+@FileName+' is done, current time '+CONVERT(VARCHAR, GETUTCDATE(),120);
		END;
	END TRY

	BEGIN CATCH
		SELECT   
			ERROR_NUMBER() AS ErrorNumber  
			,ERROR_MESSAGE() AS ErrorMessage; 

		PRINT 'ERROR in Bulk insert '+@FileName+' , current time '+CONVERT(VARCHAR, GETUTCDATE(),120);

	END CATCH

select Count(*) AS Invoices from [Sales].[InvoiceLinesYears];

-- посмотрим план запроса
-- все грустно %(
SELECT 
	Inv.InvoiceID, Inv.InvoiceDate, 
	Details.Quantity, Details.UnitPrice
FROM Sales.InvoicesYears AS Inv
	JOIN Sales.InvoiceLinesYears AS Details
		ON Inv.InvoiceID = Details.InvoiceID
			AND Inv.InvoiceDate = Details.InvoiceDate
WHERE Inv.CustomerID = 1;

-- смотрим план, где используется нужная секция
SELECT 
	Inv.InvoiceID, Inv.InvoiceDate, 
	Details.Quantity, Details.UnitPrice
FROM Sales.InvoicesYears AS Inv
	JOIN Sales.InvoiceLinesYears AS Details
		ON Inv.InvoiceID = Details.InvoiceID
			AND Inv.InvoiceDate = Details.InvoiceDate
WHERE Inv.CustomerID = 1
	AND Inv.InvoiceDate > '20160101'
		AND Inv.InvoiceDate < '20160501';


--космический план
SELECT Client.CustomerName, 
	Inv.InvoiceID, Inv.InvoiceDate, 
	Item.StockItemName, 
	Details.Quantity, Details.UnitPrice, PayClient.CustomerName AS BillForCustomer
FROM Sales.InvoicesYears AS Inv
	JOIN Sales.InvoiceLinesYears AS Details
		ON Inv.InvoiceID = Details.InvoiceID
	JOIN Sales.Customers AS Client 
		ON Client.CustomerID = Inv.CustomerID
	JOIN Application.People AS People
		ON People.PersonID = Inv.SalespersonPersonID
	JOIN Sales.Customers AS PayClient 
		ON PayClient.CustomerID = Inv.BillToCustomerID
	INNER LOOP JOIN Warehouse.StockItems AS Item 
		ON Item.StockItemID = Details.StockItemID
WHERE PayClient.CustomerID = 1;

