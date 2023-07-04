--https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog?view=sql-server-ver16
-- system-versioned temporal table = ������ ������������ ��������� [ValidFrom] � [ValidTo]
-- https://docs.microsoft.com/ru-ru/sql/relational-databases/tables/temporal-tables?redirectedfrom=MSDN&view=sql-server-ver16#Anchor_0 
insert into [WideWorldImportersDW].[Dimension].[Customer]
(     [Customer Key]
      ,[WWI Customer ID] -- ��������������, ��� ��� ���� �� ������ �������� WWI
      ,[Customer]
      ,[Bill To Customer]
      ,[Category]
      ,[Buying Group]
      ,[Primary Contact]
      ,[Postal Code]
      ,[Valid From]
      ,[Valid To]
--      ,[Lineage Key] = ���� ������������� ������
)
select [CustomerID], [CustomerID], [CustomerName],[BillToCustomerID],
[BillToCustomerID],[CustomerCategoryID],[BuyingGroupID],[PrimaryContactPersonID],
[PostalPostalCode],[ValidFrom],[ValidTo]
from [WideWorldImporters].[Sales].[Customers]