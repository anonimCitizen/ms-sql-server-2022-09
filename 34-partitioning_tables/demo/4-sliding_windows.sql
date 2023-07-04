use WideWorldImporters;
DROP TABLE if EXISTS MyTempTable;
DROP TABLE if EXISTS MyTempStaging;

CREATE TABLE MyTempTable (
  Id int ,
  Created DATE,
  Data nvarchar(1000) NULL,
  CONSTRAINT [PK_MyTempTable] PRIMARY KEY CLUSTERED 
(
	ID ASC,
	Created ASC
)
) ON [schmYearPartition] (Created)

CREATE TABLE MyTempStaging (
  Id int ,
  Created DATE,
  Data nvarchar(1000) NULL,
  CONSTRAINT [PK_MyTempStage] PRIMARY KEY CLUSTERED 
(
	ID ASC,
	Created ASC) 
) ON [schmYearPartition] (Created);

--наполним таблички
INSERT INTO [dbo].[MyTempTable] ([Id],[Created],[Data])
     VALUES (5,'20180101','asdsf'), (11,'20110101','asdsf2')
GO


--наполним стейджинг
INSERT INTO [dbo].MyTempStaging ([Id],[Created],[Data])
     VALUES (14,'20150101','asdsf')
GO

--посмотрим, что внутри таблицы
SELECT $PARTITION.fnYearPartition(Created) AS Partition,   
COUNT(*) AS [COUNT], MIN(Created),MAX(Created) 
FROM MyTempTable
GROUP BY $PARTITION.fnYearPartition(Created) 
ORDER BY Partition ;  

select * from MyTempTable;

--посмотрим, что внутри таблицы Стейджинг
SELECT $PARTITION.fnYearPartition(Created) AS Partition,   
COUNT(*) AS [COUNT], MIN(Created),MAX(Created) 
FROM [MyTempStaging]
GROUP BY $PARTITION.fnYearPartition(Created) 
ORDER BY Partition ;  

select * from MyTempTable;
select * from MyTempStaging;
-- очистим таблицу стейджинг
truncate table MyTempStaging;

-- перенесем 8 секцию из MyTempTable в MyTempStaging
ALTER TABLE MyTempTable SWITCH PARTITION 8 TO [MyTempStaging] PARTITION 8;

