use WideWorldImporters;

declare @total int = 100000;
declare @count int = 1;

WHILE @count < @total
BEGIN
SELECT * from [dbo].[Workload] ORDER by WorkloadName;
select * from Sales.Invoices inv
where inv .BillToCustomerID = 401;
insert into [dbo].[Workload]([WorloadID], WorkloadName) values(@count, 'test')
set @count = @count+1;
END

set @count = 1;
WHILE @count < @total
BEGIN
SELECT * from [dbo].[Workload] ORDER by WorkloadName;
select * from Sales.Invoices inv
where inv .BillToCustomerID = 401;
update [dbo].[Workload] set [WorkloadName] = 'boom'
where [WorloadID] = @count;
set @count = @count+1;
END

set @count = 1;
WHILE @count < @total
BEGIN
SELECT * from [dbo].[Workload] ORDER by WorkloadName;
select * from Sales.Invoices inv
where inv .BillToCustomerID = 401;
delete from [dbo].[Workload] where [WorloadID] =@count;
set @count = @count+1;
END

truncate table [dbo].[Workload]



