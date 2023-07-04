--смерджим 2 пустые секции
Alter Partition Function fnYearPartition() MERGE RANGE ('20120101');

--разделим секцию
Alter Partition Function fnYearPartition() SPLIT RANGE ('20140701');	

--Alter Partition Function fnYearPartition() MERGE RANGE ('20140701');

--разделим секцию
Alter Partition Function fnYearPartition() SPLIT RANGE ('20120101');	

--странкейтим партицию 
TRUNCATE TABLE Sales.InvoicesYears
WITH (PARTITIONS (4));

-- переключить схему хранения для последующих партиций
ALTER PARTITION SCHEME [schmYearPartition]  
NEXT USED [YearData]; 
