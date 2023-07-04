/*
Missing Index Details from 10_query3 110 sort.sql - RDWN-220729-02\MSSQLServer01.WideWorldImporters (VIMPELCOM_MAIN\KNKucherova (55))
The Query Processor estimates that implementing the following index could improve the query cost by 55.3001%.
*/

/*
USE [WideWorldImporters]
GO
CREATE NONCLUSTERED INDEX IX_Invoices_InvoiceDate_Include_CustomerID_BillToCustomerID_SalespersonPersonID
ON [Sales].[Invoices] ([InvoiceDate])
INCLUDE ([CustomerID],[BillToCustomerID],[SalespersonPersonID])
GO
*/
