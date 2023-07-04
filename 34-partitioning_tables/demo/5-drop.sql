DROP TABLE IF EXISTS [Sales].InvoicesPartitioned;

DROP TABLE IF EXISTS [Sales].InvoiceLinesPartitioned;

DROP TABLE IF EXISTS  [Sales].[InvoicesYears];

DROP TABLE IF EXISTS [Sales].[InvoiceLinesYears];

DROP TABLE IF EXISTS [dbo].[MyTempStaging];
DROP TABLE IF EXISTS [dbo].[MyTempTable];

DROP  PARTITION SCHEME [schmYearPartition];

DROP PARTITION FUNCTION [fnYearPartition];

ALTER DATABASE [WideWorldImporters]  REMOVE FILE [Years];

ALTER DATABASE [WideWorldImporters] REMOVE FILEGROUP [YearData];
