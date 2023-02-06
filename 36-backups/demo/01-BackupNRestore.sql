
--резервное копирование системных баз данных
BACKUP DATABASE master
TO DISK = 'C:\D\Backups\master.bak'
 
BACKUP DATABASE model
TO DISK = 'C:\D\Backups\model.bak'
 
BACKUP DATABASE msdb
TO DISK = 'C:\D\Backups\msdb.bak'



--создание первой полной резервной копии
BACKUP DATABASE sbase
TO DISK = 'C:\D\Backups\sbase.bak'



--Добавим данные в созданную базу
use sbase;
--Создадим таблицу test
 CREATE TABLE test(
  id INT,
  name VARCHAR(MAX)
  );
--Добавим данные
INSERT INTO test (id,name)
VALUES
  (1, 'Student Ivan'),
  (2, 'Student Sasha'),
  (3, 'Student Masha'); 



  --Делаем полный бэкап
 BACKUP DATABASE sbase
TO DISK = 'C:\D\Backups\sbase_full'--полный бекап для последующего разностного восстановления
 
--Добавим еще данные
INSERT INTO test (id,name)
VALUES
  (4, 'Student Misha'),
  (5, 'Student Sasha'),
  (6, 'Student Misha'),
  (7, 'Student Sasha'),
  (8, 'Student Misha'),
  (9, 'Student Sasha'),
  (10, 'Student Masha'); 

  select * from test;

BACKUP DATABASE sbase --  бэкап разницы от полного до включая дополнительные данные
TO DISK = 'C:\D\Backups\sbase_dif'
WITH DIFFERENTIAL;


INSERT INTO test (id,name)
VALUES
  (11, 'Student Dasha'); 
--Резервное копирование журнала транзакций
BACKUP LOG sbase
TO DISK = 'C:\D\Backups\sbase_tran.bak'


--Резервное копирование файловых групп
-- как восстановиться из резервной копии файлой группы
-- https://www.sqlshack.com/database-filegroups-and-piecemeal-restores-in-sql-server/ 
BACKUP DATABASE sbase
FILEGROUP = 'PRIMARY'
TO DISK = 'C:\D\Backups\primary.bak'



--Восстановление из первой резервной копии
USE master
GO
ALTER DATABASE sbase
SET SINGLE_USER -- если не сделать, то будет предупреждение, можно закрыть все подключения к бд
--Откатывает все неподтвержденные транзакции в базе данных.
WITH ROLLBACK IMMEDIATE
GO
RESTORE DATABASE sbase
FROM DISK='C:\D\Backups\sbase.bak'
WITH REPLACE
GO

-- проверка что есть

--Восстановление из полной резервной копии -->
USE master
ALTER DATABASE sbase
--переводим в SINGLE_USER
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE
--откатываем неподтвержденные
RESTORE DATABASE sbase
FROM  DISK = 'C:\D\Backups\sbase_full' --полная копия
--WITH  FILE = 1,  NORECOVERY, REPLACE --без проверки
WITH  FILE = 1,  RECOVERY, REPLACE -- можно с промежуточной проверкой
-- <--
use sbase;
select * from test;


--разностное восстановление
USE master
ALTER DATABASE sbase
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE
RESTORE DATABASE sbase
FROM  DISK = 'C:\D\Backups\sbase_full'-- из полной копии
WITH  FILE = 1,  NORECOVERY, REPLACE
RESTORE DATABASE sbase
FROM  DISK = 'C:\D\Backups\sbase_dif'-- из разностного
WITH  FILE = 1,  RECOVERY, REPLACE

--проверка
use sbase;
select * from test;


--Восстановление журнала транзакций.
USE master
ALTER DATABASE sbase
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE
RESTORE DATABASE sbase
FROM  DISK = 'C:\D\Backups\sbase_full'-- из полной копии
WITH  FILE = 1,  NORECOVERY, REPLACE
RESTORE DATABASE sbase
FROM  DISK = 'C:\D\Backups\sbase_dif'-- из разностного
WITH  FILE = 1,  NORECOVERY, REPLACE
RESTORE LOG sbase
FROM  DISK = 'C:\D\Backups\sbase_tran.bak'-- из журнала
WITH  FILE = 1,  RECOVERY

--проверка
use sbase;
select * from test;

--Пример восстановления до определенного времени
/*go
restore log [databasename] from disk='путь к файлу бэкапа лога' with norecovery,stopat='нужно время'
*/


--Восстановление файловых групп
RESTORE DATABASE sbase FILEGROUP = 'PRIMARY'
FROM DISK = 'C:\D\Backups\primary.bak'
WITH PARTIAL, RECOVERY, REPLACE


--посмотреть файл бэкапа
RESTORE VERIFYONLY FROM DISK = 'C:\D\Backups\sbase.bak' WITH STATS

--посмотреть заголовок файла бэкапа
RESTORE HEADERONLY   
FROM DISK = N'C:\D\Backups\sbase.bak'   
WITH NOUNLOAD; 


