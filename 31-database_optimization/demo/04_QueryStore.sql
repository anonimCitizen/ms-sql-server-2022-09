Use WideWorldImporters;
--Query Store

--4 
select * from Sales.Invoices inv
where inv .BillToCustomerID = 1060


-- 22 165
select * from Sales.Invoices inv
where inv .BillToCustomerID = 401

-- смотрим планы

-- параметризируем запросы

DBCC FREEPROCCACHE
GO

EXEC sp_executesql
N'select * from Sales.Invoices inv
where inv.BillToCustomerID = @BillToCustomerID;', N'@BillToCustomerID INT',@BillToCustomerID = 1060;
GO

EXEC sp_executesql
N'select * from Sales.Invoices inv
where inv.BillToCustomerID = @BillToCustomerID;', N'@BillToCustomerID INT',@BillToCustomerID = 401;
GO

-- Везде Index Seek

-- Запустим в обратнном порядке


DBCC FREEPROCCACHE
GO

EXEC sp_executesql
N'select * from Sales.Invoices inv
where inv.BillToCustomerID = @BillToCustomerID;', N'@BillToCustomerID INT',@BillToCustomerID = 401;
GO

EXEC sp_executesql
N'select * from Sales.Invoices inv
where inv.BillToCustomerID = @BillToCustomerID;', N'@BillToCustomerID INT',@BillToCustomerID = 1060;
GO


ALTER DATABASE WideWorldImporters
SET QUERY_STORE = ON;
GO

-- в SSMS
-- обновление в 1

-- запускаем отсюда несколько раз
DBCC FREEPROCCACHE
GO

EXEC sp_executesql
N'select * from Sales.Invoices inv
where inv.BillToCustomerID = @BillToCustomerID;', N'@BillToCustomerID INT',@BillToCustomerID = 1060;
GO

EXEC sp_executesql
N'select * from Sales.Invoices inv
where inv.BillToCustomerID = @BillToCustomerID;', N'@BillToCustomerID INT',@BillToCustomerID = 401;
GO

DBCC FREEPROCCACHE
GO

EXEC sp_executesql
N'select * from Sales.Invoices inv
where inv.BillToCustomerID = @BillToCustomerID;', N'@BillToCustomerID INT',@BillToCustomerID = 401;
GO

EXEC sp_executesql
N'select * from Sales.Invoices inv
where inv.BillToCustomerID = @BillToCustomerID;', N'@BillToCustomerID INT',@BillToCustomerID = 1060;
GO
-- до сюда

-- TOP RESOURCES CONSUMiNG QUERIES
-- FORCE PLAN