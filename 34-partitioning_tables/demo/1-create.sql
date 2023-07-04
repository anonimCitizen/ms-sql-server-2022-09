use WideWorldImporters;
--смотрим какие таблицы партиционированы
select distinct t.name
from sys.partitions p
inner join sys.tables t
	on p.object_id = t.object_id
where p.partition_number <> 1

--смотрим как конкретно по диапазонам распределились данные
SELECT  $PARTITION.fnYearPartition(InvoiceDate) AS Partition
		, COUNT(*) AS [COUNT]
		, MIN(InvoiceDate)
		,MAX(InvoiceDate) 
FROM Sales.InvoicesYears
GROUP BY $PARTITION.fnYearPartition(InvoiceDate) 
ORDER BY Partition ;  

select * from sys.partition_range_values;
select * from sys.partition_parameters;
select * from sys.partition_functions;

--можем посмотреть текущие границы
select	 f.name as NameHere
		,f.type_desc as TypeHere
		,(case when f.boundary_value_on_right=0 then 'LEFT' else 'Right' end) as LeftORRightHere
		,v.value
		,v.boundary_id
		,t.name from sys.partition_functions f
inner join  sys.partition_range_values v
	on f.function_id = v.function_id
inner join sys.partition_parameters p
	on f.function_id = p.function_id
inner join sys.types t
	on t.system_type_id = p.system_type_id
order by NameHere, boundary_id;

--создадим файловую группу
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [YearData]
GO

--добавляем файл БД
ALTER DATABASE [WideWorldImporters] ADD FILE 
( NAME = N'Years', FILENAME = N'D:\1\mssql\Yeardata.ndf' , 
SIZE = 1097152KB , FILEGROWTH = 65536KB ) TO FILEGROUP [YearData]
GO

--создаем функцию партиционирования по годам - по умолчанию left!!
CREATE PARTITION FUNCTION [fnYearPartition](DATE) AS RANGE RIGHT FOR VALUES
('20120101','20130101','20140101','20150101','20160101', '20170101',
 '20180101', '20190101', '20200101', '20210101');																																																									
GO

-- партиционируем, используя созданную функцию
CREATE PARTITION SCHEME [schmYearPartition] AS PARTITION [fnYearPartition] 
ALL TO ([YearData])
GO


SELECT count(*) 
FROM Sales.Invoices;

--создаем таблицу для секционированния 
SELECT * INTO Sales.InvoicesPartitioned
FROM Sales.Invoices;

-- на существующей таблице надо удалить кластерный индекс и создать новый кластерный индекс с ключом секционирования
-- можно создать через свойства таблицы -> хранилище

--создадим новую партиционированную таблицу
CREATE TABLE [Sales].[InvoiceLinesYears](
	[InvoiceLineID] [int] NOT NULL,
	[InvoiceID] [int] NOT NULL,
	[InvoiceDate] [date] NOT NULL,
	[StockItemID] [int] NOT NULL,
	[Description] [nvarchar](100) NOT NULL,
	[PackageTypeID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[UnitPrice] [decimal](18, 2) NULL,
	[TaxRate] [decimal](18, 3) NOT NULL,
	[TaxAmount] [decimal](18, 2) NOT NULL,
	[LineProfit] [decimal](18, 2) NOT NULL,
	[ExtendedPrice] [decimal](18, 2) NOT NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
) ON [schmYearPartition]([InvoiceDate])---в схеме [schmYearPartition] по ключу [InvoiceDate]
GO

--создадим кластерный индекс в той же схеме с тем же ключом
ALTER TABLE [Sales].[InvoiceLinesYears] ADD CONSTRAINT PK_Sales_InvoiceLinesYears 
PRIMARY KEY CLUSTERED  (InvoiceDate, InvoiceId, InvoiceLineId)
 ON [schmYearPartition]([InvoiceDate]);

--то же самое для второй таблицы
CREATE TABLE [Sales].[InvoicesYears](
	[InvoiceID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[BillToCustomerID] [int] NOT NULL,
	[OrderID] [int] NULL,
	[DeliveryMethodID] [int] NOT NULL,
	[ContactPersonID] [int] NOT NULL,
	[AccountsPersonID] [int] NOT NULL,
	[SalespersonPersonID] [int] NOT NULL,
	[PackedByPersonID] [int] NOT NULL,
	[InvoiceDate] [date] NOT NULL,
	[CustomerPurchaseOrderNumber] [nvarchar](20) NULL,
	[IsCreditNote] [bit] NOT NULL,
	[CreditNoteReason] [nvarchar](max) NULL,
	[Comments] [nvarchar](max) NULL,
	[DeliveryInstructions] [nvarchar](max) NULL,
	[InternalComments] [nvarchar](max) NULL
) ON [schmYearPartition]([InvoiceDate])
GO

ALTER TABLE [Sales].[InvoicesYears] ADD CONSTRAINT PK_Sales_InvoicesYears 
PRIMARY KEY CLUSTERED  (InvoiceDate, InvoiceId)
 ON [schmYearPartition]([InvoiceDate]);
 
